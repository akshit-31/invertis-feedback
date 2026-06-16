import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../supreme/supreme_dashboard.dart';
import '../superadmin/superadmin_dashboard.dart';
import '../coordinator/coordinator_hub.dart';
import '../shared/profile_sheet.dart';
import '../../widgets/app_drawer.dart';
import '../hod/hod_dashboard.dart';
import '../../widgets/floating_dock.dart';

class UserManagementScreen extends StatefulWidget {
  final String token;
  final String userName;
  final String userRole;
  final String initialTab;

  const UserManagementScreen({
    super.key,
    required this.token,
    this.userName = 'SUPAdmin1',
    this.userRole = 'SUPREME',
    this.initialTab = 'Departments',
  });

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final String _apiBase =
      'https://invertis-feedback-system-0chx.onrender.com/api';
  String _activeTab =
      'Departments'; // Departments, HODs, Coordinators, Acad. Promotion, Student Lookup
  final String _activeDrawerItem = 'User Management';

  // Tab Keys for auto-scrolling
  final GlobalKey _deptKey = GlobalKey();
  final GlobalKey _hodKey = GlobalKey();
  final GlobalKey _coordKey = GlobalKey();
  final GlobalKey _promoKey = GlobalKey();
  final GlobalKey _studentKey = GlobalKey();

  // Loading states
  bool _isLoadingDepts = false;
  bool _isActionInProgress = false;

  // Data lists
  List<dynamic> _departments = [];

  // Form controllers for Departments
  final _deptFormKey = GlobalKey<FormState>();
  final TextEditingController _deptNameController = TextEditingController();
  final TextEditingController _deptCodeController = TextEditingController();
  int _selectedMaxSemester = 8;

  // Form controllers for HODs
  final _hodFormKey = GlobalKey<FormState>();
  final TextEditingController _hodNameController = TextEditingController();
  final TextEditingController _hodEmailController = TextEditingController();
  final TextEditingController _hodLoginIdController = TextEditingController();
  final TextEditingController _hodPasswordController = TextEditingController();
  String? _selectedHodDeptId;

  // Form controllers for Coordinators
  final _coordFormKey = GlobalKey<FormState>();
  final TextEditingController _coordNameController = TextEditingController();
  final TextEditingController _coordEmailController = TextEditingController();
  final TextEditingController _coordLoginIdController = TextEditingController();
  final TextEditingController _coordPasswordController =
      TextEditingController();
  bool _obscureCoordPassword = true;

  List<dynamic> _staff = [];
  bool _isLoadingStaff = false;
  bool _obscureHodPassword = true;

  // Academic Promotion state
  bool _isLoadingPromotion = false;
  Map<String, dynamic>? _promotionOverview;
  String? _selectedPromotionDeptId;
  String? _specificDeptId;
  final Set<int> _selectedSemesters = {};
  final TextEditingController _specificStudentsController =
      TextEditingController();
  bool _markNextActive = false;
  Map<String, dynamic>? _promotionPreviewResult;
  Map<String, dynamic>? _promotionScopeBody;

  // Student Lookup state
  final TextEditingController _studentSearchController =
      TextEditingController();
  List<dynamic> _allStudents = [];
  List<dynamic> _filteredStudents = [];
  bool _isLoadingStudents = false;
  final Set<String> _revealedStudentIds = {};
  int _studentCurrentPage = 1;
  final int _studentsPerPage = 50;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;

