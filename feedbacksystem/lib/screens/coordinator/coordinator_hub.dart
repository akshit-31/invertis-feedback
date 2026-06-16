import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/floating_dock.dart';
import '../shared/profile_sheet.dart';
import '../supreme/supreme_dashboard.dart';
import '../superadmin/superadmin_dashboard.dart';

class CoordinatorHub extends StatefulWidget {
  final String token;
  final String userName;
  final String userRole;
  final String initialTab;

  const CoordinatorHub({
    super.key,
    required this.token,
    this.userName = 'SUPAdmin1',
    this.userRole = 'SUPREME',
    this.initialTab = 'Sections',
  });

  @override
  State<CoordinatorHub> createState() => _CoordinatorHubState();
}

class _CoordinatorHubState extends State<CoordinatorHub> {
  final String _apiBase =
      'https://invertis-feedback-system-0chx.onrender.com/api';
  late String _activeTab; // 'Sections', 'Courses', 'Faculty', 'Students'
  final String _activeDrawerItem = 'Coordinator';

  // Loading states
  bool _isLoadingDepts = false;
  bool _isLoadingSections = false;
  bool _isLoadingCourses = false;
  bool _isLoadingFaculty = false;
  bool _isLoadingStudents = false;

  bool _isActionInProgress = false;

  // Data lists
  List<dynamic> _departments = [];
  List<dynamic> _sections = [];
  List<dynamic> _courses = [];
  List<dynamic> _faculty = [];
  List<dynamic> _students = [];

  // Dropdown / Form values for Sections
  String? _selectedDeptId;
  int _selectedSemester = 1;
  String _selectedSectionLabel = 'A';

  // Form controllers for Courses
  final _courseFormKey = GlobalKey<FormState>();
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _courseCodeController = TextEditingController();
  String? _courseSelectedDeptId;

  // Form controllers for Faculty
  final _facultyFormKey = GlobalKey<FormState>();
  final TextEditingController _facultyNameController = TextEditingController();
  String? _facultySelectedDeptId;
  String _selectedTeacherType = 'college_faculty';

  // Form controllers and values for Students
  final _studentFormKey = GlobalKey<FormState>();
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _studentBatchController = TextEditingController(
    text: '2025',
  );
  String? _studentDeptId;
  String? _studentSectionId;
  int _studentSemester = 3;
  String? _studentFilterDeptId;

  // Pagination for Students
  int _studentPage = 1;
  int _studentTotalPages = 1;
  String? _studentFilterSectionId;

  // Inline Password Reset
  String? _resettingPasswordStudentId;
  final TextEditingController _inlinePasswordController =
      TextEditingController();

  // Tab Keys for auto-scroll
  final GlobalKey _sectionsKey = GlobalKey();
  final GlobalKey _coursesKey = GlobalKey();
  final GlobalKey _facultyKey = GlobalKey();
  final GlobalKey _studentsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;

