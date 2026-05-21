import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/onboarding_screen.dart';
import 'providers/app_state.dart';

class SafeShiftApp extends StatelessWidget {
  const SafeShiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'SafeShift AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFB5A1), // Truck-Art Terracotta
            onPrimary: Color(0xFF601300),
            secondary: Color(0xFF2E7D32), // Emerald Tile
            onSecondary: Colors.white,
            background: Color(0xFF131319), // Mughal Indigo
            onBackground: Color(0xFFE4E1EA),
            surface: Color(0xFF1F1F25), // Charcoal Ink
            onSurface: Color(0xFFCFC6B0), // Warm Sandstone
            error: Color(0xFFFFB4AB),
            onError: Color(0xFF690005),
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
            bodyColor: const Color(0xFFCFC6B0),
            displayColor: const Color(0xFFCFC6B0),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Color(0xFFCFC6B0)),
            titleTextStyle: TextStyle(
              color: Color(0xFFCFC6B0), 
              fontSize: 20, 
              fontWeight: FontWeight.w600
            ),
          ),
          scaffoldBackgroundColor: const Color(0xFF131319),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 8,
              shadowColor: const Color(0xFFFFB5A1).withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Round-8
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFFE1D8C1), // High-contrast Sandstone
              foregroundColor: const Color(0xFF131319), // Deep Indigo text
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
            ),
          ),
        ),
        home: const OnboardingScreen(),
      ),
    );
  }
}
