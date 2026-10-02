import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_core/shared_core.dart';
import '../worker/worker_providers.dart';
import '../../shared/empty_state.dart';
import '../../shared/error_state.dart';
import 'request_parts_sheet.dart';

class InventoryTabScreen extends ConsumerStatefulWidget {
  const InventoryTabScreen({super.key});

  @override
  ConsumerState<InventoryTabScreen> createState() => _InventoryTabScreenState();
}

class _InventoryTabScreenState extends ConsumerState<InventoryTabScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryItemsProvider);
    final lowStockAsync = ref.watch(lowStockItemsProvider);

    final lowStockList = lowStockAsync.asData?.value ?? [];
    final allInventory = inventoryAsync.asData?.value ?? [];

    final categories = ['ALL', 'Fluids & Lubricants', 'Brakes', 'Filters', 'Ignition & Electrical'];

    final filteredItems = allInventory.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.partNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesCategory = _selectedCategory == 'ALL' ||
          item.category.toLowerCase().contains(_selectedCategory.toLowerCase());
      return matchesSearch && matchesCategory;
    }).toList();

    return RefreshIndicator(
      color: const Color(0xFFFF5D2E),
      onRefresh: () async {
        ref.invalidate(inventoryItemsProvider);
        ref.invalidate(lowStockItemsProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // ── Top Section: Low Stock Items Alert Carousel ──────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const PhosphorIcon(PhosphorIconsFill.warning, size: 20, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Text(
                    'Low Stock Items (${lowStockList.length})',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Action Needed',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (lowStockList.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const PhosphorIcon(PhosphorIconsFill.checkCircle, size: 22, color: Color(0xFF16A34A)),
                  const SizedBox(width: 10),
                  Text(
                    'All inventory items have sufficient stock levels.',
                    style: GoogleFonts.instrumentSans(fontSize: 13, color: const Color(0xFF15803D)),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 142,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: lowStockList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = lowStockList[index];
                  return _buildLowStockCard(item);
                },
              ),
            ),
          const SizedBox(height: 20),

          // ── Request Parts Action Banner (Requirement) ─────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5D2E), Color(0xFFFF855F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33FF5D2E),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const PhosphorIcon(
                    PhosphorIconsFill.package,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need specific parts or fluids?',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Submit an internal requisition request to the store.',
                        style: GoogleFonts.instrumentSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => RequestPartsSheet.show(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF5D2E),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Request',
                    style: GoogleFonts.instrumentSans(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Full Workshop Catalog Search & Filters ────────────────────────
          Text(
            'Workshop Inventory Catalog',
            style: GoogleFonts.instrumentSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),

          // Search Field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search parts, filters, oils, fluids...',
                hintStyle: GoogleFonts.instrumentSans(fontSize: 13, color: Colors.black45),
                prefixIcon: const PhosphorIcon(PhosphorIconsRegular.magnifyingGlass, size: 18, color: Colors.black45),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              ),
              style: GoogleFonts.instrumentSans(fontSize: 13),
            ),
          ),
          const SizedBox(height: 10),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: const Color(0xFFFFEFE9),
                    checkmarkColor: const Color(0xFFFF5D2E),
                    labelStyle: GoogleFonts.instrumentSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFFFF5D2E) : Colors.black87,
                    ),
                    backgroundColor: const Color(0xFFF7F7F7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFFF5D2E) : const Color(0xFFE5E5E5),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Inventory List
          inventoryAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
              ),
            ),
            error: (err, _) => ServioErrorState(
              message: 'Failed to load inventory items. Tap retry to reload.',
              onRetry: () {
                ref.invalidate(inventoryItemsProvider);
                ref.invalidate(lowStockItemsProvider);
              },
            ),
            data: (_) {
              if (filteredItems.isEmpty) {
                return ServioEmptyState(
                  icon: PhosphorIconsRegular.archive,
                  title: 'No Inventory Items Found',
                  description: _searchQuery.isNotEmpty || _selectedCategory != 'ALL'
                      ? 'No items match your active search or category filters.'
                      : 'There are currently no items recorded in workshop inventory.',
                  actionLabel: _searchQuery.isNotEmpty || _selectedCategory != 'ALL'
                      ? 'Reset Filters'
                      : 'Request New Part',
                  onAction: () {
                    if (_searchQuery.isNotEmpty || _selectedCategory != 'ALL') {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedCategory = 'ALL';
                      });
                    } else {
                      RequestPartsSheet.show(context);
                    }
                  },
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: _buildInventoryTile(item),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Low Stock Alert Card ──────────────────────────────────────────────────
  Widget _buildLowStockCard(InventoryItemModel item) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12DC2626),
            blurRadius: 8,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'CRITICAL',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
              Text(
                '${item.currentStock.toInt()} left',
                style: GoogleFonts.instrumentSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            style: GoogleFonts.instrumentSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: ${item.minimumStock.toInt()} ${item.unit}',
                style: GoogleFonts.instrumentSans(fontSize: 11, color: Colors.black54),
              ),
              InkWell(
                onTap: () {
                  RequestPartsSheet.show(
                    context,
                    prefilledPartName: item.name,
                    prefilledPartNumber: item.partNumber,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2ED),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PhosphorIcon(PhosphorIconsBold.plus, size: 12, color: Color(0xFFFF5D2E)),
                      const SizedBox(width: 4),
                      Text(
                        'Reorder',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF5D2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Standard Inventory Item Tile ──────────────────────────────────────────
  Widget _buildInventoryTile(InventoryItemModel item) {
    final isLow = item.isLowStock;
    final priceStr = item.sellingPricePerUnit != null
        ? 'LKR ${item.sellingPricePerUnit!.toStringAsFixed(0)}'
        : (item.costPerUnit != null ? 'LKR ${item.costPerUnit!.toStringAsFixed(0)}' : 'N/A');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isLow ? const Color(0xFFFFF2ED) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PhosphorIcon(
              isLow ? PhosphorIconsFill.warningCircle : PhosphorIconsFill.package,
              size: 22,
              color: isLow ? const Color(0xFFFF5D2E) : Colors.black54,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (item.partNumber != null) ...[
                      Text(
                        item.partNumber!,
                        style: GoogleFonts.instrumentSans(fontSize: 11, color: Colors.black45),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      item.category,
                      style: GoogleFonts.instrumentSans(fontSize: 11, color: const Color(0xFFFF5D2E), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (item.location != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Location: ${item.location}',
                    style: GoogleFonts.instrumentSans(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLow ? const Color(0xFFFEE2E2) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.currentStock.toInt()} ${item.unit}',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isLow ? const Color(0xFFDC2626) : const Color(0xFF2E7D32),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                priceStr,
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
