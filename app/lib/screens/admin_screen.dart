import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'login_screen.dart';
import 'modules_screens.dart';

/// Pantalla del Administrador – acceso completo al sistema.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RoleScreen(
      title: 'Administrador',
      roleColor: Color(0xFFFF6B35),
      icon: Icons.admin_panel_settings,
      greeting: 'Panel de Administración',
      description: 'Control total del sistema AmazonFish',
      roleType: 'admin',
    );
  }
}

/// Pantalla del Vendedor.
class VendedorScreen extends StatelessWidget {
  const VendedorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RoleScreen(
      title: 'Vendedor',
      roleColor: Color(0xFF00B4D8),
      icon: Icons.point_of_sale,
      greeting: 'Panel de Ventas',
      description: 'Gestión de pedidos y ventas',
      roleType: 'vendedor',
    );
  }
}

/// Pantalla del Socio (cliente acuícola).
class SocioScreen extends StatelessWidget {
  const SocioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RoleScreen(
      title: 'Socio',
      roleColor: Color(0xFF52B788),
      icon: Icons.person,
      greeting: 'Mi Portal',
      description: 'Bienvenido al sistema AmazonFish',
      roleType: 'socio',
    );
  }
}

// ── Item del menú ────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget widget;
  const _MenuItem(this.icon, this.title, this.subtitle, this.widget);
}

// ── Widget base de Dashboard con Barra Lateral (Drawer) e integración ──
class _RoleScreen extends StatefulWidget {
  final String title;
  final Color roleColor;
  final IconData icon;
  final String greeting;
  final String description;
  final String roleType;

  const _RoleScreen({
    required this.title,
    required this.roleColor,
    required this.icon,
    required this.greeting,
    required this.description,
    required this.roleType,
  });

  @override
  State<_RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<_RoleScreen> {
  int _currentViewIndex = 0; // 0 = Home / Overview, >0 = Módulo
  List<_MenuItem> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _initMenu();
  }

  void _initMenu() {
    if (widget.roleType == 'admin') {
      _menuItems = const [
        _MenuItem(Icons.people, 'Personas y Usuarios', 'Gestionar directorio', PersonasUsuariosModule()),
        _MenuItem(Icons.shield, 'Roles y Permisos', 'Configurar accesos', RolesPermisosModule()),
        _MenuItem(Icons.inventory, 'Inventario', 'Productos acuícolas', InventarioModule()),
        _MenuItem(Icons.local_shipping, 'Proveedores', 'Gestionar proveedores', ProveedoresModule()),
        _MenuItem(Icons.shopping_cart, 'Pedidos', 'Control de pedidos', PedidosModule()),
        _MenuItem(Icons.sell, 'Ventas', 'Registro de ventas', VentasModule()),
        _MenuItem(Icons.bar_chart, 'Reportes', 'Estadísticas y métricas', ReportesModule()),
      ];
    } else if (widget.roleType == 'vendedor') {
      _menuItems = const [
        _MenuItem(Icons.inventory_2, 'Catálogo', 'Ver productos disponibles', InventarioModule()),
        _MenuItem(Icons.add_shopping_cart, 'Nuevo Pedido', 'Crear pedido', PedidosModule()),
        _MenuItem(Icons.sell, 'Registrar Venta', 'Nueva venta', VentasModule()),
        _MenuItem(Icons.people, 'Clientes (Socios)', 'Ver directorio', PersonasUsuariosModule()),
        _MenuItem(Icons.bar_chart, 'Reportes', 'Mis métricas', ReportesModule()),
      ];
    } else {
      // Socio
      _menuItems = const [
        _MenuItem(Icons.storefront, 'Catálogo de Productos', 'Ver disponibilidad', InventarioModule()),
        _MenuItem(Icons.add_shopping_cart, 'Hacer Pedido', 'Solicitar productos', PedidosModule()),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Determinar la vista activa
    Widget activeBody;
    String activeTitle;
    
    if (_currentViewIndex == 0) {
      activeBody = _buildOverview(isDark);
      activeTitle = 'Dashboard';
    } else {
      final item = _menuItems[_currentViewIndex - 1];
      activeBody = item.widget;
      activeTitle = item.title;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0284C7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const Icon(Icons.set_meal, color: Color(0xFF38BDF8)),
            const SizedBox(width: 10),
            Text(
              'AmazonFish',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: widget.roleColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.roleColor.withOpacity(0.4)),
              ),
              child: Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 11, color: widget.roleColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          // Toggle de Tema
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
            onPressed: () {
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      
      // PC-005: Barra de navegación lateral (Drawer)
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFF0284C7),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: widget.roleColor,
                child: Icon(widget.icon, color: Colors.white, size: 36),
              ),
              accountName: Text(
                widget.greeting,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Text(
                widget.description,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
              ),
            ),
            
            // Item de Inicio
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: Text('Inicio / Resumen', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              selected: _currentViewIndex == 0,
              selectedColor: const Color(0xFF0284C7),
              onTap: () {
                setState(() => _currentViewIndex = 0);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            
            // Módulos
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _menuItems.length,
                itemBuilder: (_, i) {
                  final item = _menuItems[i];
                  return ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.title, style: GoogleFonts.inter()),
                    subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 11)),
                    selected: _currentViewIndex == i + 1,
                    selectedColor: const Color(0xFF0284C7),
                    onTap: () {
                      setState(() => _currentViewIndex = i + 1);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      
      body: activeBody,
    );
  }

  // Vista de Inicio / Resumen del Dashboard
  Widget _buildOverview(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner de Bienvenida
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                  ? [const Color(0xFF1E293B), widget.roleColor.withOpacity(0.15)]
                  : [const Color(0xFF0284C7), widget.roleColor.withOpacity(0.2)],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.roleColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.roleColor.withOpacity(0.4)),
                ),
                child: Icon(widget.icon, color: widget.roleColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, ${widget.title}!',
                      style: GoogleFonts.inter(
                        fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    Text(
                      widget.description,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Módulos del Sistema',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        
        // Grid de accesos directos rediseñado (más pequeños y amigables)
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _menuItems.length,
            itemBuilder: (_, i) {
              final item = _menuItems[i];
              return Card(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _currentViewIndex = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.roleColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, color: widget.roleColor, size: 20),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.title,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item.subtitle,
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
