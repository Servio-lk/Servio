import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_core/shared_core.dart';
import '../worker/worker_providers.dart';

class RequestPartsSheet extends ConsumerStatefulWidget {
  final String? prefilledPartName;
  final String? prefilledPartNumber;

  const RequestPartsSheet({
    super.key,
    this.prefilledPartName,
    this.prefilledPartNumber,
  });

  static Future<void> show(
    BuildContext context, {
    String? prefilledPartName,
    String? prefilledPartNumber,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RequestPartsSheet(
        prefilledPartName: prefilledPartName,
        prefilledPartNumber: prefilledPartNumber,
      ),
    );
  }

  @override
  ConsumerState<RequestPartsSheet> createState() => _RequestPartsSheetState();
}

class _RequestPartsSheetState extends ConsumerState<RequestPartsSheet> {
  late final TextEditingController _partNameController;
  late final TextEditingController _partNumberController;
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  String _urgency = 'STANDARD';
  int? _selectedAppointmentId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _partNameController = TextEditingController(text: widget.prefilledPartName ?? '');
    _partNumberController = TextEditingController(text: widget.prefilledPartNumber ?? '');
  }

  @override
  void dispose() {
    _partNameController.dispose();
    _partNumberController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final name = _partNameController.text.trim();
    final qty = int.tryParse(_quantityController.text.trim()) ?? 1;

    if (name.isEmpty || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid part name and quantity.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final req = PartRequestModel(
        id: DateTime.now().millisecondsSinceEpoch,
        partName: name,
        partNumber: _partNumberController.text.trim().isNotEmpty ? _partNumberController.text.trim() : null,
        quantity: qty,
        urgency: _urgency,
        appointmentId: _selectedAppointmentId,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      final ok = await ref.read(workerRepositoryProvider).requestPart(req);
      if (ok && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request for $qty x $name submitted to Store Manager!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit parts request.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeJobsAsync = ref.watch(activeAppointmentsProvider);
    final safeBottom = math.max(MediaQuery.paddingOf(context).bottom, 16.0);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, safeBottom + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
                  child: const PhosphorIcon(PhosphorIconsFill.package, size: 22, color: Color(0xFFFF5D2E)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request Workshop Parts',
                        style: GoogleFonts.instrumentSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                      Text(
                        'Storekeeper & Procurement requisition form',
                        style: GoogleFonts.instrumentSans(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Part Name
            Text(
              'Part Name or Description *',
              style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _partNameController,
              decoration: InputDecoration(
                hintText: 'e.g. Brake Master Cylinder / Mobil 5W-30',
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              style: GoogleFonts.instrumentSans(fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Part Number & Quantity
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Part / OEM Number',
                        style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _partNumberController,
                        decoration: InputDecoration(
                          hintText: 'e.g. 04152-YZZA6',
                          filled: true,
                          fillColor: const Color(0xFFF7F7F7),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        style: GoogleFonts.instrumentSans(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity *',
                        style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF7F7F7),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        style: GoogleFonts.instrumentSans(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Urgency
            Text(
              'Urgency Level',
              style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildUrgencyChip('STANDARD', 'Standard (24h)', Colors.black87, const Color(0xFFF3F4F6)),
                const SizedBox(width: 8),
                _buildUrgencyChip('HIGH', 'High (Today)', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                const SizedBox(width: 8),
                _buildUrgencyChip('URGENT', 'Critical / On Bay', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
              ],
            ),
            const SizedBox(height: 12),

            // Link to Active Job (Optional)
            Text(
              'Link to Active Vehicle Job (Optional)',
              style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            activeJobsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (jobs) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      isExpanded: true,
                      hint: Text(
                        'Select associated job...',
                        style: GoogleFonts.instrumentSans(fontSize: 13, color: Colors.black54),
                      ),
                      value: _selectedAppointmentId,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('General Workshop Stock (No specific job)'),
                        ),
                        ...jobs.map((j) {
                          return DropdownMenuItem<int?>(
                            value: j.id,
                            child: Text('${j.plateDisplay} • ${j.vehicleDisplay} (#${j.id})'),
                          );
                        }),
                      ],
                      onChanged: (id) => setState(() => _selectedAppointmentId = id),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Notes
            Text(
              'Notes or Supplier Preference',
              style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Toyota genuine preferred, customer approved quote.',
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              style: GoogleFonts.instrumentSans(fontSize: 13),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submitRequest,
                icon: const PhosphorIcon(PhosphorIconsBold.paperPlaneTilt, size: 18, color: Colors.white),
                label: Text(
                  'Submit Parts Request',
                  style: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5D2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencyChip(String key, String label, Color textColor, Color bgColor) {
    final isSelected = _urgency == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _urgency = key),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? textColor : const Color(0xFFE5E5E5),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.instrumentSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? textColor : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
