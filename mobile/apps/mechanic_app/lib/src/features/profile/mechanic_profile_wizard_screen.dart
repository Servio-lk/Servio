import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_core/shared_core.dart';

class MechanicProfileWizardScreen extends StatefulWidget {
  const MechanicProfileWizardScreen({super.key});

  @override
  State<MechanicProfileWizardScreen> createState() =>
      _MechanicProfileWizardScreenState();
}

class _MechanicProfileWizardScreenState
    extends State<MechanicProfileWizardScreen> {
  final _supabaseService = SupabaseService();
  final _picker = ImagePicker();

  int _currentStep = 1;
  static const int _totalSteps = 4;
  bool _isLoadingInitial = true;
  bool _isSaving = false;

  // ── Step 1: Work & Specialization ──
  String _specialization = 'General Service';
  final _experienceController = TextEditingController();
  String _branch = 'Colombo Service Center';
  String _employmentType = 'FULL_TIME';
  final _skillTagsController = TextEditingController();

  // ── Step 2: Identity & License ──
  final _nicController = TextEditingController();
  final _passportController = TextEditingController();
  final _dobController = TextEditingController();
  String _gender = 'MALE';
  final _licenseNumberController = TextEditingController();
  final _licenseClassesController = TextEditingController(text: 'B');
  final _licenseExpiryController = TextEditingController();

  // ── Step 3: Address & Emergency ──
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  String _district = 'Colombo';
  final _postalCodeController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyRelationController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  // ── Step 4: Banking & Documents ──
  final _bankNameController = TextEditingController();
  final _bankBranchController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();

  // Uploaded documents: Map of documentType -> document metadata Map
  final Map<String, Map<String, dynamic>> _uploadedDocuments = {};
  String? _uploadingType;

  static const List<String> _specializations = [
    'General Service',
    'Engine Repair',
    'Electrical & Diagnostics',
    'Brakes & Suspension',
    'Transmission & Drivetrain',
    'AC & Climate Control',
    'Body & Paintwork',
    'Hybrid & EV Systems',
  ];

  static const List<String> _branches = [
    'Colombo Service Center',
    'Kandy Branch',
    'Galle Service Hub',
    'Negombo Express Center',
    'Kurunegala Center',
  ];

  static const List<String> _districts = [
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Kandy',
    'Matale',
    'Nuwara Eliya',
    'Galle',
    'Matara',
    'Hambantota',
    'Jaffna',
    'Kurunegala',
    'Puttalam',
    'Anuradhapura',
    'Polonnaruwa',
    'Badulla',
    'Ratnapura',
    'Kegalle',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _experienceController.dispose();
    _skillTagsController.dispose();
    _nicController.dispose();
    _passportController.dispose();
    _dobController.dispose();
    _licenseNumberController.dispose();
    _licenseClassesController.dispose();
    _licenseExpiryController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationController.dispose();
    _emergencyPhoneController.dispose();
    _bankNameController.dispose();
    _bankBranchController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final profile = await _supabaseService.getMechanicFullProfile();
      if (profile != null && mounted) {
        setState(() {
          if (profile['specialization'] != null) {
            final s = profile['specialization'].toString();
            if (_specializations.contains(s)) _specialization = s;
          }
          if (profile['experienceYears'] != null) {
            _experienceController.text = profile['experienceYears'].toString();
          }

          final details = profile['details'] as Map<String, dynamic>?;
          if (details != null) {
            if (details['branch'] != null &&
                _branches.contains(details['branch'])) {
              _branch = details['branch'];
            }
            if (details['employmentType'] != null) {
              _employmentType = details['employmentType'];
            }
            _skillTagsController.text = details['skillTags'] ?? '';
            _nicController.text = details['nicNumber'] ?? '';
            _passportController.text = details['passportNumber'] ?? '';
            _dobController.text = details['dateOfBirth'] ?? '';
            if (details['gender'] != null) _gender = details['gender'];
            _licenseNumberController.text =
                details['drivingLicenseNumber'] ?? '';
            _licenseClassesController.text = details['licenseClasses'] ?? 'B';
            _licenseExpiryController.text = details['licenseExpiryDate'] ?? '';

            _address1Controller.text = details['addressLine1'] ?? '';
            _address2Controller.text = details['addressLine2'] ?? '';
            _cityController.text = details['city'] ?? '';
            if (details['district'] != null &&
                _districts.contains(details['district'])) {
              _district = details['district'];
            }
            _postalCodeController.text = details['postalCode'] ?? '';

            _emergencyNameController.text =
                details['emergencyContactName'] ?? '';
            _emergencyRelationController.text =
                details['emergencyContactRelationship'] ?? '';
            _emergencyPhoneController.text =
                details['emergencyContactPhone'] ?? '';

            _bankNameController.text = details['bankName'] ?? '';
            _bankBranchController.text = details['bankBranch'] ?? '';
            _accountHolderController.text = details['accountHolderName'] ?? '';
            _accountNumberController.text = details['accountNumber'] ?? '';
          }

          final docs = profile['documents'] as List<dynamic>?;
          if (docs != null) {
            for (final d in docs) {
              if (d is Map<String, dynamic> && d['documentType'] != null) {
                _uploadedDocuments[d['documentType']] = d;
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading initial profile: $e');
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'specialization': _specialization,
      'experienceYears': int.tryParse(_experienceController.text.trim()),
      'details': {
        'branch': _branch,
        'jobTitle': 'Mechanic',
        'employmentType': _employmentType,
        'skillTags': _skillTagsController.text.trim(),
        'nicNumber': _nicController.text.trim(),
        'passportNumber': _passportController.text.trim(),
        'dateOfBirth': _dobController.text.trim().isNotEmpty
            ? _dobController.text.trim()
            : null,
        'gender': _gender,
        'drivingLicenseNumber': _licenseNumberController.text.trim(),
        'licenseClasses': _licenseClassesController.text.trim(),
        'licenseExpiryDate': _licenseExpiryController.text.trim().isNotEmpty
            ? _licenseExpiryController.text.trim()
            : null,
        'addressLine1': _address1Controller.text.trim(),
        'addressLine2': _address2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'district': _district,
        'postalCode': _postalCodeController.text.trim(),
        'emergencyContactName': _emergencyNameController.text.trim(),
        'emergencyContactRelationship': _emergencyRelationController.text.trim(),
        'emergencyContactPhone': _emergencyPhoneController.text.trim(),
        'bankName': _bankNameController.text.trim(),
        'bankBranch': _bankBranchController.text.trim(),
        'accountHolderName': _accountHolderController.text.trim(),
        'accountNumber': _accountNumberController.text.trim(),
      },
      'documents': _uploadedDocuments.values.toList(),
    };
  }

  Future<void> _pickAndUploadDocument(String documentType) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _uploadingType = documentType);

      final uploaded = await _supabaseService.uploadMechanicDocument(
        file: File(picked.path),
        documentType: documentType,
      );

      if (uploaded != null && mounted) {
        setState(() {
          _uploadedDocuments[documentType] = uploaded;
        });
        _showSnackBar('$documentType uploaded successfully', isError: false);
      } else if (mounted) {
        _showSnackBar('Upload failed. Please try again.', isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error picking file: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingType = null);
    }
  }

  Future<void> _handleSaveDraft() async {
    setState(() => _isSaving = true);
    try {
      final success =
          await _supabaseService.updateMechanicProfile(_buildPayload());
      if (mounted) {
        if (success) {
          _showSnackBar('Profile draft saved successfully!', isError: false);
          context.pop();
        } else {
          _showSnackBar('Failed to save draft.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleSubmitForVerification() async {
    // Validate required verification details
    if (_nicController.text.trim().isEmpty &&
        _passportController.text.trim().isEmpty) {
      _showSnackBar('Please enter your NIC or Passport number (Step 2).');
      setState(() => _currentStep = 2);
      return;
    }

    if (_licenseNumberController.text.trim().isEmpty) {
      _showSnackBar('Please enter your Driving License number (Step 2).');
      setState(() => _currentStep = 2);
      return;
    }

    if (_emergencyPhoneController.text.trim().length != 10) {
      _showSnackBar('Please enter a valid 10-digit emergency contact phone (Step 3).');
      setState(() => _currentStep = 3);
      return;
    }

    if (_accountNumberController.text.trim().isEmpty ||
        _bankNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter your bank name and account number (Step 4).');
      setState(() => _currentStep = 4);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final success =
          await _supabaseService.submitMechanicVerification(_buildPayload());
      if (mounted) {
        if (success) {
          _showSnackBar(
            'Profile submitted for admin verification!',
            isError: false,
          );
          context.go('/worker');
        } else {
          _showSnackBar(
            'Failed to submit for verification. Check details.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
    if (_isLoadingInitial) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF7F5),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
        ),
      );
    }

    String title;
    String subtitle;
    switch (_currentStep) {
      case 1:
        title = 'Work & Experience';
        subtitle = 'Tell us about your technical specialties and service branch.';
        break;
      case 2:
        title = 'Identity & License';
        subtitle = 'Provide official identification and driving credentials.';
        break;
      case 3:
        title = 'Address & Contact';
        subtitle = 'Enter your residential address and an emergency contact.';
        break;
      case 4:
      default:
        title = 'Bank & Documents';
        subtitle = 'Add payout account details and upload verification copies.';
        break;
    }

    return SignUpScaffold(
      children: [
        SignUpHeader(
          step: _currentStep,
          totalSteps: _totalSteps,
          title: title,
          subtitle: subtitle,
          onBack: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentStep == 1) _buildStep1Work(),
                if (_currentStep == 2) _buildStep2Identity(),
                if (_currentStep == 3) _buildStep3Address(),
                if (_currentStep == 4) _buildStep4BankAndDocs(),
                const SizedBox(height: 24),

                // Primary Next / Submit Button
                SignUpPrimaryButton(
                  label: _currentStep < _totalSteps
                      ? 'Next Step'
                      : 'Submit for Admin Verification',
                  isLoading: _isSaving,
                  onTap: () {
                    if (_currentStep < _totalSteps) {
                      setState(() => _currentStep++);
                    } else {
                      _handleSubmitForVerification();
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Save draft button
                SignUpSecondaryButton(
                  label: 'Save Draft & Exit',
                  onTap: _isSaving ? null : _handleSaveDraft,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 1: Work & Experience ──
  Widget _buildStep1Work() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SignUpLabel('PRIMARY SPECIALIZATION *'),
        const SizedBox(height: 8),
        SignUpDropdownField<String>(
          value: _specialization,
          hint: 'Select specialization',
          items: _specializations
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _specialization = val);
          },
        ),
        const SizedBox(height: 16),

        const SignUpLabel('YEARS OF EXPERIENCE'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _experienceController,
          hint: 'e.g. 5',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),

        const SignUpLabel('PREFERRED SERVICE BRANCH *'),
        const SizedBox(height: 8),
        SignUpDropdownField<String>(
          value: _branch,
          hint: 'Select branch',
          items: _branches
              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _branch = val);
          },
        ),
        const SizedBox(height: 16),

        const SignUpLabel('EMPLOYMENT TYPE'),
        const SizedBox(height: 8),
        SignUpDropdownField<String>(
          value: _employmentType,
          hint: 'Select employment type',
          items: const [
            DropdownMenuItem(value: 'FULL_TIME', child: Text('Full-time')),
            DropdownMenuItem(value: 'PART_TIME', child: Text('Part-time')),
            DropdownMenuItem(value: 'CONTRACT', child: Text('Contract')),
            DropdownMenuItem(value: 'TRAINEE', child: Text('Trainee')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _employmentType = val);
          },
        ),
        const SizedBox(height: 16),

        const SignUpLabel('ADDITIONAL SKILLS & TAGS'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _skillTagsController,
          hint: 'e.g. EFI diagnostics, Hybrid battery, Wheel alignment',
          maxLines: 2,
        ),
      ],
    );
  }

  // ── Step 2: Identity & License ──
  Widget _buildStep2Identity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SignUpLabel('NATIONAL IDENTITY CARD (NIC) NUMBER *'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _nicController,
          hint: 'e.g. 199512345678 or 951234567V',
        ),
        const SizedBox(height: 16),

        const SignUpLabel('PASSPORT NUMBER (OPTIONAL)'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _passportController,
          hint: 'e.g. N1234567',
        ),
        const SizedBox(height: 16),

        const SignUpLabel('DATE OF BIRTH (YYYY-MM-DD)'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _dobController,
          hint: 'e.g. 1995-05-18',
          keyboardType: TextInputType.datetime,
        ),
        const SizedBox(height: 16),

        const SignUpLabel('GENDER'),
        const SizedBox(height: 8),
        SignUpDropdownField<String>(
          value: _gender,
          hint: 'Select gender',
          items: const [
            DropdownMenuItem(value: 'MALE', child: Text('Male')),
            DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
            DropdownMenuItem(value: 'OTHER', child: Text('Other')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _gender = val);
          },
        ),
        const SizedBox(height: 16),

        const SignUpLabel('DRIVING LICENSE NUMBER *'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _licenseNumberController,
          hint: 'e.g. B1234567',
        ),
        const SizedBox(height: 16),

        const SignUpLabel('LICENSE CLASSES'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _licenseClassesController,
          hint: 'e.g. A1, B, G1',
        ),
        const SizedBox(height: 16),

        const SignUpLabel('LICENSE EXPIRY DATE (YYYY-MM-DD)'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _licenseExpiryController,
          hint: 'e.g. 2028-12-31',
          keyboardType: TextInputType.datetime,
        ),
      ],
    );
  }

  // ── Step 3: Address & Emergency Contact ──
  Widget _buildStep3Address() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SignUpLabel('RESIDENTIAL ADDRESS LINE 1 *'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _address1Controller,
          hint: 'e.g. 45/2 Temple Road',
        ),
        const SizedBox(height: 16),

        const SignUpLabel('ADDRESS LINE 2'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _address2Controller,
          hint: 'e.g. Maharagama',
        ),
        const SizedBox(height: 16),

        const SignUpLabel('CITY *'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _cityController,
          hint: 'e.g. Colombo',
        ),
        const SizedBox(height: 16),

        const SignUpLabel('DISTRICT *'),
        const SizedBox(height: 8),
        SignUpDropdownField<String>(
          value: _district,
          hint: 'Select district',
          items: _districts
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _district = val);
          },
        ),
        const SizedBox(height: 16),

        const SignUpLabel('POSTAL CODE'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _postalCodeController,
          hint: 'e.g. 10280',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Icon(PhosphorIconsRegular.phoneCall,
                size: 20, color: const Color(0xFFFF5D2E)),
            const SizedBox(width: 8),
            Text(
              'Emergency Contact',
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        const SignUpLabel('CONTACT PERSON NAME *'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _emergencyNameController,
          hint: 'e.g. Priyanthi Perera',
        ),
        const SizedBox(height: 16),

        const SignUpLabel('RELATIONSHIP *'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _emergencyRelationController,
          hint: 'e.g. Spouse / Mother / Brother',
        ),
        const SizedBox(height: 16),

        const SignUpLabel('EMERGENCY PHONE NUMBER *'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _emergencyPhoneController,
          hint: 'e.g. 0719876543',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
      ],
    );
  }

  // ── Step 4: Bank Details & Documents ──
  Widget _buildStep4BankAndDocs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(PhosphorIconsRegular.bank,
                size: 20, color: const Color(0xFFFF5D2E)),
            const SizedBox(width: 8),
            Text(
              'Banking & Payroll',
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        const SignUpLabel('BANK NAME *'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _bankNameController,
          hint: 'e.g. Commercial Bank of Ceylon',
        ),
        const SizedBox(height: 16),

        const SignUpLabel('BRANCH NAME *'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _bankBranchController,
          hint: 'e.g. Colombo Main Branch',
        ),
        const SizedBox(height: 16),

        const SignUpLabel('ACCOUNT HOLDER NAME *'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _accountHolderController,
          hint: 'e.g. K. A. Kasun Perera',
        ),
        const SizedBox(height: 16),

        const SignUpLabel('ACCOUNT NUMBER *'),
        const SizedBox(height: 8),
        SignUpInputField(
          controller: _accountNumberController,
          hint: 'e.g. 8001234567',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Icon(PhosphorIconsRegular.fileText,
                size: 20, color: const Color(0xFFFF5D2E)),
            const SizedBox(width: 8),
            Text(
              'Verification Documents',
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Upload clear photos or scans of your identification documents.',
          style: GoogleFonts.instrumentSans(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 16),

        _buildDocumentUploadTile(
          title: 'Profile Photo',
          subtitle: 'A clear passport-style headshot',
          documentType: 'PROFILE_PHOTO',
          icon: PhosphorIconsRegular.userCircle,
        ),
        const SizedBox(height: 12),

        _buildDocumentUploadTile(
          title: 'NIC / Passport Copy *',
          subtitle: 'Front & back of your National ID',
          documentType: 'NIC_COPY',
          icon: PhosphorIconsRegular.identificationCard,
        ),
        const SizedBox(height: 12),

        _buildDocumentUploadTile(
          title: 'Driving License Copy *',
          subtitle: 'Valid driver license document',
          documentType: 'DRIVING_LICENSE',
          icon: PhosphorIconsRegular.car,
        ),
        const SizedBox(height: 12),

        _buildDocumentUploadTile(
          title: 'Training Certificate (Optional)',
          subtitle: 'Vocational or technical qualification',
          documentType: 'CERTIFICATE',
          icon: PhosphorIconsRegular.certificate,
        ),
        const SizedBox(height: 12),

        _buildDocumentUploadTile(
          title: 'Police Clearance (Optional)',
          subtitle: 'Background verification certificate',
          documentType: 'POLICE_CLEARANCE',
          icon: PhosphorIconsRegular.shieldCheck,
        ),
      ],
    );
  }

  Widget _buildDocumentUploadTile({
    required String title,
    required String subtitle,
    required String documentType,
    required IconData icon,
  }) {
    final uploaded = _uploadedDocuments[documentType];
    final isCurrentUploading = _uploadingType == documentType;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: uploaded != null
              ? const Color(0xFF10B981)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: uploaded != null
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFFFE7DF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              uploaded != null ? PhosphorIconsRegular.check : icon,
              size: 22,
              color: uploaded != null
                  ? const Color(0xFF059669)
                  : const Color(0xFFFF5D2E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  uploaded != null ? 'Uploaded & attached' : subtitle,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 12,
                    color: uploaded != null
                        ? const Color(0xFF059669)
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isCurrentUploading
                ? null
                : () => _pickAndUploadDocument(documentType),
            style: ElevatedButton.styleFrom(
              backgroundColor: uploaded != null
                  ? const Color(0xFFF3F4F6)
                  : const Color(0xFFFF5D2E),
              foregroundColor:
                  uploaded != null ? Colors.black87 : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isCurrentUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    uploaded != null ? 'Change' : 'Upload',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
