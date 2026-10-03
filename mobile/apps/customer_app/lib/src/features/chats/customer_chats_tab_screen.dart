import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_core/shared_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bookings/appointments_providers.dart';
import 'customer_chat_screen.dart';

class CustomerChatsTabScreen extends ConsumerStatefulWidget {
  final VoidCallback? onExploreServices;

  const CustomerChatsTabScreen({super.key, this.onExploreServices});

  @override
  ConsumerState<CustomerChatsTabScreen> createState() =>
      _CustomerChatsTabScreenState();
}

class _CustomerChatsTabScreenState extends ConsumerState<CustomerChatsTabScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final appointmentsAsync = ref.watch(userAppointmentsProvider(userId));

    return Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messages',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chat directly with your service technician and workshop',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE7DF), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.03),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by service or vehicle...',
                    hintStyle: GoogleFonts.instrumentSans(
                      fontSize: 14,
                      color: Colors.black38,
                    ),
                    prefixIcon: const PhosphorIcon(
                      PhosphorIconsRegular.magnifyingGlass,
                      size: 20,
                      color: Colors.black45,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Colors.black45),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.instrumentSans(fontSize: 14),
                ),
              ),
            ),

            // Conversations List
            Expanded(
              child: appointmentsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const PhosphorIcon(
                          PhosphorIconsRegular.warningCircle,
                          size: 48,
                          color: Color(0xFFFF5D2E),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load conversations',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please check your connection and try again.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              ref.invalidate(userAppointmentsProvider(userId)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5D2E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.instrumentSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (appointments) {
                  // Sort: IN_PROGRESS first, then CONFIRMED, PENDING, others
                  final sorted = List<AppointmentModel>.from(appointments);
                  sorted.sort((a, b) {
                    int priority(AppointmentModel m) {
                      final s = m.status.toUpperCase();
                      if (s == 'IN_PROGRESS') return 0;
                      if (s == 'CONFIRMED') return 1;
                      if (s == 'PENDING') return 2;
                      return 3;
                    }

                    final cmp = priority(a).compareTo(priority(b));
                    if (cmp != 0) return cmp;
                    return b.appointmentDate.compareTo(a.appointmentDate);
                  });

                  final q = _searchQuery.toLowerCase();
                  final filtered = sorted.where((appt) {
                    if (q.isEmpty) return true;
                    if (appt.serviceType.toLowerCase().contains(q)) return true;
                    if (appt.plateDisplay.toLowerCase().contains(q)) return true;
                    if (appt.vehicleDisplay.toLowerCase().contains(q)) return true;
                    if (appt.assignedMechanicName?.toLowerCase().contains(q) == true) {
                      return true;
                    }
                    return false;
                  }).toList();

                  if (filtered.isEmpty) {
                    return RefreshIndicator(
                      color: const Color(0xFFFF5D2E),
                      onRefresh: () async {
                        ref.invalidate(userAppointmentsProvider(userId));
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: 380,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE7DF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: PhosphorIcon(
                                    PhosphorIconsFill.chatCircleDots,
                                    size: 28,
                                    color: Color(0xFFFF5D2E),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No chats match "$_searchQuery"'
                                    : 'No messages yet',
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Try checking another query or vehicle.'
                                    : 'When you book a service, you can chat with your technician directly here.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.instrumentSans(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              if (widget.onExploreServices != null && _searchQuery.isEmpty) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: widget.onExploreServices,
                                  icon: const Icon(Icons.build, size: 16, color: Colors.white),
                                  label: Text(
                                    'Explore Services',
                                    style: GoogleFonts.instrumentSans(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF5D2E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFFFF5D2E),
                    onRefresh: () async {
                      ref.invalidate(userAppointmentsProvider(userId));
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final appt = filtered[index];
                        return _CustomerChatThreadCard(
                          appointment: appt,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CustomerChatScreen(appointment: appt),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerChatThreadCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;

  const _CustomerChatThreadCard({
    required this.appointment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final serviceType = appointment.serviceType;
    final mechanicName =
        appointment.assignedMechanicName ?? 'Workshop Team';
    final status = appointment.status.toUpperCase();

    Color statusBg;
    Color statusFg;
    if (status == 'IN_PROGRESS') {
      statusBg = const Color(0xFFFEF3C7);
      statusFg = const Color(0xFFB45309);
    } else if (status == 'CONFIRMED') {
      statusBg = const Color(0xFFDCFCE7);
      statusFg = const Color(0xFF15803D);
    } else if (status == 'COMPLETED') {
      statusBg = const Color(0xFFF3F4F6);
      statusFg = const Color(0xFF4B5563);
    } else {
      statusBg = const Color(0xFFFFF0EC);
      statusFg = const Color(0xFFFF5D2E);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFE7DF), width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.04),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Service Icon Avatar with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      ServiceIconHelper.getServiceColors(serviceType).background,
                  child: Icon(
                    ServiceIconHelper.getPhosphorIcon(serviceType),
                    size: 20,
                    color:
                        ServiceIconHelper.getServiceColors(serviceType).primary,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIconsFill.chatCircleDots,
                      size: 11,
                      color: Color(0xFFFF5D2E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          serviceType,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        appointment.formattedDate,
                        style: GoogleFonts.instrumentSans(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const PhosphorIcon(
                        PhosphorIconsRegular.user,
                        size: 13,
                        color: Color(0xFFFF5D2E),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          mechanicName,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4B4B4B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          appointment.plateDisplay,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          appointment.vehicleDisplay,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          appointment.statusLabel,
                          style: GoogleFonts.instrumentSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: statusFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const PhosphorIcon(
              PhosphorIconsBold.caretRight,
              size: 16,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}
