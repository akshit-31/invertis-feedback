import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screens/superadmin/superadmin_dashboard.dart';
import '../screens/supreme/supreme_dashboard.dart';
import '../screens/superadmin/user_management_screen.dart';
import '../screens/supreme/identity_reveal_screen.dart';
import '../screens/coordinator/coordinator_hub.dart';
import '../screens/shared/leaderboard_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/shared/analytics_screen.dart';
import '../screens/shared/profile_sheet.dart';
import '../screens/hod/hod_dashboard.dart';

class AppDrawer extends StatefulWidget {
  final String token;
  final String userName;
  final String userRole;
  final String activeDrawerItem;
  final String activeSubItem;
  final ImageProvider<Object>? profileImage;

  const AppDrawer({
    super.key,
    required this.token,
    required this.userName,
    required this.userRole,
    required this.activeDrawerItem,
    this.activeSubItem = '',
    this.profileImage,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late String _activeDrawerItem;
  late String _activeSubItem;
  String? _profilePicUrl;
  final Color primaryNavy = const Color(0xFF1A2744);
  final Color accentRed = const Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _activeDrawerItem = widget.activeDrawerItem;
    _activeSubItem = widget.activeSubItem;
    _fetchProfilePic();
  }

  Future<void> _fetchProfilePic() async {
    try {
      final response = await http.get(
        Uri.parse('https://invertis-feedback-system-0chx.onrender.com/api/auth/profile-data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'] ?? {};
        final pic = user['profile_photo'] ?? user['profile_pic'] ?? user['profile_pic_url'] ?? user['url'];
        if (pic != null && pic.toString().isNotEmpty) {
          setState(() {
            _profilePicUrl = pic.toString();
          });
        }
      }
    } catch (_) {}
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).pop(); // Close drawer
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _pushScreen(BuildContext context, Widget screen) {
    Navigator.of(context).pop(); // Close drawer
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  ImageProvider<Object>? _getProfileImage() {
    if (_profilePicUrl != null && _profilePicUrl!.isNotEmpty) {
      if (_profilePicUrl!.startsWith('data:image')) {
        try {
          final base64String = _profilePicUrl!.split(',').last;
          return MemoryImage(base64Decode(base64String));
        } catch (e) {
          return widget.profileImage;
        }
      } else if (_profilePicUrl!.startsWith('http')) {
        return NetworkImage(_profilePicUrl!);
      }
    }
    return widget.profileImage;
  }

  @override
  Widget build(BuildContext context) {
    final String initial = widget.userName.isNotEmpty
        ? widget.userName[0].toUpperCase()
        : 'S';

    final ImageProvider<Object>? currentProfileImage = _getProfileImage();

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header
          Container(
            color: primaryNavy,
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 18,
                  backgroundImage: currentProfileImage,
                  child: currentProfileImage == null
                      ? Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        widget.userRole.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              physics: const BouncingScrollPhysics(),
              children: _buildDrawerItems(),
            ),
          ),

          // Bottom "My Profile" button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => ProfileSheet(token: widget.token),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primaryNavy,
                      radius: 14,
                      backgroundImage: currentProfileImage,
                      child: currentProfileImage == null 
                          ? const Icon(
                              Icons.person_outline,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'My Profile',
                      style: TextStyle(
                        color: primaryNavy,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerItems() {
    final role = widget.userRole.toLowerCase();

    if (role == 'student') {
      return [
        _drawerItem(
          icon: Icons.dashboard_customize_outlined,
          text: 'Dashboard',
          isSelected: _activeDrawerItem == 'Dashboard',
          onTap: () {
            if (widget.activeDrawerItem != 'Dashboard') {
              _navigateToScreen(
                context,
                StudentDashboard(
                  token: widget.token,
                  userName: widget.userName,
                  userRole: widget.userRole,
                  initialTab: 'Dashboard',
                ),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        _drawerItem(
          icon: Icons.emoji_events_outlined,
          text: 'Leaderboard',
          isSelected: _activeDrawerItem == 'Leaderboard',
          onTap: () {
            if (widget.activeDrawerItem == 'Leaderboard') {
              Navigator.of(context).pop();
            } else {
              _pushScreen(
                context,
                LeaderboardScreen(
                  token: widget.token,
                  userName: widget.userName,
                  userRole: widget.userRole,
                ),
              );
            }
          },
        ),
      ];
    }
    
    if (role == 'hod') {
      return [
        _drawerItem(
          icon: Icons.dashboard_customize_outlined,
          text: 'Dashboard',
          isSelected: _activeDrawerItem == 'Dashboard',
          onTap: () {
            if (widget.activeDrawerItem != 'Dashboard') {
              _navigateToScreen(
                context,
                HodDashboard(
                  token: widget.token,
                  userName: widget.userName,
                  userRole: widget.userRole,
                  initialTab: 'Dashboard',
                ),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        _drawerItem(
          icon: Icons.public_outlined,
          text: 'Identity Reveal',
          isSelected: _activeDrawerItem == 'Identity Reveal',
          onTap: () {
            if (widget.activeDrawerItem == 'Identity Reveal') {
              Navigator.of(context).pop();
            } else {
              _pushScreen(
                context,
                IdentityRevealScreen(
                  token: widget.token,
                  userName: widget.userName,
                  userRole: widget.userRole,
                ),
              );
            }
          },
        ),
        _drawerItem(
          icon: Icons.bar_chart_outlined,
          text: 'Analytics',
          isSelected: _activeDrawerItem == 'Analytics',
          onTap: () {
            if (widget.activeDrawerItem == 'Analytics') {
              Navigator.of(context).pop();
            } else {
              _navigateToScreen(
                context,
                AnalyticsScreen(
                  token: widget.token,
                  userName: widget.userName,
                  userRole: widget.userRole,
                  initialTab: 'Faculty Rankings',
                ),
              );
            }
          },
        ),
        _drawerItem(
          icon: Icons.emoji_events_outlined,
          text: 'Leaderboard',
          isSelected: _activeDrawerItem == 'Leaderboard',
          onTap: () {
            if (widget.activeDrawerItem == 'Leaderboard') {
              Navigator.of(context).pop();
            } else {
              _pushScreen(
                context,
                LeaderboardScreen(
                  token: widget.token,
                  userName: widget.userName,
                  userRole: widget.userRole,
                ),
              );
            }
          },
        ),
        if (_activeDrawerItem == 'Dashboard') ...[
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 12, bottom: 4),
            child: Text(
              'ON THIS PAGE',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          _buildSubDrawerItem('Welcome', Icons.waving_hand_outlined, () {
            setState(() => _activeSubItem = 'Welcome');
            _navigateToScreen(
              context,
              HodDashboard(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Welcome',
              ),
            );
          }),
          _buildSubDrawerItem('Sections', Icons.layers_outlined, () {
            setState(() => _activeSubItem = 'Sections');
            _navigateToScreen(
              context,
              HodDashboard(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Sections',
              ),
            );
          }),
          _buildSubDrawerItem('Create Form', Icons.add_box_outlined, () {
            setState(() => _activeSubItem = 'Create Form');
            _navigateToScreen(
              context,
              HodDashboard(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Create Form',
              ),
            );
          }),
        ],
        if (_activeDrawerItem == 'Analytics') ...[
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 12, bottom: 4),
            child: Text(
              'ON THIS PAGE',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          _buildSubDrawerItem('Faculty Rankings', Icons.military_tech_outlined, () {
            setState(() => _activeSubItem = 'Faculty Rankings');
            _navigateToScreen(
              context,
              AnalyticsScreen(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Faculty Rankings',
              ),
            );
          }),
          _buildSubDrawerItem('Attribute Analysis', Icons.show_chart, () {
            setState(() => _activeSubItem = 'Attribute Analysis');
            _navigateToScreen(
              context,
              AnalyticsScreen(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Attribute Analysis',
              ),
            );
          }),
          _buildSubDrawerItem('Department Overview', Icons.people_outline, () {
            setState(() => _activeSubItem = 'Department Overview');
            _navigateToScreen(
              context,
              AnalyticsScreen(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Department Overview',
              ),
            );
          }),
          _buildSubDrawerItem('Submission Trends', Icons.trending_up, () {
            setState(() => _activeSubItem = 'Submission Trends');
            _navigateToScreen(
              context,
              AnalyticsScreen(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Submission Trends',
              ),
            );
          }),
          _buildSubDrawerItem('Course Reports', Icons.menu_book, () {
            setState(() => _activeSubItem = 'Course Reports');
            _navigateToScreen(
              context,
              AnalyticsScreen(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Course Reports',
              ),
            );
          }),
          _buildSubDrawerItem('Feedback Insights', Icons.chat_bubble_outline, () {
            setState(() => _activeSubItem = 'Feedback Insights');
            _navigateToScreen(
              context,
              AnalyticsScreen(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Feedback Insights',
              ),
            );
          }),
        ],
      ];
    }

    // If role is coordinator, return only the specific layout you asked for
    if (role == 'coordinator') {
      return [
        _drawerItem(
          icon: Icons.dashboard_customize_outlined,
          text: 'Dashboard',
          isSelected:
              _activeDrawerItem == 'Coordinator' ||
              _activeDrawerItem == 'Dashboard',
          onTap: () {
            if (widget.activeDrawerItem != 'Coordinator' &&
                widget.activeDrawerItem != 'Dashboard') {
              _navigateToScreen(
                context,
                CoordinatorHub(
                  token: widget.token,
                  userName: widget.userName,
                  userRole: widget.userRole,
                  initialTab: 'Sections',
                ),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        _drawerItem(
          icon: Icons.emoji_events_outlined,
          text: 'Leaderboard',
          isSelected: _activeDrawerItem == 'Leaderboard',
          onTap: () {
            if (widget.activeDrawerItem == 'Leaderboard') {
              Navigator.of(context).pop();
            } else {
              _pushScreen(
                context,
                LeaderboardScreen(
                  token: widget.token,
                  userName: widget.userName,
                  userRole: widget.userRole,
                ),
              );
            }
          },
        ),
        if (_activeDrawerItem == 'Coordinator' ||
            _activeDrawerItem == 'Dashboard') ...[
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 12, bottom: 4),
            child: Text(
              'ON THIS PAGE',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          _buildSubDrawerItem('Sections', Icons.layers_outlined, () {
            setState(() => _activeSubItem = 'Sections');
            _navigateToScreen(
              context,
              CoordinatorHub(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Sections',
              ),
            );
          }),
          _buildSubDrawerItem('Courses', Icons.menu_book_outlined, () {
            setState(() => _activeSubItem = 'Courses');
            _navigateToScreen(
              context,
              CoordinatorHub(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Courses',
              ),
            );
          }),
          _buildSubDrawerItem('Faculty', Icons.people_outline, () {
            setState(() => _activeSubItem = 'Faculty');
            _navigateToScreen(
              context,
              CoordinatorHub(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Faculty',
              ),
            );
          }),
          _buildSubDrawerItem('Students', Icons.school_outlined, () {
            setState(() => _activeSubItem = 'Students');
            _navigateToScreen(
              context,
              CoordinatorHub(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Students',
              ),
            );
          }),
        ],
      ];
    }

    // Default layout for supreme, superadmin, etc.
    return [
      _drawerItem(
        icon: role == 'supreme'
            ? Icons.workspace_premium_outlined
            : Icons.dashboard_customize_outlined,
        text: role == 'supreme' ? 'Supreme Panel' : 'Dashboard',
        isSelected:
            _activeDrawerItem == 'Supreme Panel' ||
            _activeDrawerItem == 'Dashboard',
        onTap: () {
          final String target = role == 'supreme'
              ? 'Supreme Panel'
              : 'Dashboard';
          if (widget.activeDrawerItem == target) {
            Navigator.of(context).pop();
            return;
          }
          if (role == 'supreme') {
            _navigateToScreen(
              context,
              SupremeDashboard(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
              ),
            );
          } else {
            _navigateToScreen(
              context,
              SuperadminDashboard(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
              ),
            );
          }
        },
      ),
      _drawerItem(
        icon: Icons.shield_outlined,
        text: 'User Management',
        isSelected: _activeDrawerItem == 'User Management',
        onTap: () {
          setState(() {
            if (_activeDrawerItem == 'User Management') {
              _activeDrawerItem = 'Supreme Panel'; // Collapse
            } else {
              _activeDrawerItem = 'User Management';
              _activeSubItem = 'Departments';
            }
          });
          if (widget.activeDrawerItem != 'User Management') {
            _navigateToScreen(
              context,
              UserManagementScreen(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Departments',
              ),
            );
          }
        },
      ),
      _drawerItem(
        icon: Icons.public_outlined,
        text: 'Identity Reveal',
        isSelected: _activeDrawerItem == 'Identity Reveal',
        onTap: () {
          if (widget.activeDrawerItem == 'Identity Reveal') {
            Navigator.of(context).pop();
            return;
          }
          _pushScreen(
            context,
            IdentityRevealScreen(
              token: widget.token,
              userName: widget.userName,
              userRole: widget.userRole,
            ),
          );
        },
      ),
      _drawerItem(
        icon: Icons.people_outline,
        text: 'Coordinator',
        isSelected: _activeDrawerItem == 'Coordinator',
        onTap: () {
          setState(() {
            if (_activeDrawerItem == 'Coordinator') {
              _activeDrawerItem = 'Supreme Panel'; // Collapse
            } else {
              _activeDrawerItem = 'Coordinator';
              _activeSubItem = 'Sections';
            }
          });
          if (widget.activeDrawerItem != 'Coordinator') {
            _navigateToScreen(
              context,
              CoordinatorHub(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Sections',
              ),
            );
          }
        },
      ),
      _drawerItem(
        icon: Icons.bar_chart_outlined,
        text: 'Analytics',
        isSelected: _activeDrawerItem == 'Analytics',
        onTap: () {
          setState(() {
            if (_activeDrawerItem == 'Analytics') {
              _activeDrawerItem = 'Supreme Panel';
            } else {
              _activeDrawerItem = 'Analytics';
              if (_activeSubItem.isEmpty ||
                  ![
                    'Faculty Rankings',
                    'Attribute Analysis',
                    'Department Overview',
                    'Submission Trends',
                    'Course Reports',
                    'Feedback Insights',
                  ].contains(_activeSubItem)) {
                _activeSubItem = 'Faculty Rankings';
              }
            }
          });
          if (widget.activeDrawerItem != 'Analytics') {
            _navigateToScreen(
              context,
              AnalyticsScreen(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Faculty Rankings',
              ),
            );
          }
        },
      ),
      _drawerItem(
        icon: Icons.emoji_events_outlined,
        text: 'Leaderboard',
        isSelected: _activeDrawerItem == 'Leaderboard',
        onTap: () {
          if (widget.activeDrawerItem == 'Leaderboard') {
            Navigator.of(context).pop();
            return;
          }
          _pushScreen(
            context,
            LeaderboardScreen(
              token: widget.token,
              userName: widget.userName,
              userRole: widget.userRole,
            ),
          );
        },
      ),

      // --- ON THIS PAGE Sub-items ---
      if (_activeDrawerItem == 'User Management') ...[
        Padding(
          padding: const EdgeInsets.only(left: 24, top: 12, bottom: 4),
          child: Text(
            'ON THIS PAGE',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        _buildSubDrawerItem('Departments', Icons.business, () {
          setState(() => _activeSubItem = 'Departments');
          _navigateToScreen(
            context,
            UserManagementScreen(
              token: widget.token,
              userName: widget.userName,
              userRole: widget.userRole,
              initialTab: 'Departments',
            ),
          );
        }),
        _buildSubDrawerItem('HODs', Icons.people_outline, () {
          setState(() => _activeSubItem = 'HODs');
          _navigateToScreen(
            context,
            UserManagementScreen(
              token: widget.token,
              userName: widget.userName,
              userRole: widget.userRole,
              initialTab: 'HODs',
            ),
          );
        }),
        _buildSubDrawerItem('Coordinators', Icons.school_outlined, () {
          setState(() => _activeSubItem = 'Coordinators');
          _navigateToScreen(
            context,
            UserManagementScreen(
              token: widget.token,
              userName: widget.userName,
              userRole: widget.userRole,
              initialTab: 'Coordinators',
            ),
          );
        }),
        _buildSubDrawerItem('Acad. Promotion', Icons.trending_up, () {
          setState(() => _activeSubItem = 'Acad. Promotion');
          _navigateToScreen(
            context,
            UserManagementScreen(
              token: widget.token,
              userName: widget.userName,
              userRole: widget.userRole,
              initialTab: 'Acad. Promotion',
            ),
          );
        }),
        _buildSubDrawerItem('Student Lookup', Icons.search, () {
          setState(() => _activeSubItem = 'Student Lookup');
          _navigateToScreen(
            context,
            UserManagementScreen(
              token: widget.token,
              userName: widget.userName,
              userRole: widget.userRole,
              initialTab: 'Student Lookup',
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
      if (_activeDrawerItem == 'Coordinator') ...[
        Padding(
          padding: const EdgeInsets.only(left: 24, top: 12, bottom: 4),
          child: Text(
            'ON THIS PAGE',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        _buildSubDrawerItem('Sections', Icons.layers_outlined, () {
          setState(() => _activeSubItem = 'Sections');
          _navigateToScreen(
            context,
            CoordinatorHub(
              token: widget.token,
              userName: widget.userName,
              userRole: widget.userRole,
              initialTab: 'Sections',
            ),
          );
        }),
        _buildSubDrawerItem('Courses', Icons.menu_book_outlined, () {
          setState(() => _activeSubItem = 'Courses');
          _navigateToScreen(
            context,
            CoordinatorHub(
              token: widget.token,
              userName: widget.userName,
              userRole: widget.userRole,
              initialTab: 'Courses',
            ),
          );
        }),
        _buildSubDrawerItem('Faculty', Icons.people_outline, () {
          setState(() => _activeSubItem = 'Faculty');
          _navigateToScreen(
            context,
            CoordinatorHub(
              token: widget.token,
              userName: widget.userName,
              userRole: widget.userRole,
              initialTab: 'Faculty',
            ),
          );
        }),
        _buildSubDrawerItem('Students', Icons.school_outlined, () {
          setState(() => _activeSubItem = 'Students');
          _navigateToScreen(
            context,
            CoordinatorHub(
              token: widget.token,
              userName: widget.userName,
              userRole: widget.userRole,
              initialTab: 'Students',
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
      if (_activeDrawerItem == 'Analytics') ...[
        Padding(
          padding: const EdgeInsets.only(left: 24, top: 12, bottom: 4),
          child: Text(
            'ON THIS PAGE',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        _buildSubDrawerItem(
          'Faculty Rankings',
          Icons.military_tech_outlined,
          () {
            setState(() => _activeSubItem = 'Faculty Rankings');
            _navigateToScreen(
              context,
              AnalyticsScreen(
                token: widget.token,
                userName: widget.userName,
                userRole: widget.userRole,
                initialTab: 'Faculty Rankings',
              ),
            );
          },
        ),
        _buildSubDrawerItem('Attribute Analysis', Icons.show_chart, () {
          setState(() => _activeSubItem = 'Attribute Analysis');
          _navigateToScreen(
            context,
            AnalyticsScreen(
              token: widget.token,
              userName: widget.userName,
              userRole: widget.userRole,
              initialTab: 'Attribute Analysis',
            ),
          );
        }),
        _buildSubDrawerItem('Department Overview', Icons.people_outline, () {
          setState(() => _activeSubItem = 'Department Overview');
          _navigateToScreen(
            context,
            AnalyticsScreen(
              token: widget.token,
              userName: widget.userName,
              userRole: widget.userRole,
              initialTab: 'Department Overview',
            ),
          );
        }),
        _buildSubDrawerItem('Submission Trends', Icons.trending_up, () {
          setState(() => _activeSubItem = 'Submission Trends');
          _navigateToScreen(
            context,
            AnalyticsScreen(
              token: widget.token,
              userName: widget.userName,
              userRole: widget.userRole,
              initialTab: 'Submission Trends',
            ),
          );
        }),
        _buildSubDrawerItem('Course Reports', Icons.menu_book, () {
          setState(() => _activeSubItem = 'Course Reports');
          _navigateToScreen(
            context,
            AnalyticsScreen(
              token: widget.token,
              userName: widget.userName,
              userRole: widget.userRole,
              initialTab: 'Course Reports',
            ),
          );
        }),
        _buildSubDrawerItem('Feedback Insights', Icons.chat_bubble_outline, () {
          setState(() => _activeSubItem = 'Feedback Insights');
          _navigateToScreen(
            context,
            AnalyticsScreen(
              token: widget.token,
              userName: widget.userName,
              userRole: widget.userRole,
              initialTab: 'Feedback Insights',
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    ];
  }

  Widget _drawerItem({
    required IconData icon,
    required String text,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Container(
      color: isSelected ? primaryNavy : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : primaryNavy,
          size: 20,
        ),
        title: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : primaryNavy,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      ),
    );
  }

  Widget _buildSubDrawerItem(String text, IconData icon, VoidCallback onTap) {
    const textSecondary = Color(0xFF9E9E9E);
    bool isSelected = _activeSubItem == text;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? accentRed.withAlpha((0.08 * 255).round())
            : Colors.transparent,
        border: isSelected
            ? Border(left: BorderSide(color: accentRed, width: 3))
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? accentRed : textSecondary,
          size: 18,
        ),
        title: Text(
          text,
          style: TextStyle(
            color: isSelected ? accentRed : textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.chevron_right, color: accentRed, size: 18)
            : null,
        dense: true,
        contentPadding: const EdgeInsets.only(left: 32, right: 16),
        onTap: onTap,
      ),
    );
  }
}
