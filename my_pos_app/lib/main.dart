import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/providers/theme_provider.dart';
import 'package:my_pos_app/theme/app_theme.dart';
import 'package:my_pos_app/screens/welcome_screen.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyPosApp());
}

class MyPosApp extends StatelessWidget {
  const MyPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<POSProvider>(create: (_) => POSProvider()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Update system UI overlay to match the current theme
          final isDark = themeProvider.isDarkMode;
          SystemChrome.setSystemUIOverlayStyle(
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          );

          return MaterialApp(
            title: 'Command Center POS',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const WelcomeScreen(),
          );
        },
      ),
    );
  }
}
