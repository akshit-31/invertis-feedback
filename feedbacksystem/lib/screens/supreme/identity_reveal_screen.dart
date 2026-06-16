import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/login_screen.dart';
import '../supreme/supreme_dashboard.dart';
import '../superadmin/superadmin_dashboard.dart';
import '../coordinator/coordinator_hub.dart';
import '../superadmin/user_management_screen.dart';
import '../shared/profile_sheet.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/floating_dock.dart';
import '../hod/hod_dashboard.dart';

class IdentityRevealScreen extends StatefulWidget {
  final String token;
  final String userName;
  final String userRole;

  const IdentityRevealScreen({
    super.key,
    required this.token,
    required this.userName,
    required this.userRole,
  });

  @override
  State<IdentityRevealScreen> createState() => _IdentityRevealScreenState();
}

class _IdentityRevealScreenState extends State<IdentityRevealScreen> {
  final String _apiBase =
      'https://invertis-feedback-system-0chx.onrender.com/api';
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _studentData;
  String? _errorMessage;

  Future<void> _logout() async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _searchStudent() async {
    final query = _searchController.text.trim().toUpperCase();
    if (query.isEmpty) {
      setState(() => _errorMessage = 'Please enter an anonymous ID.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _studentData = null;
    });

    try {
      final res = await http.get(
        Uri.parse('$_apiBase/superadmin/reveal?anon_id=$query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          _studentData = jsonDecode(res.body);
        });
      } else if (res.statusCode == 404) {
        setState(
          () => _errorMessage = 'No student found with that Anonymous ID.',
        );
      } else {
        final err = jsonDecode(res.body);
        setState(
          () => _errorMessage = err['message'] ?? 'Failed to reveal identity.',
        );
      }
    } catch (e) {
      setState(
        () => _errorMessage = 'Network error occurred. Please try again.',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryNavy = const Color(0xFF1A2744);
    final textSecondary = Colors.blueGrey.shade600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: AppDrawer(
        token: widget.token,
        userName: widget.userName,
        userRole: widget.userRole,
        activeDrawerItem: 'Identity Reveal',
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        iconTheme: const IconThemeData(color: Color(0xFF1A2744)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/invertis_logo.png',
              width: 140,
              height: 36,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.business, color: Color(0xFF1A2744)),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background photo
          Positioned.fill(
            child: Image.asset(
              'assets/images/campus_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.blueGrey.shade50),
            ),
          ),
          // Gradient Overlay with Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withAlpha(180),
                      Colors.blueGrey.shade50.withAlpha(200),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top red border
                Container(height: 3, color: const Color(0xFFE53935)),

                // Header section
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.fingerprint,
                          color: Color(0xFFEF5350),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Student Identity Reveal',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A2744),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reveal the real identity behind an anonymous student ID',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Search Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(240),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(5),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ENTER ANONYMOUS STUDENT ID',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: textSecondary,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'ANO-XXXXXX',
                                  hintStyle: TextStyle(
                                    color: Colors.blueGrey.shade300,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.tag,
                                    color: Colors.blueGrey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.blueGrey.shade50.withAlpha(
                                    100,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 20,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(
                                      color: Colors.blueGrey.shade100,
                                      width: 1.0,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(
                                      color: Colors.blueGrey.shade100,
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1A2744),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) => _searchStudent(),
                              ),
                              const SizedBox(height: 16),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _searchStudent,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.search,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                  label: Text(
                                    _isLoading ? 'Searching...' : 'Search',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF9A9A),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blueGrey.shade700,
                                    height: 1.4,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text:
                                          'Anonymous IDs are in the format ANO-XXXXXX (e.g. ',
                                    ),
                                    const TextSpan(
                                      text: 'ANO-A3F281',
                                      style: TextStyle(
                                        color: Color(0xFF00BFA5),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          '). Copy the ID from the feedback response or leaderboard.',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Error Message
                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade400,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Result Card
                        if (_studentData != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1DE9B6,
                                        ).withAlpha(30),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF00BFA5),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'IDENTITY REVEALED',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00BFA5),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                _buildDetailRow(
                                  'FULL NAME',
                                  _studentData!['name'] ?? 'N/A',
                                ),
                                const SizedBox(height: 16),
                                _buildDetailRow(
                                  'STUDENT ID',
                                  _studentData!['student_id'] ?? 'N/A',
                                ),
                                const SizedBox(height: 16),
                                _buildDetailRow(
                                  'EMAIL',
                                  _studentData!['email'] ?? 'N/A',
                                ),
                                const SizedBox(height: 16),

                                const Divider(height: 32),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDetailRow(
                                        'SEMESTER',
                                        _studentData!['semester']?.toString() ??
                                            'N/A',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildDetailRow(
                                        'BATCH',
                                        _studentData!['batch'] ?? 'N/A',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Footer
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            '© 2026 Invertis University, Invertis Village, Bareilly-Lucknow National Highway, NH-24, Bareilly-243123, Uttar Pradesh.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.blueGrey.shade400,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating Dock
          FloatingDock(
            activeIndex: -1,
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

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey.shade400,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2744),
          ),
        ),
      ],
    );
  }
}
