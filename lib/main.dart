import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'state/app_settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screen/login_screen.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // If .env is missing in dev, continue; values might be set some other way
  }

  // Initialize Supabase (prefer compile-time defines, then .env)
  final defineUrl = const String.fromEnvironment('SUPABASE_URL');
  final defineAnon = const String.fromEnvironment('SUPABASE_ANON_KEY');
  final supabaseUrl = defineUrl.isNotEmpty
    ? defineUrl
    : (dotenv.maybeGet('SUPABASE_URL') ?? '');
  final supabaseAnonKey = defineAnon.isNotEmpty
    ? defineAnon
    : (dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '');
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      debug: false,
    );
  }

  // Load app settings (theme mode, language)
  await AppSettings.instance.init();

  runApp(const SafeHajjApp());
}

class SafeHajjApp extends StatelessWidget {
  const SafeHajjApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp when settings change (theme or locale)
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) => MaterialApp(
      title: 'SafeHajj App',
      debugShowCheckedModeBanner: false,
      locale: AppSettings.instance.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ms'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        // Dynamic color scheme with proper Material 3 tones
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4663AC),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF4663AC),
          primaryContainer: const Color(0xFFD2DEEB),
          secondary: const Color(0xFF1E88E5),
          secondaryContainer: const Color(0xFFC8D9ED),
          tertiary: const Color(0xFFC1D8F0),
          surface: Colors.white,
          surfaceVariant: const Color(0xFFF5F7FA),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black87,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        
        // Global font setup
        fontFamily: GoogleFonts.nunito().fontFamily,
        fontFamilyFallback: const [
          'Noto Sans Arabic',
          'Segoe UI',
          'Arial',
        ],
        textTheme: GoogleFonts.nunitoTextTheme().copyWith(
          displayLarge: GoogleFonts.nunito(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25),
          displayMedium: GoogleFonts.nunito(fontSize: 45, fontWeight: FontWeight.w400),
          displaySmall: GoogleFonts.nunito(fontSize: 36, fontWeight: FontWeight.w400),
          headlineLarge: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w600),
          headlineMedium: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600),
          headlineSmall: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w600),
          titleLarge: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w700),
          titleMedium: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15),
          titleSmall: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
          bodyLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
          bodyMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
          bodySmall: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
          labelLarge: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
          labelMedium: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          labelSmall: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        
        // Material 3 elevation system
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.15),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        
        // Improved card styling
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        
        // App bar with Material 3 styling
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: const Color(0xFF4663AC),
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF4663AC), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        
        // Bottom navigation bar theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF4663AC),
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w500),
          type: BottomNavigationBarType.fixed,
        ),
        
        // Floating action button theme
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 3,
          highlightElevation: 6,
          backgroundColor: const Color(0xFF4663AC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        
        // Chip theme for tags and filters
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF4663AC).withOpacity(0.1),
          selectedColor: const Color(0xFF4663AC),
          disabledColor: Colors.grey.shade200,
          labelStyle: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4663AC),
          ),
          secondaryLabelStyle: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        
        // Dialog theme
                dialogTheme: DialogThemeData(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  backgroundColor: Colors.white,
                  titleTextStyle: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
        
        // Snackbar theme
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentTextStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        
        // List tile theme
        listTileTheme: ListTileThemeData(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          titleTextStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          subtitleTextStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade600,
          ),
        ),
        
        // Icon theme
        iconTheme: const IconThemeData(
          color: Color(0xFF4663AC),
          size: 24,
        ),
        
        // Divider theme
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade200,
          thickness: 1,
          space: 1,
        ),
      ),
      home: const LoginScreen(),
    ),
    );
  }
}
