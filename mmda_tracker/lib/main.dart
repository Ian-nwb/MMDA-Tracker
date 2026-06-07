import 'dart:ui';
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
        scaffoldBackgroundColor: const Color(0xFF0B0C10),
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
  String _selectedFilter = 'all';

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
    switch (status.toLowerCase()) {
      case 'flooded':
        return const Color(0xFF00E5FF);
      case 'heavy':
        return const Color(0xFFFF3366);
      case 'moderate':
        return const Color(0xFFFF9F43);
      case 'light':
      default:
        return const Color(0xFF00FF87);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'flooded':
        return Icons.tsunami_rounded;
      case 'heavy':
        return Icons.warning_amber_rounded;
      case 'moderate':
        return Icons.report_problem_rounded;
      case 'light':
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const PulsingDot(),
                  const SizedBox(width: 12),
                  const Text(
                    'MMDA LIVE TRACKER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              RotatingRefreshButton(
                isLoading: _isLoading,
                onPressed: _fetchDashboardData,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String count, Color color, IconData icon, String filterKey) {
    final isSelected = _selectedFilter == filterKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.15),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withValues(alpha: 0.25) : Colors.transparent,
              blurRadius: isSelected ? 8 : 0,
              spreadRadius: isSelected ? 1 : 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : color.withValues(alpha: 0.7),
              size: 14,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count,
                style: TextStyle(
                  color: isSelected ? Colors.white : color.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSummary() {
    final totalCount = _alerts.length;
    final floodedCount = _alerts.where((a) => a.status.toLowerCase() == 'flooded').length;
    final heavyCount = _alerts.where((a) => a.status.toLowerCase() == 'heavy').length;
    final moderateCount = _alerts.where((a) => a.status.toLowerCase() == 'moderate').length;
    final lightCount = _alerts.where((a) => a.status.toLowerCase() == 'light').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            _buildStatPill('ALL', totalCount.toString(), Colors.white, Icons.dashboard_rounded, 'all'),
            const SizedBox(width: 8),
            _buildStatPill('FLOODED', floodedCount.toString(), const Color(0xFF00E5FF), Icons.tsunami_rounded, 'flooded'),
            const SizedBox(width: 8),
            _buildStatPill('HEAVY', heavyCount.toString(), const Color(0xFFFF3366), Icons.warning_amber_rounded, 'heavy'),
            const SizedBox(width: 8),
            _buildStatPill('MODERATE', moderateCount.toString(), const Color(0xFFFF9F43), Icons.report_problem_rounded, 'moderate'),
            const SizedBox(width: 8),
            _buildStatPill('LIGHT', lightCount.toString(), const Color(0xFF00FF87), Icons.check_circle_outline_rounded, 'light'),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF87)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Syncing with Live Feeds...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF3366).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: Color(0xFFFF3366),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Connection Error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchDashboardData,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3366).withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    side: BorderSide(
                      color: const Color(0xFFFF3366).withValues(alpha: 0.4),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 48,
                  color: Color(0xFF00FF87),
                ),
                const SizedBox(height: 16),
                const Text(
                  'All Clear',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No traffic incidents or blockages reported at this time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchDashboardData,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Check Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    foregroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_list_off_rounded,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Results',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No traffic incidents match the "${_selectedFilter.toUpperCase()}" filter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedFilter = 'all';
                    });
                  },
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  label: const Text('Reset Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    foregroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(TrafficAlert alert, int index) {
    final statusColor = _getStatusColor(alert.status);
    final statusIcon = _getStatusIcon(alert.status);

    return StaggeredEntranceAlertTile(
      index: index,
      id: alert.id,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.04),
                    Colors.white.withValues(alpha: 0.01),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.18),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: statusColor, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                alert.status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      alert.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFCBD5E1),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.01),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                            const SizedBox(width: 6),
                            Text(
                              alert.timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAlerts = _selectedFilter == 'all'
        ? _alerts
        : _alerts.where((a) => a.status.toLowerCase() == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B0C10),
              Color(0xFF1F2833),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildAnalyticsSummary(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingState()
                        : _errorMessage != null
                            ? _buildErrorState()
                            : _alerts.isEmpty
                                ? _buildEmptyState()
                                : filteredAlerts.isEmpty
                                    ? _buildFilteredEmptyState()
                                    : RefreshIndicator(
                                        onRefresh: _fetchDashboardData,
                                        color: const Color(0xFF00FF87),
                                        backgroundColor: const Color(0xFF0B0C10),
                                        child: ListView.builder(
                                          physics: const AlwaysScrollableScrollPhysics(
                                            parent: BouncingScrollPhysics(),
                                          ),
                                          padding: const EdgeInsets.only(bottom: 32),
                                          itemCount: filteredAlerts.length,
                                          itemBuilder: (context, index) {
                                            return _buildAlertCard(filteredAlerts[index], index);
                                          },
                                        ),
                                      ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00FF87),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FF87).withValues(alpha: 0.6 * _animation.value),
                blurRadius: 8 * _animation.value,
                spreadRadius: 2 * _animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class RotatingRefreshButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const RotatingRefreshButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<RotatingRefreshButton> createState() => _RotatingRefreshButtonState();
}

class _RotatingRefreshButtonState extends State<RotatingRefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RotatingRefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: IconButton(
        icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
        onPressed: widget.isLoading ? null : widget.onPressed,
        tooltip: 'Refresh Feed',
      ),
    );
  }
}

class StaggeredEntranceAlertTile extends StatelessWidget {
  final Widget child;
  final int index;
  final String id;

  const StaggeredEntranceAlertTile({
    super.key,
    required this.child,
    required this.index,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(id),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 80).clamp(0, 400)),
      curve: Curves.easeOutQuint,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}