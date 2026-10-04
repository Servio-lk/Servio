import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../features/home/home_screen.dart';
import '../features/services/services_screen.dart';
import '../features/services/service_detail_screen.dart';
import '../features/services/service_detail_resolver.dart';
import '../features/services/services_providers.dart';
import '../features/bookings/activity_screen.dart';
import '../features/chats/customer_chats_tab_screen.dart';
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
  late final ServicesScreenController _servicesController;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 4).toInt();
    _servicesController = ServicesScreenController();
    _screens = [
      HomeScreen(
        onSearchTap: () {
          _servicesController.openSearch(query: '', focusKeyboard: true);
          setState(() => _selectedIndex = 1);
        },
        onSeeAllServices: () {
          _servicesController.clearSearch();
          setState(() => _selectedIndex = 1);
        },
        onSuggestionTap: (title) {
          final categories = ref.read(serviceCategoriesProvider).asData?.value;
          final detail = resolveServiceDetail(title, categories);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ServiceDetailScreen(data: detail),
            ),
          );
        },
        onOfferTap: (offer) {
          final categories = ref.read(serviceCategoriesProvider).asData?.value;
          final detail = resolveOfferDetail(offer, categories);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ServiceDetailScreen(data: detail),
            ),
          );
        },
      ),
      ServicesScreen(controller: _servicesController),
      const ActivityScreen(),
      CustomerChatsTabScreen(
        onExploreServices: () => setState(() => _selectedIndex = 1),
      ),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _servicesController.dispose();
    super.dispose();
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
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _TabBarItem(
                icon: PhosphorIconsFill.house,
                inactiveIcon: PhosphorIconsBold.house,
                label: 'Home',
                isSelected: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
            ),
            Expanded(
              child: _TabBarItem(
                icon: PhosphorIconsBold.dotsNine,
                inactiveIcon: PhosphorIconsRegular.dotsNine,
                label: 'Services',
                isSelected: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
            ),
            Expanded(
              child: _TabBarItem(
                icon: PhosphorIconsFill.fileMagnifyingGlass,
                inactiveIcon: PhosphorIconsBold.fileMagnifyingGlass,
                label: 'Activity',
                isSelected: _selectedIndex == 2,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
            ),
            Expanded(
              child: _TabBarItem(
                icon: PhosphorIconsFill.chatCircleDots,
                inactiveIcon: PhosphorIconsBold.chatCircleDots,
                label: 'Chat',
                isSelected: _selectedIndex == 3,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
            ),
            Expanded(
              child: _TabBarItem(
                icon: PhosphorIconsFill.userCircle,
                inactiveIcon: PhosphorIconsBold.userCircle,
                label: 'Account',
                isSelected: _selectedIndex == 4,
                onTap: () => setState(() => _selectedIndex = 4),
              ),
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
      child: Padding(
        padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              isSelected ? icon : inactiveIcon,
              size: 24,
              color: isSelected
                  ? Colors.black
                  : Colors.black.withAlpha(128),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    );
  }
}
