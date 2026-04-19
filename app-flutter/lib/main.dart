import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/app_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_device_screen.dart';
import 'screens/home/home_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const NexPosLaundryApp());
}

class NexPosLaundryApp extends StatelessWidget {
  const NexPosLaundryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'NexPos Laundry',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const _AppRouter(),
      ),
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AppProvider>().authStatus;

    switch (authStatus) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        return const LoginDeviceScreen();
    }
  }
}
