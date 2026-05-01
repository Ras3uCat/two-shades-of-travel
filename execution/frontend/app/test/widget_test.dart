// Core unit tests for Raspucat client template.
// Run: flutter test
//
// These tests cover pure business logic — no network, no widgets, no dart-define
// required. AppEnv default values are used throughout.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:raspucat_client/core/config/app_env.dart';
import 'package:raspucat_client/core/theme/e_colors.dart';
import 'package:raspucat_client/core/theme/e_spacing.dart';

void main() {
  // ── EColors ────────────────────────────────────────────────────────────────

  group('EColors', () {
    test('default primary parses to correct Color', () {
      // AppEnv.colorPrimary defaults to '6750A4' (Material You purple)
      expect(EColors.primary, const Color(0xFF6750A4));
    });

    test('default surface parses to correct Color', () {
      // AppEnv.colorSurface defaults to 'FFFBFE'
      expect(EColors.surface, const Color(0xFFFFFBFE));
    });

    test('default error parses to correct Color', () {
      expect(EColors.error, const Color(0xFFB3261E));
    });

    test('colors are fully opaque', () {
      expect(EColors.primary.a, 1.0);
      expect(EColors.surface.a, 1.0);
    });

    test('onSurfaceMuted is semi-transparent', () {
      // onSurfaceMuted = onSurface.withValues(alpha: 0.5)
      expect(EColors.onSurfaceMuted.a, closeTo(0.5, 0.01));
    });
  });

  // ── ESpacing ───────────────────────────────────────────────────────────────

  group('ESpacing', () {
    test('base scale follows 8pt grid', () {
      expect(ESpacing.xs,   8.0);
      expect(ESpacing.sm,  12.0);
      expect(ESpacing.md,  16.0);
      expect(ESpacing.lg,  24.0);
      expect(ESpacing.xl,  32.0);
      expect(ESpacing.xxl, 48.0);
    });

    test('section gap constants are defined', () {
      expect(ESpacing.sectionGapV,       80.0);
      expect(ESpacing.sectionGapVMobile, 56.0);
    });

    test('sectionGap resolves to one of the two gap values', () {
      // In test (Dart VM), kIsWeb = false → sectionGap = sectionGapVMobile
      expect(
        ESpacing.sectionGap == ESpacing.sectionGapV ||
            ESpacing.sectionGap == ESpacing.sectionGapVMobile,
        isTrue,
      );
    });

    test('responsive breakpoints are ascending', () {
      expect(ESpacing.mobileBreak, lessThan(ESpacing.tabletBreak));
      expect(ESpacing.tabletBreak, lessThan(ESpacing.desktopBreak));
    });
  });

  // ── AppEnv defaults ────────────────────────────────────────────────────────

  group('AppEnv defaults', () {
    test('clientName has a non-empty default', () {
      expect(AppEnv.clientName, isNotEmpty);
    });

    test('personality is a known value', () {
      const valid = {'luxury', 'minimal', 'bold', 'warm', 'corporate'};
      expect(valid.contains(AppEnv.personality), isTrue);
    });

    test('font fields are non-empty', () {
      expect(AppEnv.fontPrimary,   isNotEmpty);
      expect(AppEnv.fontSecondary, isNotEmpty);
    });

    test('stripeMode is a recognised value', () {
      const valid = {'standard', 'connect_multi_staff', 'none', ''};
      expect(valid.contains(AppEnv.stripeMode), isTrue);
    });
  });
}
