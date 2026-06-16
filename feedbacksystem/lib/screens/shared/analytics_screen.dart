import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../widgets/app_drawer.dart';
import '../../widgets/floating_dock.dart';
import '../shared/profile_sheet.dart';
import '../supreme/supreme_dashboard.dart';
import '../superadmin/superadmin_dashboard.dart';
import '../coordinator/coordinator_hub.dart';
import '../superadmin/user_management_screen.dart';
import '../hod/hod_dashboard.dart';

class AnalyticsScreen extends StatefulWidget {
  final String token;
  final String userName;
  final String userRole;
  final String initialTab;

  const AnalyticsScreen({
    super.key,
    required this.token,
    this.userName = 'SUPAdmin1',
    this.userRole = 'SUPREME',
    this.initialTab = 'Faculty Rankings',
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final String _apiBase =
      'https://invertis-feedback-system-0chx.onrender.com/api';
  late String _activeSubItem;

  bool _isLoading = false;
  Map<String, dynamic>? _analyticsData;
  Map<String, dynamic> _userData = {};

  String _selectedDepartment = 'All Departments';
  String _selectedInsightsFaculty = 'All Faculty';
  String _selectedRole = 'All'; // All, Faculty, Trainer

  @override
  void initState() {
    super.initState();
    _activeSubItem = widget.initialTab;
    _fetchProfileData();
    _fetchAnalytics();
  }

  Future<void> _fetchProfileData() async {
    try {
      final response = await http.get(Uri.parse('$_apiBase/auth/profile-data'), headers: _headers);
      if (response.statusCode == 200 && mounted) {
        setState(() => _userData = jsonDecode(response.body)['user'] ?? {});
      }
    } catch (_) {}
  }

  ImageProvider<Object>? _getProfileImage() {
    final pic = _userData['profile_pic']?.toString() ?? _userData['profile_photo']?.toString();
    if (pic == null || pic.isEmpty) return null;
    if (pic.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(pic.split(',').last));
      } catch (_) { return null; }
    } else if (pic.startsWith('http')) {
      return NetworkImage(pic);
    }
    return null;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${widget.token}',
  };

