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
}