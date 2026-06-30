import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/bills/providers/bills_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/history/providers/history_provider.dart';
import 'features/transfers/providers/transfer_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BadWalletApp());
}

class BadWalletApp extends StatelessWidget {
  const BadWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TransferProvider()),
        ChangeNotifierProvider(create: (_) => BillsProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(
        title: 'BadWallet',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
