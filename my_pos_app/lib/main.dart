import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_pos_app/providers/pos_provider.dart';
import 'package:my_pos_app/screens/welcome_screen.dart';

void main() {
  runApp(const MyPosApp());
}

class MyPosApp extends StatelessWidget {
  const MyPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<POSProvider>(
          create: (_) => POSProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Command Center POS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFB4C5FF),
            onPrimary: Color(0xFF002A78),
            primaryContainer: Color(0xFF2563EB),
            onPrimaryContainer: Color(0xFFEEEFFF),
            secondary: Color(0xFFB7C8E1),
            onSecondary: Color(0xFF213145),
            secondaryContainer: Color(0xFF3A4A5F),
            onSecondaryContainer: Color(0xFFA9BAD3),
            tertiary: Color(0xFFFFB596),
            onTertiary: Color(0xFF581E00),
            tertiaryContainer: Color(0xFFBC4800),
            onTertiaryContainer: Color(0xFFFFEDE6),
            error: Color(0xFFFFB4AB),
            onError: Color(0xFF690005),
            errorContainer: Color(0xFF93000A),
            onErrorContainer: Color(0xFFFFDAD6),
            surface: Color(0xFF11131B),
            onSurface: Color(0xFFE1E2ED),
            onSurfaceVariant: Color(0xFFC3C6D7),
            outline: Color(0xFF8D90A0),
            outlineVariant: Color(0xFF434655),
          ),
          scaffoldBackgroundColor: const Color(0xFF11131B),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF11131B),
            foregroundColor: Color(0xFFE1E2ED),
            centerTitle: false,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1D1F27),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF434655)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF434655)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFB4C5FF), width: 2),
            ),
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF1D1F27),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF434655)),
            ),
          ),
        ),
        home: const WelcomeScreen(),
      ),
    );
  }
}
