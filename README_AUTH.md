# FreshFarmily Farmer App - Authentication System

## Overview

The FreshFarmily Farmer App features a comprehensive authentication system that enables secure user authentication, profile management, and account maintenance. This document outlines the authentication enhancements implemented in the application.

## Authentication Features

### Core Authentication

- **Email/Password Login**: Traditional login method with email validation and secure password handling
- **Google Sign-In**: OAuth 2.0 integration for single-click login using Google accounts
- **User Registration**: Complete registration flow with validation and optional email verification
- **JWT Token Management**: Secure token storage and handling for API requests
- **Role-Based Permissions**: Access control based on user roles (admin, farmer, driver, consumer)

### Account Management

- **Password Reset**: Secure flow for handling forgotten passwords
- **Email Verification**: Verification process to ensure valid email addresses
- **Profile Management**: Complete user profile editing capabilities
- **Profile Image Upload**: Support for uploading and managing profile images

## Implementation Details

### Authentication Service

The `AuthService` class (`lib/shared/services/auth_service.dart`) is the central component of the authentication system. It:

- Manages authentication state using `ChangeNotifier`
- Handles API communication for all auth-related operations
- Provides secure token storage using `flutter_secure_storage`
- Contains mock implementations for testing without a backend

### Security Features

- **Secure Token Storage**: JWT tokens stored in encrypted storage
- **Password Validation**: Client-side password requirements enforcement
- **Form Validation**: Complete input validation across all authentication forms
- **Error Handling**: Comprehensive error handling with user-friendly messages

### Screens

- **Login Screen**: Email/password login with Google Sign-In option
- **Register Screen**: Complete registration form with validation
- **Forgot Password Screen**: Request password reset via email
- **Reset Password Screen**: Set new password using reset token
- **Email Verification Screen**: Verify email address using verification token
- **Profile Screen**: View and edit user profile information

## Usage

### Login

```dart
final authService = Provider.of<AuthService>(context, listen: false);
try {
  await authService.login(email, password);
  // Navigate to home screen on success
} catch (e) {
  // Handle login errors
}
```

### Registration

```dart
final authService = Provider.of<AuthService>(context, listen: false);
try {
  final userData = {
    'name': name,
    'email': email,
    'password': password,
    // Other user data
  };
  
  await authService.register(userData);
  // Navigate to verification or home screen
} catch (e) {
  // Handle registration errors
}
```

### Google Sign-In

```dart
final authService = Provider.of<AuthService>(context, listen: false);
try {
  await authService.signInWithGoogle();
  // Navigate to home screen on success
} catch (e) {
  // Handle Google sign-in errors
}
```

### Password Reset

```dart
final authService = Provider.of<AuthService>(context, listen: false);
try {
  await authService.requestPasswordReset(email);
  // Show success message
} catch (e) {
  // Handle password reset request errors
}
```

### Profile Management

```dart
final authService = Provider.of<AuthService>(context, listen: false);
try {
  await authService.updateProfile({
    'name': updatedName,
    'email': updatedEmail,
    // Other updated fields
  });
  // Show success message
} catch (e) {
  // Handle profile update errors
}
```

## Testing

The authentication system includes mock implementations that can be used without a backend, making it suitable for testing and development. The system will automatically fall back to these mock implementations if the API requests fail.

## Dependencies

- `provider`: For state management
- `http`: For API communication
- `flutter_secure_storage`: For secure token storage
- `shared_preferences`: For general preferences storage
- `google_sign_in`: For Google authentication
- `image_picker`: For profile image upload

## Future Enhancements

- Two-factor authentication
- Biometric authentication
- Social sign-in options beyond Google
- Enhanced session management with token refresh
