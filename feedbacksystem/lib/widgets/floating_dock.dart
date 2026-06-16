import 'dart:ui';
import 'package:flutter/material.dart';

class FloatingDock extends StatelessWidget {
  final int activeIndex;
  final Function(int) onTabTapped;
  final bool showUsers;
  final String middleLabel;
  final IconData middleIcon;

  const FloatingDock({
    super.key,
    required this.activeIndex,
    required this.onTabTapped,
    this.showUsers = true,
    this.middleLabel = 'Users',
    this.middleIcon = Icons.group_rounded,
  });

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF1A2744);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(50),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Colors.white.withAlpha(100),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              color: Colors.white.withAlpha(80),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DockItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isActive: activeIndex == 0,
                    onTap: () => onTabTapped(0),
                    activeColor: primaryNavy,
                  ),
                  if (showUsers) ...[
                    const SizedBox(width: 8),
                    _DockItem(
                      icon: middleIcon,
                      label: middleLabel,
                      isActive: activeIndex == 1,
                      onTap: () => onTabTapped(1),
                      activeColor: primaryNavy,
                    ),
                  ],
                  const SizedBox(width: 8),
                  _DockItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    isActive: activeIndex == 2,
                    onTap: () => onTabTapped(2),
                    activeColor: primaryNavy,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : activeColor.withAlpha(180),
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
