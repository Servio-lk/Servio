import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Helper to resolve dynamic icons, images, and colors for automotive service categories.
class ServiceIconHelper {
  ServiceIconHelper._();

  static const Map<String, String> _assetIconMap = {
    'washing packages': 'assets/service icons/Washing Packages.png',
    'car wash': 'assets/service icons/Washing Packages.png',
    'lube services': 'assets/service icons/Lube Services.png',
    'lubricant service': 'assets/service icons/Lube Services.png',
    'oil change': 'assets/service icons/Lube Services.png',
    'exterior & interior detailing': 'assets/service icons/Exterior & Interior Detailing.png',
    'exterior detailing': 'assets/service icons/Exterior & Interior Detailing.png',
    'interior detailing': 'assets/service icons/Exterior & Interior Detailing.png',
    'detailing': 'assets/service icons/Exterior & Interior Detailing.png',
    'engine tune ups': 'assets/service icons/Engine Tune ups.png',
    'engine tune up': 'assets/service icons/Engine Tune ups.png',
    'engine repair': 'assets/service icons/Engine Tune ups.png',
    'inspection reports': 'assets/service icons/Inspection Reports.png',
    'multipoint inspection': 'assets/service icons/Inspection Reports.png',
    'tyre services': 'assets/service icons/Tyre Services.png',
    'tire services': 'assets/service icons/Tyre Services.png',
    'battery services': 'assets/service icons/Battery Services.png',
    'electrical & electronic': 'assets/service icons/Battery Services.png',
    'insurance claims': 'assets/service icons/Insurance Claims.png',
    'full paints': 'assets/service icons/Full Paints.png',
    'paint': 'assets/service icons/Full Paints.png',
    'waxing': 'assets/service icons/Waxing.png',
    'undercarriage degreasing': 'assets/service icons/Undercarriage Degreasing.png',
    'windscreen treatments': 'assets/service icons/Windscreen Treatments.png',
    'wheel alignment': 'assets/service icons/Wheel Alignment.png',
    'part replacements': 'assets/service icons/Part Replacements.png',
    'nano coating packages': 'assets/service icons/Nano Coating Packages.png',
    'nano coating treatments': 'assets/service icons/Nano Coating Treatments.png',
  };

