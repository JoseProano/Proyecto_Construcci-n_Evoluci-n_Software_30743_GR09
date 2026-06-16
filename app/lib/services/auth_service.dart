import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de autenticación – comunica con el backend FastAPI.
/// Endpoint: POST /api/v1/auth/login
class AuthService {
  // URL base del backend (se inyecta en tiempo de build via --dart-define)
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://amazonfish-backend.onrender.com',
  );

  static const String _tokenKey = 'af_token';
  static const String _rolesKey = 'af_roles';
  static const String _usernameKey = 'af_username';

  /// Login: retorna los roles del usuario si tiene éxito, lanza excepción si falla.
  Future<List<String>> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/api/v1/auth/login');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = data['access_token'] as String;
      final usuario = data['usuario'] as Map<String, dynamic>;
      final rolesRaw = usuario['roles'] as List<dynamic>? ?? [];
      final roles = rolesRaw
          .map((r) => (r as Map<String, dynamic>)['rol']?['nombre'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();

      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setStringList(_rolesKey, roles);
      await prefs.setString(_usernameKey, username);

      return roles;
    } else if (resp.statusCode == 401) {
      throw Exception('Credenciales incorrectas');
    } else {
      throw Exception('Error del servidor: ${resp.statusCode}');
    }
  }

  /// Obtiene el token JWT almacenado localmente.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Obtiene los roles del usuario almacenados localmente.
  Future<List<String>> getRoles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_rolesKey) ?? [];
  }

  /// Obtiene el username del usuario actual.
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  /// Cierra sesión: elimina el token y la info local.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_rolesKey);
    await prefs.remove(_usernameKey);
  }
}
