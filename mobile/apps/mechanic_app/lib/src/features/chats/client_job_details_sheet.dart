import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_core/shared_core.dart';

class ClientJobDetailsSheet extends StatelessWidget {
  final AppointmentModel job;

  const ClientJobDetailsSheet({super.key, required this.job});

  static Future<void> show(BuildContext context, {required AppointmentModel job}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClientJobDetailsSheet(job: job),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client Job Overview',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Job #${job.id} • ${job.plateDisplay}',
                    style: GoogleFonts.instrumentSans(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  job.statusLabel,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF5D2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                // Vehicle Details Card
                _buildSectionCard(
                  title: 'Vehicle & Service Specs',
                  icon: PhosphorIconsFill.car,
                  children: [
                    _buildDetailRow('Vehicle Model', job.vehicleDisplay),
                    _buildDetailRow('License Plate', job.plateDisplay),
                    _buildDetailRow('Service Requested', job.serviceType),
                    _buildDetailRow('Scheduled Time', '${job.formattedDate} • ${job.formattedTime}'),
                  ],
                ),
                const SizedBox(height: 12),

                // Customer & Contact Card
                _buildSectionCard(
                  title: 'Client Details',
                  icon: PhosphorIconsFill.user,
                  children: [
                    _buildDetailRow('Client ID', job.userId ?? 'Registered Customer'),
                    _buildDetailRow('Location', job.location ?? 'Workshop Service Bay'),
                  ],
                ),
                const SizedBox(height: 12),

                // Financials & Notes Card
                _buildSectionCard(
                  title: 'Cost & Workshop Notes',
                  icon: PhosphorIconsFill.receipt,
                  children: [
                    _buildDetailRow('Estimated Cost', job.formattedCost),
                    if (job.actualCost != null)
                      _buildDetailRow('Actual Total Cost', 'LKR ${job.actualCost!.toStringAsFixed(0)}'),
                    _buildDetailRow(
                      'Customer Notes',
                      (job.notes?.trim().isNotEmpty == true) ? job.notes! : 'No notes provided.',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5D2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Close Details',
                style: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(icon, size: 18, color: const Color(0xFFFF5D2E)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.instrumentSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.instrumentSans(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.instrumentSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
