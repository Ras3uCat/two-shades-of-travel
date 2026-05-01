import 'package:flutter/material.dart';
import '../config/app_env.dart';

/// EColors — all brand colors resolved from AppEnv (client.json).
/// Always consume EColors.xxx — never hardcode hex values in widgets.
class EColors {
  EColors._();

  static Color _hex(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    final value = int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16);
    return Color(value);
  }

  static Color get primary    => _hex(AppEnv.colorPrimary);
  static Color get secondary  => _hex(AppEnv.colorSecondary);
  static Color get accent     => _hex(AppEnv.colorAccent);
  static Color get surface    => _hex(AppEnv.colorSurface);
  static Color get onSurface  => _hex(AppEnv.colorOnSurface);
  static Color get error      => _hex(AppEnv.colorError);

  // Derived
  static Color get primaryLight   => primary.withValues(alpha: 0.15);
  static Color get primaryMedium  => primary.withValues(alpha: 0.5);
  static Color get surfaceVariant => onSurface.withValues(alpha: 0.05);
  static Color get divider        => onSurface.withValues(alpha: 0.12);
  static Color get onSurfaceMuted => onSurface.withValues(alpha: 0.5);
  static Color get transparent    => Colors.transparent;
  static Color get white          => Colors.white;
  static Color get black          => Colors.black;
}
