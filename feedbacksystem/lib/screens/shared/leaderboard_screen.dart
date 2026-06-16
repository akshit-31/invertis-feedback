import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../widgets/app_drawer.dart';
import '../../widgets/floating_dock.dart';
import '../supreme/supreme_dashboard.dart';
import '../superadmin/superadmin_dashboard.dart';
import '../coordinator/coordinator_hub.dart';
import '../student/student_dashboard.dart';
import '../superadmin/user_management_screen.dart';
import '../shared/profile_sheet.dart';
import '../hod/hod_dashboard.dart';

class LeaderboardScreen extends StatefulWidget {
  final String token;
  final String userName;
  final String userRole;

  const LeaderboardScreen({
    super.key,
    required this.token,
    required this.userName,
    required this.userRole,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final String _apiBase =
      'https://invertis-feedback-system-0chx.onrender.com/api';
  bool _isLoading = true;
  List<dynamic> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final res = await http.get(
        Uri.parse('$_apiBase/student/leaderboard?limit=100'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (res.statusCode == 200) {
        final dynamic data = jsonDecode(res.body);
        List<dynamic> listData = [];
        if (data is List) {
          listData = data;
        } else if (data is Map) {
          if (data['leaderboard'] is List) {
            listData = data['leaderboard'];
          } else if (data['data'] is List)
            listData = data['data'];
          else if (data['students'] is List)
            listData = data['students'];
          else if (data['top_students'] is List)
            listData = data['top_students'];
          else if (data['results'] is List)
            listData = data['results'];
          else {
            _showErrorDialog(
              'Unknown JSON structure. Keys: ${data.keys.join(", ")}',
            );
            return;
          }
        }

        if (mounted) {
          setState(() {
            _leaderboard = listData;
            _isLoading = false;
          });
        }
      } else {
        _showErrorDialog('Failed: ${res.statusCode} Body: ${res.body}');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  void _showErrorDialog(String msg) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug API Error'),
        content: SingleChildScrollView(child: Text(msg)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _useMockData() {
    if (!mounted) return;
    setState(() {
      _leaderboard = [
        {'name': 'BTAI Student 01', 'batch': '2022-26', 'points': 220},
        {'name': 'BCS Student 01', 'batch': '2022-26', 'points': 190},
        {'name': 'BCS Student 02', 'batch': '2022-26', 'points': 180},
        {'name': 'BCS Student 20', 'batch': '2022-26', 'points': 180},
        {'name': 'BTAI Student 16', 'batch': '2022-26', 'points': 180},
        {'name': 'BTAI Student 18', 'batch': '2022-26', 'points': 180},
        {'name': 'BTAI Student 09', 'batch': '2022-26', 'points': 180},
        {'name': 'BCS Student 17', 'batch': '2022-26', 'points': 180},
        {'name': 'BTAI Student 19', 'batch': '2022-26', 'points': 180},
        {'name': 'BTAI Student 05', 'batch': '2022-26', 'points': 180},
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF1A2744);
    const accentRed = Color(0xFFE53935);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AppDrawer(
        token: widget.token,
        userName: widget.userName,
        userRole: widget.userRole,
        activeDrawerItem: 'Leaderboard',
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        iconTheme: const IconThemeData(color: primaryNavy),
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
      body: Stack(
        children: [
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
                  (0.6 * 255).round(),
                ), // Less opaque
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Trophy Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: accentRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentRed.withAlpha((0.4 * 255).round()),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Top Contributors',
                  style: TextStyle(
                    color: primaryNavy,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Earn points by submitting feedback and improving teaching quality.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryNavy.withAlpha((0.7 * 255).round()),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.95 * 255).round()),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryNavy,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _leaderboard.length,
                            separatorBuilder: (context, index) =>
                                Divider(color: Colors.grey.shade200, height: 1),
                            itemBuilder: (context, index) {
                              final student = _leaderboard[index];
                              return _buildLeaderboardItem(student, index + 1);
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          // Floating Dock
          FloatingDock(
            activeIndex: widget.userRole == 'student' ? 1 : -1,
            showUsers: widget.userRole != 'coordinator',
            middleLabel: widget.userRole == 'student' ? 'Leaderboard' : 'Users',
            middleIcon: widget.userRole == 'student' ? Icons.emoji_events_rounded : Icons.group_rounded,
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
                      } else if (widget.userRole == 'student') {
                        return StudentDashboard(
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
                if (widget.userRole != 'student') {
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
                }
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

  Widget _buildLeaderboardItem(Map<String, dynamic> student, int rank) {
    const primaryNavy = Color(0xFF1A2744);
    const accentRed = Color(0xFFE53935);
    final String name = student['name'] ?? student['student_name'] ?? 'Student';
    final String batch = student['batch'] ?? student['department'] ?? '2022-26';

    // Attempt to parse points robustly
    int points = 0;
    final rawPoints =
        student['points'] ?? student['score'] ?? student['total_points'];
    if (rawPoints is int) {
      points = rawPoints;
    } else if (rawPoints is String) {
      points = int.tryParse(rawPoints) ?? 0;
    }

    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.orange;
    } else if (rank == 2) {
      rankColor = Colors.blueGrey;
    } else if (rank == 3) {
      rankColor = Colors.deepOrange;
    } else {
      rankColor = Colors.blueGrey.shade100;
    }

    final bool isTop3 = rank <= 3;
    final Color rankTextColor = isTop3 ? Colors.white : primaryNavy;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: rankColor,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rankTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: primaryNavy,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isTop3) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.workspace_premium_outlined,
                        color: rank == 1
                            ? Colors.orange
                            : (rank == 2 ? Colors.blueGrey : Colors.deepOrange),
                        size: 14,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Participant • Batch: $batch',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: accentRed, size: 12),
                const SizedBox(width: 4),
                Text(
                  '$points',
                  style: const TextStyle(
                    color: accentRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'PTS',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
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
