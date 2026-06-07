import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mmda_tracker/core/network/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MMDA Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Keeps everything a clean dark mode theme
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  // Equivalent to React's useEffect(() => {}, [])
  @override
  void initState() {
    super.initState();
    _loadLiveBackendData();
  }

  void _loadLiveBackendData() async {
    debugPrint('🔄 Connecting to Elysia API engine...');
    try {
      final alerts = await _apiService.fetchLiveAlerts();
      debugPrint('✅ SUCCESS! Fetched ${alerts.length} live incident entries from backend.');
      
      if (alerts.isNotEmpty) {
        debugPrint('📌 First Scraped Incident: [${alerts[0].location}] -> ${alerts[0].message}');
      }
    } catch (error) {
      debugPrint('🚨 Frontend network pipeline broke down: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Check your VS Code Debug Terminal console logs! 📡',
          style: TextStyle(fontSize: 16, letterSpacing: 0.5),
        ),
      ),
    );
  }
}