  /// Returns the asset path for a known service type, or null if no PNG asset exists.
  static String? getAssetIconPath(String? serviceName) {
    if (serviceName == null || serviceName.trim().isEmpty) return null;
    final lower = serviceName.trim().toLowerCase();

    if (_assetIconMap.containsKey(lower)) {
      return _assetIconMap[lower];
    }

    for (final entry in _assetIconMap.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Returns a Phosphor IconData representing the service.
  static IconData getPhosphorIcon(String? serviceName) {
    if (serviceName == null || serviceName.trim().isEmpty) {
      return PhosphorIconsFill.wrench;
    }

    final lower = serviceName.trim().toLowerCase();

    // Oil / Fluids
    if (lower.contains('lube') || lower.contains('oil') || lower.contains('fluid')) {
      return PhosphorIconsFill.drop;
    }

    // Engine / Mechanical
    if (lower.contains('engine') || lower.contains('tune') || lower.contains('mechanical')) {
      return PhosphorIconsFill.gearSix;
    }

    // Brakes
    if (lower.contains('brake') || lower.contains('pad') || lower.contains('rotor')) {
      return PhosphorIconsFill.disc;
    }

    // Battery / Electrical / Hybrid
    if (lower.contains('battery') ||
        lower.contains('electric') ||
        lower.contains('hybrid') ||
        lower.contains('alternator')) {
      return PhosphorIconsFill.lightning;
    }

    // Tyres & Wheels
    if (lower.contains('tyre') ||
        lower.contains('tire') ||
        lower.contains('wheel') ||
        lower.contains('alignment')) {
      return PhosphorIconsFill.steeringWheel;
    }

    // AC & Climate
    if (lower.contains('ac') ||
        lower.contains('air conditioning') ||
        lower.contains('climate') ||
        lower.contains('cooling') ||
        lower.contains('radiator')) {
      return PhosphorIconsFill.fan;
    }

    // Wash & Clean
    if (lower.contains('wash') || lower.contains('cleaning') || lower.contains('steam')) {
      return PhosphorIconsFill.shower;
    }

    // Detailing, Paint, Polish, Wax
    if (lower.contains('detail') ||
        lower.contains('paint') ||
        lower.contains('wax') ||
        lower.contains('coating') ||
        lower.contains('polish') ||
        lower.contains('nano')) {
      return PhosphorIconsFill.sparkle;
    }

    // Inspections
    if (lower.contains('inspect') || lower.contains('report') || lower.contains('diagnostic')) {
      return PhosphorIconsFill.clipboardText;
    }

    // Insurance & Collision
    if (lower.contains('insurance') || lower.contains('claim') || lower.contains('collision')) {
      return PhosphorIconsFill.shieldCheck;
    }

    // Parts & Replacements
    if (lower.contains('part') || lower.contains('replacement') || lower.contains('suspension')) {
      return PhosphorIconsFill.nut;
    }

    // Windscreen & Glass
    if (lower.contains('windscreen') || lower.contains('glass') || lower.contains('window')) {
      return PhosphorIconsFill.car;
    }

    return PhosphorIconsFill.wrench;
  }

  /// Returns recommended primary and background accent colors for the service.
  static ({Color primary, Color background}) getServiceColors(String? serviceName) {
    if (serviceName == null || serviceName.trim().isEmpty) {
      return (primary: const Color(0xFFFF5D2E), background: const Color(0xFFFFECE5));
    }

    final lower = serviceName.trim().toLowerCase();

    if (lower.contains('lube') || lower.contains('oil')) {
      return (primary: const Color(0xFFD97706), background: const Color(0xFFFEF3C7));
    }
    if (lower.contains('engine') || lower.contains('tune')) {
      return (primary: const Color(0xFFDC2626), background: const Color(0xFFFEE2E2));
    }
    if (lower.contains('brake')) {
      return (primary: const Color(0xFFE11D48), background: const Color(0xFFFFE4E6));
    }
    if (lower.contains('battery') || lower.contains('electric')) {
      return (primary: const Color(0xFF0284C7), background: const Color(0xFFE0F2FE));
    }
    if (lower.contains('tyre') || lower.contains('tire') || lower.contains('wheel')) {
      return (primary: const Color(0xFF475569), background: const Color(0xFFF1F5F9));
    }
    if (lower.contains('ac') || lower.contains('air conditioning')) {
      return (primary: const Color(0xFF0D9488), background: const Color(0xFFCCFBF1));
    }
    if (lower.contains('wash') || lower.contains('clean')) {
      return (primary: const Color(0xFF2563EB), background: const Color(0xFFDBEAFE));
    }
    if (lower.contains('detail') || lower.contains('paint') || lower.contains('wax') || lower.contains('coating')) {
      return (primary: const Color(0xFF7C3AED), background: const Color(0xFFEDE9FE));
    }
    if (lower.contains('inspect')) {
      return (primary: const Color(0xFF059669), background: const Color(0xFFD1FAE5));
    }

    return (primary: const Color(0xFFFF5D2E), background: const Color(0xFFFFECE5));
  }

  /// Builds a widget badge or avatar icon with service-specific styling.
  static Widget buildServiceBadge(
    String? serviceName, {
    double size = 44,
    double iconSize = 22,
    bool showAssetImage = true,
  }) {
    final colors = getServiceColors(serviceName);
    final iconData = getPhosphorIcon(serviceName);
    final assetPath = showAssetImage ? getAssetIconPath(serviceName) : null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: assetPath != null
          ? Image.asset(
              assetPath,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                iconData,
                size: iconSize,
                color: colors.primary,
              ),
            )
          : Icon(
              iconData,
              size: iconSize,
              color: colors.primary,
            ),
    );
  }
}
