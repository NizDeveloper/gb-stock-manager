import 'package:flutter/material.dart';
import 'package:gb_stock_manager/core/theme/app_theme.dart';

// ─── Modelo de producto ───
class Product {
  final String id;
  String name;
  String sku;
  String category;
  String icon;
  double buyPrice;
  double sellPrice;
  int stock;
  int minStock;
  String location;
  String supplier;
  String description;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.icon,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
    required this.minStock,
    this.location = '',
    this.supplier = '',
    this.description = '',
  });
}

// ─── Datos de prueba ───
final List<Product> _sampleProducts = [
  Product(id: '1', name: 'Laptop HP Pavilion 15', sku: 'HP-PAV-15',   category: 'Electrónica',  icon: '💻', buyPrice: 900,  sellPrice: 1099, stock: 0,  minStock: 3),
  Product(id: '2', name: 'Audífonos Sony WH-1000XM5', sku: 'SNY-WH-X5', category: 'Audio',       icon: '🎧', buyPrice: 200,  sellPrice: 299,  stock: 25, minStock: 5),
  Product(id: '3', name: 'Mouse Logitech MX Master 3', sku: 'LGT-MX3', category: 'Periféricos',  icon: '🖱️', buyPrice: 80,   sellPrice: 129,  stock: 4,  minStock: 5),
  Product(id: '4', name: 'Teclado mecánico Keychron K2', sku: 'KCH-K2-BL', category: 'Periféricos', icon: '⌨️', buyPrice: 100, sellPrice: 149, stock: 4, minStock: 5),
  Product(id: '5', name: 'Monitor LG 27" 4K', sku: 'LG-27UK850',     category: 'Electrónica',  icon: '🖥️', buyPrice: 400,  sellPrice: 599,  stock: 6,  minStock: 2),
  Product(id: '6', name: 'Webcam Logitech C920', sku: 'LGT-C920',     category: 'Accesorios',   icon: '📷', buyPrice: 55,   sellPrice: 89,   stock: 12, minStock: 4),
  Product(id: '7', name: 'Hub USB-C 7 puertos', sku: 'USB-HUB-7P',    category: 'Accesorios',   icon: '🔌', buyPrice: 25,   sellPrice: 45,   stock: 18, minStock: 6),
];

const List<String> _allCategories = [
  'Todos', 'Electrónica', 'Audio', 'Periféricos', 'Accesorios', 'Oficina', 'Ropa',
];

