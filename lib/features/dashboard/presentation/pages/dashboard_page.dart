import 'package:flutter/material.dart';
import 'package:gb_stock_manager/core/network/api_service.dart';
import 'package:gb_stock_manager/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _apiService = ApiService();

  bool   _loading       = true;
  int    _totalProducts = 0;
  double _totalValue    = 0;
  int    _lowStock      = 0;
  int    _outOfStock    = 0;
  String _userName      = '';
  List<dynamic> _lowStockProducts  = [];
  List<dynamic> _recentProducts    = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final name  = prefs.getString('name')  ?? '';
      _apiService.setToken(token);

      final stats   = await _apiService.getDashboardStats();
      final lowStock = await _apiService.getLowStockProducts();
      final recent   = await _apiService.getRecentProducts();

      setState(() {
        _userName           = name;
        _totalProducts      = stats['totalProducts'];
        _totalValue         = double.parse(stats['totalValue'].toString());
        _lowStock           = stats['lowStock'];
        _outOfStock         = stats['outOfStock'];
        _lowStockProducts   = lowStock;
        _recentProducts     = recent;
        _loading            = false;
      });
    } catch (e) {
      setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bienvenido 👋',
                      style: TextStyle(fontSize: 13, color: AppTheme.textGrey)),
                    Text(_userName,
                      style: const TextStyle(fontSize: 26,
                          fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  ],
                ),
                GestureDetector(
                  onTap: _logout,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.logout_rounded, color: AppTheme.danger, size: 22),
                  ),
                ),
              ],
            ),

            // ─── Stats Grid ───
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _statCard('Productos',  '$_totalProducts', Icons.inventory_2_outlined,   AppTheme.primary),
                _statCard('Valor total','\$$_totalValue',  Icons.attach_money_rounded,   Colors.green),
                _statCard('Stock bajo', '$_lowStock',      Icons.warning_amber_outlined,  Colors.orange),
                _statCard('Sin stock',  '$_outOfStock',    Icons.error_outline,           Colors.red),
              ],
            ),
            const SizedBox(height: 24),

            // ─── Alertas de stock ───
            if (_lowStockProducts.isNotEmpty) ...[
              const Text('⚠️ Alertas de stock',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 12),
              ..._lowStockProducts.map((p) => _alertItem(p)),
              const SizedBox(height: 24),
            ],

            // ─── Productos recientes ───
            const Text('Productos recientes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            ..._recentProducts.map((p) => _productItem(p)),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          Text(label,  style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
        ],
      ),
    );
  }

  Widget _alertItem(dynamic p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                Text('Stock: ${p['quantity_in_stock']} | Categoría: ${p['category_name']}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('${p['quantity_in_stock']}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _productItem(dynamic p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                Text(p['category_name'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
              ],
            ),
          ),
          Text('\$${p['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ],
      ),
    );
  }
}