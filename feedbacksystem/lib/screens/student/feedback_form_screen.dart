import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import '../../widgets/app_drawer.dart';
import '../auth/login_screen.dart';

class FeedbackFormScreen extends StatefulWidget {
  final String tlfqId;
  final String token;
  final String userName;
  final String userRole;

  const FeedbackFormScreen({
    super.key,
    required this.tlfqId,
    required this.token,
    required this.userName,
    required this.userRole,
  });

  @override
  State<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends State<FeedbackFormScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _apiBase = 'https://invertis-feedback-system-0chx.onrender.com/api';
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic> _formDetails = {};
  List<dynamic> _questions = [];
  Map<String, int> _answers = {};
  String _comment = '';
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _fetchFormData();
  }

  Future<void> _fetchFormData() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/student/tlfq/${widget.tlfqId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _formDetails = data;
            _questions = data['questions'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        _showError('Failed to load form data');
      }
    } catch (e) {
      _showError('Exception: $e');
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitFeedback() async {
    if (_answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions before submitting.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final List<Map<String, dynamic>> answersArray = _answers.entries.map((e) => {
        'question_id': e.key,
        'rating': e.value,
      }).toList();

      final response = await http.post(
        Uri.parse('$_apiBase/student/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'tlfq_id': widget.tlfqId,
          'answers': answersArray,
          'comment': _comment,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feedback submitted successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // true indicates successful submission
        }
      } else {
        final err = jsonDecode(response.body);
        _showError(err['message'] ?? 'Submission failed');
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      _showError('Exception during submission: $e');
      setState(() => _isSubmitting = false);
    }
  }

  void _resetDraft() {
    setState(() {
      _answers.clear();
      _comment = '';
    });
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final String initial = widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'S';

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        userName: widget.userName,
        userRole: widget.userRole,
        token: widget.token,
        activeDrawerItem: 'Dashboard', // Keep same drawer logic
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
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(initial),
                const Divider(height: 1, thickness: 2, color: Colors.red),
                
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderTitle(),
                            const SizedBox(height: 16),
                            _buildBadges(),
                            const SizedBox(height: 24),
                            _buildSummaryCard(),
                            const SizedBox(height: 30),
                            _buildProgressBar(),
                            const SizedBox(height: 24),
                            ..._buildQuestionCards(),
                            const SizedBox(height: 16),
                            _buildCommentBox(),
                            const SizedBox(height: 32),
                            _buildBottomButtons(),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(String initial) {
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
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
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
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                  onPressed: () {
                     Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                  },
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

  Widget _buildHeaderTitle() {
    return const Text(
      'TLFQ Sheet',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1A2744),
      ),
    );
  }

  Widget _buildBadges() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.lock_outline, size: 12, color: Color(0xFF10B981)),
              SizedBox(width: 4),
              Text(
                'ANONYMOUS',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  color: Color(0xFF10B981),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.autorenew, size: 12, color: Color(0xFF475569)),
              SizedBox(width: 4),
              Text(
                'AUTO-SAVE',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  color: Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final title = _formDetails['title']?.toString() ?? 'Evaluation';
    final facultyName = _formDetails['faculty_name']?.toString() ?? 'Faculty Name';
    final courseName = _formDetails['course_name']?.toString() ?? 'Course Name';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        facultyName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.book_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        courseName.length > 20 ? '${courseName.substring(0, 18)}...' : courseName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: _resetDraft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.autorenew, size: 12, color: Color(0xFF64748B)),
                    SizedBox(width: 4),
                    Text(
                      'RESET DRAFT',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    int answered = _answers.length;
    int total = _questions.length;
    double percent = total == 0 ? 0 : (answered / total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'COMPLETION STATUS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                color: Color(0xFF475569),
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '$answered / $total QUESTIONS',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                color: Color(0xFF475569),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
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

  List<Widget> _buildQuestionCards() {
    List<Widget> cards = [];
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final qId = q['id'].toString();
      final currentRating = _answers[qId];

      cards.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        q['question_text'] ?? 'Question',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _speak(q['question_text'] ?? 'Question'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.volume_up_outlined, size: 18, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(10, (index) {
                  int rating = index + 1;
                  bool isSelected = currentRating == rating;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _answers[qId] = rating;
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0F766E) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$rating',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      );
    }
    return cards;
  }

  Widget _buildCommentBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Narrative',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Feedback',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'OPTIONAL\nSUBJECTIVE INPUT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF64748B),
                      height: 1.2,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voice dictation coming soon!')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.mic_none, size: 12, color: Color(0xFF64748B)),
                      SizedBox(width: 6),
                      Text(
                        'VOICE\nDICTATION',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          color: Color(0xFF475569),
                          height: 1.2,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              TextField(
                maxLines: 4,
                onChanged: (val) => _comment = val,
                style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Share any specific feedback about\nteaching style, course content, or\nimprovement suggestions...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600, height: 1.5),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF0F766E)),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Icon(Icons.chat_bubble_outline, color: const Color(0xFFE2E8F0).withValues(alpha: 0.8), size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () {
              if (_answers.length < _questions.length) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please answer all questions before finalizing.')),
                );
              } else {
                _submitFeedback();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A2744),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.send_outlined, size: 14, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'FINALIZE\nSUBMISSION',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A2744),
              padding: const EdgeInsets.symmetric(vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              elevation: 0,
            ),
            child: const Text(
              'DISCARD',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
