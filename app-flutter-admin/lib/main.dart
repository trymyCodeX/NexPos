import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/admin_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/outlets/outlets_screen.dart';
import 'screens/devices/devices_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/account/account_screen.dart';
import 'screens/superadmin/superadmin_login_screen.dart';
import 'screens/superadmin/superadmin_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NexPosAdminApp());
}

class NexPosAdminApp extends StatelessWidget {
  const NexPosAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OutletProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SuperAdminProvider()),
      ],
      child: MaterialApp(
        title: 'NexPos Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/forgot-password': (_) => const ForgotPasswordScreen(),
          '/dashboard': (_) => const DashboardScreen(),
          '/outlets': (_) => const OutletsScreen(),
          '/devices': (_) => const DevicesScreen(),
          '/transactions': (_) => const TransactionsScreen(),
          '/reports': (_) => const ReportsScreen(),
          '/notifications': (_) => const NotificationsScreen(),
          '/account': (_) => const AccountScreen(),
          '/superadmin': (_) => const SuperAdminLoginScreen(),
          '/superadmin/dashboard': (_) => const SuperAdminDashboardScreen(),
        },
      ),
    );
  }
}
