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
    const primaryColor = Color(0xFFF24928);
    const secondaryColor = Color(0xFF160D4E);

    final baseScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    );

    final colorScheme = baseScheme.copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: secondaryColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      surface: Colors.white,
      background: Colors.white,
    );

    return MaterialApp(
      title: 'MercaDea',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: secondaryColor,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: secondaryColor,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: secondaryColor, width: 2),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: secondaryColor,
          contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          behavior: SnackBarBehavior.floating,
          shape: StadiumBorder(),
        ),
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
