import 'package:flutter/material.dart';
import 'package:gb_stock_manager/core/theme/app_theme.dart';

// ─── Modelo de categoría ───
class _Category {
  final String name;
  final String icon;
  final int productCount;
  final Color accentColor;

  const _Category({
    required this.name,
    required this.icon,
    required this.productCount,
    required this.accentColor,
  });
}

const _kCategories = [
  _Category(
    name: 'Accesorios',
    icon: '🎒',
    productCount: 2,
    accentColor: Color(0xFFEC4899),
  ),
  _Category(
    name: 'Audio',
    icon: '🎧',
    productCount: 1,
    accentColor: Color(0xFF10B981),
  ),
  _Category(
    name: 'Electrónica',
    icon: '🖥️',
    productCount: 2,
    accentColor: Color(0xFF6C63FF),
  ),
  _Category(
    name: 'Periféricos',
    icon: '⌨️',
    productCount: 2,
    accentColor: Color(0xFF3B82F6),
  ),
  _Category(
    name: 'Oficina',
    icon: '📋',
    productCount: 1,
    accentColor: Color(0xFFF59E0B),
  ),
];

class CatalogPage extends StatelessWidget {
  final void Function(String? category)? onNavigateToInventory;

  const CatalogPage({super.key, this.onNavigateToInventory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Categorías',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _kCategories.length,
      itemBuilder: (_, i) => _CategoryCard(
        category: _kCategories[i],
        onTap: () => onNavigateToInventory?.call(_kCategories[i].name),
      ),
    );
  }
}

// ─── Tarjeta de categoría ───
class _CategoryCard extends StatelessWidget {
  final _Category category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Stack(
          children: [
            // Borde inferior de color
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: category.accentColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono con fondo
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: category.accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        category.icon,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Nombre
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Contador
                  Text(
                    '${category.productCount} producto${category.productCount != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
