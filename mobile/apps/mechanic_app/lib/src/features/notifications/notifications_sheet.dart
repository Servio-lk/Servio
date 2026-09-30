import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../worker/worker_providers.dart';

class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsSheet(),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'JOB_ASSIGNED':
        return PhosphorIconsFill.wrench;
      case 'LOW_STOCK':
        return PhosphorIconsFill.warning;
      case 'PART_REQUEST':
        return PhosphorIconsFill.package;
      case 'CHAT_MESSAGE':
        return PhosphorIconsFill.chatCircleText;
      default:
        return PhosphorIconsFill.bell;
    }
  }

  Color _colorForType(String type) {
    switch (type.toUpperCase()) {
      case 'JOB_ASSIGNED':
        return const Color(0xFFFF5D2E);
      case 'LOW_STOCK':
        return const Color(0xFFDC2626);
      case 'PART_REQUEST':
        return const Color(0xFF2563EB);
      case 'CHAT_MESSAGE':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFFFF5D2E);
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final safeBottom = math.max(MediaQuery.paddingOf(context).bottom, 16.0);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, safeBottom + MediaQuery.of(context).viewInsets.bottom),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const PhosphorIcon(
                    PhosphorIconsFill.bell,
                    size: 22,
                    color: Color(0xFFFF5D2E),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Notifications',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  ref.invalidate(notificationsProvider);
                  Navigator.pop(context);
                },
                child: Text(
                  'Mark all read',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF5D2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: notificationsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
                ),
              ),
              error: (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'No notifications available.',
                    style: GoogleFonts.instrumentSans(color: Colors.black54),
                  ),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PhosphorIcon(PhosphorIconsRegular.bellSlash, size: 36, color: Colors.black26),
                          const SizedBox(height: 8),
                          Text('No new notifications', style: GoogleFonts.instrumentSans(color: Colors.black54)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final color = _colorForType(item.type);
                    final icon = _iconForType(item.type);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: PhosphorIcon(icon, size: 20, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: GoogleFonts.instrumentSans(
                                          fontSize: 14,
                                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTimeAgo(item.createdAt),
                                      style: GoogleFonts.instrumentSans(
                                        fontSize: 11,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.message,
                                  style: GoogleFonts.instrumentSans(
                                    fontSize: 13,
                                    height: 1.3,
                                    color: item.isRead ? Colors.black54 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!item.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFF5D2E),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
