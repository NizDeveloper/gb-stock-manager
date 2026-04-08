import 'package:flutter/material.dart';
import 'package:gb_stock_manager/core/network/api_service.dart';
import 'package:gb_stock_manager/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final ApiService _apiService = ApiService();

  bool _loading = true;
  List<Map<String, dynamic>> _categories = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      _apiService.setToken(token);

      final products = await _apiService.getProducts();

      // Agrupar productos por categoría y contar
      final Map<String, int> countMap = {};
      for (final p in products) {
        final cat = (p['category_name'] ?? p['category'] ?? 'Sin categoría').toString();
        countMap[cat] = (countMap[cat] ?? 0) + 1;
      }

      setState(() {
        _categories = countMap.entries
            .map((e) => {'name': e.key, 'count': e.value})
            .toList()
          ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar las categorías';
        _loading = false;
      });
    }
  }

  static const List<Color> _borderColors = [
    Color(0xFF7C3AED),
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF3B82F6),
    Color(0xFF14B8A6),
    Color(0xFFF43F5E),
  ];

  IconData _iconForCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('electr'))                                     return Icons.computer_outlined;
    if (n.contains('audio'))                                      return Icons.headphones_outlined;
    if (n.contains('periférico') || n.contains('periferico'))     return Icons.keyboard_outlined;
    if (n.contains('accesorio'))                                  return Icons.backpack_outlined;
    if (n.contains('oficina'))                                    return Icons.assignment_outlined;
    if (n.contains('red') || n.contains('network'))               return Icons.language_outlined;
    if (n.contains('ropa') || n.contains('moda'))                 return Icons.checkroom_outlined;
    if (n.contains('deporte'))                                    return Icons.sports_soccer_outlined;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
          GestureDetector(
            onTap: _loadCategories,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh, color: AppTheme.textDark, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.textGrey, size: 48),
            const SizedBox(height: 12),
            Text(_error, style: const TextStyle(color: AppTheme.textGrey)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadCategories,
              child: const Text('Reintentar', style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_view_rounded, color: AppTheme.textGrey, size: 48),
            SizedBox(height: 12),
            Text('Sin categorías', style: TextStyle(color: AppTheme.textGrey)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final borderColor = _borderColors[index % _borderColors.length];
        return _buildCategoryCard(cat, borderColor);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat, Color borderColor) {
    final name  = cat['name'] as String;
    final count = cat['count'] as int;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(color: borderColor, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_iconForCategory(name), color: AppTheme.textDark, size: 30),
            const Spacer(),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$count ${count == 1 ? 'producto' : 'productos'}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}