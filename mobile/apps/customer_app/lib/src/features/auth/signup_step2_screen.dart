import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'signup_widgets.dart';

class _VehicleTypeItem {
  final String label;
  final IconData outlineIcon;
  final IconData filledIcon;

  const _VehicleTypeItem(this.label, this.outlineIcon, this.filledIcon);
}

class SignUpStep2Screen extends StatefulWidget {
  final Map<String, dynamic>? extras;

  const SignUpStep2Screen({super.key, this.extras});

  @override
  State<SignUpStep2Screen> createState() => _SignUpStep2ScreenState();
}

class _SignUpStep2ScreenState extends State<SignUpStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _makeModelController = TextEditingController();
  final _yearController = TextEditingController();
  final _registrationController = TextEditingController();
  final _nicknameController = TextEditingController();

  int _selectedVehicleType = 0;

  static const List<_VehicleTypeItem> _vehicleTypes = [
    _VehicleTypeItem('Car', PhosphorIconsRegular.car, PhosphorIconsFill.car),
    _VehicleTypeItem(
      'SUV',
      PhosphorIconsRegular.carProfile,
      PhosphorIconsFill.carProfile,
    ),
    _VehicleTypeItem(
      'Bike',
      PhosphorIconsRegular.motorcycle,
      PhosphorIconsFill.motorcycle,
    ),
    _VehicleTypeItem('Van', PhosphorIconsRegular.van, PhosphorIconsFill.van),
    _VehicleTypeItem(
      'Truck',
      PhosphorIconsRegular.truck,
      PhosphorIconsFill.truck,
    ),
    _VehicleTypeItem('Bus', PhosphorIconsRegular.bus, PhosphorIconsFill.bus),
  ];

  @override
  void initState() {
    super.initState();
    final extras = widget.extras;
    if (extras == null) return;

    _makeModelController.text = (extras['make_model'] as String?) ?? '';
    _yearController.text = (extras['year'] as String?) ?? '';
    _registrationController.text = (extras['registration'] as String?) ?? '';
    _nicknameController.text = (extras['nickname'] as String?) ?? '';

    final typeLabel = extras['vehicle_type'] as String?;
    if (typeLabel != null) {
      final index = _vehicleTypes.indexWhere(
        (item) => item.label.toLowerCase() == typeLabel.toLowerCase(),
      );
      if (index >= 0) {
        _selectedVehicleType = index;
      }
    }
  }

  @override
  void dispose() {
    _makeModelController.dispose();
    _yearController.dispose();
    _registrationController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _handleNextStep() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    context.go('/signup/mileage', extra: _currentStepData());
  }

  Map<String, dynamic> _currentStepData() {
    return <String, dynamic>{
      ...?widget.extras,
      'vehicle_type': _vehicleTypes[_selectedVehicleType].label,
      'make_model': _makeModelController.text.trim(),
      'year': _yearController.text.trim(),
      'registration': _registrationController.text.trim(),
      'nickname': _nicknameController.text.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SignUpScaffold(
      children: [
        // Header
        SignUpHeader(
          step: 3,
          title: 'Add your primary vehicle',
          subtitle:
              'Tell us what you drive so we can fetch the right service schedules and parts.',
          onBack: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/signup/otp', extra: _currentStepData());
            }
          },
        ),
        const SizedBox(height: 8),

        // Form
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SignUpLabel('Vehicle Type:'),
                  const SizedBox(height: 8),

                  // Row 1: Car, SUV, Bike
                  Row(
                    children: List.generate(3, (i) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: i > 0 ? 12 : 0),
                          child: _buildVehicleTypeButton(i),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  // Row 2: Van, Truck, Bus
                  Row(
                    children: List.generate(3, (i) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: i > 0 ? 12 : 0),
                          child: _buildVehicleTypeButton(i + 3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  const SignUpLabel('Vehicle Make & Model:'),
                  const SizedBox(height: 8),
                  SignUpInputField(
                    controller: _makeModelController,
                    hint: 'Toyota Corolla',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter make & model';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const SignUpLabel('Vehicle Year:'),
                  const SizedBox(height: 8),
                  SignUpInputField(
                    controller: _yearController,
                    hint: '2019',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter the year';
                      }
                      final year = int.tryParse(v.trim());
                      if (year == null || year < 1900 || year > 2030) {
                        return 'Enter a valid year';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const SignUpLabel('Vehicle Registration No.:'),
                  const SizedBox(height: 8),
                  SignUpInputField(
                    controller: _registrationController,
                    hint: 'CBA-1234',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter registration number';
                      }
                      final digitsMatch = RegExp(r'\d').allMatches(v);
                      if (digitsMatch.length < 4) {
                        return 'Must contain at least 4 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  const SignUpHelperText(
                    'Helps your mechanic identify your car when you arrive.',
                  ),
                  const SizedBox(height: 16),

                  const SignUpLabel('Vehicle Nickname (Optional):'),
                  const SizedBox(height: 8),
                  SignUpInputField(
                    controller: _nicknameController,
                    hint: 'e.g., The Daily Commuter, Red Dragon',
                  ),
                  const SizedBox(height: 8),
                  const SignUpHelperText(
                    'Give your vehicle a fun name to identify it easily.',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),

        // Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SignUpPrimaryButton(
            label: 'Next Step',
            onTap: _handleNextStep,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleTypeButton(int index) {
    final item = _vehicleTypes[index];
    final isSelected = _selectedVehicleType == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedVehicleType = index),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5D2E) : const Color(0xFFFFE7DF),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.filledIcon : item.outlineIcon,
              size: 24,
              color: isSelected ? Colors.white : Colors.black,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                item.label,
                style: GoogleFonts.instrumentSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black,
                  height: 21 / 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
