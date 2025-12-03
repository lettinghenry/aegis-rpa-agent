import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/theme/app_theme.dart';
import 'dart:math';

/// Property-based test for status color coding
/// 
/// **Feature: rpa-frontend, Property 30: Status Color Coding**
/// **Validates: Requirements 8.2**
/// 
/// Property: For any status indicator displayed, the color must match the status type:
/// green for success/completed, red for error/failed, blue for in-progress.

void main() {
  group('Status Color Coding Property', () {
    final random = Random();

    // Define the expected color mappings based on Material 3 design
    final Map<String, int> expectedColors = {
      // Success/Completed - Green
      'completed': AppTheme.successGreen.value,
      'success': AppTheme.successGreen.value,
      
      // Error/Failed - Red
      'failed': AppTheme.errorRed.value,
      'error': AppTheme.errorRed.value,
      
      // In Progress - Blue
      'in_progress': AppTheme.inProgressBlue.value,
      'in-progress': AppTheme.inProgressBlue.value,
      'running': AppTheme.inProgressBlue.value,
      
      // Pending - Grey
      'pending': AppTheme.pendingGrey.value,
      
      // Cancelled - Orange
      'cancelled': AppTheme.warningOrange.value,
    };

    // Helper to generate random status strings
    String randomStatus() {
      final statuses = expectedColors.keys.toList();
      return statuses[random.nextInt(statuses.length)];
    }

    // Helper to generate status with random casing
    String randomCaseStatus(String status) {
      final choice = random.nextInt(3);
      switch (choice) {
        case 0:
          return status.toLowerCase();
        case 1:
          return status.toUpperCase();
        default:
          // Mixed case
          return status.split('').map((c) {
            return random.nextBool() ? c.toUpperCase() : c.toLowerCase();
          }).join();
      }
    }

    test('Property 30: Status colors match Material 3 specification', () {
      // Run 100 iterations as specified in design
      for (int i = 0; i < 100; i++) {
        // Generate a random status
        final status = randomStatus();
        
        // Get the color from AppTheme
        final actualColor = AppTheme.getStatusColor(status);
        final expectedColorValue = expectedColors[status.toLowerCase()]!;
        
        // Verify the color matches the expected Material 3 color
        expect(
          actualColor.value,
          equals(expectedColorValue),
          reason: 'Status "$status" should map to color 0x${expectedColorValue.toRadixString(16).toUpperCase()}, '
              'but got 0x${actualColor.value.toRadixString(16).toUpperCase()}',
        );
      }
    });

    test('Property 30: Success/Completed statuses return green', () {
      final successStatuses = ['completed', 'success'];
      
      for (int i = 0; i < 100; i++) {
        final status = successStatuses[random.nextInt(successStatuses.length)];
        final statusWithCase = randomCaseStatus(status);
        
        final color = AppTheme.getStatusColor(statusWithCase);
        
        expect(
          color.value,
          equals(AppTheme.successGreen.value),
          reason: 'Success status "$statusWithCase" must return green (0x${AppTheme.successGreen.value.toRadixString(16).toUpperCase()})',
        );
      }
    });

    test('Property 30: Error/Failed statuses return red', () {
      final errorStatuses = ['failed', 'error'];
      
      for (int i = 0; i < 100; i++) {
        final status = errorStatuses[random.nextInt(errorStatuses.length)];
        final statusWithCase = randomCaseStatus(status);
        
        final color = AppTheme.getStatusColor(statusWithCase);
        
        expect(
          color.value,
          equals(AppTheme.errorRed.value),
          reason: 'Error status "$statusWithCase" must return red (0x${AppTheme.errorRed.value.toRadixString(16).toUpperCase()})',
        );
      }
    });

    test('Property 30: In-progress statuses return blue', () {
      final inProgressStatuses = ['in_progress', 'in-progress', 'running'];
      
      for (int i = 0; i < 100; i++) {
        final status = inProgressStatuses[random.nextInt(inProgressStatuses.length)];
        final statusWithCase = randomCaseStatus(status);
        
        final color = AppTheme.getStatusColor(statusWithCase);
        
        expect(
          color.value,
          equals(AppTheme.inProgressBlue.value),
          reason: 'In-progress status "$statusWithCase" must return blue (0x${AppTheme.inProgressBlue.value.toRadixString(16).toUpperCase()})',
        );
      }
    });

    test('Property 30: Case insensitivity', () {
      // Test that status color mapping is case-insensitive
      for (int i = 0; i < 100; i++) {
        final baseStatus = randomStatus();
        final randomCasedStatus = randomCaseStatus(baseStatus);
        
        final color = AppTheme.getStatusColor(randomCasedStatus);
        final expectedColorValue = expectedColors[baseStatus.toLowerCase()]!;
        
        expect(
          color.value,
          equals(expectedColorValue),
          reason: 'Status "$randomCasedStatus" (base: "$baseStatus") should be case-insensitive '
              'and map to 0x${expectedColorValue.toRadixString(16).toUpperCase()}',
        );
      }
    });

    test('Property 30: All defined statuses have correct colors', () {
      // Explicitly test all defined status mappings
      final testCases = {
        'completed': AppTheme.successGreen,
        'success': AppTheme.successGreen,
        'failed': AppTheme.errorRed,
        'error': AppTheme.errorRed,
        'in_progress': AppTheme.inProgressBlue,
        'in-progress': AppTheme.inProgressBlue,
        'running': AppTheme.inProgressBlue,
        'pending': AppTheme.pendingGrey,
        'cancelled': AppTheme.warningOrange,
      };

      for (final entry in testCases.entries) {
        final status = entry.key;
        final expectedColor = entry.value;
        
        final actualColor = AppTheme.getStatusColor(status);
        
        expect(
          actualColor.value,
          equals(expectedColor.value),
          reason: 'Status "$status" must map to ${expectedColor.toString()}',
        );
      }
    });

    test('Property 30: Unknown statuses return default color', () {
      // Test that unknown statuses return a default color (pendingGrey)
      final unknownStatuses = [
        'unknown',
        'invalid',
        'xyz',
        'test',
        '',
        '123',
        'UNKNOWN_STATUS',
      ];

      for (final status in unknownStatuses) {
        final color = AppTheme.getStatusColor(status);
        
        expect(
          color.value,
          equals(AppTheme.pendingGrey.value),
          reason: 'Unknown status "$status" should return default color (pendingGrey)',
        );
      }
    });

    test('Property 30: Color consistency across multiple calls', () {
      // Verify that calling getStatusColor multiple times with the same status
      // returns the same color
      for (int i = 0; i < 100; i++) {
        final status = randomStatus();
        
        final color1 = AppTheme.getStatusColor(status);
        final color2 = AppTheme.getStatusColor(status);
        final color3 = AppTheme.getStatusColor(status);
        
        expect(
          color1.value,
          equals(color2.value),
          reason: 'Multiple calls with status "$status" should return consistent colors',
        );
        
        expect(
          color2.value,
          equals(color3.value),
          reason: 'Multiple calls with status "$status" should return consistent colors',
        );
      }
    });

    test('Property 30: Material 3 color values are correct', () {
      // Verify the actual color values match Material 3 specifications
      expect(AppTheme.successGreen.value, equals(0xFF4CAF50), 
        reason: 'Success green should be Material 3 green');
      expect(AppTheme.errorRed.value, equals(0xFFE53935), 
        reason: 'Error red should be Material 3 red');
      expect(AppTheme.inProgressBlue.value, equals(0xFF2196F3), 
        reason: 'In-progress blue should be Material 3 blue');
      expect(AppTheme.pendingGrey.value, equals(0xFF9E9E9E), 
        reason: 'Pending grey should be Material 3 grey');
      expect(AppTheme.warningOrange.value, equals(0xFFFF9800), 
        reason: 'Warning orange should be Material 3 orange');
    });
  });
}
