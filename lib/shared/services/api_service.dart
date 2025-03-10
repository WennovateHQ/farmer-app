import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ApiService {
  final String baseUrl = 'https://freshfarmily-api.example.com/api';
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Authentication
  Future<Map<String, dynamic>> login(String email, String password, {String userType = 'farmer'}) async {
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userType', userType);
        return data;
      } else {
        throw Exception('Login failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      // For demo, simulate successful login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userType', userType);
      
      // Return mock user data
      return {
        'token': 'mock_token_12345',
        'user': {
          'id': 1,
          'name': 'Green Valley Farm',
          'email': email,
          'userType': userType,
        }
      };
    }
  }

  // Google Sign In
  Future<Map<String, dynamic>> signInWithGoogle({String userType = 'farmer'}) async {
    try {
      // Start the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }
      
      // Get the authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Use the authentication token to authenticate with our backend
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userType', userType);
        return data;
      } else {
        throw Exception('Google login failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (e.toString() == 'Exception: Google sign in was cancelled') {
        rethrow;
      }
      
      // For demo purposes, simulate successful login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userType', userType);
      
      // Return mock user data
      return {
        'token': 'mock_google_token_12345',
        'user': {
          'id': 1,
          'name': userType == 'farmer' ? 'Green Valley Farm' : 'John Driver',
          'email': 'user@example.com',
          'userType': userType,
          'provider': 'google',
        }
      };
    }
  }

  // Register User
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData, {String userType = 'farmer'}) async {
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userType', userType);
        return data;
      } else {
        throw Exception('Registration failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      // For demo, simulate successful registration
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userType', userType);
      
      // Return mock user data
      return {
        'token': 'mock_token_12345',
        'user': {
          'id': 1,
          'name': userData['name'] ?? (userType == 'farmer' ? 'Green Valley Farm' : 'John Driver'),
          'email': userData['email'],
          'userType': userType,
        }
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
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('isLoggedIn');
      await prefs.remove('userType');
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
        throw Exception('Failed to send password reset email: ${response.reasonPhrase}');
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
        throw Exception('Failed to reset password: ${response.reasonPhrase}');
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
        return true;
      } else {
        throw Exception('Failed to verify email: ${response.reasonPhrase}');
      }
    } catch (e) {
      // For demo, simulate successful email verification
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
        throw Exception('Failed to resend verification email: ${response.reasonPhrase}');
      }
    } catch (e) {
      // For demo, simulate successful email resend
      return true;
    }
  }

  // Update User Profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData) async {
    try {
      final token = await _getToken();
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
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update profile: ${response.reasonPhrase}');
      }
    } catch (e) {
      // For demo, simulate successful profile update
      return {
        'success': true,
        'user': {
          'id': 1,
          'name': userData['name'] ?? 'Green Valley Farm',
          'email': userData['email'] ?? 'farm@example.com',
          'phone': userData['phone'] ?? '555-123-4567',
          'address': userData['address'] ?? '123 Farm Road',
          'profileImage': userData['profileImage'],
        }
      };
    }
  }

  // Upload Profile Image
  Future<String> uploadProfileImage(String filePath) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // In a real implementation, you would use a package like http_parser and http.MultipartRequest
      // to upload the file to the server
      
      // For demo, simulate successful image upload
      return 'https://example.com/uploads/profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  // Get User Profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await _getToken();
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
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get user profile: ${response.reasonPhrase}');
      }
    } catch (e) {
      // For demo, return mock profile data
      return {
        'id': 1,
        'name': 'Green Valley Farm',
        'email': 'farm@example.com',
        'phone': '555-123-4567',
        'address': '123 Farm Road, Farmville, CA 94107',
        'bio': 'We are a family-owned farm specializing in organic vegetables and fruits.',
        'userType': 'farmer',
        'isVerified': true,
        'profileImage': 'https://example.com/uploads/default_farm.jpg',
        'joinedDate': '2023-01-15',
      };
    }
  }

  // General HTTP methods
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('GET request failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      // For demo, return mock data
      return {'status': 'success', 'data': {}};
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('POST request failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      // For demo, return mock response
      return {'status': 'success', 'data': {}};
    }
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('PUT request failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      // For demo, return mock response
      return {'status': 'success', 'data': {}};
    }
  }

  Future<bool> delete(String endpoint) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      // For demo, return mock response
      return true;
    }
  }

  // Get auth token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
