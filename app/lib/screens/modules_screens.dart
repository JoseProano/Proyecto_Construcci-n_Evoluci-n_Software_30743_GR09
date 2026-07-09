import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'components/app_dialog.dart';

/// Base URL for API requests
const String _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://amazonfish-backend.onrender.com',
);

/// Get authorization headers helper
Future<Map<String, String>> _getHeaders() async {
  final token = await AuthService().getToken();
  return {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

// ════════════════════════════════════════════════════════════════
// 1. MÓDULO PERSONAS Y USUARIOS
// ════════════════════════════════════════════════════════════════
class PersonasUsuariosModule extends StatefulWidget {
  const PersonasUsuariosModule({super.key});

  @override
  State<PersonasUsuariosModule> createState() => _PersonasUsuariosModuleState();
}

class _PersonasUsuariosModuleState extends State<PersonasUsuariosModule> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _personas = [];
  List<dynamic> _usuarios = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _getHeaders();
      
      // Personas
      final resP = await http.get(Uri.parse('$_baseUrl/api/v1/personas/'), headers: headers);
      if (resP.statusCode == 200) {
        _personas = jsonDecode(resP.body);
      }

      // Usuarios
      final resU = await http.get(Uri.parse('$_baseUrl/api/v1/usuarios/'), headers: headers);
      if (resU.statusCode == 200) {
        _usuarios = jsonDecode(resU.body);
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _crearPersonaDialog() {
    final namesCtrl = TextEditingController();
    final lastCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: Text('Nueva Persona', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: namesCtrl, decoration: const InputDecoration(labelText: 'Nombres')),
                TextField(controller: lastCtrl, decoration: const InputDecoration(labelText: 'Apellidos')),
                TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Cédula / Identificación')),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Correo')),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (namesCtrl.text.isEmpty || lastCtrl.text.isEmpty || idCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                  AppDialog.show(context, title: 'Campos incompletos', message: 'Por favor llene los campos obligatorios', type: DialogType.error);
                  return;
                }
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final headers = await _getHeaders();
                  final res = await http.post(
                    Uri.parse('$_baseUrl/api/v1/personas/'),
                    headers: headers,
                    body: jsonEncode({
                      'nombres': namesCtrl.text.trim(),
                      'apellidos': lastCtrl.text.trim(),
                      'identificacion': idCtrl.text.trim(),
                      'correo': emailCtrl.text.trim(),
                      'telefono': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    }),
                  );
                  if (res.statusCode == 201) {
                    AppDialog.show(context, title: 'Éxito', message: 'Persona creada correctamente', type: DialogType.success);
                    _cargarDatos();
                  } else {
                    final err = jsonDecode(res.body)['detail'];
                    AppDialog.show(context, title: 'Error', message: err ?? 'No se pudo crear', type: DialogType.error);
                  }
                } catch (e) {
                  // ignore
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _crearUsuarioDialog() {
    if (_personas.isEmpty) {
      AppDialog.show(context, title: 'Sin personas', message: 'Primero cree una persona para asociarle un usuario', type: DialogType.error);
      return;
    }
    String? selectedPersonaId = _personas[0]['id_persona'];
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: Text('Nuevo Usuario', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedPersonaId,
                    decoration: const InputDecoration(labelText: 'Persona Asociada'),
                    items: _personas.map<DropdownMenuItem<String>>((p) {
                      return DropdownMenuItem<String>(
                        value: p['id_persona'],
                        child: Text('${p['nombres']} ${p['apellidos']}', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedPersonaId = val),
                  ),
                  TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username')),
                  TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (userCtrl.text.isEmpty || passCtrl.text.isEmpty || selectedPersonaId == null) {
                  AppDialog.show(context, title: 'Campos vacíos', message: 'Por favor complete todos los campos', type: DialogType.error);
                  return;
                }
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final headers = await _getHeaders();
                  final res = await http.post(
                    Uri.parse('$_baseUrl/api/v1/usuarios/'),
                    headers: headers,
                    body: jsonEncode({
                      'id_persona': selectedPersonaId,
                      'username': userCtrl.text.trim(),
                      'password': passCtrl.text,
                    }),
                  );
                  if (res.statusCode == 201) {
                    AppDialog.show(context, title: 'Éxito', message: 'Usuario creado correctamente', type: DialogType.success);
                    _cargarDatos();
                  } else {
                    final err = jsonDecode(res.body)['detail'];
                    AppDialog.show(context, title: 'Error', message: err ?? 'No se pudo crear', type: DialogType.error);
                  }
                } catch (e) {
                  // ignore
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0284C7),
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          indicatorColor: const Color(0xFF0284C7),
          tabs: const [
            Tab(text: 'Personas'),
            Tab(text: 'Usuarios'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Vista Personas
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _personas.length,
                  itemBuilder: (_, i) {
                    final p = _personas[i];
                    return Card(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFF0284C7), child: Icon(Icons.person, color: Colors.white)),
                        title: Text('${p['nombres']} ${p['apellidos']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Identificación: ${p['identificacion']}\nCorreo: ${p['correo']}'),
                        trailing: Icon(p['estado'] ? Icons.check_circle : Icons.cancel, color: p['estado'] ? Colors.green : Colors.red),
                      ),
                    );
                  },
                ),
                // Vista Usuarios
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _usuarios.length,
                  itemBuilder: (_, i) {
                    final u = _usuarios[i];
                    return Card(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFFFF6B35), child: Icon(Icons.alternate_email, color: Colors.white)),
                        title: Text('${u['username']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('ID Usuario: ${u['id_usuario']}\nCreado: ${u['fecha_creacion']?.substring(0, 10)}'),
                        trailing: Icon(u['estado'] ? Icons.check_circle : Icons.cancel, color: u['estado'] ? Colors.green : Colors.red),
                      ),
                    );
                  },
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0284C7),
        onPressed: () {
          if (_tabController.index == 0) {
            _crearPersonaDialog();
          } else {
            _crearUsuarioDialog();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 2. MÓDULO ROLES Y PERMISOS
// ════════════════════════════════════════════════════════════════
class RolesPermisosModule extends StatefulWidget {
  const RolesPermisosModule({super.key});

  @override
  State<RolesPermisosModule> createState() => _RolesPermisosModuleState();
}

class _RolesPermisosModuleState extends State<RolesPermisosModule> {
  List<dynamic> _usuarios = [];
  List<dynamic> _rolesDisponibles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
    _cargarRoles();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$_baseUrl/api/v1/usuarios/'), headers: headers);
      if (res.statusCode == 200) {
        setState(() => _usuarios = jsonDecode(res.body));
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarRoles() async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$_baseUrl/api/v1/roles/'), headers: headers);
      if (res.statusCode == 200) {
        _rolesDisponibles = jsonDecode(res.body);
      }
    } catch (_) {}
  }

  String? _findRolId(String nombre) {
    try {
      final r = _rolesDisponibles.firstWhere((element) => element['nombre'] == nombre);
      return r['id_rol'];
    } catch (_) {
      return null;
    }
  }

  String? _findUsuarioRolId(List<dynamic> userRoles, String nombreRol) {
    try {
      final ur = userRoles.firstWhere((r) => r['rol']?['nombre'] == nombreRol && r['estado'] == true);
      return ur['id_usuario_rol'];
    } catch (_) {
      return null;
    }
  }

  void _asignarRolDialog(dynamic user) {
    final List<dynamic> userRoles = user['roles'] ?? [];
    bool isAdmin = userRoles.any((r) => r['rol']?['nombre'] == 'administrador' && r['estado'] == true);
    bool isSeller = userRoles.any((r) => r['rol']?['nombre'] == 'vendedor' && r['estado'] == true);
    bool isPartner = userRoles.any((r) => r['rol']?['nombre'] == 'socio' && r['estado'] == true);

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: Text('Asignar Roles a ${user['username']}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text('Administrador'),
                    value: isAdmin,
                    onChanged: (val) => setDialogState(() => isAdmin = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Vendedor'),
                    value: isSeller,
                    onChanged: (val) => setDialogState(() => isSeller = val ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Socio / Cliente'),
                    value: isPartner,
                    onChanged: (val) => setDialogState(() => isPartner = val ?? false),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final headers = await _getHeaders();
                  
                  final adminRolId = _findRolId('administrador');
                  final sellerRolId = _findRolId('vendedor');
                  final partnerRolId = _findRolId('socio');

                  bool wasAdmin = userRoles.any((r) => r['rol']?['nombre'] == 'administrador' && r['estado'] == true);
                  bool wasSeller = userRoles.any((r) => r['rol']?['nombre'] == 'vendedor' && r['estado'] == true);
                  bool wasPartner = userRoles.any((r) => r['rol']?['nombre'] == 'socio' && r['estado'] == true);

                  // 1. Administrador
                  if (isAdmin && !wasAdmin && adminRolId != null) {
                    await http.post(
                      Uri.parse('$_baseUrl/api/v1/roles/asignar'),
                      headers: headers,
                      body: jsonEncode({'id_usuario': user['id_usuario'], 'id_rol': adminRolId}),
                    );
                  } else if (!isAdmin && wasAdmin) {
                    final urId = _findUsuarioRolId(userRoles, 'administrador');
                    if (urId != null) {
                      await http.delete(Uri.parse('$_baseUrl/api/v1/roles/remover/$urId'), headers: headers);
                    }
                  }

                  // 2. Vendedor
                  if (isSeller && !wasSeller && sellerRolId != null) {
                    await http.post(
                      Uri.parse('$_baseUrl/api/v1/roles/asignar'),
                      headers: headers,
                      body: jsonEncode({'id_usuario': user['id_usuario'], 'id_rol': sellerRolId}),
                    );
                  } else if (!isSeller && wasSeller) {
                    final urId = _findUsuarioRolId(userRoles, 'vendedor');
                    if (urId != null) {
                      await http.delete(Uri.parse('$_baseUrl/api/v1/roles/remover/$urId'), headers: headers);
                    }
                  }

                  // 3. Socio
                  if (isPartner && !wasPartner && partnerRolId != null) {
                    await http.post(
                      Uri.parse('$_baseUrl/api/v1/roles/asignar'),
                      headers: headers,
                      body: jsonEncode({'id_usuario': user['id_usuario'], 'id_rol': partnerRolId}),
                    );
                  } else if (!isPartner && wasPartner) {
                    final urId = _findUsuarioRolId(userRoles, 'socio');
                    if (urId != null) {
                      await http.delete(Uri.parse('$_baseUrl/api/v1/roles/remover/$urId'), headers: headers);
                    }
                  }

                  AppDialog.show(context, title: 'Éxito', message: 'Roles actualizados correctamente', type: DialogType.success);
                  _cargarUsuarios();
                } catch (e) {
                  // ignore
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _usuarios.length,
              itemBuilder: (_, i) {
                final u = _usuarios[i];
                final List<dynamic> roles = u['roles'] ?? [];
                final rolesStr = roles.map((r) => r['rol']?['nombre'] ?? '').join(', ');
                return Card(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFF10B981), child: Icon(Icons.shield_outlined, color: Colors.white)),
                    title: Text('${u['username']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Roles actuales: ${rolesStr.isEmpty ? "Ninguno" : rolesStr}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF0284C7)),
                      onPressed: () => _asignarRolDialog(u),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 3. MÓDULO INVENTARIO (PRODUCTOS ACUÍCOLAS)
// ════════════════════════════════════════════════════════════════
class InventarioModule extends StatefulWidget {
  const InventarioModule({super.key});

  @override
  State<InventarioModule> createState() => _InventarioModuleState();
}

class _InventarioModuleState extends State<InventarioModule> {
  List<dynamic> _productos = [];
  bool _isLoading = false;
  bool _canManage = false;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final roles = await AuthService().getRoles();
    if (mounted) {
      setState(() {
        _canManage = roles.contains('administrador');
      });
    }
  }

  Future<void> _cargarProductos() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$_baseUrl/api/v1/productos/'), headers: headers);
      if (res.statusCode == 200) {
        setState(() => _productos = jsonDecode(res.body));
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _crearProductoDialog() {
    String selectedTipo = 'balanceado';
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final minStockCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'kg');

    // Balanceado
    final especieCtrl = TextEditingController(text: 'tilapia');
    final etapaCtrl = TextEditingController(text: 'engorde');

    // Insumo
    final insumoCtrl = TextEditingController(text: 'probiótico');
    final aplicacionCtrl = TextEditingController();

    // Medicamento
    final principioCtrl = TextEditingController();
    final dosisCtrl = TextEditingController();
    final registroCtrl = TextEditingController();

    // Equipo
    final marcaCtrl = TextEditingController();
    final modeloCtrl = TextEditingController();
    final garantiaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: Text('Añadir Producto', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedTipo,
                      decoration: const InputDecoration(labelText: 'Tipo de Producto'),
                      items: const [
                        DropdownMenuItem(value: 'balanceado', child: Text('Balanceado')),
                        DropdownMenuItem(value: 'insumo', child: Text('Insumo Acuícola')),
                        DropdownMenuItem(value: 'medicamento', child: Text('Medicamento')),
                        DropdownMenuItem(value: 'equipo', child: Text('Equipo')),
                      ],
                      onChanged: (val) => setDialogState(() => selectedTipo = val ?? 'balanceado'),
                    ),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
                    TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio Unitario')),
                    TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Inicial')),
                    TextField(controller: minStockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Mínimo')),
                    TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unidad de Medida')),

                    // Campos dinámicos según el Factory
                    if (selectedTipo == 'balanceado') ...[
                      TextField(controller: especieCtrl, decoration: const InputDecoration(labelText: 'Especie (tilapia/camarón)')),
                      TextField(controller: etapaCtrl, decoration: const InputDecoration(labelText: 'Etapa de Vida (iniciación/engorde)')),
                    ] else if (selectedTipo == 'insumo') ...[
                      TextField(controller: insumoCtrl, decoration: const InputDecoration(labelText: 'Tipo de Insumo')),
                      TextField(controller: aplicacionCtrl, decoration: const InputDecoration(labelText: 'Aplicación')),
                    ] else if (selectedTipo == 'medicamento') ...[
                      TextField(controller: principioCtrl, decoration: const InputDecoration(labelText: 'Principio Activo')),
                      TextField(controller: dosisCtrl, decoration: const InputDecoration(labelText: 'Dosis Recomendada')),
                      TextField(controller: registroCtrl, decoration: const InputDecoration(labelText: 'Registro Sanitario')),
                    ] else if (selectedTipo == 'equipo') ...[
                      TextField(controller: marcaCtrl, decoration: const InputDecoration(labelText: 'Marca')),
                      TextField(controller: modeloCtrl, decoration: const InputDecoration(labelText: 'Modelo')),
                      TextField(controller: garantiaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Meses de Garantía')),
                    ]
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty || stockCtrl.text.isEmpty) {
                  AppDialog.show(context, title: 'Campos vacíos', message: 'Por favor complete los campos obligatorios', type: DialogType.error);
                  return;
                }
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final headers = await _getHeaders();

                  final body = {
                    'nombre': nameCtrl.text.trim(),
                    'descripcion': descCtrl.text.trim(),
                    'precio_unitario': double.parse(priceCtrl.text),
                    'stock_actual': double.parse(stockCtrl.text),
                    'stock_minimo': double.parse(minStockCtrl.text.isEmpty ? '0' : minStockCtrl.text),
                    'unidad_medida': unitCtrl.text.trim(),
                    'tipo_producto': selectedTipo,
                    
                    // Específicos
                    if (selectedTipo == 'balanceado') ...{
                      'tipo_especie': especieCtrl.text.trim(),
                      'etapa_vida': etapaCtrl.text.trim(),
                    },
                    if (selectedTipo == 'insumo') ...{
                      'tipo_insumo': insumoCtrl.text.trim(),
                      'aplicacion': aplicacionCtrl.text.trim(),
                    },
                    if (selectedTipo == 'medicamento') ...{
                      'principio_activo': principioCtrl.text.trim(),
                      'dosis_recomendada': dosisCtrl.text.trim(),
                      'registro_sanitario': registroCtrl.text.trim(),
                    },
                    if (selectedTipo == 'equipo') ...{
                      'marca': marcaCtrl.text.trim(),
                      'modelo': modeloCtrl.text.trim(),
                      'garantia_meses': int.parse(garantiaCtrl.text.isEmpty ? '0' : garantiaCtrl.text),
                    },
                  };

                  final res = await http.post(
                    Uri.parse('$_baseUrl/api/v1/productos/$selectedTipo'),
                    headers: headers,
                    body: jsonEncode(body),
                  );

                  if (res.statusCode == 201) {
                    AppDialog.show(context, title: 'Éxito', message: 'Producto creado correctamente', type: DialogType.success);
                    _cargarProductos();
                  } else {
                    final err = jsonDecode(res.body)['detail'];
                    AppDialog.show(context, title: 'Error', message: err ?? 'No se pudo crear', type: DialogType.error);
                  }
                } catch (e) {
                  // ignore
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _editarProductoDialog(dynamic p) {
    final nameCtrl = TextEditingController(text: p['nombre']);
    final descCtrl = TextEditingController(text: p['descripcion'] ?? '');
    final priceCtrl = TextEditingController(text: p['precio_unitario'].toString());
    final stockCtrl = TextEditingController(text: p['stock_actual'].toString());
    final minStockCtrl = TextEditingController(text: p['stock_minimo'].toString());
    final unitCtrl = TextEditingController(text: p['unidad_medida']);
    bool active = p['estado'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: Text('Editar Producto', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción')),
                    TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio Unitario')),
                    TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Actual')),
                    TextField(controller: minStockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Mínimo')),
                    TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unidad de Medida')),
                    CheckboxListTile(
                      title: const Text('Activo'),
                      value: active,
                      onChanged: (val) => setDialogState(() => active = val ?? true),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty || stockCtrl.text.isEmpty) {
                  AppDialog.show(context, title: 'Campos vacíos', message: 'Por favor complete los campos obligatorios', type: DialogType.error);
                  return;
                }
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final headers = await _getHeaders();
                  final body = {
                    'nombre': nameCtrl.text.trim(),
                    'descripcion': descCtrl.text.trim(),
                    'precio_unitario': double.parse(priceCtrl.text),
                    'stock_actual': double.parse(stockCtrl.text),
                    'stock_minimo': double.parse(minStockCtrl.text.isEmpty ? '0' : minStockCtrl.text),
                    'unidad_medida': unitCtrl.text.trim(),
                    'estado': active,
                  };

                  final res = await http.put(
                    Uri.parse('$_baseUrl/api/v1/productos/${p['id_producto']}'),
                    headers: headers,
                    body: jsonEncode(body),
                  );

                  if (res.statusCode == 200) {
                    AppDialog.show(context, title: 'Éxito', message: 'Producto actualizado correctamente', type: DialogType.success);
                    _cargarProductos();
                  } else {
                    final err = jsonDecode(res.body)['detail'];
                    AppDialog.show(context, title: 'Error', message: err ?? 'No se pudo actualizar', type: DialogType.error);
                  }
                } catch (e) {
                  // ignore
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _productos.length,
              itemBuilder: (_, i) {
                final p = _productos[i];
                final stock = double.parse(p['stock_actual'].toString());
                final minStock = double.parse(p['stock_minimo'].toString());
                final underStock = stock < minStock;

                return Card(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: underStock ? Colors.red.withOpacity(0.15) : const Color(0xFF0284C7).withOpacity(0.15),
                      child: Icon(
                        underStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                        color: underStock ? Colors.red : const Color(0xFF0284C7),
                      ),
                    ),
                    title: Text('${p['nombre']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Código: ${p['codigo_producto']}'),
                        Text(
                          'Stock: $stock ${p['unidad_medida']}',
                          style: TextStyle(
                            color: underStock ? Colors.red : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: underStock ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (underStock)
                          const Text(
                            '⚠️ ¡STOCK BAJO EL MÍNIMO!',
                            style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('\$${p['precio_unitario']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (_canManage) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF0284C7)),
                            onPressed: () => _editarProductoDialog(p),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _canManage
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF0284C7),
              onPressed: _crearProductoDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 4. MÓDULO PROVEEDORES
// ════════════════════════════════════════════════════════════════
class ProveedoresModule extends StatefulWidget {
  const ProveedoresModule({super.key});

  @override
  State<ProveedoresModule> createState() => _ProveedoresModuleState();
}

class _ProveedoresModuleState extends State<ProveedoresModule> {
  List<dynamic> _proveedores = [];
  bool _isLoading = false;
  bool _canManage = false;

  @override
  void initState() {
    super.initState();
    _cargarProveedores();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final roles = await AuthService().getRoles();
    if (mounted) {
      setState(() {
        _canManage = roles.contains('administrador');
      });
    }
  }

  Future<void> _cargarProveedores() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$_baseUrl/api/v1/proveedores/'), headers: headers);
      if (res.statusCode == 200) {
        setState(() => _proveedores = jsonDecode(res.body));
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _crearProveedorDialog() {
    String selectedTipo = 'natural';
    final razonSocialCtrl = TextEditingController();
    final correoCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final direccionCtrl = TextEditingController();

    // Natural
    final nombresCtrl = TextEditingController();
    final apellidosCtrl = TextEditingController();
    final cedulaCtrl = TextEditingController();

    // Juridico
    final rucCtrl = TextEditingController();
    final nombreComercialCtrl = TextEditingController();
    final representanteLegalCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: Text('Añadir Proveedor', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedTipo,
                      decoration: const InputDecoration(labelText: 'Tipo de Proveedor'),
                      items: const [
                        DropdownMenuItem(value: 'natural', child: Text('Persona Natural')),
                        DropdownMenuItem(value: 'juridico', child: Text('Persona Jurídica')),
                      ],
                      onChanged: (val) => setDialogState(() => selectedTipo = val ?? 'natural'),
                    ),
                    TextField(controller: razonSocialCtrl, decoration: const InputDecoration(labelText: 'Razón Social / Nombre Comercial')),
                    TextField(controller: correoCtrl, decoration: const InputDecoration(labelText: 'Correo')),
                    TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
                    TextField(controller: direccionCtrl, decoration: const InputDecoration(labelText: 'Dirección')),

                    if (selectedTipo == 'natural') ...[
                      TextField(controller: nombresCtrl, decoration: const InputDecoration(labelText: 'Nombres')),
                      TextField(controller: apellidosCtrl, decoration: const InputDecoration(labelText: 'Apellidos')),
                      TextField(controller: cedulaCtrl, decoration: const InputDecoration(labelText: 'Cédula')),
                    ] else ...[
                      TextField(controller: rucCtrl, decoration: const InputDecoration(labelText: 'RUC')),
                      TextField(controller: nombreComercialCtrl, decoration: const InputDecoration(labelText: 'Nombre Comercial')),
                      TextField(controller: representanteLegalCtrl, decoration: const InputDecoration(labelText: 'Representante Legal')),
                    ]
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (razonSocialCtrl.text.isEmpty) {
                  AppDialog.show(context, title: 'Campos vacíos', message: 'La Razón Social es requerida.', type: DialogType.error);
                  return;
                }
                if (selectedTipo == 'natural' && (nombresCtrl.text.isEmpty || apellidosCtrl.text.isEmpty)) {
                  AppDialog.show(context, title: 'Campos vacíos', message: 'Nombres y Apellidos son requeridos para personas naturales.', type: DialogType.error);
                  return;
                }
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final headers = await _getHeaders();
                  final endpoint = selectedTipo == 'natural' ? 'natural' : 'juridico';
                  
                  final body = {
                    'razon_social': razonSocialCtrl.text.trim(),
                    'correo': correoCtrl.text.trim().isEmpty ? null : correoCtrl.text.trim(),
                    'telefono': telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
                    'direccion': direccionCtrl.text.trim().isEmpty ? null : direccionCtrl.text.trim(),
                    'estado': true,
                    'tipo_proveedor': selectedTipo,
                    if (selectedTipo == 'natural') ...{
                      'nombres': nombresCtrl.text.trim(),
                      'apellidos': apellidosCtrl.text.trim(),
                      'cedula': cedulaCtrl.text.trim().isEmpty ? null : cedulaCtrl.text.trim(),
                    } else ...{
                      'ruc': rucCtrl.text.trim().isEmpty ? null : rucCtrl.text.trim(),
                      'nombre_comercial': nombreComercialCtrl.text.trim().isEmpty ? null : nombreComercialCtrl.text.trim(),
                      'representante_legal': representanteLegalCtrl.text.trim().isEmpty ? null : representanteLegalCtrl.text.trim(),
                    }
                  };

                  final res = await http.post(
                    Uri.parse('$_baseUrl/api/v1/proveedores/$endpoint'),
                    headers: headers,
                    body: jsonEncode(body),
                  );

                  if (res.statusCode == 201) {
                    AppDialog.show(context, title: 'Éxito', message: 'Proveedor creado correctamente', type: DialogType.success);
                    _cargarProveedores();
                  } else {
                    final err = jsonDecode(res.body)['detail'];
                    AppDialog.show(context, title: 'Error', message: err ?? 'No se pudo crear', type: DialogType.error);
                  }
                } catch (e) {
                  // ignore
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _editarProveedorDialog(dynamic prov) {
    final razonSocialCtrl = TextEditingController(text: prov['razon_social']);
    final correoCtrl = TextEditingController(text: prov['correo'] ?? '');
    final telefonoCtrl = TextEditingController(text: prov['telefono'] ?? '');
    final direccionCtrl = TextEditingController(text: prov['direccion'] ?? '');
    bool active = prov['estado'] ?? true;
    final tipo = prov['tipo_proveedor'];

    // Natural
    final nombresCtrl = TextEditingController(text: prov['nombres'] ?? '');
    final apellidosCtrl = TextEditingController(text: prov['apellidos'] ?? '');
    final cedulaCtrl = TextEditingController(text: prov['cedula'] ?? '');

    // Juridico
    final rucCtrl = TextEditingController(text: prov['ruc'] ?? '');
    final nombreComercialCtrl = TextEditingController(text: prov['nombre_comercial'] ?? '');
    final representanteLegalCtrl = TextEditingController(text: prov['representante_legal'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: Text('Editar Proveedor', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: razonSocialCtrl, decoration: const InputDecoration(labelText: 'Razón Social / Nombre Comercial')),
                    TextField(controller: correoCtrl, decoration: const InputDecoration(labelText: 'Correo')),
                    TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
                    TextField(controller: direccionCtrl, decoration: const InputDecoration(labelText: 'Dirección')),
                    CheckboxListTile(
                      title: const Text('Activo'),
                      value: active,
                      onChanged: (val) => setDialogState(() => active = val ?? true),
                    ),

                    if (tipo == 'natural') ...[
                      TextField(controller: nombresCtrl, decoration: const InputDecoration(labelText: 'Nombres')),
                      TextField(controller: apellidosCtrl, decoration: const InputDecoration(labelText: 'Apellidos')),
                      TextField(controller: cedulaCtrl, decoration: const InputDecoration(labelText: 'Cédula')),
                    ] else ...[
                      TextField(controller: rucCtrl, decoration: const InputDecoration(labelText: 'RUC')),
                      TextField(controller: nombreComercialCtrl, decoration: const InputDecoration(labelText: 'Nombre Comercial')),
                      TextField(controller: representanteLegalCtrl, decoration: const InputDecoration(labelText: 'Representante Legal')),
                    ]
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (razonSocialCtrl.text.isEmpty) {
                  AppDialog.show(context, title: 'Campos vacíos', message: 'La Razón Social es requerida.', type: DialogType.error);
                  return;
                }
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final headers = await _getHeaders();
                  final body = {
                    'razon_social': razonSocialCtrl.text.trim(),
                    'correo': correoCtrl.text.trim().isEmpty ? null : correoCtrl.text.trim(),
                    'telefono': telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
                    'direccion': direccionCtrl.text.trim().isEmpty ? null : direccionCtrl.text.trim(),
                    'estado': active,
                    'tipo_proveedor': tipo,
                    if (tipo == 'natural') ...{
                      'nombres': nombresCtrl.text.trim(),
                      'apellidos': apellidosCtrl.text.trim(),
                      'cedula': cedulaCtrl.text.trim().isEmpty ? null : cedulaCtrl.text.trim(),
                    } else ...{
                      'ruc': rucCtrl.text.trim().isEmpty ? null : rucCtrl.text.trim(),
                      'nombre_comercial': nombreComercialCtrl.text.trim().isEmpty ? null : nombreComercialCtrl.text.trim(),
                      'representante_legal': representanteLegalCtrl.text.trim().isEmpty ? null : representanteLegalCtrl.text.trim(),
                    }
                  };

                  final res = await http.put(
                    Uri.parse('$_baseUrl/api/v1/proveedores/${prov['id_proveedor']}'),
                    headers: headers,
                    body: jsonEncode(body),
                  );

                  if (res.statusCode == 200) {
                    AppDialog.show(context, title: 'Éxito', message: 'Proveedor actualizado correctamente', type: DialogType.success);
                    _cargarProveedores();
                  } else {
                    final err = jsonDecode(res.body)['detail'];
                    AppDialog.show(context, title: 'Error', message: err ?? 'No se pudo actualizar', type: DialogType.error);
                  }
                } catch (e) {
                  // ignore
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _proveedores.length,
              itemBuilder: (_, i) {
                final prov = _proveedores[i];
                final tipo = prov['tipo_proveedor'] == 'natural' ? 'Persona Natural' : 'Persona Jurídica';
                final doc = prov['tipo_proveedor'] == 'natural'
                    ? 'Cédula: ${prov['cedula'] ?? "N/A"}'
                    : 'RUC: ${prov['ruc'] ?? "N/A"}';

                return Card(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFFF59E0B), child: Icon(Icons.local_shipping_outlined, color: Colors.white)),
                    title: Text('${prov['razon_social']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Tipo: $tipo\n$doc\nCorreo: ${prov['correo'] ?? "Sin correo"}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_canManage) ...[
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF0284C7)),
                            onPressed: () => _editarProveedorDialog(prov),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(prov['estado'] ? Icons.check_circle : Icons.cancel, color: prov['estado'] ? Colors.green : Colors.red),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _canManage
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF0284C7),
              onPressed: _crearProveedorDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 5. MÓDULO PEDIDOS (CARRITO DE COMPRAS)
// ════════════════════════════════════════════════════════════════
class PedidosModule extends StatefulWidget {
  const PedidosModule({super.key});

  @override
  State<PedidosModule> createState() => _PedidosModuleState();
}

class _PedidosModuleState extends State<PedidosModule> {
  List<dynamic> _productos = [];
  final Map<String, int> _carrito = {}; // id_producto -> cantidad
  double _descuento = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$_baseUrl/api/v1/productos/'), headers: headers);
      if (res.statusCode == 200) {
        setState(() => _productos = jsonDecode(res.body));
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _subtotal {
    double sub = 0.0;
    _carrito.forEach((pId, cant) {
      final p = _productos.firstWhere((prod) => prod['id_producto'] == pId, orElse: () => null);
      if (p != null) {
        sub += double.parse(p['precio_unitario'].toString()) * cant;
      }
    });
    return sub;
  }

  double get _total => _subtotal - _descuento > 0 ? _subtotal - _descuento : 0.0;

  Future<void> _crearPedido() async {
    if (_carrito.isEmpty) {
      AppDialog.show(context, title: 'Carrito Vacío', message: 'Por favor añada al menos un producto.', type: DialogType.error);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final headers = await _getHeaders();
      final detalles = _carrito.entries.map((e) => {'id_producto': e.key, 'cantidad': e.value.toDouble()}).toList();

      final res = await http.post(
        Uri.parse('$_baseUrl/api/v1/pedidos/'),
        headers: headers,
        body: jsonEncode({
          'descuento': _descuento,
          'detalles': detalles,
        }),
      );

      if (res.statusCode == 201) {
        AppDialog.show(context, title: 'Éxito', message: 'Pedido creado exitosamente en estado Borrador.', type: DialogType.success);
        setState(() {
          _carrito.clear();
          _descuento = 0.0;
        });
      } else {
        final err = jsonDecode(res.body)['detail'];
        AppDialog.show(context, title: 'Error', message: err ?? 'No se pudo crear el pedido.', type: DialogType.error);
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Catálogo de Productos
                Expanded(
                  flex: 3,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _productos.length,
                    itemBuilder: (_, i) {
                      final p = _productos[i];
                      final pId = p['id_producto'];
                      final cant = _carrito[pId] ?? 0;
                      return Card(
                        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          title: Text('${p['nombre']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Precio: \$${p['precio_unitario']} | Stock: ${p['stock_actual']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () {
                                  if (cant > 0) {
                                    setState(() {
                                      if (cant == 1) {
                                        _carrito.remove(pId);
                                      } else {
                                        _carrito[pId] = cant - 1;
                                      }
                                    });
                                  }
                                },
                              ),
                              Text('$cant', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                onPressed: () {
                                  setState(() => _carrito[pId] = cant + 1);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Panel de checkout
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                          Text('\$${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Descuento:', style: TextStyle(fontSize: 16)),
                          SizedBox(
                            width: 80,
                            height: 32,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                              onChanged: (val) {
                                setState(() => _descuento = double.tryParse(val) ?? 0.0);
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('\$${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _crearPedido,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                          child: const Text('Crear Pedido Borrador', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 6. MÓDULO VENTAS (COBROS Y PROFORMA DIGITAL)
// ════════════════════════════════════════════════════════════════
class VentasModule extends StatefulWidget {
  const VentasModule({super.key});

  @override
  State<VentasModule> createState() => _VentasModuleState();
}

class _VentasModuleState extends State<VentasModule> {
  List<dynamic> _pedidos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$_baseUrl/api/v1/pedidos/?estado=borrador'), headers: headers);
      if (res.statusCode == 200) {
        setState(() => _pedidos = jsonDecode(res.body));
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _cobrarDialog(dynamic pedido) {
    String selectedMetodo = 'efectivo';
    final amountCtrl = TextEditingController(text: pedido['total'].toString());

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          title: Text('Procesar Cobro', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Pedido ID: ${pedido['id_pedido'].substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Total a pagar: \$${pedido['total']}', style: const TextStyle(fontSize: 16, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedMetodo,
                    decoration: const InputDecoration(labelText: 'Método de Pago'),
                    items: const [
                      DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                      DropdownMenuItem(value: 'transferencia', child: Text('Transferencia Bancaria')),
                    ],
                    onChanged: (val) => setDialogState(() => selectedMetodo = val ?? 'efectivo'),
                  ),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Monto Recibido'),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final recibido = double.tryParse(amountCtrl.text) ?? 0.0;
                if (recibido < double.parse(pedido['total'].toString())) {
                  AppDialog.show(context, title: 'Monto insuficiente', message: 'El monto pagado debe ser mayor o igual al total.', type: DialogType.error);
                  return;
                }
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final headers = await _getHeaders();
                  final res = await http.post(
                    Uri.parse('$_baseUrl/api/v1/ventas/pagar/${pedido['id_pedido']}'),
                    headers: headers,
                    body: jsonEncode({
                      'metodo_pago': selectedMetodo,
                      'monto_pagado': recibido,
                    }),
                  );

                  if (res.statusCode == 201) {
                    final venta = jsonDecode(res.body);
                    _cargarPedidos();
                    
                    // Mostrar Proforma Digital resultante
                    if (mounted) {
                      _mostrarProformaDigital(venta);
                    }
                  } else {
                    final err = jsonDecode(res.body)['detail'];
                    AppDialog.show(context, title: 'Error de Cobro', message: err ?? 'No se pudo registrar la venta.', type: DialogType.error);
                  }
                } catch (e) {
                  // ignore
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Completar Transacción'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarProformaDigital(dynamic venta) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final ped = venta['pedido'] ?? {};
        final List<dynamic> detalles = ped['detalles'] ?? [];

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PROFORMA DIGITAL', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF0284C7))),
                      const Icon(Icons.receipt_long, color: Color(0xFF0284C7), size: 28),
                    ],
                  ),
                  const Divider(height: 24),
                  Text('Venta ID: ${venta['id_venta']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('Fecha: ${venta['fecha_venta']?.substring(0, 19).replaceFirst('T', ' ')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  const Text('Detalle de Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...detalles.map((d) {
                    final prod = d['producto'] ?? {};
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${prod['nombre'] ?? "Producto"} x${d['cantidad']}')),
                          Text('\$${d['subtotal']}'),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('\$${ped['subtotal']}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Descuento:'),
                      Text('\$${ped['descuento']}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pagado:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('\$${ped['total']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0284C7))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Método de Pago: ${venta['metodo_pago']?.toString().toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                    child: const Text('Listo'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pedidos.isEmpty
              ? const Center(child: Text('No hay pedidos pendientes de cobro.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pedidos.length,
                  itemBuilder: (_, i) {
                    final ped = _pedidos[i];
                    return Card(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        title: Text('Pedido #${ped['id_pedido'].substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Fecha: ${ped['fecha_pedido']?.substring(0, 10)}\nTotal: \$${ped['total']}'),
                        trailing: ElevatedButton(
                          onPressed: () => _cobrarDialog(ped),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                          child: const Text('Cobrar'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 7. MÓDULO REPORTES (KPI DASHBOARD)
// ════════════════════════════════════════════════════════════════
class ReportesModule extends StatefulWidget {
  const ReportesModule({super.key});

  @override
  State<ReportesModule> createState() => _ReportesModuleState();
}

class _ReportesModuleState extends State<ReportesModule> {
  List<dynamic> _ventas = [];
  int _productosConAlerta = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _getHeaders();
      
      // Ventas
      final resV = await http.get(Uri.parse('$_baseUrl/api/v1/ventas/'), headers: headers);
      if (resV.statusCode == 200) {
        _ventas = jsonDecode(resV.body);
      }

      // Productos con alerta
      final resP = await http.get(Uri.parse('$_baseUrl/api/v1/productos/'), headers: headers);
      if (resP.statusCode == 200) {
        final prods = jsonDecode(resP.body);
        _productosConAlerta = prods.where((p) {
          final stock = double.parse(p['stock_actual'].toString());
          final min = double.parse(p['stock_minimo'].toString());
          return stock < min;
        }).length;
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalRecaudado {
    double total = 0.0;
    for (var v in _ventas) {
      total += double.parse(v['monto_pagado'].toString());
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Text('Resumen Comercial', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  
                  // Fila 1 KPIs
                  Row(
                    children: [
                      Expanded(
                        child: _kpiCard(
                          title: 'Total Recaudado',
                          value: '\$${_totalRecaudado.toStringAsFixed(2)}',
                          color: const Color(0xFF10B981),
                          icon: Icons.attach_money,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _kpiCard(
                          title: 'Ventas Realizadas',
                          value: '${_ventas.length}',
                          color: const Color(0xFF0284C7),
                          icon: Icons.shopping_bag_outlined,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fila 2 KPIs
                  Row(
                    children: [
                      Expanded(
                        child: _kpiCard(
                          title: 'Productos en Alerta',
                          value: '$_productosConAlerta',
                          color: Colors.red,
                          icon: Icons.warning_amber_rounded,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Text('Últimas Transacciones', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  
                  Expanded(
                    child: _ventas.isEmpty
                        ? const Center(child: Text('No hay ventas registradas.'))
                        : ListView.builder(
                            itemCount: _ventas.length > 5 ? 5 : _ventas.length,
                            itemBuilder: (_, i) {
                              final v = _ventas[i];
                              return ListTile(
                                leading: const Icon(Icons.payment, color: Color(0xFF10B981)),
                                title: Text('Venta #${v['id_venta'].substring(0, 8)}'),
                                subtitle: Text('Fecha: ${v['fecha_venta']?.substring(0, 10)} | Pago: ${v['metodo_pago']}'),
                                trailing: Text('\$${v['monto_pagado']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
