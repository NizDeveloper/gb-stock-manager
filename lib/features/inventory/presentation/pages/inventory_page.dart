import 'package:flutter/material.dart';
import 'package:gb_stock_manager/core/network/api_service.dart';
import 'package:gb_stock_manager/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Modelo de producto ───
class Product {
  final int id;
  String name;
  String code;
  int categoryId;
  String categoryName;
  double price;
  int quantityInStock;

  Product({
    required this.id,
    required this.name,
    required this.code,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.quantityInStock,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id:              j['id'],
    name:            j['name'],
    code:            j['code'],
    categoryId:      j['category_id'],
    categoryName:    j['category_name'] ?? '',
    price:           double.parse(j['price'].toString()),
    quantityInStock: j['quantity_in_stock'],
  );

  Map<String, dynamic> toJson() => {
    'name':              name,
    'code':              code,
    'price':             price,
    'quantity_in_stock': quantityInStock,
    'category_id':       categoryId,
  };
}

// ════════════════════════════════════════════════════════════
//  PÁGINA PRINCIPAL DE INVENTARIO
// ════════════════════════════════════════════════════════════
class InventoryPage extends StatefulWidget {
  final void Function(VoidCallback)? onRegisterOpen;
  const InventoryPage({super.key, this.onRegisterOpen});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  List<dynamic> _categories = [];
  bool _loading = true;
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRegisterOpen?.call(_openAddProduct);
    });
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiService.setToken(prefs.getString('token') ?? '');
      final results = await Future.wait([
        _apiService.getProducts(),
        _apiService.getCategories(),
      ]);
      setState(() {
        _products   = (results[0] as List).map((e) => Product.fromJson(e)).toList();
        _categories = results[1] as List;
        _loading    = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando productos: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _openAddProduct() async {
    final created = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddProductSheet(categories: _categories),
    );
    if (created != null) {
      try {
        await _apiService.createProduct(created);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${created['name']} agregado'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
          );
        }
      }
    }
  }

  List<Product> get _filtered {
    return _products.where((p) {
      final matchCat = _selectedCategory == 'Todos' || p.categoryName == _selectedCategory;
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
        p.name.toLowerCase().contains(q) ||
        p.code.toLowerCase().contains(q);
      return matchCat && matchSearch;
    }).toList();
  }

  List<String> get _activeCategories {
    final cats = _products.map((p) => p.categoryName).toSet().toList()..sort();
    return ['Todos', ...cats];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategoryChips(),
            Expanded(child: _buildProductList()),
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
          const Text('Inventario',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                color: AppTheme.textDark)),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.filter_list, color: AppTheme.textDark, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: AppTheme.textDark),
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Buscar producto, código...',
          hintStyle: const TextStyle(color: AppTheme.textGrey),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey),
          suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textGrey),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                })
            : null,
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _activeCategories.length,
        itemBuilder: (context, i) {
          final cat = _activeCategories[i];
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppTheme.primary : Colors.white12,
                ),
              ),
              child: Center(
                child: Text(cat,
                  style: TextStyle(
                    color: selected ? Colors.white : AppTheme.textGrey,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList() {
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.inventory_2_outlined, color: AppTheme.textGrey, size: 48),
            SizedBox(height: 12),
            Text('No hay productos', style: TextStyle(color: AppTheme.textGrey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildProductCard(list[index]),
      ),
    );
  }

  Widget _buildProductCard(Product p) {
    final isOutOfStock = p.quantityInStock == 0;
    final Color stockColor = isOutOfStock ? AppTheme.danger : AppTheme.success;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(
              product: p,
              categories: _categories,
              onProductUpdated: () => _loadData(),
              onProductDeleted: () => _loadData(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                    style: const TextStyle(fontWeight: FontWeight.w600,
                        color: AppTheme.textDark, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(p.code,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _categoryBadge(p.categoryName),
                      if (isOutOfStock) ...[
                        const SizedBox(width: 6),
                        _statusBadge('AGOTADO', AppTheme.danger),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(p.quantityInStock.toString(),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: stockColor)),
                Text('\$${p.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.primary.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label,
      style: const TextStyle(fontSize: 10, color: AppTheme.primary,
          fontWeight: FontWeight.w600)),
  );

  Widget _statusBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );

  void openAddProduct() => _openAddProduct();
}

// ════════════════════════════════════════════════════════════
//  BOTTOM SHEET — NUEVO PRODUCTO
// ════════════════════════════════════════════════════════════
class _AddProductSheet extends StatefulWidget {
  final List<dynamic> categories;
  const _AddProductSheet({required this.categories});

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _codeCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController(text: '0.00');
  final _stockCtrl = TextEditingController(text: '0');
  int? _selectedCategoryId;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _codeCtrl, _priceCtrl, _stockCtrl]) c.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')));
      return;
    }
    Navigator.pop(context, {
      'name':              _nameCtrl.text.trim(),
      'code':              _codeCtrl.text.trim(),
      'price':             double.tryParse(_priceCtrl.text) ?? 0,
      'quantity_in_stock': int.tryParse(_stockCtrl.text) ?? 0,
      'category_id':       _selectedCategoryId,
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
              color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.chevron_left,
                    color: AppTheme.textDark, size: 28)),
              const SizedBox(width: 8),
              const Text('Nuevo producto',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
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
                    _field(_nameCtrl, 'Ej. Laptop HP Pavilion',
                        validator: (v) => v!.isEmpty ? 'Requerido' : null),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('CÓDIGO / SKU *'),
                          _field(_codeCtrl, 'Ej. HP-PAV-15',
                              validator: (v) => v!.isEmpty ? 'Requerido' : null),
                        ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('CATEGORÍA *'),
                          _categoryDropdown(),
                        ])),
                    ]),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('PRECIO *'),
                          _field(_priceCtrl, '0.00',
                              keyboardType: TextInputType.number),
                        ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('STOCK INICIAL'),
                          _field(_stockCtrl, '0',
                              keyboardType: TextInputType.number),
                        ])),
                    ]),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Guardar producto',
                          style: TextStyle(color: Colors.white,
                              fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _categoryDropdown() => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: _selectedCategoryId,
        hint: const Text('Seleccionar...',
          style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
        dropdownColor: const Color(0xFF2A2A2A),
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textGrey),
        onChanged: (v) => setState(() => _selectedCategoryId = v),
        items: widget.categories.map((c) {
          final isSelected = c['id'] == _selectedCategoryId;
          return DropdownMenuItem<int>(
            value: c['id'],
            child: Text(c['name'],
              style: TextStyle(
                color: isSelected ? Colors.black87 : Colors.white,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
        color: AppTheme.textGrey, letterSpacing: 0.8)),
  );

  Widget _field(TextEditingController ctrl, String hint, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) => TextFormField(
    controller: ctrl,
    validator: validator,
    keyboardType: keyboardType,
    style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
      filled: true, fillColor: AppTheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      errorStyle: const TextStyle(color: AppTheme.danger),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  PÁGINA DETALLE DE PRODUCTO
// ════════════════════════════════════════════════════════════
class ProductDetailPage extends StatefulWidget {
  final Product product;
  final List<dynamic> categories;
  final VoidCallback onProductUpdated;
  final VoidCallback onProductDeleted;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.categories,
    required this.onProductUpdated,
    required this.onProductDeleted,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ApiService _apiService = ApiService();
  late Product _product;
  List<dynamic> _movements = [];
  bool _loadingMovements = true;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _initToken();
  }

  Future<void> _initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _apiService.setToken(prefs.getString('token') ?? '');
    await _loadMovements();
  }

  Future<void> _loadMovements() async {
    try {
      final results = await _apiService.getProductMovements(_product.id);
      setState(() {
        _movements        = results;
        _loadingMovements = false;
      });
    } catch (e) {
      setState(() => _loadingMovements = false);
    }
  }

  void _openAdjustStock() async {
    final result = await showModalBottomSheet<_StockMovement>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdjustStockSheet(product: _product),
    );
    if (result != null) {
      try {
        final newQty = (_product.quantityInStock + result.delta).clamp(0, 99999);
        await _apiService.updateProduct(_product.id, {
          'name':              _product.name,
          'code':              _product.code,
          'price':             _product.price,
          'quantity_in_stock': newQty,
          'category_id':       _product.categoryId,
        });
        await _apiService.createStockMovement({
          'product_id': _product.id,
          'type':       result.delta > 0 ? 'entry' : 'exit',
          'quantity':   result.delta.abs(),
          'notes':      result.note.isNotEmpty ? result.note : result.type,
        });
        setState(() {
          _product = Product(
            id:              _product.id,
            name:            _product.name,
            code:            _product.code,
            categoryId:      _product.categoryId,
            categoryName:    _product.categoryName,
            price:           _product.price,
            quantityInStock: newQty,
          );
        });
        await _loadMovements(); // ← recarga historial real
        widget.onProductUpdated();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stock actualizado a $newQty'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'),
                backgroundColor: AppTheme.danger),
          );
        }
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Eliminar producto',
          style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Eliminar "${_product.name}"? Esta acción no se puede deshacer.',
          style: const TextStyle(color: Color(0xFF9CA3AF))),
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
                await _apiService.deleteProduct(_product.id);
                widget.onProductDeleted();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error eliminando: $e'),
                        backgroundColor: AppTheme.danger),
                  );
                }
              }
            },
            child: const Text('Eliminar',
              style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = _product.quantityInStock == 0;
    final Color stockColor = isOutOfStock ? AppTheme.danger : AppTheme.success;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                  ),
                  const Expanded(
                    child: Text('Detalle',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  ),
                  GestureDetector(
                    onTap: _confirmDelete,
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.delete_outline,
                          color: AppTheme.danger, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Hero card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.inventory_2_outlined,
                                color: AppTheme.primary, size: 32),
                          ),
                          const SizedBox(height: 12),
                          Text(_product.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22,
                                fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Código: ${_product.code}',
                            style: const TextStyle(fontSize: 12,
                                color: Color(0xFF9CA3AF))),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _badge(_product.categoryName, AppTheme.primary),
                              if (isOutOfStock) ...[
                                const SizedBox(width: 8),
                                _badge('AGOTADO', AppTheme.danger),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Info grid ──
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.2,
                      children: [
                        _infoTile('📦 Stock actual',
                          _product.quantityInStock.toString(), stockColor),
                        _infoTile('💰 Precio',
                          '\$${_product.price.toStringAsFixed(2)}', Colors.white),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Botón ajustar stock ──
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _openAdjustStock,
                        icon: const Icon(Icons.swap_vert, color: Colors.white),
                        label: const Text('Ajustar stock',
                          style: TextStyle(color: Colors.white,
                              fontSize: 16, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Historial real ──
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Historial de movimientos',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 10),
                    if (_loadingMovements) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(color: AppTheme.primary),
                        ),
                      ),
                    ] else if (_movements.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.history, color: Color(0xFF9CA3AF), size: 20),
                            SizedBox(width: 10),
                            Text('Sin movimientos registrados',
                              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                          ],
                        ),
                      ),
                    ] else ...[
                      ..._movements.map((m) => _movementTile(m)),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label,
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
  );

  Widget _infoTile(String label, String value, Color valueColor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 4),
        Text(value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
              color: valueColor)),
      ],
    ),
  );

  Widget _movementTile(dynamic m) {
    final isEntry   = m['type'] == 'entry';
    final color     = isEntry ? AppTheme.success : AppTheme.danger;
    final icon      = isEntry ? Icons.add_circle : Icons.remove_circle;
    final qty       = m['quantity'] ?? 0;
    final notes     = m['notes'] ?? (isEntry ? 'Entrada' : 'Salida');
    final userName  = m['user_name'] ?? '';
    final createdAt = DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now();
    final dateStr   =
      '${createdAt.day}/${createdAt.month}/${createdAt.year}, '
      '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')} '
      '${createdAt.hour >= 12 ? 'PM' : 'AM'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notes,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 13)),
                Text('$dateStr · $userName',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
              ],
            ),
          ),
          Text('${isEntry ? '+' : '-'}$qty',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

// ─── Modelo de movimiento ───
class _StockMovement {
  final String type;
  final int delta;
  final DateTime date;
  final String note;
  _StockMovement({
    required this.type,
    required this.delta,
    required this.date,
    this.note = '',
  });
}

// ════════════════════════════════════════════════════════════
//  BOTTOM SHEET — AJUSTAR STOCK
// ════════════════════════════════════════════════════════════
class _AdjustStockSheet extends StatefulWidget {
  final Product product;
  const _AdjustStockSheet({required this.product});

  @override
  State<_AdjustStockSheet> createState() => _AdjustStockSheetState();
}

class _AdjustStockSheetState extends State<_AdjustStockSheet> {
  String _movType   = 'Entrada';
  int    _qty       = 1;
  final _qtyCtrl    = TextEditingController(text: '1');
  final _reasonCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    if (_qty <= 0) return;
    final delta = _movType == 'Salida' ? -_qty : _qty;
    final mov = _StockMovement(
      type:  _reasonCtrl.text.trim().isEmpty ? _movType : _reasonCtrl.text.trim(),
      delta: delta,
      date:  DateTime.now(),
      note:  _noteCtrl.text.trim(),
    );
    Navigator.pop(context, mov);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.chevron_left,
                      color: Colors.white, size: 28)),
                const SizedBox(width: 8),
                const Text('Ajustar stock',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: Colors.white)),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetLabel('PRODUCTO'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '${widget.product.name} (Stock: ${widget.product.quantityInStock})',
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _sheetLabel('TIPO DE MOVIMIENTO'),
                Row(
                  children: ['Entrada', 'Salida', 'Ajuste'].map((t) {
                    final sel = t == _movType;
                    final Color c = t == 'Entrada' ? AppTheme.success
                      : t == 'Salida' ? AppTheme.danger : AppTheme.warning;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _movType = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: sel ? c.withOpacity(0.15) : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: sel ? c : Colors.transparent),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                t == 'Entrada' ? Icons.arrow_downward
                                  : t == 'Salida' ? Icons.arrow_upward
                                  : Icons.swap_vert,
                                color: sel ? c : const Color(0xFF9CA3AF), size: 18),
                              const SizedBox(height: 4),
                              Text(t,
                                style: TextStyle(
                                  color: sel ? c : const Color(0xFF9CA3AF),
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                _sheetLabel('CANTIDAD'),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () => setState(() {
                          if (_qty > 1) {
                            _qty--;
                            _qtyCtrl.text = _qty.toString();
                          }
                        }),
                        icon: const Icon(Icons.remove, color: Colors.white)),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _qtyCtrl,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 26,
                              fontWeight: FontWeight.bold, color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) {
                            final parsed = int.tryParse(v);
                            if (parsed != null && parsed > 0) {
                              setState(() => _qty = parsed);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() {
                          _qty++;
                          _qtyCtrl.text = _qty.toString();
                        }),
                        icon: const Icon(Icons.add, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _sheetLabel('MOTIVO / REFERENCIA'),
                _sheetTextField(_reasonCtrl,
                  'Ej. Compra a proveedor, Venta, Merma...'),
                const SizedBox(height: 12),

                _sheetLabel('NOTA (OPCIONAL)'),
                _sheetTextField(_noteCtrl, 'Información adicional...', maxLines: 3),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _apply,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Aplicar movimiento',
                      style: TextStyle(color: Colors.white,
                          fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cancelar',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
          color: Color(0xFF9CA3AF), letterSpacing: 0.8)),
  );

  Widget _sheetTextField(TextEditingController ctrl, String hint,
      {int maxLines = 1}) =>
    TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
}