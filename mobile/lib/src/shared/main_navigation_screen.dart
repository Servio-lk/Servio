import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../features/home/home_screen.dart';
import '../features/services/services_screen.dart';
import '../features/bookings/activity_screen.dart';
import '../features/profile/profile_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late int _selectedIndex;

  final List<Widget> _screens = const [
    HomeScreen(),
    ServicesScreen(),
    ActivityScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex =
        widget.initialIndex.clamp(0, _screens.length - 1).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _buildCustomTabBar(),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.2), width: 0.4),
        ),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 4),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TabBarItem(
              icon: PhosphorIconsFill.house,
              inactiveIcon: PhosphorIconsBold.house,
              label: 'Home',
              isSelected: _selectedIndex == 0,
              onTap: () => setState(() => _selectedIndex = 0),
            ),
            const SizedBox(width: 16),
            _TabBarItem(
              icon: PhosphorIconsBold.dotsNine,
              inactiveIcon: PhosphorIconsRegular.dotsNine,
              label: 'Services',
              isSelected: _selectedIndex == 1,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            const SizedBox(width: 16),
            _TabBarItem(
              icon: PhosphorIconsFill.fileMagnifyingGlass,
              inactiveIcon: PhosphorIconsBold.fileMagnifyingGlass,
              label: 'Activity',
              isSelected: _selectedIndex == 2,
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            const SizedBox(width: 16),
            _TabBarItem(
              icon: PhosphorIconsFill.userCircle,
              inactiveIcon: PhosphorIconsBold.userCircle,
              label: 'Account',
              isSelected: _selectedIndex == 3,
              onTap: () => setState(() => _selectedIndex = 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarItem extends StatelessWidget {
  final IconData icon;
  final IconData inactiveIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabBarItem({
    required this.icon,
    required this.inactiveIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 75.75,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              PhosphorIcon(
                isSelected ? icon : inactiveIcon,
                size: 24,
                color: isSelected
                    ? Colors.black
                    : Colors.black.withAlpha(128),
              ),
              const SizedBox(height: 8),
              // Label
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.black
                      : Colors.black.withAlpha(128),
                  height: 22 / 12,
                ),
              ),
              const SizedBox(height: 8),
              // Indicator
              if (isSelected)
                Container(
                  width: 16,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5D2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
              else
                const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}
