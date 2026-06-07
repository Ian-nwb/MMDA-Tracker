import 'package:dio/dio.dart';
import '../../../../features/alerts/data/alert_model.dart';

class ApiService {
  // Configures a reusable network instance mapping to your live Elysia server
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:3000/api', 
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  // Async task execution returning a formatted list matching your model type
  Future<List<TrafficAlert>> fetchLiveAlerts() async {
    try {
      final response = await _dio.get('/alerts');
      
      // Target the 'data' array key coming directly out of your Elysia backend response
      final List<dynamic> rawDataList = response.data['data'];
      
      // Map across the runtime raw JSON entries and pipe them into Dart objects
      return rawDataList.map((jsonItem) => TrafficAlert.fromJson(jsonItem)).toList();
    } catch (e) {
      print('❌ Network Fetch Error: $e');
      rethrow;
    }
  }
}