import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'report_page.dart';
import 'analytics_page.dart';
import 'settings_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const ReportPage(),
    const AnalyticsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    if (isTablet) {
      // Tablet layout with side navigation
      return Scaffold(
        body: Row(
          children: [
            // Side navigation for tablets
            Container(
              width: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // QR Scanner button at top
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    child: FloatingActionButton(
                      backgroundColor: Colors.blue,
                      onPressed: () {
                        Navigator.pushNamed(context, '/qrpage');
                      },
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Navigation items
                  Expanded(
                    child: Column(
                      children: [
                        _buildSideNavItem(0, Icons.dashboard, 'Dashboard'),
                        _buildSideNavItem(1, Icons.assessment, 'Reports'),
                        _buildSideNavItem(2, Icons.analytics, 'Analytics'),
                        _buildSideNavItem(3, Icons.settings, 'Settings'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),
          ],
        ),
      );
    } else {
      // Mobile layout with bottom navigation
      return Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        floatingActionButton: Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            elevation: 0,
            onPressed: () {
              Navigator.pushNamed(context, '/qrpage');
            },
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            child: BottomAppBar(
              elevation: 0,
              height: 75,
              shape: const CircularNotchedRectangle(),
              color: const Color(0xFF1E1E1E),
              notchMargin: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      0,
                      Icons.dashboard_outlined,
                      Icons.dashboard,
                      'Dashboard',
                    ),
                    _buildNavItem(
                      1,
                      Icons.assessment_outlined,
                      Icons.assessment,
                      'Reports',
                    ),
                    const SizedBox(width: 48), // Space for FAB
                    _buildNavItem(
                      2,
                      Icons.analytics_outlined,
                      Icons.analytics,
                      'Analytics',
                    ),
                    _buildNavItem(
                      3,
                      Icons.settings_outlined,
                      Icons.settings,
                      'Settings',
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

  Widget _buildNavItem(
    int index,
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // If height is very constrained (< 35px), show icon only
              final showTextLabel = constraints.maxHeight >= 35;

              return Container(
                height: constraints.maxHeight,
                padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(isSelected ? 3 : 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          isSelected ? filledIcon : outlinedIcon,
                          color: isSelected
                              ? const Color(0xFF1976D2)
                              : Colors.grey,
                          size: showTextLabel ? 18 : 20,
                        ),
                      ),
                    ),
                    if (showTextLabel) ...[
                      const SizedBox(height: 1),
                      Flexible(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF1976D2)
                                : Colors.grey,
                            fontSize: 8,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSideNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        width: 80,
        constraints: const BoxConstraints(minHeight: 60, maxHeight: 70),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
              size: isSelected ? 26 : 22,
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.grey,
                  fontSize: 8,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
