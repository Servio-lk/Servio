import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_core/shared_core.dart';

class MechanicSignupVerifyScreen extends StatefulWidget {
  final Map<String, dynamic> mechanic;
  const MechanicSignupVerifyScreen({super.key, required this.mechanic});

  @override
  State<MechanicSignupVerifyScreen> createState() =>
      _MechanicSignupVerifyScreenState();
}

class _MechanicSignupVerifyScreenState
    extends State<MechanicSignupVerifyScreen> {
  final _supabaseService = SupabaseService();
  bool _isLoading = false;

  Future<void> _reportError() async {
    setState(() => _isLoading = true);
    try {
      final success = await _supabaseService
          .reportMechanicErrorToBackend(widget.mechanic['email']);
      if (mounted) {
        if (success) {
          _showSnackBar(
              'Error reported. An admin will check and update your details.',
              isError: false);
          context.go('/signin');
        } else {
          _showSnackBar('Failed to report error. Please try again.',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to report error.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.instrumentSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify Your Information',
                style: GoogleFonts.instrumentSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Please verify that the information below matches your details.",
                style: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 22 / 16,
                ),
              ),
              const SizedBox(height: 32),
              _buildDetailRow('Full Name', widget.mechanic['full_name'] ?? 'N/A'),
              _buildDetailRow('Email', widget.mechanic['email'] ?? 'N/A'),
              _buildDetailRow('Phone', widget.mechanic['phone'] ?? 'N/A'),
              _buildDetailRow(
                  'Specialization', widget.mechanic['specialization'] ?? 'N/A'),
              _buildDetailRow(
                  'Experience (Years)',
                  widget.mechanic['experience_years']?.toString() ?? 'N/A'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 59,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          context.push('/signup/password', extra: {
                            'mechanic': widget.mechanic,
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5D2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: _isLoading ? 0 : 8,
                    shadowColor: const Color(0xFFFF5D2E).withOpacity(0.5),
                  ),
                  child: Text(
                    'Looks Good, Proceed',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 59,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _reportError,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Information is Wrong',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