// ─── Íconos disponibles para el formulario ───
const List<String> _availableIcons = [
  '💻','📱','🖥️','🖨️','🖱️','📷','🎧','🖨️',
  '📦','🔧','💡','🔋',
];

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
  final List<Product> _products = List.from(_sampleProducts);
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Registra _openAddProduct en HomePage para que el FAB lo pueda llamar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRegisterOpen?.call(_openAddProduct);
    });
  }

  List<Product> get _filtered {
    return _products.where((p) {
      final matchCat = _selectedCategory == 'Todos' || p.category == _selectedCategory;
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q);
      return matchCat && matchSearch;
    }).toList();
  }

  // Categorías que realmente existen en los productos actuales
  List<String> get _activeCategories {
    final cats = _products.map((p) => p.category).toSet().toList()..sort();
    return ['Todos', ...cats];
  }

  void _openAddProduct() async {
    final newProduct = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddProductSheet(),
    );
    if (newProduct != null) {
      setState(() => _products.add(newProduct));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.success,
          content: Text('${newProduct.name} agregado al inventario'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

  // ─── Encabezado ───
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

  // ─── Barra de búsqueda ───
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: AppTheme.textDark),
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Buscar producto, SKU...',
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

  // ─── Chips de categorías ───
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

  // ─── Lista de productos filtrados ───
  Widget _buildProductList() {
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, color: AppTheme.textGrey, size: 48),
            const SizedBox(height: 12),
            Text('No hay productos', style: TextStyle(color: AppTheme.textGrey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildProductCard(list[index]),
    );
  }

  // ─── Card de producto ───
  Widget _buildProductCard(Product p) {
    final isOutOfStock = p.stock == 0;
    final isLowStock   = !isOutOfStock && p.stock <= p.minStock;
    final stockRatio   = p.minStock > 0 ? (p.stock / (p.minStock * 6)).clamp(0.0, 1.0) : 1.0;

    Color stockColor = AppTheme.success;
    if (isOutOfStock) stockColor = AppTheme.danger;
    else if (isLowStock) stockColor = AppTheme.warning;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(
              product: p,
              onProductUpdated: (updated) => setState(() {
                final i = _products.indexWhere((x) => x.id == updated.id);
                if (i != -1) _products[i] = updated;
              }),
              onProductDeleted: (id) => setState(() {
                _products.removeWhere((x) => x.id == id);
              }),
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
      child: Column(
        children: [
          Row(
            children: [
              // Ícono
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(p.icon, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600,
                          color: AppTheme.textDark, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(p.sku,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _categoryBadge(p.category),
                        if (isOutOfStock) ...[
                          const SizedBox(width: 6),
                          _statusBadge('AGOTADO', AppTheme.danger),
                        ] else if (isLowStock) ...[
                          const SizedBox(width: 6),
                          _statusBadge('STOCK BAJO', AppTheme.warning),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Stock y precio
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    p.stock.toString(),
                    style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: stockColor,
                    ),
                  ),
                  Text('\$${p.sellPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Barra de stock
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stockRatio,
              minHeight: 3,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(stockColor),
            ),
          ),
        ],
      ),
      ),  // end Container
    );  // end GestureDetector
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

  // Método público para que HomePage lo llame desde el FAB
  void openAddProduct() => _openAddProduct();
}

// ════════════════════════════════════════════════════════════
//  BOTTOM SHEET — NUEVO PRODUCTO
// ════════════════════════════════════════════════════════════
class _AddProductSheet extends StatefulWidget {
  const _AddProductSheet();

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final _formKey = GlobalKey<FormState>();

  String _selectedIcon = _availableIcons[0];
  String? _selectedCategory;
  final _nameCtrl     = TextEditingController();
  final _skuCtrl      = TextEditingController();
  final _buyCtrl      = TextEditingController(text: '0.00');
  final _sellCtrl     = TextEditingController(text: '0.00');
  final _stockCtrl    = TextEditingController(text: '0');
  final _minStockCtrl = TextEditingController(text: '5');
  final _locationCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _descCtrl     = TextEditingController();

  @override
  void dispose() {
    for (final c in [_nameCtrl, _skuCtrl, _buyCtrl, _sellCtrl,
      _stockCtrl, _minStockCtrl, _locationCtrl, _supplierCtrl, _descCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')));
      return;
    }
    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      sku: _skuCtrl.text.trim(),
      category: _selectedCategory!,
      icon: _selectedIcon,
      buyPrice: double.tryParse(_buyCtrl.text) ?? 0,
      sellPrice: double.tryParse(_sellCtrl.text) ?? 0,
      stock: int.tryParse(_stockCtrl.text) ?? 0,
      minStock: int.tryParse(_minStockCtrl.text) ?? 5,
      location: _locationCtrl.text.trim(),
      supplier: _supplierCtrl.text.trim(),
      description: _descCtrl.text.trim(),
    );
    Navigator.pop(context, product);
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
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.chevron_left, color: AppTheme.textDark, size: 28),
                ),
                const SizedBox(width: 8),
                const Text('Nuevo producto',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: AppTheme.textDark)),
              ],
            ),
          ),
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('ÍCONO DEL PRODUCTO'),
                    _iconPicker(),
                    const SizedBox(height: 16),

                    _label('NOMBRE DEL PRODUCTO *'),
                    _textField(_nameCtrl, 'Ej. Laptop HP Pavilion 15',
                        validator: (v) => v!.isEmpty ? 'Requerido' : null),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('SKU / CÓDIGO *'),
                        _textField(_skuCtrl, 'Ej. HP-PAV-15',
                            validator: (v) => v!.isEmpty ? 'Requerido' : null),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('CATEGORÍA *'),
                        _categoryDropdown(),
                      ])),
                    ]),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('PRECIO COMPRA *'),
                        _textField(_buyCtrl, '0.00',
                            keyboardType: TextInputType.number),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('PRECIO VENTA'),
                        _textField(_sellCtrl, '0.00',
                            keyboardType: TextInputType.number),
                      ])),
                    ]),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('STOCK INICIAL *'),
                        _textField(_stockCtrl, '0',
                            keyboardType: TextInputType.number),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('STOCK MÍNIMO'),
                        _textField(_minStockCtrl, '5',
                            keyboardType: TextInputType.number),
                      ])),
                    ]),
                    const SizedBox(height: 12),

                    _label('UBICACIÓN'),
                    _textField(_locationCtrl, 'Ej. Bodega A, Estante 3'),
                    const SizedBox(height: 12),

                    _label('PROVEEDOR'),
                    _textField(_supplierCtrl, 'Nombre del proveedor'),
                    const SizedBox(height: 12),

                    _label('DESCRIPCIÓN'),
                    _textField(_descCtrl, 'Descripción del producto...',
                        maxLines: 3),
                    const SizedBox(height: 24),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      height: 52,
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

  // ─── Icon picker ───
  Widget _iconPicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: _availableIcons.map((ico) {
          final selected = ico == _selectedIcon;
          return GestureDetector(
            onTap: () => setState(() => _selectedIcon = ico),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary.withOpacity(0.25)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppTheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(child: Text(ico, style: const TextStyle(fontSize: 22))),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Dropdown de categorías ───
  Widget _categoryDropdown() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          hint: const Text('Seleccionar...', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
          dropdownColor: const Color(0xFF1E1E1E),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textGrey),
          style: const TextStyle(color: AppTheme.textDark, fontSize: 13),
          items: _allCategories.skip(1).map((c) =>
            DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v),
        ),
      ),
    );
  }

  // ─── Helpers de UI ───
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
          color: AppTheme.textGrey, letterSpacing: 0.8)),
  );

  Widget _textField(TextEditingController ctrl, String hint, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboardType,
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
}

