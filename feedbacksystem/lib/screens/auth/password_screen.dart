import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import '../supreme/supreme_dashboard.dart';
import '../superadmin/superadmin_dashboard.dart';
import '../coordinator/coordinator_hub.dart';
import '../hod/hod_dashboard.dart';
import '../student/student_dashboard.dart';

class PasswordScreen extends StatefulWidget {
  final String studentId;
  final String userName;

  const PasswordScreen({
    super.key,
    required this.studentId,
    required this.userName,
  });

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your password'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    const primaryNavy = Color(0xFF1A2744);
    const accentRed = Color(0xFFE53935);

    try {
      final response = await http.post(
        Uri.parse(
          'https://invertis-feedback-system-0chx.onrender.com/api/auth/login',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': widget.studentId,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final token = data['token'];
        final user = data['user'] ?? {};
        final name = user['name'] ?? widget.userName;
        final role = (user['role']?.toString() ?? 'User').toLowerCase();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, $name ($role)! Login successful.'),
            backgroundColor: primaryNavy,
          ),
        );

        if (role == 'supreme') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => SupremeDashboard(
                token: token,
                userName: name,
                userRole: role,
              ),
            ),
            (route) => false,
          );
        } else if (role == 'super_admin' || role == 'superadmin') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => SuperadminDashboard(
                token: token,
                userName: name,
                userRole: role,
              ),
            ),
            (route) => false,
          );
        } else if (role == 'coordinator') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => CoordinatorHub(
                token: token,
                userName: name,
                userRole: role,
              ),
            ),
            (route) => false,
          );
        } else if (role == 'hod') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HodDashboard(
                token: token,
                userName: name,
                userRole: role,
              ),
            ),
            (route) => false,
          );
        } else if (role == 'student') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => StudentDashboard(
                token: token,
                userName: name,
                userRole: role,
              ),
            ),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => SuperadminDashboard(
                // Fallback for testing
                token: token,
                userName: name,
                userRole: role,
              ),
            ),
            (route) => false,
          );
        }
      } else {
        final message =
            data['message'] ?? 'Incorrect password or authentication error.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: accentRed),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Server unreachable. Please check your internet connection.',
          ),
          backgroundColor: accentRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF1A2744);
    const accentRed = Color(0xFFE53935);
    const textSecondary = Color(0xFF9E9E9E);
    const successGreen = Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // === TOP HEADER BAR ===
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/invertis_logo.png',
                    width: 140,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryNavy,
                            ),
                            child: const Icon(
                              Icons.public,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'INVERTIS',
                                style: TextStyle(
                                  color: primaryNavy,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'UNIVERSITY BAREILLY',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ERP SECURE ACCESS',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: successGreen,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 3, color: accentRed),

            // === BACKGROUND & LOGIN CARD ===
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/campus_bg.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: Colors.blueGrey.shade100);
                      },
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withAlpha((0.12 * 255).round()),
                    ),
                  ),

                  Positioned.fill(
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                  vertical: 16.0,
                                ),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 400,
                                  ),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: accentRed,
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(
                                          (0.15 * 255).round(),
                                        ),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // TOP SECTION
                                      const Text(
                                        'INVERTIS UNIVERSITY',
                                        style: TextStyle(
                                          color: primaryNavy,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'FEEDBACK PORTAL',
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2.0,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Divider(
                                        color: Colors.grey.shade300,
                                        height: 1,
                                        thickness: 0.8,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Security Verification',
                                        style: TextStyle(
                                          color: primaryNavy,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'TEACHING-LEARNING FEEDBACK SYSTEM',
                                        style: TextStyle(
                                          color: primaryNavy,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),

                                      // SIGNING IN AS display box
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 12.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF4F7FA),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'SIGNING IN AS',
                                              style: TextStyle(
                                                color: textSecondary.withAlpha(
                                                  (0.9 * 255).round(),
                                                ),
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              widget.studentId.toUpperCase(),
                                              style: const TextStyle(
                                                color: primaryNavy,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // PASSWORD label
                                      const Text(
                                        'PASSWORD',
                                        style: TextStyle(
                                          color: primaryNavy,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // PASSWORD field
                                      SizedBox(
                                        height: 48,
                                        child: TextField(
                                          controller: _passwordController,
                                          obscureText: _obscureText,
                                          style: const TextStyle(
                                            color: primaryNavy,
                                            fontSize: 14,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter your password',
                                            hintStyle: const TextStyle(
                                              color: textSecondary,
                                              fontSize: 13,
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.lock_outline_rounded,
                                              color: textSecondary,
                                              size: 20,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureText
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                          .visibility_off_outlined,
                                                color: textSecondary,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscureText = !_obscureText;
                                                });
                                              },
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                                width: 1.0,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                                width: 1.0,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              borderSide: const BorderSide(
                                                color: primaryNavy,
                                                width: 1.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Back Button
                                      SizedBox(
                                        height: 48,
                                        child: OutlinedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () {
                                                  Navigator.of(context).pop();
                                                },
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: primaryNavy,
                                              width: 1.2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                            ),
                                            foregroundColor: primaryNavy,
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.arrow_back, size: 16),
                                              SizedBox(width: 8),
                                              Text(
                                                'Back',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Sign In Button
                                      SizedBox(
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : _handleSignIn,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryNavy,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                              : const Text(
                                                  'Sign In',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // BOTTOM INFO SECTION
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(top: 2.0),
                                            child: Icon(
                                              Icons.verified_user_outlined,
                                              color: accentRed,
                                              size: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Your responses are strictly anonymous to faculty members. Individual submissions cannot be traced back to you.',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 10,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(top: 2.0),
                                            child: Icon(
                                              Icons.verified_user_outlined,
                                              color: accentRed,
                                              size: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'System audit controls apply. Global configuration is managed by authorized university officers.',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 10,
                                                height: 1.4,
                                              ),
                                            ),
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

                        // === BOTTOM FOOTER ===
                        Container(
                          width: double.infinity,
                          color: primaryNavy,
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: const Text(
                            'INVERTIS TLFQ SYSTEM V2.0',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
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
      ),
    );
  }
}
