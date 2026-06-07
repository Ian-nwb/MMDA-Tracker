import 'package:flutter/foundation.dart'; // Gives us access to debugPrint
import 'package:dio/dio.dart';
import 'package:mmda_tracker/features/alerts/data/alert_model.dart'; 

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://mmda-tracker.vercel.app/api', 
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  Future<List<TrafficAlert>> fetchLiveAlerts() async {
    try {
      final response = await _dio.get('/alerts');
      final List<dynamic> rawDataList = response.data['data'];
      
      return rawDataList.map((jsonItem) => TrafficAlert.fromJson(jsonItem)).toList();
    } catch (e) {
      // Swapped 'print' for 'debugPrint' to clear the linter warning rule cleanly
      debugPrint('❌ Network Fetch Error: $e');
      rethrow;
    }
  }
}