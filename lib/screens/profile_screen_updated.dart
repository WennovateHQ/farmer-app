import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../shared/services/auth_service.dart';
import '../shared/widgets/loading_overlay.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  XFile? _selectedImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Get user data from auth service
      final userData = authService.userData;

      if (userData != null) {
        _nameController.text = userData['name'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _addressController.text = userData['address'] ?? '';
        _bioController.text = userData['bio'] ?? '';
        _profileImageUrl = userData['profileImage'];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Upload image if selected
      if (_selectedImage != null) {
        _profileImageUrl =
            await authService.uploadProfileImage(_selectedImage!);
      }

      // Update profile data
      final userData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'bio': _bioController.text,
        'profileImage': _profileImageUrl,
      };

      await authService.updateProfile(userData);

      if (mounted) {
        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                tooltip: 'Edit Profile',
              )
            else
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _selectedImage = null;
                    _loadUserProfile(); // Reset form
                  });
                },
                tooltip: 'Cancel',
              ),
          ],
        ),
        body: Consumer<AuthService>(
          builder: (context, authService, child) {
            final userData = authService.userData;

            if (userData == null) {
              return const Center(
                child: Text('No user data available'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image
                    GestureDetector(
                      onTap: _isEditing ? _pickImage : null,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _selectedImage != null
                                ? FileImage(File(_selectedImage!.path))
                                : (_profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                        as ImageProvider
                                    : const AssetImage(
                                        'assets/images/default_profile.png')),
                            onBackgroundImageError: (_, __) {},
                            child: _profileImageUrl == null &&
                                    _selectedImage == null
                                ? const Icon(Icons.person,
                                    size: 60, color: Colors.grey)
                                : null,
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    if (_isEditing)
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Farm/Business Name',
                          prefixIcon: const Icon(Icons.business),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your farm/business name';
                          }
                          return null;
                        },
                      )
                    else
                      Text(
                        userData['name'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Email (always readonly)
                    if (_isEditing)
                      TextFormField(
                        controller: _emailController,
                        readOnly: true, // Email cannot be changed
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                        ),
                      )
                    else
                      Text(
                        userData['email'] ?? 'No Email',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),

                    if (!_isEditing)
                      Column(
                        children: [
                          const SizedBox(height: 32),

                          // Verification Badge
                          if (userData['isVerified'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Verified Account',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/verify-email',
                                  arguments: {'email': userData['email']},
                                );
                              },
                              icon: const Icon(Icons.mail_outline),
                              label: const Text('Verify Email'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: const BorderSide(color: Colors.orange),
                              ),
                            ),

                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Phone
                          ListTile(
                            leading:
                                const Icon(Icons.phone, color: Colors.green),
                            title: const Text('Phone'),
                            subtitle: Text(userData['phone'] ?? 'Not provided'),
                          ),

                          // Address
                          ListTile(
                            leading: const Icon(Icons.location_on,
                                color: Colors.green),
                            title: const Text('Address'),
                            subtitle:
                                Text(userData['address'] ?? 'Not provided'),
                          ),

                          // Bio
                          if (userData['bio'] != null &&
                              userData['bio'].isNotEmpty)
                            ListTile(
                              leading: const Icon(Icons.info_outline,
                                  color: Colors.green),
                              title: const Text('About'),
                              subtitle: Text(userData['bio']),
                            ),

                          // Joined Date
                          if (userData['joinedDate'] != null)
                            ListTile(
                              leading: const Icon(Icons.calendar_today,
                                  color: Colors.green),
                              title: const Text('Joined'),
                              subtitle: Text(userData['joinedDate']),
                            ),

                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Logout Button
                          OutlinedButton.icon(
                            onPressed: () async {
                              final shouldLogout = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Logout'),
                                      content: const Text(
                                          'Are you sure you want to logout?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Logout'),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;

                              if (shouldLogout && mounted) {
                                await authService.logout();
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (route) => false,
                                );
                              }
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          const SizedBox(height: 16),

                          // Phone
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

                          // Address
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: 'Farm Address',
                              prefixIcon: const Icon(Icons.location_on),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),

                          // Bio
                          TextFormField(
                            controller: _bioController,
                            decoration: InputDecoration(
                              labelText: 'About Your Farm',
                              prefixIcon: const Icon(Icons.info_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              hintText: 'Tell customers about your farm...',
                            ),
                            maxLines: 5,
                          ),
                          const SizedBox(height: 32),

                          // Save Button
                          ElevatedButton.icon(
                            onPressed: _updateProfile,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Profile'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
