import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/login_screen.dart';
import '../shared/profile_sheet.dart';
import '../coordinator/coordinator_hub.dart';
import '../superadmin/user_management_screen.dart';
import '../shared/analytics_screen.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/floating_dock.dart';

class SuperadminDashboard extends StatefulWidget {
  final String token;
  final String userName;
  final String userRole;

  const SuperadminDashboard({
    super.key,
    required this.token,
    required this.userName,
    required this.userRole,
  });

  @override
  State<SuperadminDashboard> createState() => _SuperadminDashboardState();
}

class _SuperadminDashboardState extends State<SuperadminDashboard> {
  bool _isLoadingStats = false;
  final Map<String, dynamic> _stats = {};
  final String _activeDrawerItem = 'Dashboard';

  int _totalDepartments = 0;
  String _facultyEvaluated = '0';
  String _currentSession = 'Unknown';
  String _lastPromotion = 'No history yet';

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

      // 1. Fetch Overview (for faculty count / responses)
      final resOverview = http.get(
        Uri.parse(
          'https://invertis-feedback-system-0chx.onrender.com/api/analytics/overview',
        ),
        headers: headers,
      );

      // 2. Fetch Departments
      final resDepts = http.get(
        Uri.parse(
          'https://invertis-feedback-system-0chx.onrender.com/api/coordinator/departments',
        ),
        headers: headers,
      );

      // 3. Fetch Promotion Overview
      final resPromo = http.get(
        Uri.parse(
          'https://invertis-feedback-system-0chx.onrender.com/api/superadmin/promotion/overview',
        ),
        headers: headers,
      );

      final results = await Future.wait([resOverview, resDepts, resPromo]);

      if (!mounted) return;

      setState(() {
        // Parse Overview
        if (results[0].statusCode == 200) {
          final data = jsonDecode(results[0].body);
          _facultyEvaluated = (data['total_users'] ?? data['faculty'] ?? 84)
              .toString();
        } else {
          _facultyEvaluated = '84'; // Mock or fallback
        }

        // Parse Departments
        if (results[1].statusCode == 200) {
          final List<dynamic> depts = jsonDecode(results[1].body);
          _totalDepartments = depts.length;
        } else {
          _totalDepartments = 7;
        }

        // Parse Promotion
        if (results[2].statusCode == 200) {
          final promoData = jsonDecode(results[2].body);
          _currentSession = promoData['active_session'] ?? '2025-26';
          final List<dynamic> logs = promoData['recent_logs'] ?? [];
          if (logs.isNotEmpty) {
            _lastPromotion =
                logs.first['timestamp']?.toString().split('T')[0] ?? 'Recently';
          }
        } else {
          _currentSession = '2025-26';
        }
      });
    } catch (e) {
      print('Superadmin fetch error: $e');
      if (!mounted) return;
      setState(() {
        _totalDepartments = 7;
        _facultyEvaluated = '84';
        _currentSession = '2025-26';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF1A2744);
    const accentRed = Color(0xFFE53935);
    const textSecondary = Color(0xFF9E9E9E);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu, color: primaryNavy, size: 18),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Image.asset(
          'assets/images/invertis_logo.png',
          width: 140,
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Text(
            'INVERTIS UNIVERSITY',
            style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: Colors.red),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: _handleLogout,
            ),
          ),
        ],
      ),
      drawer: AppDrawer(
        token: widget.token,
        userName: widget.userName,
        userRole: widget.userRole,
        activeDrawerItem: _activeDrawerItem,
        activeSubItem: '',
      ),
      body: Stack(
        children: [
          // Background Campus Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/campus_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.blueGrey.shade100),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.4)),
          ),
          // Main Content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header (Control Tower)
                        const Row(
                          children: [
                            Icon(Icons.circle, color: accentRed, size: 10),
                            SizedBox(width: 8),
                            Text(
                              'SUPER ADMIN',
                              style: TextStyle(
                                color: accentRed,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Control Tower',
                          style: TextStyle(
                            color: primaryNavy,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'University-wide system overview and management.',
                          style: TextStyle(color: textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 32),

                        // Stats List
                        _isLoadingStats
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: primaryNavy,
                                ),
                              )
                            : Column(
                                children: [
                                  _buildFullWidthStatCard(
                                    'DEPARTMENTS',
                                    _totalDepartments.toString(),
                                    Icons.domain,
                                    Colors.blue,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFullWidthStatCard(
                                    'FACULTY EVALUATED',
                                    _facultyEvaluated,
                                    Icons.school_outlined,
                                    Colors.blue,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFullWidthStatCard(
                                    'CURRENT SESSION',
                                    _currentSession,
                                    Icons.arrow_circle_up_outlined,
                                    Colors.blue,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFullWidthStatCard(
                                    'LAST PROMOTION',
                                    _lastPromotion,
                                    Icons.timeline,
                                    Colors.blue,
                                  ),
                                ],
                              ),

                        const SizedBox(height: 32),
                        // Quick Actions
                        const Text(
                          'QUICK ACTIONS',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildQuickAction(
                          'User Management',
                          'Create HODs & coordinators',
                          Icons.shield_outlined,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserManagementScreen(
                                token: widget.token,
                                userName: widget.userName,
                                userRole: widget.userRole,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildQuickAction(
                          'Coordinator Panel',
                          'Sections, courses, faculty',
                          Icons.layers_outlined,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CoordinatorHub(
                                token: widget.token,
                                userName: widget.userName,
                                userRole: widget.userRole,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildQuickAction(
                          'Analytics',
                          'View detailed feedback analytics',
                          Icons.bar_chart,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnalyticsScreen(
                                token: widget.token,
                                userName: widget.userName,
                                userRole: widget.userRole,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 120), // Padding for dock
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // The Dock at the very top (bottom of screen visually)
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: FloatingDock(
              activeIndex: 0,
              onTabTapped: (index) {
                if (index == 0) {
                  // Already on Home
                } else if (index == 1) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserManagementScreen(
                        token: widget.token,
                        userName: widget.userName,
                        userRole: widget.userRole,
                      ),
                    ),
                  );
                } else if (index == 2) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => ProfileSheet(token: widget.token),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1A2744),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blue.shade700, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1A2744),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.arrow_forward,
              color: Colors.blueGrey.shade300,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
