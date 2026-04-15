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

  double _totalValue    = 0;
  int    _totalProducts = 0;
  int    _lowStock      = 0;
  int    _outOfStock    = 0;

  List<dynamic> _lowStockProducts = [];
  List<dynamic> _allProducts      = [];

  // Movimientos semanales reales
  final List<int> _weekMovements = [0, 0, 0, 0, 0, 0, 0];
  final List<String> _weekLabels = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];

  int _totalEntries = 0;
  int _totalExits   = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiService.setToken(prefs.getString('token') ?? '');

      final results = await Future.wait([
        _apiService.getDashboardStats(),
        _apiService.getLowStockProducts(),
        _apiService.getProducts(),
        _apiService.getWeeklyMovements(),
        _apiService.getMovementsSummary(),
      ]);

      final stats    = results[0] as Map<String, dynamic>;
      final lowStock = results[1] as List<dynamic>;
      final products = results[2] as List<dynamic>;
      final weekly   = results[3] as List<dynamic>;
      final summary  = results[4] as List<dynamic>;

      // Mapear movimientos por día (DAYOFWEEK: 1=Dom, 2=Lun ... 7=Sab)
      final List<int> movements = [0, 0, 0, 0, 0, 0, 0];
      for (final row in weekly) {
        final dayNum = (row['day_num'] as int) - 1; // 0-6
        movements[dayNum] = int.tryParse(row['total'].toString()) ?? 0;
      }

      // Resumen entradas/salidas
      int entries = 0;
      int exits   = 0;
      for (final row in summary) {
        if (row['type'] == 'entry') {
          entries = int.tryParse(row['total_qty'].toString()) ?? 0;
        } else if (row['type'] == 'exit') {
          exits = int.tryParse(row['total_qty'].toString()) ?? 0;
        }
      }

      setState(() {
        _totalValue    = double.tryParse(stats['totalValue'].toString()) ?? 0;
        _totalProducts = stats['totalProducts'] ?? 0;
        _lowStock      = stats['lowStock']      ?? 0;
        _outOfStock    = stats['outOfStock']    ?? 0;
        _lowStockProducts = lowStock;
        _allProducts      = products;
        _weekMovements.setAll(0, movements);
        _totalEntries  = entries;
        _totalExits    = exits;
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
      final cat = (p['category_name'] ?? 'Sin categoría').toString();
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
    if (n.contains('electr'))                                  return Icons.computer_outlined;
    if (n.contains('audio'))                                   return Icons.headphones_outlined;
    if (n.contains('periférico') || n.contains('periferico')) return Icons.keyboard_outlined;
    if (n.contains('accesorio'))                               return Icons.backpack_outlined;
    if (n.contains('oficina'))                                 return Icons.assignment_outlined;
    if (n.contains('red') || n.contains('network'))            return Icons.language_outlined;
    if (n.contains('ropa') || n.contains('moda'))              return Icons.checkroom_outlined;
    if (n.contains('bebida'))                                  return Icons.local_drink_outlined;
    if (n.contains('grano') || n.contains('cereal'))           return Icons.grain_outlined;
    if (n.contains('lácteo') || n.contains('lacteo'))          return Icons.breakfast_dining_outlined;
    if (n.contains('limpieza'))                                return Icons.cleaning_services_outlined;
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
                    const Text('Reportes',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                          color: AppTheme.textDark)),
                    const SizedBox(height: 16),
                    _buildValueCard(),
                    const SizedBox(height: 12),
                    _buildMovementsCard(),
                    const SizedBox(height: 12),
                    _buildMovementsSummaryCard(),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
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
                child: const Icon(Icons.bar_chart_rounded,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Valor del inventario',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15, color: AppTheme.textDark)),
                  Text('Precio × stock de todos los productos',
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
                      '\$${_totalValue.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 32,
                          fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    Text('$_totalProducts productos en inventario',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Sin stock',
                    style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                  Text('$_outOfStock',
                    style: const TextStyle(fontSize: 26,
                        fontWeight: FontWeight.bold, color: Colors.red)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
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
                child: const Icon(Icons.trending_up_rounded,
                    color: Colors.green, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Movimientos por día',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15, color: AppTheme.textDark)),
                  Text('Últimos 7 días (entradas + salidas)',
                    style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (maxVal == 0) ...[
            _emptyState(Icons.trending_up_rounded, 'Sin movimientos',
              'Los movimientos aparecerán aquí cuando registres entradas o salidas.'),
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
                            height: ratio == 0 ? 4 : 70 * ratio,
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
                        style: const TextStyle(fontSize: 11,
                            color: AppTheme.textGrey)),
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

  // ─── 3. Resumen entradas vs salidas ───
  Widget _buildMovementsSummaryCard() {
    final total = _totalEntries + _totalExits;
    final entryRatio = total > 0 ? _totalEntries / total : 0.0;
    final exitRatio  = total > 0 ? _totalExits  / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.swap_vert_rounded,
                    color: Colors.blue, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Entradas vs Salidas',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15, color: AppTheme.textDark)),
                  Text('Total histórico de movimientos',
                    style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (total == 0) ...[
            _emptyState(Icons.swap_vert_rounded, 'Sin movimientos registrados',
              'Ajusta el stock de productos para generar movimientos.'),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _summaryTile('Entradas', _totalEntries,
                      Colors.green, Icons.arrow_downward_rounded, entryRatio),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryTile('Salidas', _totalExits,
                      Colors.red, Icons.arrow_upward_rounded, exitRatio),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryTile(String label, int qty, Color color,
      IconData icon, double ratio) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label,
                style: TextStyle(fontSize: 12, color: color,
                    fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text('$qty uds',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                color: color)),
          const SizedBox(height: 6),
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
    );
  }

  // ─── 4. Productos en alerta ───
  Widget _buildAlertCard() {
    final alerts = _lowStockProducts;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
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
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Productos en alerta',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15, color: AppTheme.textDark)),
                  Text('$_lowStock bajo stock · $_outOfStock agotados',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                ],
              ),
            ],
          ),
          if (_totalProducts == 0) ...[
            const SizedBox(height: 16),
            _emptyState(Icons.warning_amber_rounded, 'Sin productos registrados',
              'Las alertas aparecerán aquí cuando tengas productos en inventario.'),
          ] else if (alerts.isEmpty) ...[
            const SizedBox(height: 16),
            _emptyState(Icons.check_circle_outline, 'Todo en orden',
              'Ningún producto tiene stock bajo o agotado por el momento.'),
          ] else ...[
            const SizedBox(height: 12),
            ...alerts.map((p) {
              final qty    = p['quantity_in_stock'] ?? 0;
              final name   = p['name'] ?? '';
              final code   = p['code'] ?? '';
              final isOut  = qty == 0;
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
                      child: const Icon(Icons.inventory_2_outlined,
                          size: 18, color: AppTheme.textGrey),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                            style: const TextStyle(fontWeight: FontWeight.w600,
                                fontSize: 13, color: AppTheme.textDark)),
                          Text(code,
                            style: const TextStyle(fontSize: 11,
                                color: AppTheme.textGrey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
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

  // ─── 5. Por categoría ───
  Widget _buildCategoryCard() {
    final cats     = _byCategory;
    final maxCount = cats.isEmpty ? 1 : (cats.first['count'] as int);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
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
                child: const Icon(Icons.grid_view_rounded,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Por categoría',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15, color: AppTheme.textDark)),
                  Text('Distribución del inventario',
                    style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                ],
              ),
            ],
          ),
          if (cats.isEmpty) ...[
            const SizedBox(height: 16),
            _emptyState(Icons.grid_view_rounded, 'Sin categorías aún',
              'Agrega productos al inventario para ver la distribución.'),
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
                    Icon(_iconForCategory(name),
                        size: 18, color: AppTheme.textGrey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(name,
                                style: const TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textDark)),
                              Text('$count prod.',
                                style: const TextStyle(fontSize: 11,
                                    color: AppTheme.textGrey)),
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
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                const SizedBox(height: 2),
                Text(subtitle,
                  style: const TextStyle(fontSize: 11,
                      color: AppTheme.textGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}