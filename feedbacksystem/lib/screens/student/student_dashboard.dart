import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../widgets/app_drawer.dart';
import '../auth/login_screen.dart';
import '../../widgets/floating_dock.dart';
import '../shared/profile_sheet.dart';
import '../shared/leaderboard_screen.dart';
import 'feedback_form_screen.dart';

class StudentDashboard extends StatefulWidget {
  final String token;
  final String userName;
  final String userRole;
  final String? initialTab;

  const StudentDashboard({
    super.key,
    required this.token,
    required this.userName,
    required this.userRole,
    this.initialTab,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _apiBase = 'https://invertis-feedback-system-0chx.onrender.com/api';

  int _pendingForms = 0;
  int _completedForms = 0;
  int _progressPercent = 0;
  bool _isLoading = true;
  List<dynamic> _activeForms = [];
  Map<String, dynamic> _userData = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    // Real-time polling every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchDashboardData(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDashboardData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      // Fetch Profile Data
      final profileRes = await http.get(
        Uri.parse('$_apiBase/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (profileRes.statusCode == 200) {
        if (mounted) {
          setState(() {
            _userData = jsonDecode(profileRes.body);
          });
        }
      }

      final response = await http.get(
        Uri.parse('$_apiBase/student/courses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        int pending = 0;
        int completed = 0;
        List<dynamic> allForms = [];
        
        if (data is List) {
          for (var course in data) {
            pending += (course['pending_count'] ?? 0) as int;
            completed += (course['completed_count'] ?? 0) as int;
            
            final tlfqs = course['tlfqs'];
            if (tlfqs is List) {
              allForms.addAll(tlfqs);
            }
          }
        }
        
        if (mounted) {
          setState(() {
            _pendingForms = pending;
            _completedForms = completed;
            int total = pending + completed;
            _progressPercent = total > 0 ? ((completed / total) * 100).round() : 0;
            _activeForms = allForms;
            _isLoading = false;
          });
        }
      } else {
        print('--- API DASHBOARD ERROR: ${response.statusCode} ---');
        print(response.body);
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('--- API DASHBOARD EXCEPTION ---');
      print(e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF1A2744);
    final String initial = widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'S';

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        userName: widget.userName,
        userRole: widget.userRole,
        token: widget.token,
        activeDrawerItem: 'Dashboard',
        activeSubItem: 'Dashboard',
        profileImage: _getProfileImage(),
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/campus_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // White Overlay
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(primaryNavy, initial),
                const Divider(height: 1, thickness: 2, color: Colors.red),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _fetchDashboardData(silent: false);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 20),
                            _buildStatsCards(),
                            const SizedBox(height: 24),
                            _buildProgressSection(),
                            const SizedBox(height: 16),
                            _buildFormsSection(),
                            const SizedBox(height: 40),
                            _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          
          // Floating Dock at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: FloatingDock(
              activeIndex: 0,
              middleLabel: 'Leaderboard',
              middleIcon: Icons.emoji_events_rounded,
              onTabTapped: (index) {
                if (index == 0) {
                  // Already on Home
                } else if (index == 1) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LeaderboardScreen(
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
                    builder: (ctx) => ProfileSheet(
                      token: widget.token,
                      onProfileUpdated: _fetchDashboardData,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(Color primaryNavy, String initial) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black87),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
              const SizedBox(width: 12),
              Image.asset(
                'assets/images/invertis_logo.png',
                height: 40,
                errorBuilder: (context, error, stackTrace) =>
                    const Text('INVERTIS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                  onPressed: _logout,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'STUDENT DASHBOARD',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Hey, ${widget.userName} 👋',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Your section's feedback forms for this semester.",
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Column(
      children: [
        _buildStatCard('PENDING', _pendingForms.toString(), Colors.orange.shade700, Icons.access_time),
        const SizedBox(height: 12),
        _buildStatCard('COMPLETED', _completedForms.toString(), const Color(0xFF10B981), Icons.check_circle_outline),
        const SizedBox(height: 12),
        _buildStatCard('PROGRESS', '$_progressPercent%', Colors.blue.shade700, Icons.trending_up),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    int totalForms = _pendingForms + _completedForms;
    if (totalForms == 0 && _activeForms.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Overall Feedback Completion',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF475569),
              ),
            ),
            Text(
              '$_completedForms of $totalForms forms completed',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double percent = totalForms == 0 ? 0 : (_completedForms / totalForms);
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth * percent,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFormsSection() {
    if (_activeForms.isEmpty && !_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          children: [
            const Icon(Icons.school_outlined, size: 40, color: Colors.black54),
            const SizedBox(height: 16),
            const Text(
              'No active feedback forms for your\nsection right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Forms appear here when opened by your HOD.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    // Since the backend already groups by course and we flattened them,
    // let's group them back using course_code/name or subject_code.
    Map<String, List<dynamic>> groupedForms = {};
    for (var form in _activeForms) {
      final code = form['course']?['code']?.toString() ?? form['subject_code']?.toString() ?? 'CS201';
      if (!groupedForms.containsKey(code)) {
        groupedForms[code] = [];
      }
      groupedForms[code]!.add(form);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupedForms.keys.length,
      itemBuilder: (context, index) {
        String code = groupedForms.keys.elementAt(index);
        return _buildSubjectCard(code, groupedForms[code]!);
      },
    );
  }

  Widget _buildSubjectCard(String subjectCode, List<dynamic> forms) {
    // Try to get title from nested course object or fallback
    final String title = forms.isNotEmpty 
        ? (forms.first['course']?['name']?.toString() ?? forms.first['subject_name']?.toString() ?? 'Data Structures') 
        : 'Subject';
    
    int pendingCount = forms.where((f) => f['completed'] != true).length;
    int completedCount = forms.where((f) => f['completed'] == true).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  subjectCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Color(0xFF475569)),
                      const SizedBox(width: 4),
                      Text('$pendingCount', style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 12, color: Color(0xFF475569)),
                      const SizedBox(width: 4),
                      Text('$completedCount', style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ...forms.map((form) => _buildFacultyRow(form)),
        ],
      ),
    );
  }

  Widget _buildFacultyRow(Map<String, dynamic> form) {
    final String faculty = form['faculty_name']?.toString() ?? 'Faculty Name';
    final String type = form['title']?.toString() ?? 'Evaluation';
    final bool isCompleted = form['completed'] == true;

    if (isCompleted) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faculty,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FeedbackFormScreen(
                    tlfqId: form['id'].toString(),
                    token: widget.token,
                    userName: widget.userName,
                    userRole: widget.userRole,
                  ),
                ),
              );
              // If form was submitted successfully, refresh dashboard data
              if (result == true) {
                _fetchDashboardData(silent: false);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faculty,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildFooter() {
    return const Center(
      child: Text(
        '© 2023 Invertis University, Invertis Village, Bareilly-Lucknow\nNational Highway, N.H.-24, Bareilly-243123, Uttar Pradesh.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          color: Colors.black54,
          height: 1.5,
        ),
      ),
    );
  }
}