    _fetchDepartments().then((_) {
      if (_activeTab == 'Sections') _fetchSections();
      if (_activeTab == 'Courses') _fetchCourses();
      if (_activeTab == 'Faculty') _fetchFaculty();
      if (_activeTab == 'Students') _fetchStudents();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveTab();
    });
  }

  void _scrollToActiveTab() {
    GlobalKey? key;
    switch (_activeTab) {
      case 'Sections':
        key = _sectionsKey;
        break;
      case 'Courses':
        key = _coursesKey;
        break;
      case 'Faculty':
        key = _facultyKey;
        break;
      case 'Students':
        key = _studentsKey;
        break;
    }
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
    }
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _facultyNameController.dispose();
    _studentNameController.dispose();
    _studentIdController.dispose();
    _studentBatchController.dispose();
    super.dispose();
  }

  // Common Headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${widget.token}',
  };

  // --- API CALLS ---

  Future<void> _fetchDepartments() async {
    setState(() => _isLoadingDepts = true);
    try {
      final res = await http.get(
        Uri.parse('$_apiBase/coordinator/departments'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        setState(() {
          _departments = jsonDecode(res.body);
          if (_departments.isNotEmpty) {
            _selectedDeptId = _departments[0]['id'];
            _courseSelectedDeptId = _departments[0]['id'];
            _facultySelectedDeptId = _departments[0]['id'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching departments: $e');
    } finally {
      setState(() => _isLoadingDepts = false);
    }
  }

  Future<void> _fetchSections() async {
    setState(() => _isLoadingSections = true);
    try {
      final res = await http.get(
        Uri.parse('$_apiBase/coordinator/sections'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        setState(() {
          _sections = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching sections: $e');
    } finally {
      setState(() => _isLoadingSections = false);
    }
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      final res = await http.get(
        Uri.parse('$_apiBase/coordinator/courses'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        setState(() {
          _courses = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching courses: $e');
    } finally {
      setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _fetchFaculty() async {
    setState(() => _isLoadingFaculty = true);
    try {
      final res = await http.get(
        Uri.parse('$_apiBase/coordinator/faculty'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        setState(() {
          _faculty = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching faculty: $e');
    } finally {
      setState(() => _isLoadingFaculty = false);
    }
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoadingStudents = true);
    try {
      String url = '$_apiBase/coordinator/students?page=$_studentPage&limit=20';
      if (_studentFilterSectionId != null) {
        url += '&section_id=$_studentFilterSectionId';
      }
      if (_studentFilterDeptId != null) {
        url += '&department_id=$_studentFilterDeptId';
      }
      final res = await http.get(Uri.parse(url), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _students = data['students'] ?? [];
          _studentTotalPages = data['pagination']?['totalPages'] ?? 1;
        });
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
    } finally {
      setState(() => _isLoadingStudents = false);
    }
  }

  // --- ACTIONS ---

  Future<void> _createSection() async {
    if (_selectedDeptId == null) return;
    setState(() => _isActionInProgress = true);
    try {
      final res = await http.post(
        Uri.parse('$_apiBase/coordinator/sections'),
        headers: _headers,
        body: jsonEncode({
          'department_id': _selectedDeptId,
          'semester': _selectedSemester,
          'label': _selectedSectionLabel,
        }),
      );

      if (res.statusCode == 201) {
        _showSnackBar('Section created successfully!', Colors.green);
        _fetchSections();
      } else {
        final err = jsonDecode(res.body);
        _showSnackBar(err['message'] ?? 'Failed to create section', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Network error occurred.', Colors.red);
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _deleteSection(String id, String name) async {
    final confirm = await _showConfirmDialog(
      'Delete Section',
      'Are you sure you want to delete section "$name"? All students enrolled in this section will have their section field unset.',
    );
    if (!confirm) return;

    setState(() => _isActionInProgress = true);
    try {
      // DELETE sections/id is under /api/hod/sections/:id which supreme bypasses
      final res = await http.delete(
        Uri.parse('$_apiBase/hod/sections/$id'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        _showSnackBar('Section deleted.', Colors.green);
        _fetchSections();
      } else {
        _showSnackBar(
          'Failed to delete section: ${res.statusCode} ${res.body}',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Network error occurred.', Colors.red);
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _createCourse() async {
    if (!_courseFormKey.currentState!.validate() ||
        _courseSelectedDeptId == null) {
      return;
    }
    setState(() => _isActionInProgress = true);
    try {
      final res = await http.post(
        Uri.parse('$_apiBase/coordinator/courses'),
        headers: _headers,
        body: jsonEncode({
          'name': _courseNameController.text.trim(),
          'code': _courseCodeController.text.trim().toUpperCase(),
          'department_id': _courseSelectedDeptId,
        }),
      );

      if (res.statusCode == 201) {
        _showSnackBar('Course created successfully!', Colors.green);
        _courseNameController.clear();
        _courseCodeController.clear();
        _fetchCourses();
      } else {
        final err = jsonDecode(res.body);
        _showSnackBar(err['message'] ?? 'Failed to create course', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Network error.', Colors.red);
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _deleteCourse(String id) async {
    final confirm = await _showConfirmDialog(
      'Delete Course',
      'Are you sure you want to delete this course?',
    );
    if (!confirm) return;

    setState(() => _isActionInProgress = true);
    try {
      final res = await http.delete(
        Uri.parse('$_apiBase/coordinator/courses/$id'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        _showSnackBar('Course deleted.', Colors.green);
        _fetchCourses();
      } else {
        _showSnackBar('Failed to delete course.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Network error.', Colors.red);
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _createFaculty() async {
    if (!_facultyFormKey.currentState!.validate() ||
        _facultySelectedDeptId == null) {
      return;
    }
    setState(() => _isActionInProgress = true);
    try {
      final res = await http.post(
        Uri.parse('$_apiBase/coordinator/faculty'),
        headers: _headers,
        body: jsonEncode({
          'name': _facultyNameController.text.trim(),
          'department_id': _facultySelectedDeptId,
          'teacher_type': _selectedTeacherType,
        }),
      );

      if (res.statusCode == 201) {
        _showSnackBar('Faculty member created!', Colors.green);
        _facultyNameController.clear();
        _fetchFaculty();
      } else {
        final err = jsonDecode(res.body);
        _showSnackBar(err['message'] ?? 'Failed to create faculty', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Network error.', Colors.red);
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _deleteFaculty(String id) async {
    final confirm = await _showConfirmDialog(
      'Delete Faculty',
      'Are you sure you want to delete this faculty member?',
    );
    if (!confirm) return;

    setState(() => _isActionInProgress = true);
    try {
      final res = await http.delete(
        Uri.parse('$_apiBase/coordinator/faculty/$id'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        _showSnackBar('Faculty deleted.', Colors.green);
        _fetchFaculty();
      } else {
        _showSnackBar('Failed to delete faculty.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Network error.', Colors.red);
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _submitInlinePasswordReset(String id, String newPassword) async {
    setState(() => _isActionInProgress = true);
    try {
      final res = await http.put(
        Uri.parse('$_apiBase/coordinator/students/$id/reset-password'),
        headers: _headers,
        body: jsonEncode({'new_password': newPassword.trim()}),
      );

      if (res.statusCode == 200) {
        _showSnackBar('Password reset successfully!', Colors.green);
        setState(() {
          _resettingPasswordStudentId = null;
          _inlinePasswordController.clear();
        });
      } else {
        _showSnackBar('Failed to reset password.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Network error occurred.', Colors.red);
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _resetStudentPassword(String id, String name) async {
    final passController = TextEditingController(text: 'invertis123');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password for $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter new password (min 8 characters):'),
            const SizedBox(height: 8),
            TextField(
              controller: passController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (passController.text.length < 8) {
                _showSnackBar(
                  'Password must be at least 8 characters',
                  Colors.red,
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text(
              'Reset',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionInProgress = true);
    try {
      final res = await http.put(
        Uri.parse('$_apiBase/coordinator/students/$id/reset-password'),
        headers: _headers,
        body: jsonEncode({'new_password': passController.text.trim()}),
      );

      if (res.statusCode == 200) {
        _showSnackBar(
          'Password reset successfully to "${passController.text}"!',
          Colors.green,
        );
      } else {
        _showSnackBar('Failed to reset password.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Network error.', Colors.red);
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _preCreateStudent() async {
    if (!_studentFormKey.currentState!.validate() ||
        _studentDeptId == null ||
        _studentSectionId == null) {
      _showSnackBar('Please fill all required fields', Colors.red);
      return;
    }
    setState(() => _isActionInProgress = true);
    try {
      final res = await http.post(
        Uri.parse('$_apiBase/coordinator/students'),
        headers: _headers,
        body: jsonEncode({
          'name': _studentNameController.text.trim(),
          'student_id': _studentIdController.text.trim().toUpperCase(),
          'department_id': _studentDeptId,
          'section_id': _studentSectionId,
          'semester': _studentSemester,
          'batch': _studentBatchController.text.trim(),
        }),
      );

      if (res.statusCode == 201) {
        _showSnackBar(
          'Student account pre-created successfully!',
          Colors.green,
        );
        _studentNameController.clear();
        _studentIdController.clear();
        _fetchStudents();
      } else {
        final err = jsonDecode(res.body);
        _showSnackBar(
          err['message'] ?? 'Failed to pre-create student',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Network error.', Colors.red);
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _importCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isActionInProgress = true);

      String content = '';
      if (kIsWeb) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          content = utf8.decode(bytes);
        }
      } else {
        final path = result.files.first.path;
        if (path != null) {
          final file = File(path);
          content = await file.readAsString();
        }
      }

      if (content.isEmpty) {
        _showSnackBar('Selected file is empty', Colors.red);
        setState(() => _isActionInProgress = false);
        return;
      }

      // Parse CSV
      final lines = content.split(RegExp(r'\r?\n'));
      if (lines.isEmpty) {
        _showSnackBar('CSV has no lines', Colors.red);
        setState(() => _isActionInProgress = false);
        return;
      }

      // Header parsing
      final headersLine = lines[0];
      final headers = headersLine
          .split(',')
          .map((h) => h.trim().toLowerCase())
          .toList();

      final nameIdx = headers.indexOf('name');
      final studentIdIdx = headers.indexOf('student_id');
      final deptIdIdx = headers.indexOf('department_id');
      final sectionIdIdx = headers.indexOf('section_id');
      final semIdx = headers.indexOf('semester');
      final batchIdx = headers.indexOf('batch');

      if (nameIdx == -1 ||
          studentIdIdx == -1 ||
          deptIdIdx == -1 ||
          sectionIdIdx == -1 ||
          semIdx == -1) {
        _showSnackBar(
          'CSV must contain name, student_id, department_id, section_id, semester headers',
          Colors.red,
        );
        setState(() => _isActionInProgress = false);
        return;
      }

      List<Map<String, dynamic>> studentsToImport = [];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final cols = line.split(',').map((c) => c.trim()).toList();
        if (cols.length <= nameIdx ||
            cols.length <= studentIdIdx ||
            cols.length <= deptIdIdx ||
            cols.length <= sectionIdIdx ||
            cols.length <= semIdx) {
          continue;
        }

        final name = cols[nameIdx];
        final studentId = cols[studentIdIdx];
        final deptId = cols[deptIdIdx];
        final sectionId = cols[sectionIdIdx];
        final semesterVal = int.tryParse(cols[semIdx]) ?? 3;
        final batch = batchIdx != -1 && cols.length > batchIdx
            ? cols[batchIdx]
            : '2025';

        if (name.isEmpty ||
            studentId.isEmpty ||
            deptId.isEmpty ||
            sectionId.isEmpty) {
          continue;
        }

        studentsToImport.add({
          'name': name,
          'student_id': studentId.toUpperCase(),
          'department_id': deptId,
          'section_id': sectionId,
          'semester': semesterVal,
          'batch': batch,
        });
      }

      if (studentsToImport.isEmpty) {
        _showSnackBar('No valid student rows found in CSV', Colors.red);
        setState(() => _isActionInProgress = false);
        return;
      }

      final res = await http.post(
        Uri.parse('$_apiBase/coordinator/students/bulk'),
        headers: _headers,
        body: jsonEncode({'students': studentsToImport}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final successCount = data['results']?['success'] ?? 0;
        final failedCount = data['results']?['failed'] ?? 0;
        _showSnackBar(
          'Import completed! Success: $successCount, Failed: $failedCount',
          Colors.green,
        );
        _fetchStudents();
      } else {
        final err = jsonDecode(res.body);
        _showSnackBar(
          err['message'] ?? 'Failed to bulk import students',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Error importing CSV: $e', Colors.red);
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  // --- HELPERS ---

  void _showSnackBar(String message, Color bgColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: bgColor));
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  void _tabChanged(String tab) {
    setState(() {
      _activeTab = tab;
    });

    if (tab == 'Sections') {
      _fetchSections();
    } else if (tab == 'Courses') {
      _fetchCourses();
    } else if (tab == 'Faculty') {
      _fetchFaculty();
    } else if (tab == 'Students') {
      _studentPage = 1;
      _fetchStudents();
    }
    _scrollToActiveTab();
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
              onPressed: _handleLogout,
            ),
          ),
        ],
      ),
      drawer: AppDrawer(
        token: widget.token,
        userName: widget.userName,
        userRole: widget.userRole,
        activeDrawerItem: _activeDrawerItem,
        activeSubItem: _activeTab,
      ),
      body: Stack(
        children: [
          // Background Campus Image
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

          // Main Screen Content
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // --- HUB TITLE CARD ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.95 * 255).round()),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            radius: 20,
                            child: Icon(
                              Icons.layers_outlined,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Coordinator Hub',
                                  style: TextStyle(
                                    color: primaryNavy,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Manage Invertis University feedback infrastructure',
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
                  ),

                  // --- TABS BAR ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: ['Sections', 'Courses', 'Faculty', 'Students']
                            .map((tab) {
                              final isActive = _activeTab == tab;
                              GlobalKey? key;
                              if (tab == 'Sections') {
                                key = _sectionsKey;
                              } else if (tab == 'Courses')
                                key = _coursesKey;
                              else if (tab == 'Faculty')
                                key = _facultyKey;
                              else if (tab == 'Students')
                                key = _studentsKey;

                              return Padding(
                                key: key,
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        tab == 'Sections'
                                            ? Icons.layers_outlined
                                            : tab == 'Courses'
                                            ? Icons.book_outlined
                                            : tab == 'Faculty'
                                            ? Icons.people_outline
                                            : Icons.school_outlined,
                                        size: 14,
                                        color: isActive
                                            ? Colors.white
                                            : primaryNavy,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(tab),
                                    ],
                                  ),
                                  selected: isActive,
                                  onSelected: (_) => _tabChanged(tab),
                                  selectedColor: primaryNavy,
                                  backgroundColor: Colors.white.withAlpha(
                                    (0.9 * 255).round(),
                                  ),
                                  labelStyle: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : primaryNavy,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ),

                  // --- MAIN SCROLL CONTENT (Dynamic based on Tab) ---
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_isActionInProgress)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 12.0),
                                  child: LinearProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      primaryNavy,
                                    ),
                                  ),
                                ),
                              _buildTabContent(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Floating Dock
          FloatingDock(
            activeIndex: widget.userRole == 'coordinator' ? 0 : -1,
            showUsers: false,
            onTabTapped: (index) {
              if (index == 0) {
                if (widget.userRole == 'coordinator') {
                  // Already on Coordinator Hub
                } else {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => widget.userRole == 'supreme'
                          ? SupremeDashboard(
                              token: widget.token,
                              userName: widget.userName,
                              userRole: widget.userRole,
                            )
                          : SuperadminDashboard(
                              token: widget.token,
                              userName: widget.userName,
                              userRole: widget.userRole,
                            ),
                    ),
                    (route) => false,
                  );
                }
              } else if (index == 1) {
                // Not reachable because showUsers is false
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

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 'Sections':
        return _buildSectionsTab();
      case 'Courses':
        return _buildCoursesTab();
      case 'Faculty':
        return _buildFacultyTab();
      case 'Students':
        return _buildStudentsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ==================== SECTIONS TAB ====================
  Widget _buildSectionsTab() {
    const primaryNavy = Color(0xFF1A2744);
    const textSecondary = Color(0xFF9E9E9E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Create Section Card ---
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade200, width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Section',
                style: TextStyle(
                  color: primaryNavy,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // DEPARTMENT DROPDOWN
              const Text(
                'DEPARTMENT',
                style: TextStyle(
                  color: primaryNavy,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              _isLoadingDepts
                  ? const SizedBox(
                      height: 44,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      initialValue: _selectedDeptId,
                      decoration: _inputDecoration('Select Department'),
                      items: _departments.map<DropdownMenuItem<String>>((dept) {
                        return DropdownMenuItem<String>(
                          value: dept['id'],
                          child: Text(
                            dept['name'] ?? 'Dept',
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedDeptId = val;
                        });
                      },
                    ),
              const SizedBox(height: 14),

              // SEMESTER AND SECTION LABEL IN A ROW
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SEMESTER',
                          style: TextStyle(
                            color: primaryNavy,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedSemester,
                          decoration: _inputDecoration('Semester'),
                          items: List.generate(8, (index) => index + 1).map((
                            sem,
                          ) {
                            return DropdownMenuItem<int>(
                              value: sem,
                              child: Text(
                                'Sem $sem',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedSemester = val ?? 1;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SECTION',
                          style: TextStyle(
                            color: primaryNavy,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSectionLabel,
                          decoration: _inputDecoration('Section'),
                          items: ['A', 'B', 'C', 'D', 'E', 'F'].map((label) {
                            return DropdownMenuItem<String>(
                              value: label,
                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedSectionLabel = val ?? 'A';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // CREATE BUTTON
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: _isActionInProgress ? null : _createSection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Create',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- List Header ---
        const Row(
          children: [
            Icon(Icons.layers_outlined, color: Colors.white, size: 14),
            SizedBox(width: 6),
            Text(
              'Existing Sections',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // --- Sections List ---
        _isLoadingSections
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : _sections.isEmpty
            ? _buildEmptyState('No sections found.')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sections.length,
                itemBuilder: (context, index) {
                  final sec = _sections[index];
                  final name = sec['name'] ?? 'Section';
                  final deptName = sec['department_name'] ?? 'Department';
                  final sem = sec['semester'] ?? 0;
                  final id = sec['id'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: primaryNavy,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$deptName • Semester $sem',
                                style: const TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
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

  // ==================== COURSES TAB ====================
  Widget _buildCoursesTab() {
    const primaryNavy = Color(0xFF1A2744);
    const textSecondary = Color(0xFF9E9E9E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Create Course Card
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade200),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Form(
            key: _courseFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Course',
                  style: TextStyle(
                    color: primaryNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'COURSE NAME',
                  style: TextStyle(
                    color: primaryNavy,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _courseNameController,
                  style: const TextStyle(fontSize: 13),
                  decoration: _inputDecoration('e.g. Data Structures'),
                  validator: (v) =>
                      v!.isEmpty ? 'Course Name is required' : null,
                ),
                const SizedBox(height: 10),
                const Text(
                  'COURSE CODE',
                  style: TextStyle(
                    color: primaryNavy,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _courseCodeController,
                  style: const TextStyle(fontSize: 13),
                  decoration: _inputDecoration('e.g. BCS301'),
                  validator: (v) =>
                      v!.isEmpty ? 'Course Code is required' : null,
                ),
                const SizedBox(height: 10),
                const Text(
                  'DEPARTMENT',
                  style: TextStyle(
                    color: primaryNavy,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _courseSelectedDeptId,
                  decoration: _inputDecoration('Select Department'),
                  items: _departments.map<DropdownMenuItem<String>>((dept) {
                    return DropdownMenuItem<String>(
                      value: dept['id'],
                      child: Text(
                        dept['name'] ?? 'Dept',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _courseSelectedDeptId = val),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _isActionInProgress ? null : _createCourse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Create Course',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Courses List
        const Row(
          children: [
            Icon(Icons.book_outlined, color: Colors.white, size: 14),
            SizedBox(width: 6),
            Text(
              'Existing Courses',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _isLoadingCourses
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : _courses.isEmpty
            ? _buildEmptyState('No courses found.')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  final c = _courses[index];
                  final name = c['name'] ?? '';
                  final code = c['code'] ?? '';
                  final dept = c['department_name'] ?? '';
                  final id = c['id'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$name ($code)',
                                style: const TextStyle(
                                  color: primaryNavy,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dept,
                                style: const TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
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
                          onPressed: () => _deleteCourse(id),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  // ==================== FACULTY TAB ====================
  Widget _buildFacultyTab() {
    const primaryNavy = Color(0xFF1A2744);
    const textSecondary = Color(0xFF9E9E9E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Create Faculty Card
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade200),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Form(
            key: _facultyFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Faculty Profile',
                  style: TextStyle(
                    color: primaryNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'FACULTY NAME',
                  style: TextStyle(
                    color: primaryNavy,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _facultyNameController,
                  style: const TextStyle(fontSize: 13),
                  decoration: _inputDecoration('e.g. Prof. Rajiv Kumar'),
                  validator: (v) =>
                      v!.isEmpty ? 'Faculty Name is required' : null,
                ),
                const SizedBox(height: 10),
                const Text(
                  'DEPARTMENT',
                  style: TextStyle(
                    color: primaryNavy,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _facultySelectedDeptId,
                  decoration: _inputDecoration('Select Department'),
                  items: _departments.map<DropdownMenuItem<String>>((dept) {
                    return DropdownMenuItem<String>(
                      value: dept['id'],
                      child: Text(
                        dept['name'] ?? 'Dept',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _facultySelectedDeptId = val),
                ),
                const SizedBox(height: 10),
                const Text(
                  'FACULTY TYPE',
                  style: TextStyle(
                    color: primaryNavy,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTeacherType,
                  decoration: _inputDecoration('Select Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'college_faculty',
                      child: Text(
                        'College Faculty',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'visiting_faculty',
                      child: Text(
                        'Visiting Faculty',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'lab_instructor',
                      child: Text(
                        'Lab Instructor',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(
                    () => _selectedTeacherType = val ?? 'college_faculty',
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _isActionInProgress ? null : _createFaculty,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Create Profile',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Faculty List
        const Row(
          children: [
            Icon(Icons.people_outline, color: Colors.white, size: 14),
            SizedBox(width: 6),
            Text(
              'Existing Faculty Members',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _isLoadingFaculty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : _faculty.isEmpty
            ? _buildEmptyState('No faculty members found.')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _faculty.length,
                itemBuilder: (context, index) {
                  final f = _faculty[index];
                  final name = f['name'] ?? '';
                  final dept = f['department_name'] ?? '';
                  final type = (f['teacher_type'] ?? 'college_faculty')
                      .toString()
                      .replaceAll('_', ' ')
                      .toUpperCase();
                  final id = f['id'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                '$dept • $type',
                                style: const TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
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
                          onPressed: () => _deleteFaculty(id),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  // ==================== STUDENTS TAB ====================
  Widget _buildStudentsTab() {
    const primaryNavy = Color(0xFF1A2744);
    const textSecondary = Color(0xFF9E9E9E);

    // Filter sections dynamically based on selected pre-create department
    final preCreateSections = _sections
        .where((sec) => sec['department_id'] == _studentDeptId)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- PRE-CREATE STUDENT ACCOUNT CARD ---
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade200, width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _studentFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Pre-Create Student Account',
                  style: TextStyle(
                    color: primaryNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // NAME AND ID ROW
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            controller: _studentNameController,
                            style: const TextStyle(fontSize: 13),
                            decoration: _inputDecoration('Rahul Sharma'),
                            validator: (v) =>
                                v!.isEmpty ? 'Name required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STUDENT ID',
                            style: TextStyle(
                              color: primaryNavy,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _studentIdController,
                            style: const TextStyle(fontSize: 13),
                            decoration: _inputDecoration('BCS2025_55'),
                            validator: (v) => v!.isEmpty ? 'ID required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // DEPT AND SECTION ROW
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DEPARTMENT',
                            style: TextStyle(
                              color: primaryNavy,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: _studentDeptId,
                            decoration: _inputDecoration('Select..'),
                            items: _departments.map((dept) {
                              return DropdownMenuItem<String>(
                                value: dept['id'],
                                child: Text(
                                  dept['name'] ?? '',
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _studentDeptId = val;
                                _studentSectionId =
                                    null; // reset section when dept changes
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SECTION',
                            style: TextStyle(
                              color: primaryNavy,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            key: ValueKey(_studentDeptId),
                            initialValue: _studentSectionId,
                            decoration: _inputDecoration('Select..'),
                            items: preCreateSections.map((sec) {
                              return DropdownMenuItem<String>(
                                value: sec['id'],
                                child: Text(
                                  sec['name'] ?? '',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _studentSectionId = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // SEMESTER AND BATCH ROW
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SEMESTER',
                            style: TextStyle(
                              color: primaryNavy,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<int>(
                            initialValue: _studentSemester,
                            decoration: _inputDecoration('Sem 3'),
                            items: List.generate(8, (index) => index + 1).map((
                              sem,
                            ) {
                              return DropdownMenuItem<int>(
                                value: sem,
                                child: Text(
                                  'Sem $sem',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _studentSemester = val ?? 3;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BATCH YEAR',
                            style: TextStyle(
                              color: primaryNavy,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _studentBatchController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 13),
                            decoration: _inputDecoration('2025'),
                            validator: (v) =>
                                v!.isEmpty ? 'Batch required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // SUBMIT BUTTON
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isActionInProgress ? null : _preCreateStudent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Pre-Create Student',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // --- BULK IMPORT VIA CSV CARD ---
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.file_upload_outlined,
                    color: primaryNavy,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Bulk Import via CSV',
                    style: TextStyle(
                      color: primaryNavy,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Upload a CSV file with the following headers:',
                style: TextStyle(color: Colors.black54, fontSize: 11),
              ),
              const SizedBox(height: 8),

              // Snippet view of Headers
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'name, student_id, department_id, section_id, semester, batch',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // SELECT CSV FILE BUTTON
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _isActionInProgress ? null : _importCsvFile,
                  icon: const Icon(Icons.insert_drive_file_outlined, size: 16),
                  label: const Text(
                    'SELECT CSV FILE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // DATA HINTS BOX
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 12, color: Colors.grey),
                        SizedBox(width: 6),
                        Text(
                          'DATA HINTS',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'IDs are case-insensitive',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Dupes will be skipped',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- FILTER BY DEPARTMENT SELECTOR ---
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FILTER BY DEPARTMENT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              initialValue: _studentFilterDeptId,
              decoration: _inputDecoration('All'),
              dropdownColor: Colors.white,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'All Departments',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                ..._departments.map((dept) {
                  return DropdownMenuItem<String?>(
                    value: dept['id'],
                    child: Text(
                      dept['name'] ?? '',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _studentFilterDeptId = val;
                  _studentPage = 1;
                });
                _fetchStudents();
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- Students list header ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.school_outlined, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'Students List',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (_studentTotalPages > 1)
              Text(
                'Page $_studentPage of $_studentTotalPages',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // --- Students Cards List ---
        _isLoadingStudents
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : _students.isEmpty
            ? _buildEmptyState('No students found.')
            : Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final s = _students[index];
                      final name = s['name'] ?? '';
                      final studentId = s['student_id'] ?? '';
                      final sectionName = s['section_name'] ?? '—';
                      final sem = s['semester'] ?? 3;
                      final status = s['status'] ?? 'pending';
                      final id = s['id'] ?? '';

                      final isActive = status == 'active';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: primaryNavy,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFFE8F5E9)
                                        : const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: isActive
                                          ? const Color(0xFF2E7D32)
                                          : Colors.orange,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              studentId,
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$sectionName • Sem $sem',
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 10,
                              ),
                            ),
                            const Divider(height: 16, thickness: 0.5),

                            // Reset Password Action Row button
                            _resettingPasswordStudentId == id
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 36,
                                            child: TextField(
                                              controller:
                                                  _inlinePasswordController,
                                              decoration: InputDecoration(
                                                hintText:
                                                    'New password (min 8)',
                                                hintStyle: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: Colors
                                                            .grey
                                                            .shade300,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: primaryNavy,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () async {
                                            if (_inlinePasswordController
                                                    .text
                                                    .length <
                                                8) {
                                              _showSnackBar(
                                                'Min 8 chars required',
                                                Colors.red,
                                              );
                                              return;
                                            }
                                            await _submitInlinePasswordReset(
                                              id,
                                              _inlinePasswordController.text,
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              color: primaryNavy,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _resettingPasswordStudentId =
                                                  null;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.black54,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : InkWell(
                                    onTap: () {
                                      setState(() {
                                        _resettingPasswordStudentId = id;
                                        _inlinePasswordController.clear();
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.vpn_key_outlined,
                                            size: 14,
                                            color: textSecondary,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Reset Password',
                                            style: TextStyle(
                                              color: primaryNavy,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Pagination Buttons
                  if (_studentTotalPages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                          onPressed: _studentPage > 1
                              ? () {
                                  setState(() => _studentPage--);
                                  _fetchStudents();
                                }
                              : null,
                        ),
                        Text(
                          '$_studentPage / $_studentTotalPages',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                          onPressed: _studentPage < _studentTotalPages
                              ? () {
                                  setState(() => _studentPage++);
                                  _fetchStudents();
                                }
                              : null,
                        ),
                      ],
                    ),
                ],
              ),
      ],
    );
  }

  // --- Common Empty State Widget ---
  Widget _buildEmptyState(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30.0),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // --- Input Decoration helper ---
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
