import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'components/app_dialog.dart';
import 'admin_screen.dart';
import 'vendedor_screen.dart';
import 'socio_screen.dart';

enum FormType { login, register, recover }

/// Pantalla de Login y Registro – diseño adaptativo de alta legibilidad.
/// Resuelve: PC-001 (pantalla de carga), PC-004 (registro/recuperación) y PC-006 (modo claro/oscuro).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores de Login
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Controladores de Registro
  final _regNombresCtrl = TextEditingController();
  final _regApellidosCtrl = TextEditingController();
  final _regIdentificacionCtrl = TextEditingController();
  final _regCorreoCtrl = TextEditingController();
  final _regTelefonoCtrl = TextEditingController();
  final _regUsernameCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();

  // Controladores de Recuperación
  final _recUsernameCtrl = TextEditingController();
  final _recIdentificacionCtrl = TextEditingController();
  final _recCorreoCtrl = TextEditingController();
  final _recNewPasswordCtrl = TextEditingController();

  final _authService = AuthService();

  FormType _formType = FormType.login;
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _regNombresCtrl.dispose();
    _regApellidosCtrl.dispose();
    _regIdentificacionCtrl.dispose();
    _regCorreoCtrl.dispose();
    _regTelefonoCtrl.dispose();
    _regUsernameCtrl.dispose();
    _regPasswordCtrl.dispose();
    _recUsernameCtrl.dispose();
    _recIdentificacionCtrl.dispose();
    _recCorreoCtrl.dispose();
    _recNewPasswordCtrl.dispose();
    super.dispose();
  }

  void _switchForm(FormType type) {
    setState(() {
      _formType = type;
      _formKey.currentState?.reset();
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final roles = await _authService.login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
      );

      if (!mounted) return;
      
      // Mostrar modal de éxito
      await AppDialog.show(
        context,
        title: '¡Bienvenido!',
        message: 'Sesión iniciada correctamente.',
        type: DialogType.success,
      );

      _redirectByRole(roles);
    } catch (e) {
      if (!mounted) return;
      AppDialog.show(
        context,
        title: 'Error de Autenticación',
        message: e.toString().replaceFirst('Exception: ', ''),
        type: DialogType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _authService.register(
        nombres: _regNombresCtrl.text.trim(),
        apellidos: _regApellidosCtrl.text.trim(),
        identificacion: _regIdentificacionCtrl.text.trim(),
        correo: _regCorreoCtrl.text.trim(),
        telefono: _regTelefonoCtrl.text.trim(),
        username: _regUsernameCtrl.text.trim(),
        password: _regPasswordCtrl.text,
      );

      if (!mounted) return;

      await AppDialog.show(
        context,
        title: 'Registro Exitoso',
        message: 'Tu cuenta ha sido creada. Ahora puedes iniciar sesión.',
        type: DialogType.success,
      );

      // Cambiar a login y rellenar usuario
      _usernameCtrl.text = _regUsernameCtrl.text.trim();
      _switchForm(FormType.login);
    } catch (e) {
      if (!mounted) return;
      AppDialog.show(
        context,
        title: 'Error al Registrarse',
        message: e.toString().replaceFirst('Exception: ', ''),
        type: DialogType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recoverPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _authService.recoverPassword(
        username: _recUsernameCtrl.text.trim(),
        identificacion: _recIdentificacionCtrl.text.trim(),
        correo: _recCorreoCtrl.text.trim(),
        newPassword: _recNewPasswordCtrl.text,
      );

      if (!mounted) return;

      await AppDialog.show(
        context,
        title: 'Contraseña Actualizada',
        message: 'Tu contraseña ha sido restablecida con éxito.',
        type: DialogType.success,
      );

      // Volver a login
      _usernameCtrl.text = _recUsernameCtrl.text.trim();
      _switchForm(FormType.login);
    } catch (e) {
      if (!mounted) return;
      AppDialog.show(
        context,
        title: 'Error de Recuperación',
        message: e.toString().replaceFirst('Exception: ', ''),
        type: DialogType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo degradado según tema
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF0F172A), const Color(0xFF0284C7).withOpacity(0.4)]
                    : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9), const Color(0xFF38BDF8).withOpacity(0.15)],
              ),
            ),
          ),

          // Botón de Toggle del Tema en esquina superior
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
              ),
              onPressed: () {
                themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
              },
            ),
          ),

          // Contenido principal
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo y título
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0284C7).withOpacity(0.15),
                          border: Border.all(
                            color: const Color(0xFF0284C7).withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.set_meal,
                          size: 52,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'AmazonFish',
                        style: GoogleFonts.inter(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sistema de Gestión Acuícola',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Tarjeta del Formulario
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: _buildFormContent(isDark),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'GR09 · NRC 30743 · ESPE',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // PC-001: Pantalla completa de carga
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF0284C7),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _formType == FormType.login
                            ? 'Iniciando sesión...'
                            : _formType == FormType.register
                                ? 'Creando cuenta...'
                                : 'Restableciendo clave...',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormContent(bool isDark) {
    switch (_formType) {
      case FormType.login:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ingresar al Sistema',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _usernameCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _inputDecoration('Usuario', Icons.person_outline, isDark),
              validator: (v) => v == null || v.isEmpty ? 'Ingrese su usuario' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _inputDecoration(
                'Contraseña',
                Icons.lock_outline,
                isDark,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Ingrese su contraseña' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              style: _buttonStyle(const Color(0xFF0284C7)),
              child: Text('Iniciar Sesión', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _switchForm(FormType.register),
                  child: const Text('Registrarse', style: TextStyle(color: Color(0xFF0284C7))),
                ),
                TextButton(
                  onPressed: () => _switchForm(FormType.recover),
                  child: const Text('¿Olvidó su clave?', style: TextStyle(color: Color(0xFF0284C7))),
                ),
              ],
            ),
          ],
        );

      case FormType.register:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _switchForm(FormType.login),
                ),
                Text(
                  'Crear Cuenta',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _regNombresCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _inputDecoration('Nombres', Icons.badge_outlined, isDark),
              validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regApellidosCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _inputDecoration('Apellidos', Icons.badge_outlined, isDark),
              validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regIdentificacionCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _inputDecoration('Identificación (Cédula)', Icons.badge, isDark),
              validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regCorreoCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _inputDecoration('Correo Electrónico', Icons.email_outlined, isDark),
              validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regTelefonoCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _inputDecoration('Teléfono', Icons.phone_android, isDark),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regUsernameCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _inputDecoration('Nombre de Usuario', Icons.alternate_email, isDark),
              validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regPasswordCtrl,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _inputDecoration('Contraseña', Icons.lock_outline, isDark),
              validator: (v) => v == null || v.length < 8 ? 'Mínimo 8 caracteres' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              style: _buttonStyle(const Color(0xFF10B981)),
              child: Text('Registrarse', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        );

      case FormType.recover:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _switchForm(FormType.login),
                ),
                Text(
                  'Recuperar Clave',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _recUsernameCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _inputDecoration('Nombre de Usuario', Icons.person_outline, isDark),
              validator: (v) => v == null || v.isEmpty ? 'Ingrese su usuario' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _recIdentificacionCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _inputDecoration('Identificación (Cédula)', Icons.badge, isDark),
              validator: (v) => v == null || v.isEmpty ? 'Ingrese su cédula' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _recCorreoCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _inputDecoration('Correo Electrónico', Icons.email_outlined, isDark),
              validator: (v) => v == null || v.isEmpty ? 'Ingrese su correo' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _recNewPasswordCtrl,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _inputDecoration('Nueva Contraseña', Icons.lock_outline, isDark),
              validator: (v) => v == null || v.length < 8 ? 'Mínimo 8 caracteres' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _recoverPassword,
              style: _buttonStyle(const Color(0xFFF59E0B)),
              child: Text('Restablecer Clave', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
      prefixIcon: Icon(icon, color: isDark ? Colors.white38 : Colors.black38),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
      ),
    );
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    );
  }
}
