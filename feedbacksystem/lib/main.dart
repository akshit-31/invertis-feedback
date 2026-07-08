import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF1A2744);
    const accentRed = Color(0xFFE53935);

    return MaterialApp(
      title: 'Invertis Feedback Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryNavy,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryNavy,
          primary: primaryNavy,
          secondary: accentRed,
        ),
        textTheme: GoogleFonts.montserratTextTheme(),
        fontFamily: GoogleFonts.montserrat().fontFamily,
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Base width for scaling (typical mobile width)
        double baseWidth = 400.0;
        double scale = mediaQuery.size.width / baseWidth;
        // Clamp the scale to avoid overly huge text on desktop or tiny text on small phones
        if (scale < 0.85) scale = 0.85;
        if (scale > 1.2) scale = 1.2;

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        );
      },
      home: const LoginScreen(),
    );
  }
}
