import 'package:flutter/material.dart';
import 'package:gb_stock_manager/core/network/api_service.dart';
import 'package:gb_stock_manager/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ApiService _apiService = ApiService();

  bool _loading = true;

  // Datos del dashboard reutilizados
  double _totalValue    = 0;
  double _avgMargin     = 0;
  int    _totalProducts = 0;
  int    _lowStock      = 0;
  int    _outOfStock    = 0;

  List<dynamic> _lowStockProducts = [];
  List<dynamic> _allProducts      = [];

  // Movimientos simulados por día (L-D)
  final List<int> _weekMovements = [12, 8, 15, 6, 10, 20, 14];
  final List<String> _weekLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      _apiService.setToken(token);

      final stats    = await _apiService.getDashboardStats();
      final lowStock = await _apiService.getLowStockProducts();
      final products = await _apiService.getProducts();

      // Margen promedio calculado desde productos
      double margin = 0;
      if (products.isNotEmpty) {
        double total = 0;
        int count = 0;
        for (final p in products) {
          final buy  = double.tryParse(p['buy_price']?.toString()  ?? '0') ?? 0;
          final sell = double.tryParse(p['sell_price']?.toString() ?? p['price']?.toString() ?? '0') ?? 0;
          if (buy > 0 && sell > 0) {
            total += ((sell - buy) / sell) * 100;
            count++;
          }
        }
        if (count > 0) margin = total / count;
      }

      setState(() {
        _totalValue    = double.tryParse(stats['totalValue'].toString()) ?? 0;
        _totalProducts = stats['totalProducts'] ?? 0;
        _lowStock      = stats['lowStock']      ?? 0;
        _outOfStock    = stats['outOfStock']    ?? 0;
        _avgMargin     = margin;
        _lowStockProducts = lowStock;
        _allProducts      = products;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // Agrupar productos por categoría
  List<Map<String, dynamic>> get _byCategory {
    final Map<String, int> map = {};
    for (final p in _allProducts) {
      final cat = (p['category_name'] ?? p['category'] ?? 'Sin categoría').toString();
      map[cat] = (map[cat] ?? 0) + 1;
    }
    final list = map.entries
        .map((e) => {'name': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return list;
  }

  static const List<Color> _categoryColors = [
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
    if (n.contains('electr'))                                    return Icons.computer_outlined;
    if (n.contains('audio'))                                     return Icons.headphones_outlined;
    if (n.contains('periférico') || n.contains('periferico'))    return Icons.keyboard_outlined;
    if (n.contains('accesorio'))                                 return Icons.backpack_outlined;
    if (n.contains('oficina'))                                   return Icons.assignment_outlined;
    if (n.contains('red') || n.contains('network'))              return Icons.language_outlined;
    if (n.contains('ropa') || n.contains('moda'))                return Icons.checkroom_outlined;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      const Text(
                        'Reportes',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildValueCard(),
                      const SizedBox(height: 12),
                      _buildMovementsCard(),
                      const SizedBox(height: 12),
                      _buildAlertCard(),
                      const SizedBox(height: 12),
                      _buildCategoryCard(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ─── 1. Valor del inventario ───
  Widget _buildValueCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Valor del inventario',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                  Text('Actualizado hoy',
                      style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${_totalValue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.arrow_upward, color: Colors.green, size: 13),
                        SizedBox(width: 2),
                        Text('vs mes anterior',
                            style: TextStyle(fontSize: 11, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Margen promedio',
                      style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                  Text(
                    '${_avgMargin.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 2. Movimientos por día ───
  Widget _buildMovementsCard() {
    final maxVal = _weekMovements.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_up_rounded, color: Colors.green, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Movimientos por día',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                  Text('Últimos 7 días',
                      style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_totalProducts == 0) ...[
            _emptyState(Icons.trending_up_rounded, 'Sin movimientos', 'Los movimientos aparecerán aquí cuando registres productos en el inventario.'),
          ] else ...[
            SizedBox(
              height: 90,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_weekMovements.length, (i) {
                  final ratio = maxVal > 0 ? _weekMovements[i] / maxVal : 0.0;
                  final isMax = _weekMovements[i] == maxVal.toInt();
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 28,
                            height: 70 * ratio,
                            decoration: BoxDecoration(
                              color: isMax
                                  ? AppTheme.primary
                                  : AppTheme.primary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_weekLabels[i],
                          style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                    ],
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 3. Productos en alerta ───
  Widget _buildAlertCard() {
    final alerts = _lowStockProducts;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Productos en alerta',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                  Text('Stock bajo o agotado',
                      style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                ],
              ),
            ],
          ),
          if (_totalProducts == 0) ...[
            const SizedBox(height: 16),
            _emptyState(Icons.warning_amber_rounded, 'Sin productos registrados', 'Las alertas de stock bajo o agotado aparecerán aquí cuando tengas productos.'),
          ] else if (alerts.isEmpty) ...[
            const SizedBox(height: 16),
            _emptyState(Icons.check_circle_outline, 'Todo en orden', 'Ningún producto tiene stock bajo o agotado por el momento.'),
          ] else ...[
            const SizedBox(height: 12),
            ...alerts.map((p) {
              final qty  = p['quantity_in_stock'] ?? p['stock'] ?? 0;
              final name = p['name'] ?? '';
              final sku  = p['sku']  ?? '';
              final isOut = qty == 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, size: 18, color: AppTheme.textGrey),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppTheme.textDark)),
                          Text(sku,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOut
                            ? Colors.red.withOpacity(0.12)
                            : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOut ? 'AGOTADO' : '$qty uds',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOut ? Colors.red : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ─── 4. Por categoría ───
  Widget _buildCategoryCard() {
    final cats = _byCategory;
    final maxCount = cats.isEmpty ? 1 : (cats.first['count'] as int);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.grid_view_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Por categoría',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                  Text('Distribución del inventario',
                      style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                ],
              ),
            ],
          ),
          if (cats.isEmpty) ...[
            const SizedBox(height: 16),
            _emptyState(Icons.grid_view_rounded, 'Sin categorías aún', 'Agrega productos al inventario para ver la distribución por categoría.'),
          ] else ...[
            const SizedBox(height: 16),
            ...cats.asMap().entries.map((entry) {
              final i     = entry.key;
              final cat   = entry.value;
              final name  = cat['name'] as String;
              final count = cat['count'] as int;
              final ratio = maxCount > 0 ? count / maxCount : 0.0;
              final color = _categoryColors[i % _categoryColors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Icon(_iconForCategory(name), size: 18, color: AppTheme.textGrey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textDark)),
                              Text('$count prod.',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppTheme.textGrey)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 4,
                              backgroundColor: Colors.black.withOpacity(0.06),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ─── Estado vacío reutilizable ───
  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.textGrey, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}