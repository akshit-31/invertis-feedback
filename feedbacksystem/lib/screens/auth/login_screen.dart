import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _loginIdController.dispose();
    super.dispose();
  }

  Future<void> _handleProceed() async {
    final id = _loginIdController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your ID'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // ignore: unused_local_variable
    const accentRed = Color(0xFFE53935);

    try {
      final response = await http.post(
        Uri.parse(
          'https://invertis-feedback-system-0chx.onrender.com/api/auth/check-student',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'student_id': id}),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final status = data['status'] ?? 'pending';
        final name = data['name'] ?? 'User';
        final studentId = data['student_id'] ?? id;

        if (status == 'active') {
          // Navigate to Security Verification screen (PasswordScreen)
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  PasswordScreen(studentId: studentId, userName: name),
            ),
          );
        } else if (status == 'pending') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your account is pending registration. Please register on the web portal first.',
              ),
              backgroundColor: accentRed,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account status is "$status". Access restricted.'),
              backgroundColor: accentRed,
            ),
          );
        }
      } else {
        final message = data['message'] ?? 'User ID / Login ID not found.';
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Side Logo
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
                    // Right Side Badge
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
            ),
            // Red line separator
            Container(height: 3, color: accentRed),

            // === BACKGROUND & LOGIN CARD ===
            Expanded(
              child: Stack(
                children: [
                  // Campus Background Photo
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/campus_bg.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: Colors.blueGrey.shade100);
                      },
                    ),
                  ),
                  // Dark Overlay
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withAlpha((0.12 * 255).round()),
                    ),
                  ),

                  // Login Card and Content Scrollable
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
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      padding: const EdgeInsets.all(32.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Authentication',
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

                                      // INPUT SECTION
                                      const Text(
                                        'LOGIN ID',
                                        style: TextStyle(
                                          color: primaryNavy,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        height: 48,
                                        child: TextField(
                                          controller: _loginIdController,
                                          style: const TextStyle(
                                            color: primaryNavy,
                                            fontSize: 14,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter you ID',
                                            hintStyle: const TextStyle(
                                              color: textSecondary,
                                              fontSize: 13,
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.person_outline,
                                              color: textSecondary,
                                              size: 20,
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

                                      // BUTTON
                                      SizedBox(
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : _handleProceed,
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
                                                  'Proceed',
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
