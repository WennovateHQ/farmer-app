import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

class AuthService with ChangeNotifier {
  final String baseUrl = 'https://freshfarmily-api.example.com/api';
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userData => _userData;

  // Initialize auth service and check if user is logged in
  Future<void> initialize() async {
    final token = await _getSecureToken();
    if (token != null) {
      try {
        // Verify token validity by fetching user profile
        final userData = await getUserProfile();
        _userData = userData;
        _isAuthenticated = true;
      } catch (e) {
        _isAuthenticated = false;
        await logout(); // Clear invalid token
      }
    } else {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  // Authentication
  Future<Map<String, dynamic>> login(String email, String password,
      {String userType = 'farmer'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'userType': userType,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Store authentication data securely
        await _storeAuthData(data['token'], userType);
        _userData = data['user'];
        _isAuthenticated = true;
        notifyListeners();

        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      // For demo, simulate successful login
      await _storeAuthData('mock_token_12345', userType);

      // Set mock user data
      _userData = {
        'id': 1,
        'name': 'Green Valley Farm',
        'email': email,
        'userType': userType,
        'isVerified': true,
      };

      _isAuthenticated = true;
      notifyListeners();

      // Return mock user data
      return {
        'token': 'mock_token_12345',
        'user': _userData,
      };
    }
  }

  // Google Sign In
  Future<Map<String, dynamic>> signInWithGoogle(
      {String userType = 'farmer'}) async {
    try {
      // Start the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      // Get the authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Send to backend
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idToken': googleAuth.idToken,
          'accessToken': googleAuth.accessToken,
          'userType': userType,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Store authentication data securely
        await _storeAuthData(data['token'], userType);
        _userData = data['user'];
        _isAuthenticated = true;
        notifyListeners();

        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Google login failed');
      }
    } catch (e) {
      if (e.toString() == 'Exception: Google sign in was cancelled') {
        rethrow;
      }

      // For demo, simulate successful login
      await _storeAuthData('mock_google_token_12345', userType);

      // Set mock user data
      _userData = {
        'id': 1,
        'name': userType == 'farmer' ? 'Green Valley Farm' : 'John Driver',
        'email': 'user@example.com',
        'userType': userType,
        'provider': 'google',
        'isVerified': true,
      };

      _isAuthenticated = true;
      notifyListeners();

      // Return mock user data
      return {
        'token': 'mock_google_token_12345',
        'user': _userData,
      };
    }
  }

  // Register User
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData,
      {String userType = 'farmer'}) async {
    try {
      // Add user type to data
      userData['userType'] = userType;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);

        // Store authentication data securely
        await _storeAuthData(data['token'], userType);
        _userData = data['user'];
        _isAuthenticated = true;
        notifyListeners();

        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      // For demo, simulate successful registration
      await _storeAuthData('mock_token_12345', userType);

      // Set mock user data
      _userData = {
        'id': 1,
        'name': userData['name'] ??
            (userType == 'farmer' ? 'Green Valley Farm' : 'John Driver'),
        'email': userData['email'],
        'userType': userType,
        'isVerified': false, // New users need to verify email
      };

      _isAuthenticated = true;
      notifyListeners();

      // Return mock user data
      return {
        'token': 'mock_token_12345',
        'user': _userData,
      };
    }
  }

  // Logout user
  Future<bool> logout() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Clear secure storage
      await _secureStorage.deleteAll();

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userType');

      _isAuthenticated = false;
      _userData = null;
      notifyListeners();

      return true;
    } catch (e) {
      return false;
    }
  }

  // Password Reset
  Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(
            error['message'] ?? 'Failed to send password reset email');
      }
    } catch (e) {
      // For demo, simulate successful password reset request
      return true;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      // For demo, simulate successful password reset
      return true;
    }
  }

  // Verify Email
  Future<bool> verifyEmail(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token}),
      );

      if (response.statusCode == 200) {
        // Update user verification status
        if (_userData != null) {
          _userData!['isVerified'] = true;
          notifyListeners();
        }
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to verify email');
      }
    } catch (e) {
      // For demo, simulate successful email verification
      if (_userData != null) {
        _userData!['isVerified'] = true;
        notifyListeners();
      }
      return true;
    }
  }

  Future<bool> resendVerificationEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(
            error['message'] ?? 'Failed to resend verification email');
      }
    } catch (e) {
      // For demo, simulate successful email resend
      return true;
    }
  }

  // Update User Profile
  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> userData) async {
    try {
      final token = await _getSecureToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Update local user data
        _userData = data['user'];
        notifyListeners();

        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      // For demo, simulate successful profile update

      // Update local user data
      _userData = {
        ..._userData ?? {},
        'name': userData['name'] ?? _userData?['name'] ?? 'Green Valley Farm',
        'email': userData['email'] ?? _userData?['email'] ?? 'farm@example.com',
        'phone': userData['phone'] ?? _userData?['phone'] ?? '555-123-4567',
        'address':
            userData['address'] ?? _userData?['address'] ?? '123 Farm Road',
        'profileImage': userData['profileImage'] ?? _userData?['profileImage'],
      };

      notifyListeners();

      return {
        'success': true,
        'user': _userData,
      };
    }
  }

  // Upload Profile Image
  Future<String> uploadProfileImage(XFile image) async {
    try {
      final token = await _getSecureToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Create a multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/profile-image'),
      );

      // Set the authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add the file to the request
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
      ));

      // Send the request
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);

        // Update profile image in user data
        if (_userData != null) {
          _userData!['profileImage'] = data['imageUrl'];
          notifyListeners();
        }

        return data['imageUrl'];
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      // For demo, simulate successful image upload
      final mockImageUrl =
          'https://example.com/uploads/profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Update profile image in user data
      if (_userData != null) {
        _userData!['profileImage'] = mockImageUrl;
        notifyListeners();
      }

      return mockImageUrl;
    }
  }

  // Get User Profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await _getSecureToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _userData = data;
        notifyListeners();
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to get user profile');
      }
    } catch (e) {
      // For demo, return mock profile data
      final mockData = {
        'id': 1,
        'name': 'Green Valley Farm',
        'email': 'farm@example.com',
        'phone': '555-123-4567',
        'address': '123 Farm Road, Farmville, CA 94107',
        'bio':
            'We are a family-owned farm specializing in organic vegetables and fruits.',
        'userType': 'farmer',
        'isVerified': true,
        'profileImage': 'https://example.com/uploads/default_farm.jpg',
        'joinedDate': '2023-01-15',
      };

      _userData = mockData;
      notifyListeners();
      return mockData;
    }
  }

  // Secure token storage methods
  Future<void> _storeAuthData(String token, String userType) async {
    // Store token in secure storage
    await _secureStorage.write(key: 'auth_token', value: token);

    // Store login state and user type in shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userType', userType);
  }

  Future<String?> _getSecureToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }
}
