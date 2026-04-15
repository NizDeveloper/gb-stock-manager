import 'package:flutter/material.dart';
import 'package:gb_stock_manager/core/theme/app_theme.dart';
import 'package:gb_stock_manager/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:gb_stock_manager/features/inventory/presentation/pages/inventory_page.dart';
import 'package:gb_stock_manager/features/catalog/presentation/pages/catalog_page.dart';
import 'package:gb_stock_manager/features/reports/presentation/pages/reports_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Callback que InventoryPage registra para abrir su formulario
  VoidCallback? _openInventoryForm;

  void _onFabPressed() {
    if (_selectedIndex == 1 && _openInventoryForm != null) {
      _openInventoryForm!();
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Cerrar sesión',
          style: TextStyle(color: Colors.white)),
        content: const Text('¿Seguro que quieres cerrar sesión?',
          style: TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
              style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión',
              style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.primary : AppTheme.textGrey,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? AppTheme.primary : AppTheme.textGrey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _onFabPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const DashboardPage(),
          InventoryPage(
            onRegisterOpen: (cb) => _openInventoryForm = cb,
          ),
          const CatalogPage(),
          const ReportsPage(),
        ],
      ),

      // ─── Barra inferior ───
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black12,
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_rounded, 'Inicio', 0),
            _navItem(Icons.inventory_2_outlined, 'Inventario', 1),
            _buildFab(),
            _navItem(Icons.grid_view_rounded, 'Catálogo', 2),
            _navItem(Icons.bar_chart_rounded, 'Reportes', 3),
          ],
        ),
      ),
    );
  }
}