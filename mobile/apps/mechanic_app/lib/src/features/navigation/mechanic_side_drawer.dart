import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_core/shared_core.dart';
import '../worker/worker_providers.dart';

class MechanicSideDrawer extends ConsumerWidget {
  const MechanicSideDrawer({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sign Out',
          style: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to sign out from Servio Mechanic?',
          style: GoogleFonts.instrumentSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5D2E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await SupabaseService().signOut();
      if (context.mounted) {
        context.go('/signin');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mechanicAsync = ref.watch(currentMechanicProvider);
    final mechanic = mechanicAsync.asData?.value;
    final fullName = (mechanic?['full_name'] as String?) ?? 'Servio Mechanic';
    final email = (mechanic?['email'] as String?) ?? SupabaseService().currentUser?.email ?? 'mechanic@servio.lk';
    final specialization = (mechanic?['specialization'] as String?) ?? 'Automotive Technician';
    final status = (mechanic?['verification_status'] as String?) ?? 'VERIFIED';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7F5),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFFFE7DF), width: 1),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFFF5D2E),
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'M',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          email,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          specialization,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFFF5D2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: status == 'VERIFIED'
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: status == 'VERIFIED'
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFE65100),
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

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const PhosphorIcon(PhosphorIconsRegular.userCircle, size: 22),
                    title: Text(
                      'My Profile & Credentials',
                      style: GoogleFonts.instrumentSans(fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile/complete');
                    },
                  ),
                  ListTile(
                    leading: const PhosphorIcon(PhosphorIconsRegular.wrench, size: 22),
                    title: Text(
                      'Workshop & Bay Details',
                      style: GoogleFonts.instrumentSans(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Colombo Central Main Workshop',
                      style: GoogleFonts.instrumentSans(fontSize: 12, color: Colors.black54),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const PhosphorIcon(PhosphorIconsRegular.bell, size: 22),
                    title: Text(
                      'Notification Preferences',
                      style: GoogleFonts.instrumentSans(fontWeight: FontWeight.w500),
                    ),
                    trailing: Switch(
                      value: true,
                      activeTrackColor: const Color(0xFFFF5D2E),
                      onChanged: (_) {},
                    ),
                  ),
                  ListTile(
                    leading: const PhosphorIcon(PhosphorIconsRegular.shieldCheck, size: 22),
                    title: Text(
                      'Security & Password',
                      style: GoogleFonts.instrumentSans(fontWeight: FontWeight.w500),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                  const Divider(color: Color(0xFFEEEEEE)),
                  ListTile(
                    leading: const PhosphorIcon(PhosphorIconsRegular.info, size: 22),
                    title: Text(
                      'App Information',
                      style: GoogleFonts.instrumentSans(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Servio Mechanic v1.0.0 (Build 42)',
                      style: GoogleFonts.instrumentSans(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Sign Out
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleSignOut(context),
                  icon: const PhosphorIcon(PhosphorIconsRegular.signOut, size: 20, color: Colors.red),
                  label: Text(
                    'Sign Out',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFFCDD2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
