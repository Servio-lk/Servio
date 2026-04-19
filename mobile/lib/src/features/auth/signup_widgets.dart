import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// ─── Color constants ─────────────────────────────────────────────────────────
const Color _kPrimaryOrange = Color(0xFFFF5D2E);
const Color _kSubtitleGrey = Color(0xFF4B4B4B);
const Color _kHintGrey = Color(0xFF8A8A8A);
const Color _kProgressTrack = Color(0xFFD6DADB);
const Color _kInputBg = Colors.white;

// ─── Progress Bar ────────────────────────────────────────────────────────────

class SignUpProgressBar extends StatelessWidget {
  final int filledSteps;
  final int totalSteps;

  const SignUpProgressBar({
    super.key,
    required this.filledSteps,
    this.totalSteps = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 4,
      decoration: BoxDecoration(
        color: _kProgressTrack,
        borderRadius: BorderRadius.circular(2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Row(
          children: List.generate(totalSteps, (i) {
            return Container(
              width: 160.0 / totalSteps,
              height: 4,
              color: i < filledSteps ? _kPrimaryOrange : Colors.transparent,
            );
          }),
        ),
      ),
    );
  }
}

// ─── Header (Back + Progress + Title + Subtitle) ─────────────────────────────

class SignUpHeader extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const SignUpHeader({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: onBack,
                  child: const Align(
                    alignment: Alignment.center,
                    child: Icon(
                      PhosphorIconsBold.arrowLeft,
                      size: 24,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Center(
                    child: SignUpProgressBar(filledSteps: step),
                  ),
                ),
              ),
            ],
          ),
          Text(
            title,
            style: GoogleFonts.instrumentSans(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.instrumentSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _kSubtitleGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Label ───────────────────────────────────────────────────────────────────

class SignUpLabel extends StatelessWidget {
  final String text;
  const SignUpLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.instrumentSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black,
        letterSpacing: -0.08,
        height: 16 / 13,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}

// ─── Helper Text ─────────────────────────────────────────────────────────────

class SignUpHelperText extends StatelessWidget {
  final String text;
  const SignUpHelperText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.instrumentSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _kSubtitleGrey,
        letterSpacing: 0.36,
        height: 16 / 12,
      ),
    );
  }
}

// ─── Input Field ─────────────────────────────────────────────────────────────

class SignUpInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;

  const SignUpInputField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 59),
      decoration: BoxDecoration(
        color: _kInputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              validator: validator,
              readOnly: readOnly,
              onTap: onTap,
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _kHintGrey,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Password Field ──────────────────────────────────────────────────────────

class SignUpPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const SignUpPasswordField({
    super.key,
    required this.controller,
    this.hint = 'Password',
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 59),
      decoration: BoxDecoration(
        color: _kInputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              validator: validator,
              style: GoogleFonts.instrumentSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _kHintGrey,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                obscure
                    ? PhosphorIconsRegular.eyeSlash
                    : PhosphorIconsRegular.eye,
                size: 24,
                color: _kSubtitleGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Primary Button ──────────────────────────────────────────────────────────

class SignUpPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const SignUpPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isLoading
              ? _kPrimaryOrange.withOpacity(0.6)
              : _kPrimaryOrange,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: _kPrimaryOrange.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

// ─── Secondary Button ────────────────────────────────────────────────────────

class SignUpSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const SignUpSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE7DF)),
        ),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.instrumentSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

// ─── Scaffold wrapper with gradient background ───────────────────────────────

class SignUpScaffold extends StatelessWidget {
  final List<Widget> children;

  const SignUpScaffold({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF7F5), Color(0xFFFBFBFB)],
          ),
        ),
        child: SafeArea(
          child: Column(children: children),
        ),
      ),
    );
  }
}
