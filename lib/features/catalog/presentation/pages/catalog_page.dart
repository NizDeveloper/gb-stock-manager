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
      _apiService.setToken(prefs.getString('token') ?? '');

      final results = await _apiService.getCategories();
      setState(() {
        _categories = results.map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar las categorías';
        _loading = false;
      });
    }
  }

  // ─── Abrir bottom sheet para crear o editar ───
  void _openCategorySheet({Map<String, dynamic>? category}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(category: category),
    );
    if (result == null) return;

    try {
      if (category == null) {
        await _apiService.createCategory(result);
        _showSnack('Categoría creada', AppTheme.success);
      } else {
        await _apiService.updateCategory(category['id'], result);
        _showSnack('Categoría actualizada', AppTheme.success);
      }
      await _loadCategories();
    } catch (e) {
      _showSnack('Error: $e', AppTheme.danger);
    }
  }

  // ─── Confirmar eliminación ───
  void _confirmDelete(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Eliminar categoría',
          style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Eliminar "${category['name']}"? Los productos asociados quedarán sin categoría.',
          style: const TextStyle(color: Color(0xFF9CA3AF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
              style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.deleteCategory(category['id']);
                _showSnack('Categoría eliminada', AppTheme.success);
                await _loadCategories();
              } catch (e) {
                _showSnack('Error: $e', AppTheme.danger);
              }
            },
            child: const Text('Eliminar',
              style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
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
    if (n.contains('electr'))                                   return Icons.computer_outlined;
    if (n.contains('audio'))                                    return Icons.headphones_outlined;
    if (n.contains('periférico') || n.contains('periferico'))   return Icons.keyboard_outlined;
    if (n.contains('accesorio'))                                return Icons.backpack_outlined;
    if (n.contains('oficina'))                                  return Icons.assignment_outlined;
    if (n.contains('red') || n.contains('network'))             return Icons.language_outlined;
    if (n.contains('ropa') || n.contains('moda'))               return Icons.checkroom_outlined;
    if (n.contains('deporte'))                                  return Icons.sports_soccer_outlined;
    if (n.contains('bebida'))                                   return Icons.local_drink_outlined;
    if (n.contains('grano') || n.contains('cereal'))            return Icons.grain_outlined;
    if (n.contains('lácteo') || n.contains('lacteo'))           return Icons.breakfast_dining_outlined;
    if (n.contains('limpieza'))                                 return Icons.cleaning_services_outlined;
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCategorySheet(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Categorías',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                color: AppTheme.textDark)),
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
              child: const Text('Reintentar',
                style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.grid_view_rounded, color: AppTheme.textGrey, size: 48),
            const SizedBox(height: 12),
            const Text('Sin categorías',
              style: TextStyle(color: AppTheme.textGrey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openCategorySheet(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Crear categoría',
                style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      color: AppTheme.primary,
      child: GridView.builder(
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
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat, Color borderColor) {
    final name = cat['name'] as String;
    final desc = (cat['description'] ?? '') as String;

    return GestureDetector(
      onTap: () => _openCategorySheet(category: cat),
      onLongPress: () => _confirmDelete(cat),
      child: Container(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(_iconForCategory(name),
                    color: AppTheme.textDark, size: 30),
                  GestureDetector(
                    onTap: () => _confirmDelete(cat),
                    child: Icon(Icons.delete_outline,
                      color: AppTheme.danger.withOpacity(0.6), size: 18),
                  ),
                ],
              ),
              const Spacer(),
              Text(name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: AppTheme.textDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                desc.isNotEmpty ? desc : 'Sin descripción',
                style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
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

// ════════════════════════════════════════════════════════════
//  BOTTOM SHEET — CREAR / EDITAR CATEGORÍA
// ════════════════════════════════════════════════════════════
class _CategorySheet extends StatefulWidget {
  final Map<String, dynamic>? category;
  const _CategorySheet({this.category});

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameCtrl.text = widget.category!['name'] ?? '';
      _descCtrl.text = widget.category!['description'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'name':        _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.chevron_left,
                    color: AppTheme.textDark, size: 28)),
              const SizedBox(width: 8),
              Text(
                _isEditing ? 'Editar categoría' : 'Nueva categoría',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                    color: AppTheme.textDark),
              ),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('NOMBRE *'),
                    _field(_nameCtrl, 'Ej. Electrónica',
                        validator: (v) => v!.isEmpty ? 'Requerido' : null),
                    const SizedBox(height: 12),

                    _label('DESCRIPCIÓN'),
                    _field(_descCtrl, 'Descripción opcional...', maxLines: 3),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text(
                          _isEditing ? 'Guardar cambios' : 'Crear categoría',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
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

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
        color: AppTheme.textGrey, letterSpacing: 0.8)),
  );

  Widget _field(TextEditingController ctrl, String hint, {
    String? Function(String?)? validator,
    int maxLines = 1,
  }) => TextFormField(
    controller: ctrl,
    validator: validator,
    maxLines: maxLines,
    style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
      filled: true,
      fillColor: AppTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      errorStyle: const TextStyle(color: AppTheme.danger),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}