import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared/models/conversation.dart';
import 'package:shared/models/message.dart';
import 'package:shared/services/messaging_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String recipientId;
  final String recipientType;
  final String recipientName;
  final String? orderId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.recipientId,
    required this.recipientType,
    required this.recipientName,
    this.orderId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final MessagingService _messagingService = MessagingService();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();

    // Mark conversation as read when opening chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messagingService.markConversationAsRead(widget.conversationId);

      // Scroll to the bottom when the screen initializes
      if (_scrollController.hasClients) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    // Send the message
    await _messagingService.sendMessage(
      recipientId: widget.recipientId,
      recipientType: widget.recipientType,
      recipientName: widget.recipientName,
      text: text,
      orderId: widget.orderId,
    );

    // Scroll to the bottom to show the new message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recipientName,
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              _getUserTypeTitle(widget.recipientType),
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (widget.orderId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Order #${widget.orderId!.replaceAll('ORD', '')}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside the text field
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Conversation>>(
                stream: _messagingService.conversationsStream,
                initialData: _messagingService.conversations,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final List<Conversation> conversations = snapshot.data ?? [];
                  final conversation = conversations.firstWhere(
                    (c) => c.id == widget.conversationId,
                    orElse: () => Conversation(
                      id: widget.conversationId,
                      otherUserId: widget.recipientId,
                      otherUserType: widget.recipientType,
                      otherUserName: widget.recipientName,
                      messages: [],
                      lastUpdated: DateTime.now(),
                    ),
                  );

                  final messages = conversation.messages;

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet.\nStart the conversation!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Scroll to bottom when new messages arrive
                    if (_scrollController.hasClients) {
                      _scrollToBottom();
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.recipientId == widget.recipientId;

                      // Date separator logic
                      final bool showDateSeparator = index == 0 ||
                          !_isSameDay(messages[index].timestamp,
                              messages[index - 1].timestamp);

                      return Column(
                        children: [
                          if (showDateSeparator)
                            _buildDateSeparator(message.timestamp),
                          _buildMessageBubble(message, isMe),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      minLines: 1,
                      maxLines: 4,
                      onChanged: (text) {
                        setState(() {
                          _isTyping = text.trim().isNotEmpty;
                        });
                      },
                      onSubmitted: (_) {
                        if (_isTyping) {
                          _sendMessage();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: FloatingActionButton(
                      onPressed: _isTyping ? _sendMessage : null,
                      backgroundColor: _isTyping
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                      elevation: _isTyping ? 2 : 0,
                      mini: true,
                      child: Icon(
                        Icons.send,
                        color: _isTyping ? Colors.white : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime timestamp) {
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);

    String dateText;
    if (timestamp.year == today.year &&
        timestamp.month == today.month &&
        timestamp.day == today.day) {
      dateText = 'Today';
    } else if (timestamp.year == yesterday.year &&
        timestamp.month == yesterday.month &&
        timestamp.day == yesterday.day) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat.MMMd().format(timestamp);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: Colors.grey),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              dateText,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 50 : 16,
          right: isMe ? 16 : 50,
          bottom: 8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat.jm().format(message.timestamp),
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getUserTypeTitle(String userType) {
    switch (userType.toLowerCase()) {
      case 'farmer':
        return 'Farmer';
      case 'consumer':
        return 'Customer';
      case 'driver':
        return 'Driver';
      default:
        return 'User';
    }
  }
}