// ════════════════════════════════════════════════════════════
//  PÁGINA DETALLE DE PRODUCTO
// ════════════════════════════════════════════════════════════
class ProductDetailPage extends StatefulWidget {
  final Product product;
  final void Function(Product) onProductUpdated;
  final void Function(String) onProductDeleted;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.onProductUpdated,
    required this.onProductDeleted,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Product _product;
  final List<_StockMovement> _movements = [];

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    // Movimiento de ejemplo
    _movements.add(_StockMovement(
      type: 'Venta',
      delta: -2,
      date: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
    ));
  }

  void _openAdjustStock() async {
    final result = await showModalBottomSheet<_StockMovement>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdjustStockSheet(product: _product),
    );
    if (result != null) {
      setState(() {
        _product.stock = (_product.stock + result.delta).clamp(0, 99999);
        _movements.insert(0, result);
      });
      widget.onProductUpdated(_product);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Eliminar producto',
            style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar "${_product.name}"? Esta acción no se puede deshacer.',
            style: const TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);   // cierra dialog
              Navigator.pop(context);   // regresa a inventario
              widget.onProductDeleted(_product.id);
            },
            child: const Text('Eliminar', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = _product.stock == 0;
    final isLowStock   = !isOutOfStock && _product.stock <= _product.minStock;
    Color stockColor = AppTheme.success;
    if (isOutOfStock) stockColor = AppTheme.danger;
    else if (isLowStock) stockColor = AppTheme.warning;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
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
                      child: Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
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
                          Text(_product.icon, style: const TextStyle(fontSize: 52)),
                          const SizedBox(height: 12),
                          Text(_product.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22,
                                fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('SKU: ${_product.sku}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _badge(_product.category, AppTheme.primary),
                              if (isOutOfStock) ...[
                                const SizedBox(width: 8),
                                _badge('AGOTADO', AppTheme.danger),
                              ] else if (isLowStock) ...[
                                const SizedBox(width: 8),
                                _badge('STOCK BAJO', AppTheme.warning),
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
                        _infoTile('🟠 Stock actual', _product.stock.toString(), stockColor),
                        _infoTile('⚠️ Stock mínimo', _product.minStock.toString(), Colors.white),
                        _infoTile('🟠 Precio compra', '\$${_product.buyPrice.toStringAsFixed(0)}', Colors.white),
                        _infoTile('🏷️ Precio venta', '\$${_product.sellPrice.toStringAsFixed(0)}', Colors.white),
                        if (_product.location.isNotEmpty)
                          _infoTile('📍 Ubicación', _product.location, Colors.white),
                        if (_product.supplier.isNotEmpty)
                          _infoTile('🏢 Proveedor', _product.supplier, Colors.white),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Botón ajustar stock ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
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

                    // ── Historial ──
                    if (_movements.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Historial de movimientos',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      ),
                      const SizedBox(height: 10),
                      ..._movements.map((m) => _movementTile(m)),
                    ],
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    ),
  );

  Widget _movementTile(_StockMovement m) {
    final isPositive = m.delta > 0;
    final color = isPositive ? AppTheme.success : AppTheme.danger;
    final icon  = isPositive ? Icons.add_circle : Icons.remove_circle;
    final dateStr = '${m.date.day}/${m.date.month}/${m.date.year}, '
        '${m.date.hour}:${m.date.minute.toString().padLeft(2, '0')} '
        '${m.date.hour >= 12 ? 'PM' : 'AM'}';
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
                Text(m.type,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 13)),
                Text(dateStr,
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
              ],
            ),
          ),
          Text('${isPositive ? '+' : ''}${m.delta}',
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
  String _movType = 'Entrada'; // Entrada | Salida | Ajuste
  int _qty = 1;
  final _reasonCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    if (_qty <= 0) return;
    final delta = _movType == 'Salida' ? -_qty : _qty;
    final mov = _StockMovement(
      type: _reasonCtrl.text.trim().isEmpty ? _movType : _reasonCtrl.text.trim(),
      delta: delta,
      date: DateTime.now(),
      note: _noteCtrl.text.trim(),
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
            decoration: BoxDecoration(color: Colors.white24,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.chevron_left, color: Colors.white, size: 28)),
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
                // Producto
                _sheetLabel('PRODUCTO'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(widget.product.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Text('${widget.product.name} (Stock: ${widget.product.stock})',
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tipo
                _sheetLabel('TIPO DE MOVIMIENTO'),
                Row(
                  children: ['Entrada', 'Salida', 'Ajuste'].map((t) {
                    final sel = t == _movType;
                    Color c = t == 'Entrada' ? AppTheme.success
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

                // Cantidad
                _sheetLabel('CANTIDAD'),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () => setState(() { if (_qty > 1) _qty--; }),
                        icon: const Icon(Icons.remove, color: Colors.white)),
                      Text('$_qty',
                        style: const TextStyle(fontSize: 26,
                            fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(
                        onPressed: () => setState(() => _qty++),
                        icon: const Icon(Icons.add, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Motivo
                _sheetLabel('MOTIVO / REFERENCIA'),
                _sheetTextField(_reasonCtrl, 'Ej. Compra a proveedor, Venta, Merma...'),
                const SizedBox(height: 12),

                // Nota
                _sheetLabel('NOTA (OPCIONAL)'),
                _sheetTextField(_noteCtrl, 'Información adicional...', maxLines: 3),
                const SizedBox(height: 20),

                // Botones
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

  Widget _sheetTextField(TextEditingController ctrl, String hint, {int maxLines = 1}) =>
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