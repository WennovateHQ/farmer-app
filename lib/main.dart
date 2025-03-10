import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/themes/fresh_theme.dart';
import 'package:shared/services/local_storage_service.dart';
import 'package:shared/services/notification_service.dart';
import 'package:shared/auth.dart';
import 'package:page_transition/page_transition.dart';
import 'screens/product_inventory_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final localStorageService = LocalStorageService();
  await localStorageService.init();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Create the auth service
  final authService = AuthService();
  await authService.init();

  // Check authentication and onboarding status
  final isLoggedIn = await authService.isLoggedIn();
  final hasCompletedOnboarding =
      await localStorageService.getBool(FreshConfig.onboardingCompleteKey) ??
          false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authService),
      ],
      child: FreshFamilyFarmerApp(
        isLoggedIn: isLoggedIn,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ),
    ),
  );
}

class FreshFamilyFarmerApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool hasCompletedOnboarding;

  const FreshFamilyFarmerApp({
    super.key,
    this.isLoggedIn = false,
    this.hasCompletedOnboarding = false,
  });

  @override
  Widget build(BuildContext context) {
    final appConfig = FreshConfig.getAppConfig('farmer');

    return MaterialApp(
      title: appConfig['appName'],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.light(
          primary: Color(appConfig['primaryColor']),
          secondary: FreshTheme.accent,
          surface: FreshTheme.cardColor,
          onPrimary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
        ),
      ),
      initialRoute: _getInitialRoute(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(appType: 'farmer'),
        '/login': (context) => const LoginScreen(
              appName: appConfig['appName'],
              appLogo: 'assets/images/logo.png',
              appType: 'farmer',
            ),
        '/register': (context) => const RegisterScreen(
              appName: appConfig['appName'],
              appLogo: 'assets/images/logo.png',
              appType: 'farmer',
            ),
        '/dashboard': (context) => const DashboardScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/profile': (context) => const ProfileScreen(
              appType: 'farmer',
            ),
        '/change_password': (context) => const ChangePasswordScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/email_verification') {
          final args = settings.arguments as Map<String, dynamic>?;
          final email = args?['email'] ?? '';
          return PageTransition(
            type: PageTransitionType.fade,
            child: EmailVerificationScreen(email: email),
          );
        } else if (settings.name == '/reset_password') {
          final args = settings.arguments as Map<String, dynamic>?;
          final email = args?['email'] ?? '';
          final token = args?['token'] ?? '';
          return PageTransition(
            type: PageTransitionType.fade,
            child: ResetPasswordScreen(email: email, token: token),
          );
        } else if (settings.name == '/inventory_detail') {
          final args = settings.arguments as Map<String, dynamic>?;
          final productId = args?['productId'] ?? '';
          return PageTransition(
            type: PageTransitionType.rightToLeft,
            child: ProductInventoryScreen(productId: productId),
          );
        }
        return null;
      },
    );
  }

  String _getInitialRoute() {
    if (!hasCompletedOnboarding) {
      return '/onboarding';
    }
    return isLoggedIn ? '/dashboard' : '/login';
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final List<String> _tabTitles = [
    'Products',
    'Orders',
    'Analytics',
    'Profile'
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize any dashboard-specific services here
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Handle notification tap
            },
          ),
        ],
      ),
      body: _getTabPage(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _getTabPage() {
    switch (_selectedIndex) {
      case 0:
        return const ProductsTab();
      case 1:
        return const OrdersTab();
      case 2:
        return const AnalyticsTab();
      case 3:
        return const ProfileTab();
      default:
        return const ProductsTab();
    }
  }
}

// Tab Pages
class ProductsTab extends StatelessWidget {
  const ProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Products Tab - Coming Soon!'),
    );
  }
}

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildOrderItem(context, 'ORD-1234', 'Delivered', 125.50),
                _buildOrderItem(context, 'ORD-1235', 'Processing', 75.20),
                _buildOrderItem(context, 'ORD-1236', 'Pending', 42.99),
                _buildOrderItem(context, 'ORD-1237', 'Cancelled', 63.45),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
      BuildContext context, String id, String status, double total) {
    Color statusColor;
    switch (status) {
      case 'Delivered':
        statusColor = Colors.green;
        break;
      case 'Processing':
        statusColor = Colors.blue;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  id,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
                'Order Date: ${DateTime.now().subtract(const Duration(days: 2)).toString().substring(0, 10)}'),
            const SizedBox(height: 8),
            Text('Total: \$${total.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Navigate to order details
              },
              child: const Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Analytics Tab - Coming Soon!'),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: authService.userData?['profileImage'] !=
                            null
                        ? NetworkImage(authService.userData!['profileImage'])
                        : null,
                    child: authService.userData?['profileImage'] == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authService.userData?['name'] ?? 'Farm Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authService.userData?['email'] ?? 'email@example.com',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Edit Profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/change_password');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to settings
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help Center'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to help center
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to about
              },
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final result = await authService.logout();
                if (result) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
