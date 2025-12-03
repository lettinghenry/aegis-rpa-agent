import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/theme/app_theme.dart';

void main() {
  group('AppTheme Color Scheme Definitions', () {
    test('status colors are defined correctly', () {
      expect(AppTheme.successGreen, const Color(0xFF4CAF50));
      expect(AppTheme.errorRed, const Color(0xFFE53935));
      expect(AppTheme.inProgressBlue, const Color(0xFF2196F3));
      expect(AppTheme.warningOrange, const Color(0xFFFF9800));
      expect(AppTheme.pendingGrey, const Color(0xFF9E9E9E));
    });

    test('light theme has correct brightness', () {
      final theme = AppTheme.lightTheme();
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('dark theme has correct brightness', () {
      final theme = AppTheme.darkTheme();
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('light theme uses Material 3', () {
      final theme = AppTheme.lightTheme();
      expect(theme.useMaterial3, true);
    });

    test('dark theme uses Material 3', () {
      final theme = AppTheme.darkTheme();
      expect(theme.useMaterial3, true);
    });

    test('light theme has correct primary color', () {
      final theme = AppTheme.lightTheme();
      expect(theme.colorScheme.primary, const Color(0xFF2196F3));
    });

    test('dark theme has correct primary color', () {
      final theme = AppTheme.darkTheme();
      expect(theme.colorScheme.primary, const Color(0xFF64B5F6));
    });

    test('light theme has correct error color', () {
      final theme = AppTheme.lightTheme();
      expect(theme.colorScheme.error, AppTheme.errorRed);
    });

    test('dark theme has correct error color', () {
      final theme = AppTheme.darkTheme();
      expect(theme.colorScheme.error, const Color(0xFFEF5350));
    });

    test('light theme has correct surface colors', () {
      final theme = AppTheme.lightTheme();
      expect(theme.colorScheme.surface, Colors.white);
      expect(theme.colorScheme.onSurface, const Color(0xFF1C1B1F));
    });

    test('dark theme has correct surface colors', () {
      final theme = AppTheme.darkTheme();
      expect(theme.colorScheme.surface, const Color(0xFF1C1B1F));
      expect(theme.colorScheme.onSurface, const Color(0xFFE6E1E5));
    });
  });

  group('AppTheme Status Color Mappings', () {
    test('getStatusColor returns success green for completed status', () {
      expect(AppTheme.getStatusColor('completed'), AppTheme.successGreen);
      expect(AppTheme.getStatusColor('Completed'), AppTheme.successGreen);
      expect(AppTheme.getStatusColor('COMPLETED'), AppTheme.successGreen);
    });

    test('getStatusColor returns success green for success status', () {
      expect(AppTheme.getStatusColor('success'), AppTheme.successGreen);
      expect(AppTheme.getStatusColor('Success'), AppTheme.successGreen);
    });

    test('getStatusColor returns error red for failed status', () {
      expect(AppTheme.getStatusColor('failed'), AppTheme.errorRed);
      expect(AppTheme.getStatusColor('Failed'), AppTheme.errorRed);
      expect(AppTheme.getStatusColor('FAILED'), AppTheme.errorRed);
    });

    test('getStatusColor returns error red for error status', () {
      expect(AppTheme.getStatusColor('error'), AppTheme.errorRed);
      expect(AppTheme.getStatusColor('Error'), AppTheme.errorRed);
    });

    test('getStatusColor returns in-progress blue for in_progress status', () {
      expect(AppTheme.getStatusColor('in_progress'), AppTheme.inProgressBlue);
      expect(AppTheme.getStatusColor('In_Progress'), AppTheme.inProgressBlue);
    });

    test('getStatusColor returns in-progress blue for in-progress status', () {
      expect(AppTheme.getStatusColor('in-progress'), AppTheme.inProgressBlue);
      expect(AppTheme.getStatusColor('In-Progress'), AppTheme.inProgressBlue);
    });

    test('getStatusColor returns in-progress blue for running status', () {
      expect(AppTheme.getStatusColor('running'), AppTheme.inProgressBlue);
      expect(AppTheme.getStatusColor('Running'), AppTheme.inProgressBlue);
    });

    test('getStatusColor returns pending grey for pending status', () {
      expect(AppTheme.getStatusColor('pending'), AppTheme.pendingGrey);
      expect(AppTheme.getStatusColor('Pending'), AppTheme.pendingGrey);
    });

    test('getStatusColor returns warning orange for cancelled status', () {
      expect(AppTheme.getStatusColor('cancelled'), AppTheme.warningOrange);
      expect(AppTheme.getStatusColor('Cancelled'), AppTheme.warningOrange);
    });

    test('getStatusColor returns pending grey for unknown status', () {
      expect(AppTheme.getStatusColor('unknown'), AppTheme.pendingGrey);
      expect(AppTheme.getStatusColor('invalid'), AppTheme.pendingGrey);
      expect(AppTheme.getStatusColor(''), AppTheme.pendingGrey);
    });

    test('getStatusIcon returns correct icon for completed status', () {
      expect(AppTheme.getStatusIcon('completed'), Icons.check_circle);
      expect(AppTheme.getStatusIcon('success'), Icons.check_circle);
    });

    test('getStatusIcon returns correct icon for failed status', () {
      expect(AppTheme.getStatusIcon('failed'), Icons.error);
      expect(AppTheme.getStatusIcon('error'), Icons.error);
    });

    test('getStatusIcon returns correct icon for in_progress status', () {
      expect(AppTheme.getStatusIcon('in_progress'), Icons.pending);
      expect(AppTheme.getStatusIcon('in-progress'), Icons.pending);
      expect(AppTheme.getStatusIcon('running'), Icons.pending);
    });

    test('getStatusIcon returns correct icon for pending status', () {
      expect(AppTheme.getStatusIcon('pending'), Icons.schedule);
    });

    test('getStatusIcon returns correct icon for cancelled status', () {
      expect(AppTheme.getStatusIcon('cancelled'), Icons.cancel);
    });

    test('getStatusIcon returns help icon for unknown status', () {
      expect(AppTheme.getStatusIcon('unknown'), Icons.help_outline);
      expect(AppTheme.getStatusIcon(''), Icons.help_outline);
    });
  });

  group('AppTheme Theme Switching', () {
    test('light and dark themes have different color schemes', () {
      final lightTheme = AppTheme.lightTheme();
      final darkTheme = AppTheme.darkTheme();

      expect(lightTheme.colorScheme.brightness, Brightness.light);
      expect(darkTheme.colorScheme.brightness, Brightness.dark);
      
      // Primary colors should be different
      expect(lightTheme.colorScheme.primary, isNot(equals(darkTheme.colorScheme.primary)));
      
      // Surface colors should be different
      expect(lightTheme.colorScheme.surface, isNot(equals(darkTheme.colorScheme.surface)));
    });

    test('both themes have consistent component styling', () {
      final lightTheme = AppTheme.lightTheme();
      final darkTheme = AppTheme.darkTheme();

      // Card elevation should be the same
      expect(lightTheme.cardTheme.elevation, darkTheme.cardTheme.elevation);
      
      // Card border radius should be the same
      final lightCardShape = lightTheme.cardTheme.shape as RoundedRectangleBorder;
      final darkCardShape = darkTheme.cardTheme.shape as RoundedRectangleBorder;
      expect(
        (lightCardShape.borderRadius as BorderRadius).topLeft.x,
        (darkCardShape.borderRadius as BorderRadius).topLeft.x,
      );

      // Button padding should be the same
      final lightButtonStyle = lightTheme.elevatedButtonTheme.style!;
      final darkButtonStyle = darkTheme.elevatedButtonTheme.style!;
      expect(
        lightButtonStyle.padding?.resolve({}),
        darkButtonStyle.padding?.resolve({}),
      );
    });

    test('both themes have Material 3 text theme', () {
      final lightTheme = AppTheme.lightTheme();
      final darkTheme = AppTheme.darkTheme();

      // Check that text themes are defined
      expect(lightTheme.textTheme.displayLarge, isNotNull);
      expect(darkTheme.textTheme.displayLarge, isNotNull);
      
      expect(lightTheme.textTheme.headlineMedium, isNotNull);
      expect(darkTheme.textTheme.headlineMedium, isNotNull);
      
      expect(lightTheme.textTheme.bodyLarge, isNotNull);
      expect(darkTheme.textTheme.bodyLarge, isNotNull);

      // Font sizes should be the same across themes
      expect(
        lightTheme.textTheme.displayLarge!.fontSize,
        darkTheme.textTheme.displayLarge!.fontSize,
      );
      expect(
        lightTheme.textTheme.bodyMedium!.fontSize,
        darkTheme.textTheme.bodyMedium!.fontSize,
      );
    });

    test('both themes have app bar configuration', () {
      final lightTheme = AppTheme.lightTheme();
      final darkTheme = AppTheme.darkTheme();

      expect(lightTheme.appBarTheme.elevation, 0);
      expect(darkTheme.appBarTheme.elevation, 0);
      
      expect(lightTheme.appBarTheme.centerTitle, false);
      expect(darkTheme.appBarTheme.centerTitle, false);
    });

    test('both themes have input decoration configuration', () {
      final lightTheme = AppTheme.lightTheme();
      final darkTheme = AppTheme.darkTheme();

      expect(lightTheme.inputDecorationTheme.filled, true);
      expect(darkTheme.inputDecorationTheme.filled, true);
      
      // Border radius should be consistent
      final lightBorder = lightTheme.inputDecorationTheme.border as OutlineInputBorder;
      final darkBorder = darkTheme.inputDecorationTheme.border as OutlineInputBorder;
      expect(
        (lightBorder.borderRadius as BorderRadius).topLeft.x,
        (darkBorder.borderRadius as BorderRadius).topLeft.x,
      );
    });

    test('both themes have dialog configuration', () {
      final lightTheme = AppTheme.lightTheme();
      final darkTheme = AppTheme.darkTheme();

      expect(lightTheme.dialogTheme.elevation, 8);
      expect(darkTheme.dialogTheme.elevation, 8);
      
      final lightDialogShape = lightTheme.dialogTheme.shape as RoundedRectangleBorder;
      final darkDialogShape = darkTheme.dialogTheme.shape as RoundedRectangleBorder;
      expect(
        (lightDialogShape.borderRadius as BorderRadius).topLeft.x,
        (darkDialogShape.borderRadius as BorderRadius).topLeft.x,
      );
    });

    test('both themes have snackbar configuration', () {
      final lightTheme = AppTheme.lightTheme();
      final darkTheme = AppTheme.darkTheme();

      expect(lightTheme.snackBarTheme.behavior, SnackBarBehavior.floating);
      expect(darkTheme.snackBarTheme.behavior, SnackBarBehavior.floating);
    });

    test('theme can be applied to MaterialApp', () {
      final lightTheme = AppTheme.lightTheme();
      final darkTheme = AppTheme.darkTheme();

      // Verify themes can be used in MaterialApp
      expect(lightTheme, isA<ThemeData>());
      expect(darkTheme, isA<ThemeData>());
      
      // Verify they have all required properties
      expect(lightTheme.colorScheme, isNotNull);
      expect(darkTheme.colorScheme, isNotNull);
      expect(lightTheme.textTheme, isNotNull);
      expect(darkTheme.textTheme, isNotNull);
    });
  });

  group('AppTheme Component Styling', () {
    test('card theme has correct elevation and shape', () {
      final theme = AppTheme.lightTheme();
      
      expect(theme.cardTheme.elevation, 1);
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      expect(theme.cardTheme.clipBehavior, Clip.antiAlias);
    });

    test('elevated button theme has correct styling', () {
      final theme = AppTheme.lightTheme();
      final buttonStyle = theme.elevatedButtonTheme.style!;
      
      expect(buttonStyle.elevation?.resolve({}), 2);
      expect(buttonStyle.padding?.resolve({}), 
        const EdgeInsets.symmetric(horizontal: 24, vertical: 12));
      expect(buttonStyle.shape?.resolve({}), isA<RoundedRectangleBorder>());
    });

    test('text button theme has correct styling', () {
      final theme = AppTheme.lightTheme();
      final buttonStyle = theme.textButtonTheme.style!;
      
      expect(buttonStyle.padding?.resolve({}), 
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8));
      expect(buttonStyle.shape?.resolve({}), isA<RoundedRectangleBorder>());
    });

    test('floating action button theme has correct styling', () {
      final theme = AppTheme.lightTheme();
      
      expect(theme.floatingActionButtonTheme.elevation, 4);
      expect(theme.floatingActionButtonTheme.shape, isA<RoundedRectangleBorder>());
    });

    test('progress indicator uses primary color', () {
      final lightTheme = AppTheme.lightTheme();
      final darkTheme = AppTheme.darkTheme();
      
      expect(lightTheme.progressIndicatorTheme.color, lightTheme.colorScheme.primary);
      expect(darkTheme.progressIndicatorTheme.color, darkTheme.colorScheme.primary);
    });
  });
}
