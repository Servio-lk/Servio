import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_core/shared_core.dart';
import '../worker/worker_providers.dart';

class AssignMechanicSheet extends ConsumerStatefulWidget {
  final AppointmentModel job;
  final ValueChanged<String>? onAssigned;

  const AssignMechanicSheet({
    super.key,
    required this.job,
    this.onAssigned,
  });

  static Future<void> show(
    BuildContext context, {
    required AppointmentModel job,
    ValueChanged<String>? onAssigned,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssignMechanicSheet(job: job, onAssigned: onAssigned),
    );
  }

  @override
  ConsumerState<AssignMechanicSheet> createState() => _AssignMechanicSheetState();
}

class _AssignMechanicSheetState extends ConsumerState<AssignMechanicSheet> {
  int? _selectedMechanicId;
  String? _selectedMechanicName;
  bool _submitting = false;

  Future<void> _confirmAssignment() async {
    if (_selectedMechanicId == null || _selectedMechanicName == null) return;

    setState(() => _submitting = true);
    try {
      final success = await ref.read(workerRepositoryProvider).assignMechanic(
            widget.job.id,
            _selectedMechanicId!,
          );
      if (success) {
        ref.invalidate(pendingAppointmentsProvider);
        ref.invalidate(activeAppointmentsProvider);
        ref.invalidate(staffListProvider);
        widget.onAssigned?.call(_selectedMechanicName!);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Assigned $_selectedMechanicName to ${widget.job.plateDisplay}.'),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not assign mechanic. Please try again.'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);
    final safeBottom = math.max(MediaQuery.paddingOf(context).bottom, 16.0);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, safeBottom + MediaQuery.of(context).viewInsets.bottom),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const PhosphorIcon(
                  PhosphorIconsFill.userPlus,
                  size: 22,
                  color: Color(0xFFFF5D2E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assign Mechanic',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${widget.job.serviceType} • ${widget.job.plateDisplay}',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Select a technician for this job:',
            style: GoogleFonts.instrumentSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: staffAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
              ),
              error: (_, __) => Center(
                child: Text(
                  'Could not load mechanics list.',
                  style: GoogleFonts.instrumentSans(color: Colors.black54),
                ),
              ),
              data: (mechanics) {
                if (mechanics.isEmpty) {
                  return const Center(child: Text('No mechanics registered.'));
                }

                return ListView.separated(
                  itemCount: mechanics.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final m = mechanics[index];
                    final isSelected = _selectedMechanicId == m.id;
                    final isOnDuty = m.isOnDuty;
                    final isOnLeave = m.isOnLeave;

                    Color statusBg = const Color(0xFFE8F5E9);
                    Color statusColor = const Color(0xFF2E7D32);
                    String statusText = 'On Duty';

                    if (isOnLeave) {
                      statusBg = const Color(0xFFFFEBEE);
                      statusColor = const Color(0xFFC62828);
                      statusText = 'On Leave';
                    } else if (!isOnDuty) {
                      statusBg = const Color(0xFFF5F5F5);
                      statusColor = Colors.black54;
                      statusText = 'Off Duty';
                    }

                    return InkWell(
                      onTap: isOnLeave
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${m.fullName} is currently on leave (${m.leaveReason ?? 'Leave'}).'),
                                  backgroundColor: Colors.black87,
                                ),
                              );
                            }
                          : () {
                              setState(() {
                                _selectedMechanicId = m.id;
                                _selectedMechanicName = m.fullName;
                              });
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFF2ED) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF5D2E) : const Color(0xFFE6E6E6),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isSelected ? const Color(0xFFFF5D2E) : const Color(0xFFEEEEEE),
                              child: Text(
                                m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : 'M',
                                style: GoogleFonts.instrumentSans(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : Colors.black87,
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
                                          m.fullName,
                                          style: GoogleFonts.instrumentSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: GoogleFonts.instrumentSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    m.specialization ?? 'General Technician',
                                    style: GoogleFonts.instrumentSans(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${m.assignedJobs.length} active jobs assigned',
                                    style: GoogleFonts.instrumentSans(
                                      fontSize: 11,
                                      color: m.assignedJobs.isEmpty ? const Color(0xFF16A34A) : const Color(0xFFFF5D2E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? const Color(0xFFFF5D2E) : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFFF5D2E) : const Color(0xFFCCCCCC),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Center(
                                      child: Icon(Icons.check, size: 14, color: Colors.white),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: (_selectedMechanicId == null || _submitting) ? null : _confirmAssignment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5D2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Confirm Assignment',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
