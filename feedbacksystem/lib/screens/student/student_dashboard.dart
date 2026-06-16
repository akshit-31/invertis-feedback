import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../widgets/app_drawer.dart';
import '../auth/login_screen.dart';
import '../../widgets/floating_dock.dart';
import '../shared/profile_sheet.dart';
import '../shared/leaderboard_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
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
        Uri.parse('$_apiBase/student/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _pendingForms = data['pending'] ?? 0;
            _completedForms = data['completed'] ?? 0;
            _progressPercent = data['progress'] ?? 0;
            _activeForms = data['forms'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
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
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildStatsCards(),
                          const SizedBox(height: 24),
                          _buildFormsSection(),
                          const SizedBox(height: 40),
                          _buildFooter(),
                        ],
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
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'STUDENT DASHBOARD',
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Your section's feedback forms for this semester.",
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Column(
      children: [
        _buildStatCard('PENDING', _pendingForms.toString(), Colors.orange, Icons.access_time),
        const SizedBox(height: 12),
        _buildStatCard('COMPLETED', _completedForms.toString(), Colors.green, Icons.check_circle_outline),
        const SizedBox(height: 12),
        _buildStatCard('PROGRESS', '$_progressPercent%', Colors.blue, Icons.trending_up),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black54,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: color,
            ),
          ),
        ],
      ),
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activeForms.length,
      itemBuilder: (context, index) {
        final form = _activeForms[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(form['title'] ?? 'Feedback Form'),
            subtitle: Text(form['status'] ?? 'Open'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to form submission
            },
          ),
        );
      },
    );
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
