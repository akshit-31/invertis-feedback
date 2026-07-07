import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../coordinator/coordinator_hub.dart';
import '../shared/leaderboard_screen.dart';
import '../student/student_dashboard.dart';

class ProfileSheet extends StatefulWidget {
  final String token;
  final VoidCallback? onProfileUpdated;

  const ProfileSheet({
    super.key, 
    required this.token,
    this.onProfileUpdated,
  });

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _stats = {};
  String _accessLevel = '';

  // Password change state
  bool _isChangingPassword = false;
  bool _isSavingPassword = false;
  bool _isUploadingPic = false;
  final _passwordFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://invertis-feedback-system-0chx.onrender.com/api/auth/profile-data',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userData = data['user'] ?? {};
          _stats = data['stats'] ?? {};
          _accessLevel = data['accessLevel'] ?? 'User';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePasswordUpdate() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isSavingPassword = true;
    });

    try {
      final res = await http.put(
        Uri.parse(
          'https://invertis-feedback-system-0chx.onrender.com/api/auth/change-password',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'current_password': _currentPasswordController.text,
          'new_password': _newPasswordController.text,
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: Color(0xFF1A2744),
          ),
        );
        setState(() {
          _isChangingPassword = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      } else {
        final data = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to change password.'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error connecting to backend.'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPassword = false;
        });
      }
    }
  }

  Future<void> _uploadProfilePic() async {
    final String roleStr = (_userData['role'] ?? '').toString().toLowerCase();

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        setState(() => _isUploadingPic = true);

        var request = http.MultipartRequest(
          'POST',
          Uri.parse(
            'https://invertis-feedback-system-0chx.onrender.com/api/auth/profile-photo',
          ),
        );
        request.headers['Authorization'] = 'Bearer ${widget.token}';

        final ext = image.name.split('.').last.toLowerCase();
        final String mimeType = ext == 'png' ? 'png' : (ext == 'webp' ? 'webp' : (ext == 'gif' ? 'gif' : 'jpeg'));

        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            await image.readAsBytes(),
            filename: image.name,
            contentType: MediaType('image', mimeType),
          ),
        );

        var response = await request.send();

        if (response.statusCode == 200 || response.statusCode == 201) {
          final resData = await response.stream.bytesToString();
          final parsed = jsonDecode(resData);

          setState(() {
            _userData['profile_pic'] =
                parsed['profile_photo'] ??
                parsed['profile_pic_url'] ??
                parsed['url'] ??
                parsed['profile_pic'];
          });
          if (widget.onProfileUpdated != null) {
            widget.onProfileUpdated!();
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                backgroundColor: Color(0xFF1A2744),
              ),
            );
          }
        } else {
          final errData = await response.stream.bytesToString();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed (${response.statusCode}): $errData'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPic = false);
      }
    }
  }

  ImageProvider<Object>? _getProfileImage() {
    final pic = _userData['profile_pic']?.toString() ?? _userData['profile_photo']?.toString();
    if (pic == null || pic.isEmpty) return null;
    if (pic.startsWith('data:image')) {
      try {
        final base64String = pic.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        return null;
      }
    } else if (pic.startsWith('http')) {
      return NetworkImage(pic);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF1A2744);
    const textSecondary = Color(0xFF9E9E9E);

    if (_isLoading) {
      return Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryNavy),
          ),
        ),
      );
    }

    final String name = _userData['name'] ?? 'User';
    final String email = _userData['email'] ?? '';
    final String loginId = _userData['student_id'] ?? '';
    final String status = _userData['status'] ?? 'Active';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    final String roleStr = (_userData['role'] ?? '').toString().toLowerCase();
    final bool isSuperAdmin =
        _accessLevel.toLowerCase().contains('super admin') ||
        roleStr.contains('super_admin') ||
        roleStr.contains('superadmin');
    final bool isSupreme =
        _accessLevel.toLowerCase().contains('supreme') ||
        roleStr.contains('supreme');
    final bool isStudent = roleStr == 'student';

    final Color themeColor = isStudent 
        ? const Color(0xFF00A3C4) 
        : (isSuperAdmin ? const Color(0xFF0066FF) : (isSupreme ? Colors.orange : primaryNavy));
    final String roleBadgeText = isStudent 
        ? 'STUDENT' 
        : (isSuperAdmin ? 'SUPER ADMIN' : (isSupreme ? 'SUPREME AUTHORITY' : _accessLevel.toUpperCase()));

    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
        top: MediaQuery.of(context).padding.top + 24.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.school_outlined, color: primaryNavy, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'My Profile',
                        style: TextStyle(
                          color: primaryNavy,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blueGrey.shade50,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: primaryNavy,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Area
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Orange Cover & Avatar
                    SizedBox(
                      height: 150,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 110,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: themeColor,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: primaryNavy,
                                  backgroundImage: _getProfileImage(),
                                  child: _getProfileImage() == null
                                      ? Text(
                                          initial,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.white,
                                  child: _isUploadingPic
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.orange,
                                                ),
                                          ),
                                        )
                                      : GestureDetector(
                                            onTap: _uploadProfilePic,
                                            child: CircleAvatar(
                                              radius: 14,
                                              backgroundColor: themeColor,
                                              child: const Icon(
                                                Icons.camera_alt_outlined,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                    // Name & Badges
                    Text(
                      name,
                      style: const TextStyle(
                        color: primaryNavy,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: themeColor.withOpacity(0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isStudent 
                                      ? Icons.school_outlined 
                                      : (isSupreme
                                          ? Icons.workspace_premium_outlined
                                          : Icons.admin_panel_settings_outlined),
                                  color: themeColor,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    roleBadgeText,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: themeColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ID: $loginId',
                            style: TextStyle(
                              color: primaryNavy,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Account Information Card
                    _sectionHeader('ACCOUNT INFORMATION'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _infoRow(Icons.tag_rounded, 'LOGIN ID', loginId),
                            const Divider(height: 1),
                            _infoRow(
                              Icons.email_outlined,
                              'EMAIL ADDRESS',
                              email,
                            ),
                            const Divider(height: 1),
                            _infoRow(
                              Icons.apartment_rounded,
                              'DEPARTMENT',
                              _userData['department'] ?? _stats['department'] ?? '—',
                            ),
                            const Divider(height: 1),
                            _statusRow(
                              Icons.school_outlined,
                              'ACCOUNT STATUS',
                              status,
                            ),
                            if (isStudent) ...[
                              const Divider(height: 1),
                              _infoRow(
                                Icons.calendar_today_outlined,
                                'BATCH',
                                _userData['batch'] ?? _stats['batch'] ?? '2022-26',
                              ),
                              const Divider(height: 1),
                              _infoRow(
                                Icons.menu_book_outlined,
                                'SEMESTER',
                                _userData['semester']?.toString() ?? _stats['semester']?.toString() ?? '3',
                              ),
                              const Divider(height: 1),
                              _infoRow(
                                Icons.public_outlined,
                                'ANONYMOUS ID',
                                _userData['anonymous_id'] ?? 'ANO-E1E957',
                              ),
                              const Divider(height: 1),
                              _infoRow(
                                Icons.emoji_events_outlined,
                                'POINTS',
                                _userData['points']?.toString() ?? _stats['points']?.toString() ?? '190',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Management Overview Grid
                    _sectionHeader('MANAGEMENT OVERVIEW'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: isStudent
                          ? Column(
                              children: [
                                Row(
                                  children: [
                                    _studentMetricCard(Icons.check, '${_stats['forms_submitted'] ?? 13}', 'FORMS SUBMITTED'),
                                    const SizedBox(width: 12),
                                    _studentMetricCard(Icons.tag_rounded, '${_stats['enrollments'] ?? 2}', 'ENROLLMENTS'),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _studentMetricCard(Icons.emoji_events_outlined, '${_userData['points']?.toString() ?? _stats['points']?.toString() ?? '190'}', 'POINTS'),
                                  ],
                                ),
                              ],
                            )
                          : GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.2,
                              children: [
                                _metricCard(
                                  Icons.layers_outlined,
                                  '${_stats['sections'] ?? 0}',
                                  'SECTIONS',
                                ),
                                _metricCard(
                                  Icons.book_outlined,
                                  '${_stats['courses'] ?? 0}',
                                  'COURSES',
                                ),
                                _metricCard(
                                  Icons.people_outline,
                                  '${_stats['faculty'] ?? 0}',
                                  'FACULTY',
                                ),
                                _metricCard(
                                  Icons.school_outlined,
                                  '${_stats['students'] ?? 0}',
                                  'STUDENTS',
                                ),
                                _metricCard(
                                  Icons.link,
                                  '${_stats['assignments'] ?? 0}',
                                  'ASSIGNMENTS',
                                ),
                                _statusMetricCard(
                                  Icons.flash_on_rounded,
                                  _stats['systemStatus'] ?? 'Online',
                                  'SYSTEM STATUS',
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Access & Permissions
                    _sectionHeader('ACCESS & PERMISSIONS'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.deepPurple.shade50,
                              child: const Icon(
                                Icons.shield_outlined,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ACCESS LEVEL',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isStudent ? 'Student — Feedback Submission & Leaderboard' : _accessLevel,
                                    style: const TextStyle(
                                      color: primaryNavy,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _sectionHeader('QUICK ACTIONS'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          if (isStudent) ...[
                            _actionCard(
                              Icons.dashboard_customize_outlined,
                              'My Dashboard',
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => StudentDashboard(
                                      token: widget.token,
                                      userName: _userData['name'] ?? 'User',
                                      userRole: _userData['role'] ?? 'user',
                                      initialTab: 'Dashboard',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            _actionCard(
                              Icons.emoji_events_outlined,
                              'View Leaderboard',
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => LeaderboardScreen(
                                      token: widget.token,
                                      userName: _userData['name'] ?? 'User',
                                      userRole: _userData['role'] ?? 'user',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                          if (!isStudent) ...[
                            _actionCard(
                              Icons.layers_outlined,
                              'Manage Sections & Faculty',
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CoordinatorHub(
                                      token: widget.token,
                                      userName: _userData['name'] ?? 'User',
                                      userRole: _userData['role'] ?? 'user',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            _actionCard(
                              Icons.people_outline,
                              'Manage Students',
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CoordinatorHub(
                                      token: widget.token,
                                      userName: _userData['name'] ?? 'User',
                                      userRole: _userData['role'] ?? 'user',
                                      initialTab: 'Students',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            _actionCard(
                              Icons.emoji_events_outlined,
                              'View Leaderboard',
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => LeaderboardScreen(
                                      token: widget.token,
                                      userName: _userData['name'] ?? 'User',
                                      userRole: _userData['role'] ?? 'user',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Security section
                    _sectionHeader('SECURITY'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _isChangingPassword
                          ? _buildInlineChangePasswordForm()
                          : SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isChangingPassword = true;
                                  });
                                },
                                icon: const Icon(
                                  Icons.vpn_key_outlined,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Change Password',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryNavy,
                                  side: const BorderSide(
                                    color: Colors.grey,
                                    width: 1.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade200, endIndent: 8)),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade200, indent: 8)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade50,
            child: Icon(icon, color: const Color(0xFF1A2744), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1A2744),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(IconData icon, String label, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade50,
            child: Icon(icon, color: const Color(0xFF1A2744), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        color: _userData['role'] == 'student'
                            ? Colors.orange
                            : const Color(0xFF4CAF50),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(IconData icon, String val, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade50,
            child: Icon(icon, color: const Color(0xFF1A2744), size: 16),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                val,
                style: const TextStyle(
                  color: Color(0xFF1A2744),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusMetricCard(IconData icon, String val, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade50,
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 16),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    val,
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard(IconData icon, String actionText, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE8F5E9),
              child: Icon(icon, color: const Color(0xFF4CAF50), size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                actionText,
                style: const TextStyle(
                  color: Color(0xFF1A2744),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineChangePasswordForm() {
    const primaryNavy = Color(0xFF1A2744);
    const textSecondary = Color(0xFF9E9E9E);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CHANGE PASSWORD',
                  style: TextStyle(
                    color: primaryNavy,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isChangingPassword = false;
                      _currentPasswordController.clear();
                      _newPasswordController.clear();
                      _confirmPasswordController.clear();
                    });
                  },
                  child: const Icon(
                    Icons.close,
                    color: textSecondary,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current Password
            const Text(
              'CURRENT PASSWORD',
              style: TextStyle(
                color: textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                style: const TextStyle(
                  color: primaryNavy,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                    child: Icon(
                      _obscureCurrent
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: textSecondary,
                      size: 16,
                    ),
                  ),
                ),
                validator: (v) => v!.isEmpty ? '*' : null,
              ),
            ),
            const SizedBox(height: 12),

            // New Password
            const Text(
              'NEW PASSWORD',
              style: TextStyle(
                color: textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                style: const TextStyle(
                  color: primaryNavy,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscureNew = !_obscureNew),
                    child: Icon(
                      _obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: textSecondary,
                      size: 16,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v!.isEmpty) return '*';
                  if (v.length < 8) return 'Min 8 chars';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),

            // Confirm New Password
            const Text(
              'CONFIRM NEW PASSWORD',
              style: TextStyle(
                color: textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                style: const TextStyle(
                  color: primaryNavy,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                validator: (v) {
                  if (v != _newPasswordController.text) return 'Mismatched';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Update Button
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: _isSavingPassword ? null : _handlePasswordUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: _isSavingPassword
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Update Password',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentMetricCard(IconData icon, String val, String title) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey.shade50,
              child: Icon(icon, color: Colors.grey.shade600, size: 14),
            ),
            const SizedBox(height: 8),
            Text(
              val,
              style: const TextStyle(
                color: Color(0xFF1A2744),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 7,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
