import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_core/shared_core.dart';
import '../worker/worker_providers.dart';
import '../../shared/empty_state.dart';
import '../../shared/error_state.dart';

class StaffTabScreen extends ConsumerStatefulWidget {
  const StaffTabScreen({super.key});

  @override
  ConsumerState<StaffTabScreen> createState() => _StaffTabScreenState();
}

class _StaffTabScreenState extends ConsumerState<StaffTabScreen> {
  String _selectedFilter = 'ALL'; // ALL, ON_DUTY, ON_LEAVE

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);

    return RefreshIndicator(
      color: const Color(0xFFFF5D2E),
      onRefresh: () async {
        ref.invalidate(staffListProvider);
      },
      child: staffAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
        ),
        error: (err, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: ServioErrorState(
              message: 'Could not load staff list. Tap retry to reload.',
              onRetry: () => ref.invalidate(staffListProvider),
            ),
          ),
        ),
        data: (staffList) {
          if (staffList.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: ServioEmptyState(
                  icon: PhosphorIconsRegular.users,
                  title: 'No Technicians Found',
                  description: 'There are currently no staff members registered in the workshop.',
                  actionLabel: 'Refresh Staff',
                  onAction: () => ref.invalidate(staffListProvider),
                ),
              ),
            );
          }

          final totalCount = staffList.length;
          final onDutyCount = staffList.where((m) => m.isOnDuty).length;
          final onLeaveCount = staffList.where((m) => m.isOnLeave).length;
          final offDutyCount = staffList.where((m) => m.isOffDuty).length;

          final filteredList = staffList.where((m) {
            if (_selectedFilter == 'ON_DUTY') return m.isOnDuty;
            if (_selectedFilter == 'ON_LEAVE') return m.isOnLeave;
            return true;
          }).toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // ── Attendance Metrics Header ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Workshop Staff Attendance',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$totalCount Technicians',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAttendanceStatItem(
                            label: 'On Duty',
                            count: onDutyCount,
                            color: const Color(0xFF16A34A),
                            bgColor: const Color(0xFFF0FDF4),
                            icon: PhosphorIconsFill.checkCircle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildAttendanceStatItem(
                            label: 'On Leave',
                            count: onLeaveCount,
                            color: const Color(0xFFDC2626),
                            bgColor: const Color(0xFFFEF2F2),
                            icon: PhosphorIconsFill.calendarX,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildAttendanceStatItem(
                            label: 'Off Duty',
                            count: offDutyCount,
                            color: Colors.black54,
                            bgColor: const Color(0xFFF9F9F9),
                            icon: PhosphorIconsFill.moon,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Filter Chips ──────────────────────────────────────────────
              Row(
                children: [
                  _buildFilterChip('ALL', 'All Staff ($totalCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('ON_DUTY', 'On Duty ($onDutyCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('ON_LEAVE', 'On Leave ($onLeaveCount)'),
                ],
              ),
              const SizedBox(height: 14),

              // ── Mechanics Staff Cards List ────────────────────────────────
              if (filteredList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No technicians match the selected filter.',
                      style: GoogleFonts.instrumentSans(fontSize: 14, color: Colors.black54),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final mechanic = filteredList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildMechanicCard(mechanic),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAttendanceStatItem({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PhosphorIcon(icon, size: 16, color: color),
              Text(
                count.toString(),
                style: GoogleFonts.instrumentSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.instrumentSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = key),
      selectedColor: const Color(0xFFFFEFE9),
      labelStyle: GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? const Color(0xFFFF5D2E) : Colors.black87,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? const Color(0xFFFF5D2E) : const Color(0xFFE5E5E5)),
      ),
    );
  }

  // ── Mechanic Card ────────────────────────────────────────────────────────
  Widget _buildMechanicCard(MechanicStaffModel mechanic) {
    final isOnDuty = mechanic.isOnDuty;
    final isOnLeave = mechanic.isOnLeave;

    Color badgeBg = const Color(0xFFE8F5E9);
    Color badgeColor = const Color(0xFF2E7D32);
    String badgeText = 'ON DUTY';

    if (isOnLeave) {
      badgeBg = const Color(0xFFFFEBEE);
      badgeColor = const Color(0xFFC62828);
      badgeText = 'ON LEAVE';
    } else if (!isOnDuty) {
      badgeBg = const Color(0xFFF5F5F5);
      badgeColor = Colors.black54;
      badgeText = 'OFF DUTY';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFFFECE5),
                child: Text(
                  mechanic.fullName.isNotEmpty ? mechanic.fullName[0].toUpperCase() : 'M',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF5D2E),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mechanic.fullName,
                            style: GoogleFonts.instrumentSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.instrumentSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mechanic.specialization ?? 'General Technician',
                      style: GoogleFonts.instrumentSans(fontSize: 12, color: const Color(0xFFFF5D2E), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${mechanic.employeeCode ?? 'MEC'} • ${mechanic.experienceYears ?? 5} yrs experience',
                      style: GoogleFonts.instrumentSans(fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Leave Details if on leave
          if (isOnLeave && mechanic.leaveReason != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const PhosphorIcon(PhosphorIconsFill.info, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Leave reason: ${mechanic.leaveReason}',
                      style: GoogleFonts.instrumentSans(fontSize: 11, color: const Color(0xFF991B1B)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),

          // ── Assigned Jobs Section (Requirement) ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Currently Assigned Jobs (${mechanic.assignedJobs.length})',
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              if (mechanic.assignedJobs.isNotEmpty)
                Text(
                  'Active on Bay',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          if (mechanic.assignedJobs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'No jobs currently assigned. Available for new assignments.',
                style: GoogleFonts.instrumentSans(fontSize: 12, color: Colors.black45, fontStyle: FontStyle.italic),
              ),
            )
          else
            Column(
              children: mechanic.assignedJobs.map((job) {
                return Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEBEBEB)),
                  ),
                  child: Row(
                    children: [
                      const PhosphorIcon(PhosphorIconsRegular.car, size: 16, color: Color(0xFFFF5D2E)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${job.plateDisplay} • ${job.vehicleDisplay}',
                              style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              job.serviceType,
                              style: GoogleFonts.instrumentSans(fontSize: 11, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: job.status == 'IN_PROGRESS' ? const Color(0xFFE8F5E9) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          job.status == 'IN_PROGRESS' ? 'IN PROGRESS' : 'PENDING',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: job.status == 'IN_PROGRESS' ? const Color(0xFF2E7D32) : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
