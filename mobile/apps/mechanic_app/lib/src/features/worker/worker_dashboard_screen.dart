import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'worker_providers.dart';
import '../navigation/mechanic_side_drawer.dart';
import '../notifications/notifications_sheet.dart';
import '../jobs/jobs_tab_screen.dart';
import '../chats/chats_tab_screen.dart';
import '../inventory/inventory_tab_screen.dart';
import '../inventory/request_parts_sheet.dart';
import '../staff/staff_tab_screen.dart';

class WorkerDashboardScreen extends ConsumerStatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  ConsumerState<WorkerDashboardScreen> createState() =>
      _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends ConsumerState<WorkerDashboardScreen> {
  int _selectedTab = 0; // 0: Jobs, 1: Chats, 2: Inventory, 3: Staff
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _tabRegularIcons = [
    PhosphorIconsRegular.wrench,
    PhosphorIconsRegular.chatCircleDots,
    PhosphorIconsRegular.package,
    PhosphorIconsRegular.users,
  ];
  static const _tabFillIcons = [
    PhosphorIconsFill.wrench,
    PhosphorIconsFill.chatCircleDots,
    PhosphorIconsFill.package,
    PhosphorIconsFill.users,
  ];
  static const _tabLabels = ['Jobs', 'Chats', 'Inventory', 'Staff'];

  @override
  Widget build(BuildContext context) {
    final mechanicAsync = ref.watch(currentMechanicProvider);
    final mechanic = mechanicAsync.asData?.value;
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadNotificationCount = notificationsAsync.asData?.value
            .where((n) => !n.isRead)
            .length ??
        0;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const MechanicSideDrawer(),
      backgroundColor: const Color(0xFFFFF7F5),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF7F5), Color(0xFFFBFBFB)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Top Header with Sidemenu, Search Bar & Notification Bell ──
              _buildTopHeader(unreadNotificationCount),

              // Verification Banner if profile incomplete
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildVerificationBanner(mechanic),
              ),

              // ── Active Tab Content ────────────────────────────────────────
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: const [
                    JobsTabScreen(),
                    ChatsTabScreen(),
                    InventoryTabScreen(),
                    StaffTabScreen(),
                  ],
                ),
              ),

              // ── Modern 4-Tab Navigation Bar ───────────────────────────────
              _buildTabBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Header Bar ────────────────────────────────────────────────────────
  Widget _buildTopHeader(int unreadCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          // Left Sidemenu Hamburger Icon (User Comment)
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const PhosphorIcon(PhosphorIconsBold.list, size: 26, color: Colors.black87),
            tooltip: 'Menu',
          ),
          const SizedBox(width: 4),

          // Center Search for Parts Field with Request Button
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE7DF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  const PhosphorIcon(
                    PhosphorIconsRegular.magnifyingGlass,
                    size: 20,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTab = 2); // Switch to inventory tab
                      },
                      child: Text(
                        'Search parts...',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.black.withValues(alpha: 0.15),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: InkWell(
                      onTap: () => RequestPartsSheet.show(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5D2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const PhosphorIcon(
                              PhosphorIconsFill.package,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Request',
                              style: GoogleFonts.instrumentSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Right Notification Bell with Unread Badge (Replaces Logout Button)
          IconButton(
            onPressed: () => NotificationsSheet.show(context),
            icon: Stack(
              children: [
                const PhosphorIcon(
                  PhosphorIconsRegular.bell,
                  size: 26,
                  color: Colors.black87,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5D2E),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: GoogleFonts.instrumentSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notifications',
          ),
        ],
      ),
    );
  }

  // ── Verification Banner ───────────────────────────────────────────────────
  Widget _buildVerificationBanner(Map<String, dynamic>? mechanic) {
    if (mechanic == null) return const SizedBox.shrink();
    final status =
        (mechanic['verification_status'] as String?)?.toUpperCase() ?? 'VERIFIED';
    if (status == 'VERIFIED') return const SizedBox.shrink();

    final bool isIncomplete = status == 'INCOMPLETE';
    final bool isPending = status == 'PENDING_VERIFICATION';
    final String? rejectionReason = mechanic['rejection_reason'] as String?;

    final Color bg;
    final Color borderColor;
    final Color titleColor;
    final Color textColor;
    final IconData icon;
    final Color iconColor;
    final String title;
    final String description;
    final String buttonText;
    final Color buttonBg;

    if (isIncomplete) {
      bg = const Color(0xFFFFF2ED);
      borderColor = const Color(0xFFFFD0C1);
      titleColor = const Color(0xFFC03A12);
      textColor = const Color(0xFF7C2D12);
      icon = PhosphorIconsFill.identificationCard;
      iconColor = const Color(0xFFFF5D2E);
      title = 'Complete Your Profile';
      description =
          'Finish adding your qualifications, work details, and documents to start receiving job assignments.';
      buttonText = 'Complete Profile';
      buttonBg = const Color(0xFFFF5D2E);
    } else if (isPending) {
      bg = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      titleColor = const Color(0xFF92400E);
      textColor = const Color(0xFF78350F);
      icon = PhosphorIconsFill.hourglass;
      iconColor = const Color(0xFFD97706);
      title = 'Verification Pending';
      description =
          'Your details have been submitted to the admin team for review. You will be notified once approved.';
      buttonText = 'View Submission';
      buttonBg = const Color(0xFFD97706);
    } else {
      bg = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      titleColor = const Color(0xFF991B1B);
      textColor = const Color(0xFF7F1D1D);
      icon = PhosphorIconsFill.warningOctagon;
      iconColor = const Color(0xFFDC2626);
      title = 'Verification Changes Requested';
      description = (rejectionReason != null && rejectionReason.isNotEmpty)
          ? 'Admin noted: "$rejectionReason". Tap below to update your details and resubmit.'
          : 'Your verification was returned for changes. Please review and update your information.';
      buttonText = 'Update Details';
      buttonBg = const Color(0xFFDC2626);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(icon, size: 22, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 12,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              context.push('/profile/complete').then((_) {
                ref.invalidate(currentMechanicProvider);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonBg,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              buttonText,
              style: GoogleFonts.instrumentSans(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Tab Bar (Jobs, Chats, Inventory, Staff) ────────────────────────
  Widget _buildTabBar() {
    final bottomInset = math.max(MediaQuery.paddingOf(context).bottom, 16.0);
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 0.5,
            color: Colors.black.withValues(alpha: 0.1),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset),
            child: Row(
              children: List.generate(4, (i) {
                final bool isActive = _selectedTab == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = i),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          PhosphorIcon(
                            isActive ? _tabFillIcons[i] : _tabRegularIcons[i],
                            size: 24,
                            color: isActive
                                ? const Color(0xFFFF5D2E)
                                : Colors.black.withValues(alpha: 0.45),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _tabLabels[i],
                            style: GoogleFonts.instrumentSans(
                              fontSize: 12,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isActive
                                  ? const Color(0xFFFF5D2E)
                                  : Colors.black.withValues(alpha: 0.55),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          if (isActive)
                            Container(
                              width: 18,
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5D2E),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )
                          else
                            const SizedBox(height: 3),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
