import 'package:flutter/material.dart';
import 'package:shared/models/onboarding_model.dart';
import 'package:shared/screens/onboarding_screen.dart';
import 'package:shared/services/local_storage_service.dart';

/// Farmer App onboarding screen based on Pro-Grocery UI kit design
class FarmerOnboardingScreen extends OnboardingScreen {
  const FarmerOnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _FarmerOnboardingScreenState();
}

class _FarmerOnboardingScreenState
    extends OnboardingScreenState<FarmerOnboardingScreen> {
  @override
  List<OnboardingModel> get onboardingItems => [
        OnboardingModel(
          // Using placeholder icon instead of missing image asset
          placeholderIcon: Icons.eco,
          headline: 'Welcome to FreshFarmily Farmer',
          description:
              'Manage your farm products and connect directly with consumers through our sustainable food platform.',
        ),
        OnboardingModel(
          // Using placeholder icon instead of missing image asset
          placeholderIcon: Icons.bar_chart,
          headline: 'Track Your Sales & Analytics',
          description:
              'Get detailed insights into your sales performance, customer preferences, and earning potential.',
        ),
        OnboardingModel(
          // Using placeholder icon instead of missing image asset
          placeholderIcon: Icons.inventory,
          headline: 'Real-time Inventory Management',
          description:
              'Update your product inventory, pricing, and availability in real-time to maximize your sales.',
        ),
        OnboardingModel(
          // Using placeholder icon instead of missing image asset
          placeholderIcon: Icons.chat,
          headline: 'Direct Customer Communication',
          description:
              'Chat directly with customers about your products and build strong relationships with your community.',
        ),
      ];

  @override
  void onFinishOnboarding() async {
    // Mark onboarding as completed
    final localStorageService = LocalStorageService();
    await localStorageService.setBool('has_completed_onboarding', true);

    // Check if user is already logged in
    final isLoggedIn =
        await localStorageService.getBool('is_logged_in') ?? false;

    if (mounted) {
      if (isLoggedIn) {
        // Navigate to dashboard screen if already logged in
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        // Navigate to login screen
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Color get progressIndicatorColor =>
      const Color(0xFF4CAF50); // Farmer green color
}
