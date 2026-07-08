import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/vendedor_screen.dart';
import 'screens/socio_screen.dart';

// A global theme notifier for ThemeMode toggling
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() {
  runApp(const AmazonFishApp());
}

class AmazonFishApp extends StatelessWidget {
  const AmazonFishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'AmazonFish',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0096C7),
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.interTextTheme(
              ThemeData.light().textTheme.copyWith(
                bodyLarge: const TextStyle(color: Colors.black87),
                bodyMedium: const TextStyle(color: Colors.black54),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0096C7),
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.interTextTheme(
              ThemeData.dark().textTheme.copyWith(
                bodyLarge: const TextStyle(color: Colors.white),
                bodyMedium: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
          home: const AuthWrapper(),
        );
      },
    );
  }
}

/// Redirige al usuario según su rol al iniciar la app.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  Widget? _activeScreen;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final token = await _authService.getToken();
    if (token == null) {
      setState(() => _activeScreen = const LoginScreen());
      return;
    }

    final roles = await _authService.getRoles();
    _redirectByRole(roles);
  }

  void _redirectByRole(List<String> roles) {
    Widget screen;
    if (roles.contains('administrador')) {
      screen = const AdminScreen();
    } else if (roles.contains('vendedor')) {
      screen = const VendedorScreen();
    } else {
      screen = const SocioScreen();
    }
    setState(() => _activeScreen = screen);
  }

  @override
  Widget build(BuildContext context) {
    if (_activeScreen != null) {
      return _activeScreen!;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.set_meal,
              size: 80,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
            ),
            const SizedBox(height: 24),
            Text(
              'AmazonFish',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sistema de Gestión Acuícola',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
