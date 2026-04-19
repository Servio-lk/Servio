import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/services/supabase_service.dart';
import '../profile/vehicles_repository.dart';
import 'signup_widgets.dart';

class SignUpStep3Screen extends StatefulWidget {
  final Map<String, dynamic>? extras;

  const SignUpStep3Screen({super.key, this.extras});

  @override
  State<SignUpStep3Screen> createState() => _SignUpStep3ScreenState();
}

class _SignUpStep3ScreenState extends State<SignUpStep3Screen> {
  final _mileageController = TextEditingController();
  final _dateController = TextEditingController();
  final _supabaseService = SupabaseService();
  final _vehiclesRepo = VehiclesRepository();

  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final extras = widget.extras;
    if (extras == null) return;

    _mileageController.text = (extras['mileage'] as String?) ?? '';
    _dateController.text = (extras['last_service_date'] as String?) ?? '';
    if (_dateController.text.isNotEmpty) {
      _selectedDate = DateTime.tryParse(_dateController.text);
    }
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF5D2E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleFinish() async {
    FocusScope.of(context).unfocus();

    final data = _currentStepData();
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      _showSnackBar('Please verify your email before finishing setup.');
      context.go('/signup/otp', extra: data);
      return;
    }

    final makeModel = ((data['make_model'] as String?) ?? '').trim();
    if (makeModel.isEmpty) {
      _showSnackBar('Please add your vehicle details first.');
      context.go('/signup/vehicle', extra: data);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final year = int.tryParse(((data['year'] as String?) ?? '').trim());
      final registration = ((data['registration'] as String?) ?? '').trim();

      // Keep both fields non-empty for stricter DB constraints.
      final parts = makeModel
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      final make = parts.first;
      final model = parts.length > 1 ? parts.sublist(1).join(' ') : parts.first;

      await _vehiclesRepo.createVehicle(
        make: make,
        model: model,
        year: year,
        licensePlate: registration.isNotEmpty ? registration : null,
      );

      if (!mounted) return;

      _showSnackBar('Setup complete! Welcome to Servio.', isError: false);
      context.go('/home');
    } catch (e) {
      debugPrint('Error saving vehicle: $e');
      if (mounted) {
        final error = e.toString();
        if (error.contains('42501') ||
            error.contains('row-level security policy')) {
          _showSnackBar(
            'Vehicle save blocked by database permissions. Please contact support to run the vehicles policy migration.',
          );
        } else if (error.contains('No active session')) {
          _showSnackBar('Please verify your email and sign in again.');
          context.go('/signin');
        } else {
          _showSnackBar('Failed to save vehicle. Please try again.');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSkip() {
    FocusScope.of(context).unfocus();
    context.go('/home');
  }

  Map<String, dynamic> _currentStepData() {
    return <String, dynamic>{
      ...?widget.extras,
      'mileage': _mileageController.text.trim(),
      'last_service_date': _dateController.text.trim(),
    };
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignUpScaffold(
      children: [
        // Header
        SignUpHeader(
          step: 4,
          title: 'Where are we starting?',
          subtitle:
              'Add your current stats so we can remind you when your next service is due.',
          onBack: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/signup/vehicle', extra: _currentStepData());
            }
          },
        ),
        const SizedBox(height: 8),

        // Form
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SignUpLabel('Current Mileage (Optional):'),
                const SizedBox(height: 8),
                SignUpInputField(
                  controller: _mileageController,
                  hint: '45,000 km',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                const SignUpHelperText('A rough estimate is fine!'),
                const SizedBox(height: 16),

                const SignUpLabel('Last Service Date (Optional):'),
                const SizedBox(height: 8),
                SignUpInputField(
                  controller: _dateController,
                  hint: 'Select a date',
                  readOnly: true,
                  onTap: _pickDate,
                ),
              ],
            ),
          ),
        ),

        // Finish Setup button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SignUpPrimaryButton(
            label: 'Finish Setup',
            onTap: _handleFinish,
            isLoading: _isLoading,
          ),
        ),
        const SizedBox(height: 8),
        // Skip button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SignUpSecondaryButton(
            label: 'Skip this for now',
            onTap: _isLoading ? null : _handleSkip,
          ),
        ),
      ],
    );
  }
}
