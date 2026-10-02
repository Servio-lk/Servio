import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_core/shared_core.dart';
import '../worker/worker_providers.dart';

class ItemsUsedSheet extends ConsumerStatefulWidget {
  final int appointmentId;
  final ValueChanged<String>? onPartLogged;

  const ItemsUsedSheet({
    super.key,
    required this.appointmentId,
    this.onPartLogged,
  });

  static Future<void> show(
    BuildContext context, {
    required int appointmentId,
    ValueChanged<String>? onPartLogged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ItemsUsedSheet(
        appointmentId: appointmentId,
        onPartLogged: onPartLogged,
      ),
    );
  }

  @override
  ConsumerState<ItemsUsedSheet> createState() => _ItemsUsedSheetState();
}

class _ItemsUsedSheetState extends ConsumerState<ItemsUsedSheet> {
  final _partNameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _costController = TextEditingController(text: '0');
  InventoryItemModel? _selectedInventoryItem;
  bool _submitting = false;

  final List<Map<String, dynamic>> _alreadyLoggedParts = [];

  @override
  void dispose() {
    _partNameController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _submitPart() async {
    final name = _partNameController.text.trim();
    final qty = int.tryParse(_quantityController.text.trim()) ?? 1;
    final cost = double.tryParse(_costController.text.trim()) ?? 0.0;

    if (name.isEmpty || qty <= 0) return;

    setState(() => _submitting = true);
    try {
      await ref.read(workerRepositoryProvider).logPartUsed(
            appointmentId: widget.appointmentId,
            partName: name,
            quantity: qty,
            unitCost: cost,
          );

      setState(() {
        _alreadyLoggedParts.add({'name': name, 'qty': qty, 'unitCost': cost});
        _partNameController.clear();
        _quantityController.text = '1';
        _costController.text = '0';
        _selectedInventoryItem = null;
      });

      widget.onPartLogged?.call('Used item added: $qty x $name (LKR ${(cost * qty).toStringAsFixed(0)})');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged "$name" to service items!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to record used part.'),
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
    final inventoryAsync = ref.watch(inventoryItemsProvider);
    final safeBottom = math.max(MediaQuery.paddingOf(context).bottom, 16.0);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    double totalPartsCost = 0.0;
    for (final item in _alreadyLoggedParts) {
      totalPartsCost += (item['qty'] as int) * (item['unitCost'] as double);
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, safeBottom + bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2ED),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const PhosphorIcon(
                      PhosphorIconsFill.package,
                      size: 20,
                      color: Color(0xFFFF5D2E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Items & Parts Used',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Text(
                'Total: LKR ${totalPartsCost.toStringAsFixed(0)}',
                style: GoogleFonts.instrumentSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF5D2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Logged parts list
          if (_alreadyLoggedParts.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'No parts logged to this repair yet.',
                style: GoogleFonts.instrumentSans(fontSize: 12, color: Colors.black45),
              ),
            ),
          ] else ...[
            Text(
              'Logged to this repair:',
              style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _alreadyLoggedParts.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (context, index) {
                  final part = _alreadyLoggedParts[index];
                  final subtotal = (part['qty'] as int) * (part['unitCost'] as double);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const PhosphorIcon(PhosphorIconsFill.checkCircle, size: 16, color: Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${part['qty']}x ${part['name']}',
                            style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          'LKR ${subtotal.toStringAsFixed(0)}',
                          style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],

          Text(
            'Add Consumed Part / Fluid:',
            style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 8),

          // Quick select from inventory dropdown
          inventoryAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (inventory) {
              if (inventory.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<InventoryItemModel>(
                      isExpanded: true,
                      hint: Text(
                        'Select from workshop stock...',
                        style: GoogleFonts.instrumentSans(fontSize: 13, color: Colors.black54),
                      ),
                      value: _selectedInventoryItem,
                      items: inventory.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(
                            '${item.name} (${item.currentStock.toInt()} in stock)',
                            style: GoogleFonts.instrumentSans(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (item) {
                        if (item != null) {
                          setState(() {
                            _selectedInventoryItem = item;
                            _partNameController.text = item.name;
                            _costController.text = (item.sellingPricePerUnit ?? item.costPerUnit ?? 0).toStringAsFixed(0);
                          });
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          // Custom entry fields
          TextField(
            controller: _partNameController,
            decoration: InputDecoration(
              hintText: 'Or enter custom part name...',
              filled: true,
              fillColor: const Color(0xFFF7F7F7),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            style: GoogleFonts.instrumentSans(fontSize: 13),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  style: GoogleFonts.instrumentSans(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Unit Price (LKR)',
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  style: GoogleFonts.instrumentSans(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submitPart,
              icon: const PhosphorIcon(PhosphorIconsBold.plusCircle, size: 18, color: Colors.white),
              label: Text(
                'Log Item to Job',
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
}
