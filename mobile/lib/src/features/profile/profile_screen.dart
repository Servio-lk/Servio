import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_providers.dart';
import 'vehicles_repository.dart';
import 'models/vehicle_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSigningOut = false;

  User? get _user => Supabase.instance.client.auth.currentUser;
  String get _fullName {
    final name = _user?.userMetadata?['full_name'] as String?;
    return (name != null && name.isNotEmpty) ? name : 'User';
  }

  String get _email => _user?.email ?? '';
  String get _phone {
    final phone = _user?.userMetadata?['phone'] as String?;
    return (phone != null && phone.isNotEmpty) ? phone : 'Not set';
  }

  String get _initials {
    final parts = _fullName.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'U';
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sign Out',
          style: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.instrumentSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.instrumentSans(color: const Color(0xFF4B4B4B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sign Out',
              style: GoogleFonts.instrumentSans(color: const Color(0xFFFF5D2E)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSigningOut = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/signin');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  void _showChangeEmailDialog() {
    final controller = TextEditingController(text: _email);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Change Email',
          style: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A confirmation link will be sent to the new email address.',
              style: GoogleFonts.instrumentSans(
                fontSize: 13,
                color: const Color(0xFF4B4B4B),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'New Email',
                labelStyle: GoogleFonts.instrumentSans(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFFF5D2E)),
                ),
              ),
              style: GoogleFonts.instrumentSans(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.instrumentSans(color: const Color(0xFF4B4B4B)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newEmail = controller.text.trim();
              if (newEmail.isEmpty || !newEmail.contains('@')) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid email')),
                  );
                }
                return;
              }
              Navigator.of(ctx).pop();
              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(email: newEmail),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Confirmation sent to $newEmail'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            child: Text(
              'Update',
              style: GoogleFonts.instrumentSans(color: const Color(0xFFFF5D2E)),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog() {
    final emailAddr = _email;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Reset Password',
          style: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'A password reset link will be sent to $emailAddr.',
          style: GoogleFonts.instrumentSans(
            fontSize: 14,
            color: const Color(0xFF4B4B4B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.instrumentSans(color: const Color(0xFF4B4B4B)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await Supabase.instance.client.auth
                    .resetPasswordForEmail(emailAddr);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset link sent to $emailAddr'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            child: Text(
              'Send Link',
              style: GoogleFonts.instrumentSans(color: const Color(0xFFFF5D2E)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(userVehiclesProvider);

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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ──
                const SizedBox(height: 4),
                Text(
                  'Account',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Profile Card ──
                _ProfileCard(
                  fullName: _fullName,
                  email: _email,
                  initials: _initials,
                ),
                const SizedBox(height: 24),

                // ── My Vehicles ──
                _MyVehiclesSection(
                  vehiclesAsync: vehiclesAsync,
                  onRefresh: () => ref.invalidate(userVehiclesProvider),
                ),
                const SizedBox(height: 24),
                const _SectionDivider(),
                const SizedBox(height: 24),

                // ── Personal Details ──
                _PersonalDetailsSection(
                  phone: _phone,
                  email: _email,
                  onChangeEmail: _showChangeEmailDialog,
                  onResetPassword: _showResetPasswordDialog,
                ),
                const SizedBox(height: 24),
                const _SectionDivider(),
                const SizedBox(height: 24),

                // ── Payment & Preferences ──
                const _PaymentPreferencesSection(),
                const SizedBox(height: 24),
                const _SectionDivider(),
                const SizedBox(height: 24),

                // ── Sign Out ──
                _SignOutButton(
                  onTap: _handleSignOut,
                  isLoading: _isSigningOut,
                ),
                const SizedBox(height: 16),

                // ── App Version ──
                Center(
                  child: Opacity(
                    opacity: 0.5,
                    child: Text(
                      'Servio v1.0.0',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4B4B4B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── PROFILE CARD ────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String fullName;
  final String email;
  final String initials;
  const _ProfileCard({
    required this.fullName,
    required this.email,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE7DF), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFE7DF),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.instrumentSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF5D2E),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4B4B4B),
                  ),
                ),
              ],
            ),
          ),
          const Opacity(
            opacity: 0.5,
            child: PhosphorIcon(
              PhosphorIconsBold.caretRight,
              size: 16,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MY VEHICLES SECTION ─────────────────────────────────────────────────────

class _MyVehiclesSection extends StatelessWidget {
  final AsyncValue<List<VehicleModel>> vehiclesAsync;
  final VoidCallback onRefresh;
  const _MyVehiclesSection({
    required this.vehiclesAsync,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'My Vehicles',
                style: GoogleFonts.instrumentSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _showVehicleFormDialog(context, null),
              child: const PhosphorIcon(
                PhosphorIconsRegular.plus,
                size: 24,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        vehiclesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
            ),
          ),
          error: (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Could not load vehicles',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onRefresh,
                    child: Text(
                      'Retry',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF5D2E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No vehicles added yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 14,
                      color: Colors.black38,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: vehicles.asMap().entries.map((entry) {
                final index = entry.key;
                final v = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < vehicles.length - 1 ? 8 : 0,
                  ),
                  child: _VehicleCard(
                    vehicle: v,
                    isPrimary: index == 0,
                    onEdit: () => _showVehicleFormDialog(context, v),
                    onDelete: () => _confirmDeleteVehicle(context, v),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showVehicleFormDialog(BuildContext context, VehicleModel? existing) {
    final makeCtrl = TextEditingController(text: existing?.make ?? '');
    final modelCtrl = TextEditingController(text: existing?.model ?? '');
    final yearCtrl = TextEditingController(
      text: existing?.year?.toString() ?? '',
    );
    final plateCtrl = TextEditingController(
      text: existing?.licensePlate ?? '',
    );
    final vinCtrl = TextEditingController(text: existing?.vin ?? '');
    final isEditing = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEditing ? 'Edit Vehicle' : 'Add Vehicle',
          style: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(makeCtrl, 'Make (e.g. Toyota)'),
              const SizedBox(height: 12),
              _buildTextField(modelCtrl, 'Model (e.g. Premio)'),
              const SizedBox(height: 12),
              _buildTextField(yearCtrl, 'Year (e.g. 2020)',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(plateCtrl, 'License Plate (e.g. CAR-1234)'),
              const SizedBox(height: 12),
              _buildTextField(vinCtrl, 'VIN (optional)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.instrumentSans(
                color: const Color(0xFF4B4B4B),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final make = makeCtrl.text.trim();
              final model = modelCtrl.text.trim();
              if (make.isEmpty || model.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Make and Model are required'),
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop();
              try {
                final repo = VehiclesRepository();
                if (isEditing) {
                  await repo.updateVehicle(
                    vehicleId: existing.id,
                    make: make,
                    model: model,
                    year: int.tryParse(yearCtrl.text.trim()),
                    licensePlate: plateCtrl.text.trim(),
                    vin: vinCtrl.text.trim(),
                  );
                } else {
                  await repo.createVehicle(
                    make: make,
                    model: model,
                    year: int.tryParse(yearCtrl.text.trim()),
                    licensePlate: plateCtrl.text.trim(),
                    vin: vinCtrl.text.trim(),
                  );
                }
                onRefresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing ? 'Vehicle updated' : 'Vehicle added',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            child: Text(
              isEditing ? 'Update' : 'Save',
              style: GoogleFonts.instrumentSans(
                color: const Color(0xFFFF5D2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.instrumentSans(fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFF5D2E)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: GoogleFonts.instrumentSans(fontSize: 14),
    );
  }

  void _confirmDeleteVehicle(BuildContext context, VehicleModel vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Vehicle',
          style: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to remove ${vehicle.displayName}?',
          style: GoogleFonts.instrumentSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.instrumentSans(
                color: const Color(0xFF4B4B4B),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await VehiclesRepository().deleteVehicle(vehicle.id);
                onRefresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vehicle deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.instrumentSans(
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── VEHICLE CARD ────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final bool isPrimary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VehicleCard({
    required this.vehicle,
    required this.isPrimary,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE7DF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const PhosphorIcon(
                PhosphorIconsRegular.car,
                size: 24,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.displayName,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  if (vehicle.detailLine.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      vehicle.detailLine,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4B4B4B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isPrimary) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFE7DF),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Primary',
                  style: GoogleFonts.instrumentSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF5D2E),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: PhosphorIcon(
                  PhosphorIconsRegular.trash,
                  size: 18,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Opacity(
              opacity: 0.5,
              child: PhosphorIcon(
                PhosphorIconsBold.caretRight,
                size: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SECTION DIVIDER ─────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: Center(
        child: Container(
          height: 1,
          width: double.infinity,
          color: Colors.black.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}

// ─── PERSONAL DETAILS SECTION ────────────────────────────────────────────────

class _PersonalDetailsSection extends StatelessWidget {
  final String phone;
  final String email;
  final VoidCallback onChangeEmail;
  final VoidCallback onResetPassword;

  const _PersonalDetailsSection({
    required this.phone,
    required this.email,
    required this.onChangeEmail,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Details',
          style: GoogleFonts.instrumentSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _InfoRow(
          icon: PhosphorIconsRegular.phone,
          label: 'Phone',
          value: phone,
          onTap: () {},
        ),
        const SizedBox(height: 4),
        _InfoRow(
          icon: PhosphorIconsRegular.envelopeSimple,
          label: 'Email',
          value: email,
          onTap: onChangeEmail,
        ),
        const SizedBox(height: 4),
        _InfoRow(
          icon: PhosphorIconsRegular.lockKey,
          label: 'Password',
          value: 'Reset via email',
          onTap: onResetPassword,
        ),
        const SizedBox(height: 4),
        _InfoRow(
          icon: PhosphorIconsRegular.bell,
          label: 'Notifications',
          value: 'Enabled',
          onTap: () {},
        ),
      ],
    );
  }
}

// ─── PAYMENT & PREFERENCES SECTION ──────────────────────────────────────────

class _PaymentPreferencesSection extends StatelessWidget {
  const _PaymentPreferencesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment & Preferences',
          style: GoogleFonts.instrumentSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _InfoRow(
          icon: PhosphorIconsRegular.creditCard,
          label: 'Payment Methods',
          value: 'Cash',
          onTap: () {},
        ),
        const SizedBox(height: 4),
        _InfoRow(
          icon: PhosphorIconsRegular.clockCounterClockwise,
          label: 'Service History',
          onTap: () {},
        ),
        const SizedBox(height: 4),
        _InfoRow(
          icon: PhosphorIconsRegular.mapPin,
          label: 'Preferred Service Center',
          value: 'Servio Service Center',
          onTap: () {},
        ),
        const SizedBox(height: 4),
        _InfoRow(
          icon: PhosphorIconsRegular.globe,
          label: 'Language',
          value: 'English',
          onTap: () {},
        ),
      ],
    );
  }
}

// ─── INFO ROW ────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            PhosphorIcon(icon, size: 24, color: Colors.black),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4B4B4B),
                    ),
                  ),
                  if (value != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      value!,
                      style: GoogleFonts.instrumentSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Opacity(
              opacity: 0.5,
              child: PhosphorIcon(
                PhosphorIconsBold.caretRight,
                size: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SIGN OUT BUTTON ─────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  const _SignOutButton({required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE7DF), width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: isLoading
              ? const [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF5D2E),
                    ),
                  ),
                ]
              : [
                  const PhosphorIcon(
                    PhosphorIconsRegular.signOut,
                    size: 20,
                    color: Color(0xFFFF5D2E),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFFF5D2E),
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}
