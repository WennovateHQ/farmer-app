import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared/models/conversation.dart';
import 'package:shared/services/messaging_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final MessagingService _messagingService = MessagingService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: _messagingService.conversationsStream,
        initialData: _messagingService.conversations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Conversation> conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Messages from customers and drivers will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final lastMessage = conversation.messages.isNotEmpty
                  ? conversation.messages.last
                  : null;

              // Format timestamp
              String timeText = '';
              if (lastMessage != null) {
                final now = DateTime.now();
                final yesterday = DateTime(now.year, now.month, now.day - 1);

                if (lastMessage.timestamp
                    .isAfter(DateTime(now.year, now.month, now.day))) {
                  // Today: show time
                  timeText = DateFormat.jm().format(lastMessage.timestamp);
                } else if (lastMessage.timestamp.isAfter(yesterday)) {
                  // Yesterday
                  timeText = 'Yesterday';
                } else if (lastMessage.timestamp
                    .isAfter(DateTime(now.year, now.month, now.day - 6))) {
                  // Within last week: show day name
                  timeText = DateFormat.E().format(lastMessage.timestamp);
                } else {
                  // Older: show date
                  timeText = DateFormat.MMMd().format(lastMessage.timestamp);
                }
              }

              final bool isOrderRelated = conversation.orderId != null &&
                  conversation.orderId!.isNotEmpty;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getUserColor(conversation.otherUserType),
                  child: Icon(
                    _getUserIcon(conversation.otherUserType),
                    color: Colors.white,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        conversation.otherUserName,
                        style: TextStyle(
                          fontWeight: conversation.unreadMessages
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isOrderRelated)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Order',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: conversation.unreadMessages
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        lastMessage?.text ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: conversation.unreadMessages
                              ? Colors.black87
                              : Colors.grey[600],
                          fontWeight: conversation.unreadMessages
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (conversation.unreadMessages)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        conversationId: conversation.id,
                        recipientId: conversation.otherUserId,
                        recipientType: conversation.otherUserType,
                        recipientName: conversation.otherUserName,
                        orderId: conversation.orderId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      // Demo buttons for testing
      floatingActionButton: _buildTestingButtons(),
    );
  }

  // Helper method to determine avatar color based on user type
  Color _getUserColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'farmer':
        return Colors.green[700]!;
      case 'consumer':
        return Colors.blue[700]!;
      case 'driver':
        return Colors.amber[800]!;
      default:
        return Colors.grey[700]!;
    }
  }

  // Helper method to determine icon based on user type
  IconData _getUserIcon(String userType) {
    switch (userType.toLowerCase()) {
      case 'farmer':
        return Icons.agriculture;
      case 'consumer':
        return Icons.person;
      case 'driver':
        return Icons.delivery_dining;
      default:
        return Icons.person;
    }
  }

  // For testing and demo purposes only
  Widget _buildTestingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'simulateConsumer',
          backgroundColor: Colors.blue,
          mini: true,
          child: const Icon(Icons.person),
          onPressed: () {
            _messagingService.simulateIncomingMessage(
              senderId: 'consumer456',
              senderType: 'consumer',
              senderName: 'Jane Smith',
              text:
                  'I have a question about your organic apples. Are they available for delivery this week?',
              orderId:
                  'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13)}',
            );
          },
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'simulateDriver',
          backgroundColor: Colors.amber,
          mini: true,
          child: const Icon(Icons.delivery_dining),
          onPressed: () {
            _messagingService.simulateIncomingMessage(
              senderId: 'driver789',
              senderType: 'driver',
              senderName: 'Alex Driver',
              text: 'I\'m at your farm for pickup. Where should I park?',
              orderId:
                  'ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13)}',
            );
          },
        ),
      ],
    );
  }
}
