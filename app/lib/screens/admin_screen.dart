import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

/// Pantalla del Administrador – acceso completo al sistema.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _RoleScreen(
      title: 'Administrador',
      roleColor: const Color(0xFFFF6B35),
      icon: Icons.admin_panel_settings,
      greeting: 'Panel de Administración',
      description: 'Control total del sistema AmazonFish',
      menuItems: const [
        _MenuItem(Icons.people, 'Personas y Usuarios', 'Gestionar directorio'),
        _MenuItem(Icons.shield, 'Roles y Permisos', 'Configurar accesos'),
        _MenuItem(Icons.inventory, 'Inventario', 'Productos acuícolas'),
        _MenuItem(Icons.local_shipping, 'Proveedores', 'Gestionar proveedores'),
        _MenuItem(Icons.shopping_cart, 'Pedidos', 'Control de pedidos'),
        _MenuItem(Icons.bar_chart, 'Reportes', 'Estadísticas y métricas'),
        _MenuItem(Icons.sell, 'Ventas', 'Registro de ventas'),
        _MenuItem(Icons.settings, 'Configuración', 'Ajustes del sistema'),
      ],
    );
  }
}

/// Pantalla del Vendedor.
class VendedorScreen extends StatelessWidget {
  const VendedorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _RoleScreen(
      title: 'Vendedor',
      roleColor: const Color(0xFF00B4D8),
      icon: Icons.point_of_sale,
      greeting: 'Panel de Ventas',
      description: 'Gestión de pedidos y ventas',
      menuItems: const [
        _MenuItem(Icons.inventory_2, 'Catálogo', 'Ver productos disponibles'),
        _MenuItem(Icons.add_shopping_cart, 'Nuevo Pedido', 'Crear pedido'),
        _MenuItem(Icons.receipt_long, 'Mis Pedidos', 'Historial de pedidos'),
        _MenuItem(Icons.sell, 'Registrar Venta', 'Nueva venta'),
        _MenuItem(Icons.people, 'Clientes (Socios)', 'Ver directorio'),
        _MenuItem(Icons.bar_chart, 'Mi Resumen', 'Mis métricas'),
      ],
    );
  }
}

/// Pantalla del Socio (cliente acuícola).
class SocioScreen extends StatelessWidget {
  const SocioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _RoleScreen(
      title: 'Socio',
      roleColor: const Color(0xFF52B788),
      icon: Icons.person,
      greeting: 'Mi Portal',
      description: 'Bienvenido al sistema AmazonFish',
      menuItems: const [
        _MenuItem(Icons.storefront, 'Catálogo de Productos', 'Ver disponibilidad'),
        _MenuItem(Icons.add_shopping_cart, 'Hacer Pedido', 'Solicitar productos'),
        _MenuItem(Icons.history, 'Mis Pedidos', 'Historial y estado'),
        _MenuItem(Icons.receipt, 'Mis Facturas', 'Comprobantes de pago'),
        _MenuItem(Icons.person, 'Mi Perfil', 'Datos personales'),
      ],
    );
  }
}

// ── Widgets internos reutilizables ────────────────────────────────

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  const _MenuItem(this.icon, this.title, this.subtitle);
}

class _RoleScreen extends StatelessWidget {
  final String title;
  final Color roleColor;
  final IconData icon;
  final String greeting;
  final String description;
  final List<_MenuItem> menuItems;

  const _RoleScreen({
    required this.title,
    required this.roleColor,
    required this.icon,
    required this.greeting,
    required this.description,
    required this.menuItems,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020024),
      appBar: AppBar(
        backgroundColor: const Color(0xFF03045E),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.set_meal, color: Color(0xFF00B4D8)),
            const SizedBox(width: 10),
            Text(
              'AmazonFish',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: roleColor.withOpacity(0.4)),
              ),
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12, color: roleColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF03045E), roleColor.withOpacity(0.3)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: roleColor.withOpacity(0.3)),
                  ),
                  child: Icon(icon, color: roleColor, size: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: GoogleFonts.inter(
                        fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Grid de opciones
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: menuItems.length,
              itemBuilder: (_, i) => _MenuCard(
                item: menuItems[i],
                color: roleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  final Color color;
  const _MenuCard({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.title} – Próximamente'),
              backgroundColor: const Color(0xFF03045E),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
