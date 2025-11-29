import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/login_screen.dart';
import 'features/common/loading_view.dart';
import 'features/home/home_screen.dart';
import 'providers/auth_provider.dart';

class MercaDeaApp extends StatelessWidget {
  const MercaDeaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.green.shade600);
    return MaterialApp(
      title: 'MercaDea',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade50,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isInitializing) {
            return const Scaffold(body: LoadingView());
          }

          if (!auth.isAuthenticated) {
            return const LoginScreen();
          }

          return const HomeScreen();
        },
      ),
    );
  }
}
