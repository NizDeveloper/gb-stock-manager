import 'package:dio/dio.dart';
import 'api_config.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  // ─── Agregar token a las peticiones ───
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // ─── Login ───
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email':    email,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de conexión';
    }
  }

  // ─── Productos ───
  Future<List<dynamic>> getProducts() async {
    try {
      final response = await _dio.get('/products');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de conexión';
    }
  }

  // ─── Dashboard ───
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _dio.get('/dashboard/stats');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de conexión';
    }
  }
  // ─── Productos con stock bajo ───
  Future<List<dynamic>> getLowStockProducts() async {
    try {
      final response = await _dio.get('/dashboard/low-stock');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de conexión';
    }
  }

  // ─── Productos recientes ───
  Future<List<dynamic>> getRecentProducts() async {
    try {
      final response = await _dio.get('/dashboard/recent-products');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de conexión';
    }
  }

    // ─── Categorías ───
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de conexión';
    }
  }

  // ─── Crear producto ───
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/products', data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de conexión';
    }
  }

  // ─── Actualizar producto ───
  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/products/$id', data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de conexión';
    }
  }

  // ─── Eliminar producto ───
  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete('/products/$id');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de conexión';
    }
  }
  
  // ─── Crear categoría ───
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/categories', data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de conexión';
    }
  }

  // ─── Actualizar categoría ───
  Future<Map<String, dynamic>> updateCategory(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/categories/$id', data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de conexión';
    }
  }

  // ─── Eliminar categoría ───
  Future<void> deleteCategory(int id) async {
    try {
      await _dio.delete('/categories/$id');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de conexión';
    }
  }

  // ─── Reportes ───
  Future<List<dynamic>> getWeeklyMovements() async {
    try {
      final response = await _dio.get('/reports/weekly-movements');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de conexión';
    }
  }

  Future<List<dynamic>> getMovementsSummary() async {
    try {
      final response = await _dio.get('/reports/movements-summary');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de conexión';
    }
  }

  // ─── Registrar movimiento de stock ───
  Future<Map<String, dynamic>> createStockMovement(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/reports/movements', data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de conexión';
    }
  }

  Future<List<dynamic>> getProductMovements(int productId) async {
    try {
      final response = await _dio.get('/reports/movements/$productId');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de conexión';
    }
  }
}