    if (_activeTab == 'Departments') {
      _fetchDepartments();
    } else if (_activeTab == 'HODs' || _activeTab == 'Coordinators') {
      _fetchDepartments().then((_) => _fetchStaff());
    } else if (_activeTab == 'Acad. Promotion') {
      _fetchDepartments().then((_) => _fetchPromotionOverview());
    } else if (_activeTab == 'Student Lookup') {
      _fetchDepartments().then((_) => _fetchStudents());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveTab();
    });
  }

  void _scrollToActiveTab() {
    GlobalKey? key;
    switch (_activeTab) {
      case 'Departments':
        key = _deptKey;
        break;
      case 'HODs':
        key = _hodKey;
        break;
      case 'Coordinators':
        key = _coordKey;
        break;
      case 'Acad. Promotion':
        key = _promoKey;
        break;
      case 'Student Lookup':
        key = _studentKey;
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
    _deptNameController.dispose();
    _deptCodeController.dispose();
    _hodNameController.dispose();
    _hodEmailController.dispose();
    _hodLoginIdController.dispose();
    _hodPasswordController.dispose();
    _coordNameController.dispose();
    _coordEmailController.dispose();
    _coordLoginIdController.dispose();
    _coordPasswordController.dispose();
    _studentSearchController.dispose();
    _specificStudentsController.dispose();
    super.dispose();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${widget.token}',
  };

  // --- API Methods ---

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
        });
      } else {
        _showError('Failed to fetch departments');
      }
    } catch (e) {
      _showError('Network error');
    } finally {
      setState(() => _isLoadingDepts = false);
    }
  }

  Future<void> _createDepartment() async {
    if (!_deptFormKey.currentState!.validate()) return;
    setState(() => _isActionInProgress = true);

    try {
      final res = await http.post(
        Uri.parse('$_apiBase/coordinator/departments'),
        headers: _headers,
        body: jsonEncode({
          'name': _deptNameController.text.trim(),
          'code': _deptCodeController.text.trim().toUpperCase(),
          'max_semester': _selectedMaxSemester,
        }),
      );

      if (res.statusCode == 201) {
        _deptNameController.clear();
        _deptCodeController.clear();
        setState(() => _selectedMaxSemester = 8);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Department created successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF1A2744),
          ),
        );
        _fetchDepartments();
      } else {
        final err = jsonDecode(res.body);
        _showError(err['message'] ?? 'Failed to create department');
      }
    } catch (e) {
      _showError('Network error');
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _deleteDepartment(String id) async {
    setState(() => _isActionInProgress = true);
    try {
      final res = await http.delete(
        Uri.parse('$_apiBase/coordinator/departments/$id'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Department deleted',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF1A2744),
          ),
        );
        _fetchDepartments();
      } else {
        final err = jsonDecode(res.body);
        _showError(err['message'] ?? 'Failed to delete department');
      }
    } catch (e) {
      _showError('Network error');
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _fetchStaff() async {
    setState(() => _isLoadingStaff = true);
    try {
      final res = await http.get(
        Uri.parse('$_apiBase/superadmin/staff'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        setState(() {
          _staff = jsonDecode(res.body);
        });
      }
    } catch (e) {
      _showError('Failed to fetch staff');
    } finally {
      setState(() => _isLoadingStaff = false);
    }
  }

  Future<void> _createHod() async {
    if (!_hodFormKey.currentState!.validate()) return;
    if (_selectedHodDeptId == null) {
      _showError('Please select a department');
      return;
    }
    setState(() => _isActionInProgress = true);

    try {
      final res = await http.post(
        Uri.parse('$_apiBase/superadmin/hods'),
        headers: _headers,
        body: jsonEncode({
          'name': _hodNameController.text.trim(),
          'email': _hodEmailController.text.trim(),
          'login_id': _hodLoginIdController.text.trim(),
          'password': _hodPasswordController.text,
          'department_id': _selectedHodDeptId,
        }),
      );

      if (res.statusCode == 201) {
        _hodNameController.clear();
        _hodEmailController.clear();
        _hodLoginIdController.clear();
        _hodPasswordController.clear();
        setState(() => _selectedHodDeptId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'HOD created successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF1A2744),
          ),
        );
        _fetchStaff();
      } else {
        final err = jsonDecode(res.body);
        _showError(err['message'] ?? 'Failed to create HOD');
      }
    } catch (e) {
      _showError('Network error');
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _createCoordinator() async {
    if (!_coordFormKey.currentState!.validate()) return;
    setState(() => _isActionInProgress = true);

    try {
      final res = await http.post(
        Uri.parse('$_apiBase/superadmin/coordinators'),
        headers: _headers,
        body: jsonEncode({
          'name': _coordNameController.text.trim(),
          'email': _coordEmailController.text.trim(),
          'login_id': _coordLoginIdController.text.trim(),
          'password': _coordPasswordController.text,
        }),
      );

      if (res.statusCode == 201) {
        _coordNameController.clear();
        _coordEmailController.clear();
        _coordLoginIdController.clear();
        _coordPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Coordinator created successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF1A2744),
          ),
        );
        _fetchStaff();
      } else {
        final err = jsonDecode(res.body);
        _showError(err['message'] ?? 'Failed to create Coordinator');
      }
    } catch (e) {
      _showError('Network error');
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _deleteUser(int id) async {
    setState(() => _isActionInProgress = true);
    try {
      final res = await http.delete(
        Uri.parse('$_apiBase/superadmin/users/$id'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'User deleted',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF1A2744),
          ),
        );
        _fetchStaff();
      } else {
        final err = jsonDecode(res.body);
        _showError(err['message'] ?? 'Failed to delete user');
      }
    } catch (e) {
      _showError('Network error');
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _fetchPromotionOverview() async {
    setState(() => _isLoadingPromotion = true);
    try {
      final res = await http.get(
        Uri.parse('$_apiBase/superadmin/promotion/overview'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        setState(() {
          _promotionOverview = jsonDecode(res.body);
        });
      }
    } catch (e) {
      _showError('Failed to fetch promotion overview');
    } finally {
      setState(() => _isLoadingPromotion = false);
    }
  }

  Future<void> _previewPromotion() async {
    setState(() => _isActionInProgress = true);
    try {
      final body = <String, dynamic>{};
      if (_selectedPromotionDeptId == 'Specific Department' &&
          _specificDeptId != null) {
        body['department_id'] = _specificDeptId;
      } else if (_selectedPromotionDeptId == 'Specific Semesters' &&
          _selectedSemesters.isNotEmpty) {
        body['semesters'] = _selectedSemesters.toList();
      } else if (_selectedPromotionDeptId == 'Selected Students (IDs)' &&
          _specificStudentsController.text.isNotEmpty) {
        body['student_ids'] = _specificStudentsController.text
            .split(',')
            .map((s) => s.trim().toUpperCase())
            .toList();
      }

      final res = await http.post(
        Uri.parse('$_apiBase/superadmin/promotion/preview'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _promotionPreviewResult = data;
          _promotionScopeBody = body;
        });
      } else {
        final err = jsonDecode(res.body);
        _showError(err['message'] ?? 'Failed to preview promotion');
      }
    } catch (e) {
      _showError('Network error');
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _executePromotion(Map<String, dynamic> scopeBody) async {
    setState(() => _isActionInProgress = true);
    try {
      final body = {
        ...scopeBody,
        'confirm': true,
        'activate_next_session': _markNextActive,
      };

      final res = await http.post(
        Uri.parse('$_apiBase/superadmin/promotion/execute'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Promotion executed successfully!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF1DE9B6),
          ),
        );
        setState(() {
          _promotionPreviewResult = null;
          _promotionScopeBody = null;
        });
        _fetchPromotionOverview(); // Refresh overview/logs
      } else {
        final err = jsonDecode(res.body);
        _showError(err['message'] ?? 'Failed to execute promotion');
      }
    } catch (e) {
      _showError('Network error');
    } finally {
      setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoadingStudents = true);
    try {
      final res = await http.get(
        Uri.parse('$_apiBase/tlfq/students?limit=1000'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _allStudents = data['students'] ?? [];
          _filteredStudents = _allStudents;
          _studentCurrentPage = 1;
        });
      }
    } catch (e) {
      _showError('Failed to fetch students');
    } finally {
      setState(() => _isLoadingStudents = false);
    }
  }

  void _filterStudents(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredStudents = _allStudents;
        _studentCurrentPage = 1;
      });
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((s) {
        final anon = (s['unique_feedback_id'] ?? '').toString().toLowerCase();
        final name = (s['name'] ?? '').toString().toLowerCase();
        final sid = (s['student_id'] ?? '').toString().toLowerCase();
        return anon.contains(q) || name.contains(q) || sid.contains(q);
      }).toList();
      _studentCurrentPage = 1;
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFE53935)),
    );
  }

  // --- UI Build ---
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
            icon: const Icon(Icons.menu, color: primaryNavy),
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
          // White overlay with blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
              child: Container(
                color: Colors.white.withAlpha(
                  (0.5 * 255).round(),
                ), // Lighter overlay
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentRed.withAlpha(25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: accentRed,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'User Management',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create and manage departments, HODs,\ncoordinators & student records',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blueGrey.shade700,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Semester Change Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.sync, size: 16, color: Colors.white),
                  label: const Text(
                    'SEMESTER CHANGE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildTab(
                      'Departments',
                      Icons.business,
                      'DEPARTMENTS',
                      _deptKey,
                    ),
                    const SizedBox(width: 16),
                    _buildTab('HODs', Icons.people_outline, 'HODS', _hodKey),
                    const SizedBox(width: 16),
                    _buildTab(
                      'Coordinators',
                      Icons.admin_panel_settings,
                      'COORDINATORS',
                      _coordKey,
                    ),
                    const SizedBox(width: 16),
                    _buildTab(
                      'Acad. Promotion',
                      Icons.trending_up,
                      'ACADEMIC PROMOTION',
                      _promoKey,
                    ),
                    const SizedBox(width: 16),
                    _buildTab(
                      'Student Lookup',
                      Icons.school,
                      'STUDENT LOOKUP',
                      _studentKey,
                    ),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: _activeTab == 'Departments'
                    ? _buildDepartmentsTab(primaryNavy, textSecondary)
                    : _activeTab == 'HODs'
                    ? _buildHodsTab(primaryNavy, textSecondary)
                    : _activeTab == 'Coordinators'
                    ? _buildCoordinatorsTab(primaryNavy, textSecondary)
                    : _activeTab == 'Acad. Promotion'
                    ? _buildPromotionTab(primaryNavy, textSecondary)
                    : _activeTab == 'Student Lookup'
                    ? _buildStudentLookupTab(primaryNavy, textSecondary)
                    : Center(
                        child: Text(
                          '$_activeTab content not implemented yet.',
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
              ),
            ],
          ),
          if (_isActionInProgress)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
          // Floating Dock
          FloatingDock(
            activeIndex: 1,
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

  Widget _buildTab(String tabId, IconData icon, String label, GlobalKey key) {
    final isActive = _activeTab == tabId;
    final primaryNavy = const Color(0xFF1A2744);

    return InkWell(
      key: key,
      onTap: () {
        if (key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.5, // Center the tab
          );
        }
        setState(() {
          _activeTab = tabId;
          if (_activeTab == 'Departments') {
            _fetchDepartments();
          } else if (_activeTab == 'HODs' || _activeTab == 'Coordinators') {
            if (_departments.isEmpty) _fetchDepartments();
            _fetchStaff();
          } else if (_activeTab == 'Acad. Promotion') {
            if (_departments.isEmpty) _fetchDepartments();
            _fetchPromotionOverview();
          } else if (_activeTab == 'Student Lookup') {
            if (_departments.isEmpty) _fetchDepartments();
            _fetchStudents();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? primaryNavy : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? primaryNavy : Colors.blueGrey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: isActive ? primaryNavy : Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentsTab(Color primaryNavy, Color textSecondary) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // New Department Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _deptFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add, color: primaryNavy, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'NEW DEPARTMENT',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: primaryNavy,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Name
                  Text(
                    'NAME',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _deptNameController,
                    decoration: _inputDecoration(
                      'e.g. B.Tech Computer Science',
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Code
                  Text(
                    'CODE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _deptCodeController,
                    decoration: _inputDecoration('e.g. BCS'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Duration
                  Text(
                    'COURSE DURATION (SEMESTERS)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedMaxSemester,
                    items: [2, 4, 6, 8, 10].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(
                          '$value Semesters (${value / 2} Years)',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedMaxSemester = v!),
                    decoration: _inputDecoration(''),
                  ),
                  const SizedBox(height: 24),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createDepartment,
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'CREATE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryNavy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // All Departments List
          Row(
            children: [
              Icon(Icons.domain, color: primaryNavy, size: 18),
              const SizedBox(width: 8),
              Text(
                'ALL DEPARTMENTS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: primaryNavy,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_departments.length} TOTAL',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2744),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingDepts)
            const Center(child: CircularProgressIndicator())
          else if (_departments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No departments found.',
                  style: TextStyle(color: textSecondary),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _departments.length,
              itemBuilder: (context, index) {
                final dept = _departments[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.domain,
                          color: Color(0xFFE53935),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dept['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1A2744),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _buildPill(dept['code'] ?? 'N/A'),
                                const SizedBox(width: 8),
                                _buildPill('${dept['max_semester'] ?? 8} SEMS'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFE53935),
                          size: 20,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Department'),
                              content: const Text(
                                'Are you sure you want to delete this department?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _deleteDepartment(dept['id']);
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Color(0xFFE53935)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHodsTab(Color primaryNavy, Color textSecondary) {
    final hodsList = _staff.where((s) => s['role'] == 'hod').toList();
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // New HOD Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _hodFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add, color: primaryNavy, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'NEW HOD',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: primaryNavy,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Full Name
                  Text(
                    'FULL NAME',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _hodNameController,
                    decoration: _inputDecoration('e.g. Dr. Rajesh Kumar'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  Text(
                    'EMAIL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _hodEmailController,
                    decoration: _inputDecoration(
                      'e.g. hod.bcs@invertis.edu.in',
                    ),
                    validator: (v) => v!.isEmpty
                        ? 'Required'
                        : (!v.contains('@') ? 'Invalid email' : null),
                  ),
                  const SizedBox(height: 16),

                  // Login ID
                  Text(
                    'LOGIN ID',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _hodLoginIdController,
                    decoration: _inputDecoration('e.g. HOD1'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Department
                  Text(
                    'DEPARTMENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedHodDeptId,
                    hint: const Text(
                      'Select Department...',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    items: _departments.map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept['id'],
                        child: Text(
                          '${dept['name']} (${dept['code']})',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedHodDeptId = v),
                    decoration: _inputDecoration(''),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  Text(
                    'PASSWORD',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _hodPasswordController,
                    obscureText: _obscureHodPassword,
                    decoration: _inputDecoration('••••••••').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureHodPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => _obscureHodPassword = !_obscureHodPassword,
                        ),
                      ),
                    ),
                    validator: (v) => v!.isEmpty
                        ? 'Required'
                        : (v.length < 6 ? 'Min 6 chars' : null),
                  ),
                  const SizedBox(height: 24),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createHod,
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'CREATE HOD',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryNavy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // All HODs List
          Row(
            children: [
              Icon(Icons.people, color: primaryNavy, size: 18),
              const SizedBox(width: 8),
              Text(
                'ALL HODS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: primaryNavy,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${hodsList.length} TOTAL',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2744),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingStaff)
            const Center(child: CircularProgressIndicator())
          else if (hodsList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No HODs found.',
                  style: TextStyle(color: textSecondary),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hodsList.length,
              itemBuilder: (context, index) {
                final hod = hodsList[index];
                final dept = _departments.firstWhere(
                  (d) => d['id'] == hod['department_id'],
                  orElse: () => {'code': 'N/A'},
                );
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFFE53935),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hod['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1A2744),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _buildPill(dept['code']),
                                const SizedBox(width: 8),
                                _buildPill(hod['student_id'] ?? 'N/A'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFE53935),
                          size: 20,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete HOD'),
                              content: const Text(
                                'Are you sure you want to delete this HOD?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _deleteUser(hod['id']);
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Color(0xFFE53935)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCoordinatorsTab(Color primaryNavy, Color textSecondary) {
    final coordsList = _staff.where((s) => s['role'] == 'coordinator').toList();
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // New Coordinator Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _coordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add, color: primaryNavy, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'NEW COORDINATOR',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: primaryNavy,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Coordinators have university-wide access to manage all departments and resources.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blueGrey.shade700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Full Name
                  Text(
                    'FULL NAME',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _coordNameController,
                    decoration: _inputDecoration('e.g. Academic Coordinator'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  Text(
                    'EMAIL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _coordEmailController,
                    decoration: _inputDecoration(
                      'e.g. coordinator@invertis.edu.in',
                    ),
                    validator: (v) => v!.isEmpty
                        ? 'Required'
                        : (!v.contains('@') ? 'Invalid email' : null),
                  ),
                  const SizedBox(height: 16),

                  // Login ID
                  Text(
                    'LOGIN ID',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _coordLoginIdController,
                    decoration: _inputDecoration('e.g. COORD1'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  Text(
                    'PASSWORD',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _coordPasswordController,
                    obscureText: _obscureCoordPassword,
                    decoration: _inputDecoration('••••••••').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCoordPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => _obscureCoordPassword = !_obscureCoordPassword,
                        ),
                      ),
                    ),
                    validator: (v) => v!.isEmpty
                        ? 'Required'
                        : (v.length < 6 ? 'Min 6 chars' : null),
                  ),
                  const SizedBox(height: 24),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createCoordinator,
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'CREATE COORDINATOR',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryNavy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // All Coordinators List
          Row(
            children: [
              Icon(Icons.people, color: primaryNavy, size: 18),
              const SizedBox(width: 8),
              Text(
                'ALL COORDINATORS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: primaryNavy,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${coordsList.length} ACTIVE',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2744),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingStaff)
            const Center(child: CircularProgressIndicator())
          else if (coordsList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No coordinators found.',
                  style: TextStyle(color: textSecondary),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: coordsList.length,
              itemBuilder: (context, index) {
                final coord = coordsList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.people,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coord['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1A2744),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${coord['email']} • ID: ${coord['student_id'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'University-wide Access',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A2744),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFE53935),
                          size: 20,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Coordinator'),
                              content: const Text(
                                'Are you sure you want to delete this coordinator?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _deleteUser(coord['id']);
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Color(0xFFE53935)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPromotionTab(Color primaryNavy, Color textSecondary) {
    if (_isLoadingPromotion) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_promotionOverview == null) {
      return Center(
        child: Text(
          'Failed to load promotion data',
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    final activeSession = _promotionOverview!['active_session'];
    final nextSession = _promotionOverview!['next_session'];
    final logs = _promotionOverview!['recent_logs'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Academic Session Promotion Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Academic Session Promotion',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2744),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Preview and promote students in bulk with session rollover and audit logging.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey.shade700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Active / Next
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1A2744),
                    ),
                    children: [
                      const TextSpan(
                        text: 'Active: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: activeSession != null
                            ? activeSession['name']
                            : 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const TextSpan(
                        text: ' → Next: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: nextSession != null ? nextSession['name'] : 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Promotion Scope Dropdown
                Text(
                  'PROMOTION SCOPE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedPromotionDeptId ?? 'All Departments',
                  items:
                      [
                        'All Departments',
                        'Specific Department',
                        'Specific Semesters',
                        'Selected Students (IDs)',
                      ].map((scope) {
                        return DropdownMenuItem<String>(
                          value: scope,
                          child: Text(
                            scope,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                  onChanged: (v) =>
                      setState(() => _selectedPromotionDeptId = v),
                  decoration: _inputDecoration(''),
                ),

                // Show extra inputs based on scope
                if (_selectedPromotionDeptId == 'Specific Department') ...[
                  const SizedBox(height: 16),
                  Text(
                    'SELECT DEPARTMENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: _specificDeptId,
                    items: _departments.map((dept) {
                      return DropdownMenuItem<String?>(
                        value: dept['id'],
                        child: Text(
                          '${dept['name']} (${dept['code']})',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _specificDeptId = v),
                    decoration: _inputDecoration('Select a department'),
                  ),
                ] else if (_selectedPromotionDeptId ==
                    'Specific Semesters') ...[
                  const SizedBox(height: 16),
                  Text(
                    'SEMESTERS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(8, (index) {
                      final sem = index + 1;
                      final isSelected = _selectedSemesters.contains(sem);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedSemesters.remove(sem);
                            } else {
                              _selectedSemesters.add(sem);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryNavy : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? primaryNavy
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Sem $sem',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.blueGrey.shade700,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ] else if (_selectedPromotionDeptId ==
                    'Selected Students (IDs)') ...[
                  const SizedBox(height: 16),
                  Text(
                    'ENTER STUDENT IDs (Comma separated)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _specificStudentsController,
                    decoration: _inputDecoration('e.g. BCS001, BCS002'),
                  ),
                ],
                const SizedBox(height: 20),

                // Preview Button
                ElevatedButton(
                  onPressed: _isActionInProgress ? null : _previewPromotion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'PREVIEW',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Checkbox
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _markNextActive,
                        onChanged: (v) =>
                            setState(() => _markNextActive = v ?? false),
                        activeColor: primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mark next academic session as active after promotion',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // PROMOTION PREVIEW CARD
          if (_promotionPreviewResult != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROMOTION PREVIEW',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A2744),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Confirm Button
                  ElevatedButton(
                    onPressed: _isActionInProgress
                        ? null
                        : () => _executePromotion(_promotionScopeBody!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade400,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'CONFIRM PROMOTION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final summary = _promotionPreviewResult!['summary'] ?? {};
                      final stats = [
                        {
                          'label': 'SCANNED',
                          'value': summary['students_scanned'] ?? 0,
                        },
                        {
                          'label': 'TO PROMOTE',
                          'value': summary['to_promote'] ?? 0,
                        },
                        {
                          'label': 'TO GRADUATE',
                          'value': summary['to_graduate'] ?? 0,
                        },
                        {'label': 'SKIPPED', 'value': summary['skipped'] ?? 0},
                      ];

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: stats.map((stat) {
                          return Container(
                            width:
                                (constraints.maxWidth - 16) /
                                2, // 2 items per row
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stat['label'].toString(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey.shade600,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  stat['value'].toString(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1A2744),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Semester Mapping
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SEMESTER MAPPING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A2744),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (ctx) {
                            final transitions =
                                _promotionPreviewResult!['transitions'];
                            if (transitions == null ||
                                (transitions is Map && transitions.isEmpty) ||
                                (transitions is List && transitions.isEmpty)) {
                              return Text(
                                'No transitions available for the selected scope.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey.shade500,
                                ),
                              );
                            }

                            if (transitions is Map) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: transitions.entries
                                    .map(
                                      (e) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          '${e.key} (${e.value} students)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blueGrey.shade700,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                            }
                            return Text(
                              'Transitions ready.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey.shade700,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Blockers
                  Builder(
                    builder: (ctx) {
                      final blockers =
                          _promotionPreviewResult!['blockers']
                              as List<dynamic>?;
                      if (blockers == null || blockers.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange.shade800,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Blockers Found',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Some students cannot be promoted due to missing next-semester section mapping with same section label.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade900,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Promotion History
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.history,
                      color: Color(0xFF1A2744),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'PROMOTION HISTORY',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A2744),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Header row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildHistoryHeader('WHEN', 100),
                      _buildHistoryHeader('ADMIN', 120),
                      _buildHistoryHeader('SCOPE', 100),
                      _buildHistoryHeader('SESSION', 120),
                      _buildHistoryHeader('PROMOTED', 80),
                      _buildHistoryHeader('GRADUATED', 80),
                    ],
                  ),
                ),
                const Divider(height: 24),

                if (logs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No promotion history yet.',
                      style: TextStyle(
                        color: Colors.blueGrey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  // Map logs
                  ...logs.map((log) {
                    final date = DateTime.tryParse(
                      log['promoted_at'] ?? '',
                    )?.toLocal();
                    final dateStr = date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Unknown';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildHistoryCell(dateStr, 100),
                            _buildHistoryCell(
                              log['admin']?['name'] ?? 'System',
                              120,
                            ),
                            _buildHistoryCell(
                              log['department']?['code'] ?? 'ALL',
                              100,
                            ),
                            _buildHistoryCell(
                              '${log['from_session']?['name'] ?? ''} → ${log['to_session']?['name'] ?? ''}',
                              120,
                            ),
                            _buildHistoryCell(
                              '${log['promoted_count'] ?? 0}',
                              80,
                              isBold: true,
                            ),
                            _buildHistoryCell(
                              '${log['graduated_count'] ?? 0}',
                              80,
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildHistoryCell(String text, double width, {bool isBold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: const Color(0xFF1A2744),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStudentLookupTab(Color primaryNavy, Color textSecondary) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Student Directory Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Color(0xFF1A2744),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Student Directory',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2744),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Find and manage student records',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Search by Anonymous ID (e.g. ANO-A3F281), name, or college ID to find and view student records.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Search Bar
                TextField(
                  controller: _studentSearchController,
                  onChanged: _filterStudents,
                  decoration: InputDecoration(
                    hintText: 'Search by Anonymous ID, name, or...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.grey.shade200,
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
                ),
                const SizedBox(height: 16),

                // Total Counter
                Row(
                  children: [
                    const Icon(
                      Icons.grid_3x3,
                      size: 14,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Total:  ${_filteredStudents.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2744),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_isLoadingStudents)
            const Center(child: CircularProgressIndicator())
          else if (_filteredStudents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No students found.',
                  style: TextStyle(color: textSecondary),
                ),
              ),
            )
          else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredStudents
                  .skip((_studentCurrentPage - 1) * _studentsPerPage)
                  .take(_studentsPerPage)
                  .length,
              itemBuilder: (context, index) {
                final studentIndex =
                    (_studentCurrentPage - 1) * _studentsPerPage + index;
                final student = _filteredStudents[studentIndex];
                final anonId = student['unique_feedback_id'] ?? 'ANO-UNKNOWN';
                final isRevealed = _revealedStudentIds.contains(anonId);
                final realName = student['name'] ?? 'Unknown';
                final studentId = student['student_id'] ?? 'N/A';

                String deptCode = 'N/A';
                if (student['department_id'] != null) {
                  final dept = _departments.firstWhere(
                    (d) => d['id'] == student['department_id'],
                    orElse: () => null,
                  );
                  if (dept != null) deptCode = dept['code'] ?? 'N/A';
                }

                // A mock batch/sem text for UI pill
                final batchText = student['batch'] ?? 'Sem 3';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ANONYMOUS ID (PUBLIC)',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                              letterSpacing: 1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1DE9B6).withAlpha(40),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00BFA5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Anonymous ID Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          anonId,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2744),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Bottom Row: Identity & Reveal
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'REAL IDENTITY',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (!isRevealed)
                                  Text(
                                    'Click 👁️ to reveal',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.blueGrey.shade400,
                                    ),
                                  )
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        realName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A2744),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ID: $studentId',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blueGrey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildPill(deptCode),
                                    const SizedBox(width: 8),
                                    _buildPill(batchText),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isRevealed
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: isRevealed
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFF1A2744),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                if (isRevealed) {
                                  _revealedStudentIds.remove(anonId);
                                } else {
                                  _revealedStudentIds.add(anonId);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // Pagination Card
            if (_filteredStudents.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      '${_filteredStudents.length} TOTAL RECORDS',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.blueGrey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),

                    // Prev Button
                    InkWell(
                      onTap: _studentCurrentPage > 1
                          ? () => setState(() => _studentCurrentPage--)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'PREV',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _studentCurrentPage > 1
                                ? const Color(0xFF1A2744)
                                : Colors.blueGrey.shade300,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Current / Total
                    Text(
                      '$_studentCurrentPage / ${(_filteredStudents.length / _studentsPerPage).ceil()}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2744),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Next Button
                    InkWell(
                      onTap:
                          _studentCurrentPage <
                              (_filteredStudents.length / _studentsPerPage)
                                  .ceil()
                          ? () => setState(() => _studentCurrentPage++)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'NEXT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color:
                                _studentCurrentPage <
                                    (_filteredStudents.length /
                                            _studentsPerPage)
                                        .ceil()
                                ? const Color(0xFF1A2744)
                                : Colors.blueGrey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A2744),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1A2744), width: 1.2),
      ),
    );
  }
}
