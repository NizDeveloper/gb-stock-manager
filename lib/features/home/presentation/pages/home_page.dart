import 'package:flutter/material.dart';
import 'package:gb_stock_manager/core/theme/app_theme.dart';
import 'package:gb_stock_manager/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:gb_stock_manager/features/inventory/presentation/pages/inventory_page.dart';
import 'package:gb_stock_manager/features/catalog/presentation/pages/catalog_page.dart';
import 'package:gb_stock_manager/features/reports/presentation/pages/reports_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  VoidCallback? _openInventoryForm;
  String? _inventoryCategory; // 👈 nuevo

  void _navigateToInventory(String? category) {
    // 👈 nuevo
    setState(() {
      _inventoryCategory = category;
      _selectedIndex = 1;
    });
  }

  void _onFabPressed() {
    if (_selectedIndex == 1 && _openInventoryForm != null) {
      _openInventoryForm!();
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
            initialCategory: _inventoryCategory, // 👈 nuevo
          ),
          CatalogPage(
            onNavigateToInventory: _navigateToInventory, // 👈 nuevo
          ),
          const ReportsPage(),
        ],
      ),
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
