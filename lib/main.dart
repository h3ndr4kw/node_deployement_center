import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Node Deployment Center',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.light,
          surface: Colors.white,
          onSurface: const Color(0xFF111827),
          outline: Colors.grey.shade200,
        ),
        cardColor: Colors.white,
        dividerColor: const Color.fromRGBO(238, 238, 238, 1),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme)
            .apply(
              bodyColor: const Color(0xFF1F2937),
              displayColor: const Color(0xFF111827),
            ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(
          0xFF1E1F22,
        ), // JetBrains Background
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.dark,
          surface: const Color(0xFF2B2D30), // JetBrains Surface
          onSurface: const Color(0xFFDFE1E5), // JetBrains Text
          outline: const Color(0xFF4E5155), // JetBrains Border
        ),
        cardColor: const Color(0xFF2B2D30),
        dividerColor: const Color(0xFF43454A),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).apply(bodyColor: const Color(0xFFBCBEC4), displayColor: Colors.white),
      ),
      home: const HomeScreen(),
    );
  }
}
