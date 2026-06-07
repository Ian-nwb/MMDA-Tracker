import 'package:flutter/material.dart';
import 'core/network/api_service.dart';
import 'features/alerts/data/alert_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MMDA Metro Alert Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        // 1. Fixed: Swapped CardTheme with CardThemeData
        cardTheme: const CardThemeData(
          color: Color(0xFF161925),
          elevation: 2,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  
  List<TrafficAlert> _alerts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final freshAlerts = await _apiService.fetchLiveAlerts();
      setState(() {
        _alerts = freshAlerts;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to sync with live traffic feeds. Tap to retry.';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Flooded':
        return Colors.blueAccent;
      case 'Heavy':
        return const Color(0xFFFF4D4D);
      case 'Moderate':
        return const Color(0xFFFF9F43);
      case 'Light':
      default:
        return const Color(0xFF2ED573);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161925),
        title: Row(
          children: [
            const Icon(Icons.traffic_rounded, color: Color(0xFFFF9F43), size: 28),
            const SizedBox(width: 12),
            Text(
              'MMDA LIVE TRACKER',
              style: TextStyle(
                // 2. Fixed: Swapped missing 'FontWeight.black' for 'FontWeight.w900'
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchDashboardData,
            tooltip: 'Refresh Feed',
          ),
          const SizedBox(width: 8),
        ],
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9F43)),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchDashboardData,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF161925)),
                        child: const Text('Retry Connection'),
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDashboardData,
                  color: const Color(0xFFFF9F43),
                  child: _alerts.isEmpty
                      ? const Center(
                          child: Text('No current traffic blockages reported.'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _alerts.length,
                          itemBuilder: (context, index) {
                            final alert = _alerts[index];
                            final statusColor = _getStatusColor(alert.status);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  // 3. Fixed: Used modern .withAlpha for absolute accuracy
                                  color: statusColor.withAlpha(76), // ~30% opacity
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            alert.location,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withAlpha(38), // ~15% opacity
                                            borderRadius: BorderRadius.circular(8),
                                            // 4. Fixed: Used Border.all for the BoxBorder type match
                                            border: Border.all(color: statusColor, width: 1),
                                          ),
                                          child: Text(
                                            alert.status.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              // 5. Fixed: Swapped line 200 .black for .w900
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      alert.message,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFFE2E8F0),
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(color: Colors.white10, height: 1),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              alert.timeAgo,
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white24),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}