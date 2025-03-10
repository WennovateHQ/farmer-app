import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:page_transition/page_transition.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

// Services
import 'shared/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create instance of AuthService
  final authService = AuthService();
  await authService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
      ],
      child: const FreshFamilyApp(),
    ),
  );
}

class FreshFamilyApp extends StatelessWidget {
  const FreshFamilyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the auth service to determine initial route
    final authService = Provider.of<AuthService>(context);

    return MaterialApp(
      title: 'FreshFarmily Farmer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.light(
          primary: Colors.green,
          secondary: Colors.lightGreen,
          surface: Colors.white,
          onPrimary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.green,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
        ),
      ),
      initialRoute: authService.isAuthenticated ? '/home' : '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return PageTransition(
              type: PageTransitionType.rightToLeft,
              child: const LoginScreen(),
            );
          case '/register':
            return PageTransition(
              type: PageTransitionType.rightToLeft,
              child: const RegisterScreen(),
            );
          case '/home':
            return PageTransition(
              type: PageTransitionType.fade,
              child: const HomeScreen(),
            );
          case '/forgot-password':
            return PageTransition(
              type: PageTransitionType.rightToLeft,
              child: const ForgotPasswordScreen(),
            );
          case '/reset-password':
            return PageTransition(
              type: PageTransitionType.rightToLeft,
              settings: settings,
              child: const ResetPasswordScreen(),
            );
          case '/verify-email':
            return PageTransition(
              type: PageTransitionType.rightToLeft,
              settings: settings,
              child: const EmailVerificationScreen(),
            );
          case '/profile':
            return PageTransition(
              type: PageTransitionType.bottomToTop,
              child: const ProfileScreen(),
            );
          case '/onboarding':
            return PageTransition(
              type: PageTransitionType.rightToLeft,
              child: const FarmerOnboardingScreen(),
            );
          default:
            return PageTransition(
              type: PageTransitionType.fade,
              child: authService.isAuthenticated
                  ? const HomeScreen()
                  : const LoginScreen(),
            );
        }
      },
    );
  }
}