  Future<void> _fetchAnalytics() async {
    setState(() => _isLoading = true);
    try {
      String deptQuery = _selectedDepartment == 'All Departments'
          ? ''
          : '?department_id=$_selectedDepartment';
      final res = await http.get(
        Uri.parse('$_apiBase/responses/analytics$deptQuery'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        setState(() {
          _analyticsData = jsonDecode(res.body);
        });
      } else {
        setState(() {
          _analyticsData = null; // No data available
        });
      }
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
      setState(() {
        _analyticsData = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF1A2744);
    const accentRed = Color(0xFFE53935);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: primaryNavy),
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
            style: TextStyle(
              color: primaryNavy,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: accentRed),
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
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ),
        ],
      ),
      drawer: AppDrawer(
        token: widget.token,
        userName: widget.userName,
        userRole: widget.userRole,
        activeDrawerItem: 'Analytics',
        activeSubItem: _activeSubItem,
        profileImage: _getProfileImage(),
      ),
      body: Stack(
        children: [
          // Background photo
          Positioned.fill(
            child: Image.asset(
              'assets/images/campus_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.blueGrey.shade100),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
              child: Container(
                color: Colors.white.withAlpha(
                  (0.4 * 255).round(),
                ), // Lighter Frosted glass
              ),
            ),
          ),

          // Content
          Positioned.fill(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryNavy),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTopCard(primaryNavy),
                            const SizedBox(height: 16),
                            _buildStatCards(),
                            const SizedBox(height: 16),
                            _buildSubTabs(),
                            const SizedBox(height: 16),
                            _buildSubTabContent(),
                            const SizedBox(height: 16),
                            if (_analyticsData == null ||
                                _analyticsData!.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(
                                    (0.95 * 255).round(),
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No analytics data available.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          // Floating Dock
          FloatingDock(
            activeIndex: -1,
            showUsers: widget.userRole != 'coordinator',
            onTabTapped: (index) {
              if (index == 0) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) {
                      if (widget.userRole == 'supreme') {
                        return SupremeDashboard(
                          token: widget.token,
                          userName: widget.userName,
                          userRole: widget.userRole,
                        );
                      } else if (widget.userRole == 'coordinator') {
                        return CoordinatorHub(
                          token: widget.token,
                          userName: widget.userName,
                          userRole: widget.userRole,
                          initialTab: 'Sections',
                        );
                      } else if (widget.userRole.toLowerCase() == 'hod') {
                        return HodDashboard(
                          token: widget.token,
                          userName: widget.userName,
                          userRole: widget.userRole,
                          initialTab: 'Sections',
                        );
                      } else {
                        return SuperadminDashboard(
                          token: widget.token,
                          userName: widget.userName,
                          userRole: widget.userRole,
                        );
                      }
                    },
                  ),
                  (route) => false,
                );
              } else if (index == 1) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserManagementScreen(
                      token: widget.token,
                      userName: widget.userName,
                      userRole: widget.userRole,
                      initialTab: 'Departments',
                    ),
                  ),
                );
              } else if (index == 2) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ProfileSheet(token: widget.token),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopCard(Color primaryNavy) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.95 * 255).round()),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.bar_chart,
                  color: Colors.cyan.shade300,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'System Intelligence',
                  style: TextStyle(
                    color: Color(0xFF1A2744),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Advanced multi-dimensional feedback analytics.',
            style: TextStyle(
              color: primaryNavy.withAlpha((0.7 * 255).round()),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // Department Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(24),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDepartment,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade600,
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'All Departments',
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_alt_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'All Departments',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...(_analyticsData?['deptOverview'] ?? []).map(
                    (d) => DropdownMenuItem<String>(
                      value: d['id'].toString(),
                      child: Text(
                        d['name']?.toString() ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedDepartment = val);
                    _fetchAnalytics();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Segmented Control
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                _buildSegmentButton('All'),
                Container(width: 1, height: 20, color: Colors.grey.shade300),
                _buildSegmentButton('Faculty'),
                Container(width: 1, height: 20, color: Colors.grey.shade300),
                _buildSegmentButton('Trainer'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String role) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedRole = role);
          _fetchAnalytics();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1A2744) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              role,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1A2744),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildSubTabPill('Faculty Rankings', Icons.military_tech_outlined),
          const SizedBox(width: 12),
          _buildSubTabPill('Attribute Analysis', Icons.show_chart),
          const SizedBox(width: 12),
          _buildSubTabPill('Department Overview', Icons.people_outline),
          const SizedBox(width: 12),
          _buildSubTabPill('Submission Trends', Icons.trending_up),
          const SizedBox(width: 12),
          _buildSubTabPill('Course Reports', Icons.menu_book),
          const SizedBox(width: 12),
          _buildSubTabPill('Feedback Insights', Icons.chat_bubble_outline),
        ],
      ),
    );
  }

  Widget _buildSubTabPill(String title, IconData icon) {
    final isActive = _activeSubItem == title;
    return GestureDetector(
      onTap: () => setState(() => _activeSubItem = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1A2744) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isActive ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade700,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabContent() {
    if (_activeSubItem == 'Faculty Rankings') {
      return _buildFacultyRankings();
    } else if (_activeSubItem == 'Attribute Analysis') {
      return _buildAttributeAnalysis();
    } else if (_activeSubItem == 'Department Overview') {
      return _buildDepartmentOverview();
    } else if (_activeSubItem == 'Submission Trends') {
      return _buildSubmissionTrends();
    } else if (_activeSubItem == 'Course Reports') {
      return _buildCourseReports();
    } else if (_activeSubItem == 'Feedback Insights') {
      return _buildFeedbackInsights();
    } else {
      return _buildComingSoonState();
    }
  }

  Widget _buildComingSoonState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.95 * 255).round()),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.construction, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Coming Soon',
              style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionTrends() {
    List<dynamic> timeline = _analyticsData?['timelineData'] ?? [];
    if (timeline.isEmpty) {
      return _buildEmptyState('No submission trends available.');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.95 * 255).round()),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1), // Light red border from screenshot
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: Color(0xFF1A2744)),
              SizedBox(width: 8),
              Text(
                'Submission Volume Trends',
                style: TextStyle(
                  color: Color(0xFF1A2744),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 300,
            width: double.infinity,
            child: CustomPaint(
              painter: LineChartPainter(timeline),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDepartmentOverview() {
    List<dynamic> depts = _analyticsData?['deptOverview'] ?? [];
    if (depts.isEmpty) {
      return _buildEmptyState('No department overview available.');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
        childAspectRatio: 1.4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: depts.length,
      itemBuilder: (context, index) {
        final d = depts[index];
        final bool portalOpen = d['portal_open'] == true;
        final name = d['name']?.toString() ?? 'Unknown';
        final code = d['code']?.toString() ?? '';
        final rating = double.tryParse(d['avg_rating']?.toString() ?? '0') ?? 0.0;
        final facultyCount = d['faculty_count']?.toString() ?? '0';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.95 * 255).round()),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.grid_view, color: Colors.grey.shade700, size: 24),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: portalOpen ? Colors.tealAccent.shade100.withAlpha(100) : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      portalOpen ? 'PORTAL OPEN' : 'PORTAL CLOSED',
                      style: TextStyle(
                        color: portalOpen ? const Color(0xFF10B981) : Colors.red,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF1A2744),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                code,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AVG RATING',
                            style: TextStyle(color: Color(0xFF78909C), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.orange, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                rating > 0 ? rating.toStringAsFixed(2) : '0',
                                style: const TextStyle(
                                  color: Color(0xFF1A2744),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 30, color: Colors.grey.shade200),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FACULTY',
                            style: TextStyle(color: Color(0xFF78909C), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            facultyCount,
                            style: const TextStyle(
                              color: Color(0xFF1A2744),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCourseReports() {
    List<dynamic> courses = _analyticsData?['submissionRates'] ?? [];
    if (courses.isEmpty) {
      return _buildEmptyState('No course reports available.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final c = courses[index];
        final String code = c['course_code']?.toString() ?? 'Unknown';
        final String name = c['course_name']?.toString() ?? 'Unknown Course';
        final int rate = (c['rate'] as num?)?.toInt() ?? 0;
        final String enrolled = c['enrolled']?.toString() ?? '0';
        final String responses = c['submitted']?.toString() ?? '0';

        Color progressColor;
        if (rate >= 70) {
          progressColor = const Color(0xFF10B981); // Emerald
        } else if (rate >= 40) {
          progressColor = const Color(0xFFF59E0B); // Amber
        } else {
          progressColor = const Color(0xFFEF4444); // Red
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.95 * 255).round()),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Text(
                    '$rate%',
                    style: TextStyle(
                      color: progressColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF1A2744),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: rate > 100 ? 1.0 : rate / 100.0,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ENROLLED',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            enrolled,
                            style: const TextStyle(
                              color: Color(0xFF1A2744),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 24, color: Colors.grey.shade300),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RESPONSES',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            responses,
                            style: const TextStyle(
                              color: Color(0xFF1A2744),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedbackInsights() {
    List<dynamic> comments = _analyticsData?['recentComments'] ?? [];
    if (comments.isEmpty) {
      return _buildEmptyState('No feedback insights available.');
    }

    // Extract unique faculty names for filter dropdown
    Set<String> facultySet = {'All Faculty'};
    for (var c in comments) {
      if (c['faculty_name'] != null) {
        facultySet.add(c['faculty_name'].toString());
      }
    }
    List<String> facultyOptions = facultySet.toList();

    // Filter comments
    List<dynamic> filteredComments = comments;
    if (_selectedInsightsFaculty != 'All Faculty') {
      filteredComments = comments.where((c) => c['faculty_name'] == _selectedInsightsFaculty).toList();
    }

    return Column(
      children: [
        // Filter Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.95 * 255).round()),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FEEDBACK INSIGHTS',
                style: TextStyle(
                  color: Color(0xFF1A2744),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'FILTER FEEDBACK NARRATIVE COMMENTS BY INSTRUCTOR',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'FACULTY:',
                    style: TextStyle(
                      color: Color(0xFF1A2744),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedInsightsFaculty,
                          isDense: true,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade700),
                          style: const TextStyle(
                            color: Color(0xFF1A2744),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedInsightsFaculty = newValue;
                              });
                            }
                          },
                          items: facultyOptions.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        if (filteredComments.isEmpty)
          _buildEmptyState('No comments found for selected faculty.')
        else
          // Comments List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredComments.length,
            itemBuilder: (context, index) {
              final c = filteredComments[index];
              final String anonId = c['anonymous_id']?.toString() ?? 'ANONYMOUS';
              final String comment = c['comment']?.toString() ?? '';
              final String facultyName = c['faculty_name']?.toString() ?? 'Unknown Faculty';
              final String courseName = c['course_name']?.toString() ?? 'Unknown Course';
              
              String dateString = 'UNKNOWN DATE';
              if (c['submitted_at'] != null) {
                try {
                  final dt = DateTime.parse(c['submitted_at'].toString());
                  // Simple format like "SUN, MAY 24, 2026"
                  final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
                  final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
                  final dayName = days[dt.weekday - 1];
                  final monthName = months[dt.month - 1];
                  dateString = '$dayName, $monthName ${dt.day}, ${dt.year}';
                } catch (e) {
                  // Ignore parse error
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.95 * 255).round()),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_outline, size: 10, color: Color(0xFF1A2744)),
                              const SizedBox(width: 4),
                              Text(
                                anonId,
                                style: const TextStyle(
                                  color: Color(0xFF1A2744),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chat_bubble_outline, color: Colors.grey.shade300, size: 28),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '"$comment"',
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(height: 1, width: double.infinity, color: Colors.grey.shade200),
                    const SizedBox(height: 16),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xFF1A2744),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: facultyName,
                            style: const TextStyle(
                              color: Color(0xFF3B6EA5),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const TextSpan(text: ' • '),
                          TextSpan(text: courseName),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'SUBMITTED ON $dateString',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFacultyRankings() {
    List<dynamic> facultyList = _analyticsData?['avgRatingPerFaculty'] ?? [];
    
    // Filter by selected role
    if (_selectedRole == 'Faculty') {
      facultyList = facultyList.where((f) => f['teacher_type']?.toString().toLowerCase() == 'college_faculty').toList();
    } else if (_selectedRole == 'Trainer') {
      facultyList = facultyList.where((f) => f['teacher_type']?.toString().toLowerCase() == 'trainer').toList();
    }

    if (facultyList.isEmpty) {
      return _buildEmptyState('No faculty rankings found.');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.95 * 255).round()),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFF1A2744)),
              SizedBox(width: 8),
              Text(
                'Faculty Rankings (out of 10)',
                style: TextStyle(
                  color: Color(0xFF1A2744),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'VIEW: ',
                style: TextStyle(
                  color: Color(0xFF78909C),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text(
                      'All Faculty (Overview)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2744),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Text(
                '💡 ',
                style: TextStyle(fontSize: 12),
              ),
              Expanded(
                child: Text(
                  'Click on any bar below to view that teacher\'s personal rating breakdown.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...facultyList.asMap().entries.map((entry) {
            final int i = entry.key;
            final f = entry.value;
            final name = f['name']?.toString() ?? 'Unknown';
            final rating = double.tryParse(f['avg_rating']?.toString() ?? '0') ?? 0.0;
            final percentage = rating / 10.0;
            
            // Generate a color based on index to match web app pattern
            final colors = [
              const Color(0xFF0F2D52), // Darkest Navy
              const Color(0xFF1D4E89), // Dark Navy
              const Color(0xFF3B6EA5), // Mid Blue
              const Color(0xFF10B981), // Emerald
              const Color(0xFFF59E0B), // Amber
              const Color(0xFFC62828), // Red
            ];
            Color barColor = colors[i % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      name,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF455A64),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: Row(
                      children: [
                        Flexible(
                          flex: (percentage * 100).toInt(),
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 100 - (percentage * 100).toInt(),
                          child: Container(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          // X-Axis
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Container(),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('3', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('6', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('10', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildAttributeAnalysis() {
    List<dynamic> attributes = _analyticsData?['attributeAnalytics'] ?? [];
    if (attributes.isEmpty) {
      return _buildEmptyState('No attribute analysis found.');
    }

    // Prepare data for Radar Chart
    final List<double> values = [];
    final List<String> labels = [];
    for (var a in attributes) {
      final score = double.tryParse(a['score']?.toString() ?? '0') ?? 0.0;
      final name = a['attribute']?.toString() ?? 'Unknown';
      values.add(score / 10.0);
      labels.add(name);
    }

    return Column(
      children: [
        // Radar Chart Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.95 * 255).round()),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.show_chart, color: Color(0xFF1A2744)),
                  SizedBox(width: 8),
                  Text(
                    'Attribute Breakdown',
                    style: TextStyle(
                      color: Color(0xFF1A2744),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: CustomPaint(
                    painter: RadarChartPainter(values, labels),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Individual Attribute Cards
        ...attributes.map((a) {
          final fullText = a['full_text']?.toString() ?? a['attribute']?.toString() ?? 'Unknown';
          final score = double.tryParse(a['score']?.toString() ?? '0') ?? 0.0;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.95 * 255).round()),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    fullText,
                    style: const TextStyle(
                      color: Color(0xFF1A2744),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Flexible(
                        flex: (score * 10).toInt(),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2744),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 100 - (score * 10).toInt(),
                        child: Container(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 32,
                  child: Text(
                    score.toStringAsFixed(2),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF1A2744),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.95 * 255).round()),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    // We can use timeline or overview data for stat cards
    final List<dynamic>? facultyList = _analyticsData?['avgRatingPerFaculty'];
    int totalResponses = 0;
    double sumRating = 0;
    if (facultyList != null && facultyList.isNotEmpty) {
      for (var f in facultyList) {
        totalResponses += (f['total_responses'] as num?)?.toInt() ?? 0;
        sumRating += (f['avg_rating'] as num?)?.toDouble() ?? 0;
      }
      sumRating = sumRating / facultyList.length;
    }

    final activeCourses = _analyticsData?['submissionRates']?.length.toString() ?? '0';
    
    // Get engagement from submissionRates or mock it
    final List<dynamic>? submissionRates = _analyticsData?['submissionRates'];
    int engagementRate = 0;
    if (submissionRates != null && submissionRates.isNotEmpty) {
      int sum = 0;
      for (var s in submissionRates) {
        sum += (s['rate'] as num?)?.toInt() ?? 0;
      }
      engagementRate = sum ~/ submissionRates.length;
    }

    return Column(
      children: [
        _buildStatCard(
          'TOTAL RESPONSES',
          totalResponses.toString(),
          Icons.chat_bubble_outline,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'AVG RATING',
          sumRating.toStringAsFixed(1),
          Icons.star_border,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'ACTIVE COURSES',
          activeCourses,
          Icons.menu_book,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'ENGAGEMENT',
          '$engagementRate%',
          Icons.trending_up,
          Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.95 * 255).round()),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF78909C), // BlueGrey 400
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1A2744),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  RadarChartPainter(this.values, this.labels);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 40;
    final int sides = values.length;
    if (sides < 3) return;

    final paintLine = Paint()
      ..color = Colors.blueGrey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final paintFill = Paint()
      ..color = const Color(0xFF3B6EA5).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final paintStroke = Paint()
      ..color = const Color(0xFF1A2744)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Concentric polygons
    for (int step = 1; step <= 5; step++) {
      final r = radius * (step / 5);
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final angle = (2 * pi / sides) * i - pi / 2;
        final dx = center.dx + r * cos(angle);
        final dy = center.dy + r * sin(angle);
        if (i == 0) {
          path.moveTo(dx, dy);
        } else {
          path.lineTo(dx, dy);
        }
      }
      path.close();
      canvas.drawPath(path, paintLine);
    }

    // Lines from center
    for (int i = 0; i < sides; i++) {
      final angle = (2 * pi / sides) * i - pi / 2;
      final dx = center.dx + radius * cos(angle);
      final dy = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(dx, dy), paintLine);
      
      // Labels
      final labelDx = center.dx + (radius + 20) * cos(angle);
      final labelDy = center.dy + (radius + 20) * sin(angle);
      
      final textPainter = TextPainter(
        text: TextSpan(text: labels[i], style: TextStyle(color: Colors.grey.shade800, fontSize: 9)),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        textAlign: TextAlign.center,
      );
      textPainter.layout(maxWidth: 60);
      textPainter.paint(canvas, Offset(labelDx - textPainter.width / 2, labelDy - textPainter.height / 2));
    }

    // Data polygon
    final dataPath = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (2 * pi / sides) * i - pi / 2;
      final r = radius * values[i];
      final dx = center.dx + r * cos(angle);
      final dy = center.dy + r * sin(angle);
      if (i == 0) {
        dataPath.moveTo(dx, dy);
      } else {
        dataPath.lineTo(dx, dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, paintFill);
    canvas.drawPath(dataPath, paintStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LineChartPainter extends CustomPainter {
  final List<dynamic> data;

  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double width = size.width;
    final double height = size.height;
    const double paddingLeft = 40.0;
    const double paddingBottom = 30.0;
    const double paddingTop = 20.0;
    final double chartWidth = width - paddingLeft;
    final double chartHeight = height - paddingBottom - paddingTop;

    // Determine max Y
    double maxY = 0;
    for (var d in data) {
      final count = double.tryParse(d['count']?.toString() ?? '0') ?? 0;
      if (count > maxY) maxY = count;
    }
    if (maxY == 0) maxY = 10;
    
    // Snap to nearest convenient step
    double stepY = 250;
    if (maxY <= 5) {
      stepY = 1;
    } else if (maxY <= 20) stepY = 5;
    else if (maxY < 50) stepY = 10;
    else if (maxY < 200) stepY = 50;
    else if (maxY < 500) stepY = 100;
    
    int numSteps = (maxY / stepY).ceil();
    if (numSteps < 4) numSteps = 4;
    double maxScale = numSteps * stepY;

    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw horizontal dashed grid lines & Y labels
    for (int i = 0; i <= numSteps; i++) {
      final double yValue = i * stepY;
      final double y = paddingTop + chartHeight - (yValue / maxScale) * chartHeight;
      
      // Dashed line
      double startX = paddingLeft;
      while (startX < width) {
        canvas.drawLine(Offset(startX, y), Offset(startX + 4, y), gridPaint);
        startX += 8;
      }
      
      // Y label
      final textPainter = TextPainter(
        text: TextSpan(
          text: yValue.toInt().toString(),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 8, y - textPainter.height / 2));
    }

    // Points calculation
    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final count = double.tryParse(data[i]['count']?.toString() ?? '0') ?? 0;
      double x;
      if (data.length == 1) {
        x = paddingLeft + chartWidth / 2; // Center the single point
      } else {
        x = paddingLeft + (i / (data.length - 1)) * chartWidth;
      }
      final y = paddingTop + chartHeight - (count / maxScale) * chartHeight;
      points.add(Offset(x, y));
    }

    // Draw line and gradient
    final Path linePath = Path();
    if (points.isNotEmpty) {
      linePath.moveTo(points.first.dx, points.first.dy);
      
      if (points.length == 1) {
        // Draw a horizontal line across the chart for a single data point
        linePath.moveTo(paddingLeft, points.first.dy);
        linePath.lineTo(width, points.first.dy);
      } else if (points.length == 2) {
        // Draw a straight line for 2 points to match Recharts behavior
        linePath.lineTo(points.last.dx, points.last.dy);
      } else {
        // Smooth curve using cubic bezier
        for (int i = 0; i < points.length - 1; i++) {
          final p0 = points[i];
          final p1 = points[i + 1];
          final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
          final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
          linePath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
        }
      }
    }

    // Gradient Fill
    final Path fillPath = Path.from(linePath);
    if (points.isNotEmpty) {
      if (points.length == 1) {
        fillPath.lineTo(width, paddingTop + chartHeight);
        fillPath.lineTo(paddingLeft, paddingTop + chartHeight);
      } else {
        fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
        fillPath.lineTo(points.first.dx, paddingTop + chartHeight);
      }
      fillPath.close();

      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1D4E89).withOpacity(0.4),
            const Color(0xFF1D4E89).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTRB(paddingLeft, paddingTop, width, paddingTop + chartHeight));
      canvas.drawPath(fillPath, gradientPaint);
    }

    // Draw solid line
    final linePaint = Paint()
      ..color = const Color(0xFF1D4E89)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);

    // Draw X labels (First, Middle, Last)
    if (data.isNotEmpty) {
      void drawXLabel(int index, double xPosition) {
        if (index < 0 || index >= data.length) return;
        final date = data[index]['date']?.toString() ?? '';
        final dt = DateTime.tryParse(date);
        String label = date;
        if (dt != null) {
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          label = '${months[dt.month - 1]} ${dt.day}';
        }

        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(xPosition - textPainter.width / 2, paddingTop + chartHeight + 10));
      }
      
      if (data.length == 1) {
        drawXLabel(0, points.first.dx);
      } else if (data.length <= 6) {
        for (int i = 0; i < data.length; i++) {
          drawXLabel(i, points[i].dx);
        }
      } else {
        // Draw 5 evenly spaced labels for large datasets
        int step = (data.length - 1) ~/ 4;
        for (int i = 0; i < data.length; i += step) {
          drawXLabel(i, points[i].dx);
        }
        // Always ensure the last point is drawn
        if ((data.length - 1) % step != 0) {
          drawXLabel(data.length - 1, points.last.dx);
        }
      }
      
      // Draw visible dots on points to ensure it's clear
      final dotPaint = Paint()
        ..color = const Color(0xFF1D4E89)
        ..style = PaintingStyle.fill;
      for (var point in points) {
        canvas.drawCircle(point, 4, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
