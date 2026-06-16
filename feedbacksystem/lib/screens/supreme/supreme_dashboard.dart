import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/login_screen.dart';
import '../shared/profile_sheet.dart';
import '../superadmin/user_management_screen.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/floating_dock.dart';

class SupremeDashboard extends StatefulWidget {
  final String token;
  final String userName;
  final String userRole;

  const SupremeDashboard({
    super.key,
    required this.token,
    required this.userName,
    required this.userRole,
  });

  @override
  State<SupremeDashboard> createState() => _SupremeDashboardState();
}

class _SupremeDashboardState extends State<SupremeDashboard> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _loginIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<dynamic> _superAdmins = [];
  bool _isLoadingList = false;
  bool _isCreating = false;
  final String _activeDrawerItem = 'Supreme Panel';
  final String _activeSubItem = 'Departments';

  @override
  void initState() {
    super.initState();
    _fetchSuperAdmins();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuperAdmins() async {
    setState(() {
      _isLoadingList = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://invertis-feedback-system-0chx.onrender.com/api/superadmin/staff',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> allStaff = jsonDecode(response.body);
        setState(() {
          // Filter to only display Super Admin accounts
          _superAdmins = allStaff
              .where((s) => s['role'] == 'super_admin')
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load Super Admins list.'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error connecting to backend server.'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingList = false;
        });
      }
    }
  }

  Future<void> _handleCreateSuperAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    final primaryNavy = const Color(0xFF1A2744);
    const accentRed = Color(0xFFE53935);

    try {
      final response = await http.post(
        Uri.parse(
          'https://invertis-feedback-system-0chx.onrender.com/api/superadmin/superadmins',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'login_id': _loginIdController.text.trim().toUpperCase(),
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Super Admin account created successfully!'),
            backgroundColor: Color(0xFF1A2744),
          ),
        );
        _nameController.clear();
        _emailController.clear();
        _loginIdController.clear();
        _passwordController.clear();
        // Refresh the list
        _fetchSuperAdmins();
      } else {
        final message =
            data['message'] ?? 'Failed to create Super Admin account.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: accentRed),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Failed to create account.'),
          backgroundColor: accentRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _handleDeleteSuperAdmin(String id, String name) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete Super Admin "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    const primaryNavy = Color(0xFF1A2744);
    const accentRed = Color(0xFFE53935);

    try {
      final response = await http.delete(
        Uri.parse(
          'https://invertis-feedback-system-0chx.onrender.com/api/superadmin/users/$id',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Super Admin account deleted.'),
            backgroundColor: primaryNavy,
          ),
        );
        _fetchSuperAdmins();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete Super Admin.'),
            backgroundColor: accentRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Failed to delete account.'),
          backgroundColor: accentRed,
        ),
      );
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

    final String initial = widget.userName.isNotEmpty
        ? widget.userName[0].toUpperCase()
        : 'S';

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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                  padding: EdgeInsets.zero,
                  onPressed: _handleLogout,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(
        token: widget.token,
        userName: widget.userName,
        userRole: widget.userRole,
        activeDrawerItem: _activeDrawerItem,
        activeSubItem: _activeSubItem,
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
            child: Container(color: Colors.white.withOpacity(0.4)),
          ),

          // Scrollable layout
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 20.0,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- PANEL TITLE HEADER ---
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.95 * 255).round()),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(
                                  (0.08 * 255).round(),
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(
                                  0xFFFFF9C4,
                                ), // circular background
                                radius: 20,
                                child: Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Color(0xFFFBC02D),
                                ), // Crown Icon
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Supreme Authority Panel',
                                      style: TextStyle(
                                        color: primaryNavy,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Only Supreme Accounts can access this panel.',
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- CREATE ACCOUNT CARD ---
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accentRed, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(
                                  (0.1 * 255).round(),
                                ),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.add, color: accentRed, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Create New Super Admin Account',
                                      style: TextStyle(
                                        color: primaryNavy,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Super Admins can manage HODs, Coordinators, view all analytics, and assign teaching staff.',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // FULL NAME
                                const Text(
                                  'FULL NAME',
                                  style: TextStyle(
                                    color: primaryNavy,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _nameController,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: _inputDecoration(
                                    'Dr. Vikram Chandra',
                                  ),
                                  validator: (value) => value!.isEmpty
                                      ? 'Full Name is required'
                                      : null,
                                ),
                                const SizedBox(height: 12),

                                // EMAIL ADDRESS
                                const Text(
                                  'EMAIL ADDRESS',
                                  style: TextStyle(
                                    color: primaryNavy,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(fontSize: 13),
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _inputDecoration(
                                    'admin@invertis.edu.in',
                                  ),
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // LOGIN ID
                                const Text(
                                  'LOGIN ID',
                                  style: TextStyle(
                                    color: primaryNavy,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _loginIdController,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: _inputDecoration(
                                    'e.g. SUPADMIN1',
                                  ),
                                  validator: (value) => value!.isEmpty
                                      ? 'Login ID is required'
                                      : null,
                                ),
                                const SizedBox(height: 12),

                                // PASSWORD
                                const Text(
                                  'PASSWORD',
                                  style: TextStyle(
                                    color: primaryNavy,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _passwordController,
                                  style: const TextStyle(fontSize: 13),
                                  obscureText: true,
                                  decoration: _inputDecoration('••••••••'),
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (value.length < 8) {
                                      return 'Password must be at least 8 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // SUBMIT BUTTON
                                SizedBox(
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: _isCreating
                                        ? null
                                        : _handleCreateSuperAdmin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryNavy,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: _isCreating
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .check_circle_outline_rounded,
                                                size: 16,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Create Super Admin',
                                                style: TextStyle(
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
                        ),
                        const SizedBox(height: 24),

                        // --- EXISTING ACCOUNTS LIST ---
                        Row(
                          children: [
                            const Icon(
                              Icons.people_alt_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Existing Super Admins',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: primaryNavy,
                              radius: 10,
                              child: Text(
                                '${_superAdmins.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Accounts List
                        _isLoadingList
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.0),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : _superAdmins.isEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20.0,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'No Super Admin accounts found.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _superAdmins.length,
                                itemBuilder: (context, index) {
                                  final admin = _superAdmins[index];
                                  final String name =
                                      admin['name'] ?? 'Super Admin';
                                  final String email = admin['email'] ?? '';
                                  final String loginId =
                                      admin['student_id'] ?? '';
                                  final String firstLetter = name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : 'A';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(
                                            (0.08 * 255).round(),
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 12.0,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.grey.shade100,
                                          child: Text(
                                            firstLetter,
                                            style: const TextStyle(
                                              color: primaryNavy,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  color: primaryNavy,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$email • ID: $loginId',
                                                style: const TextStyle(
                                                  color: textSecondary,
                                                  fontSize: 10,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Super Admin',
                                                  style: TextStyle(
                                                    color: primaryNavy,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () =>
                                              _handleDeleteSuperAdmin(
                                                admin['id'],
                                                name,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Floating Dock
          FloatingDock(
            activeIndex: 0,
            onTabTapped: (index) {
              if (index == 1) {
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A2744), width: 1.2),
      ),
      errorStyle: const TextStyle(fontSize: 10, height: 0.8),
    );
  }
}
