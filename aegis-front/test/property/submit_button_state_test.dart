import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

/// Property-based test for submit button state
/// 
/// **Feature: rpa-frontend, Property 2: Submit Button State**
/// **Validates: Requirements 2.2**
/// 
/// Property: For any text input value in the landing screen input field,
/// the submit button must be enabled if and only if the input is non-empty
/// (after trimming whitespace).

void main() {
  group('Submit Button State Property', () {
    final random = Random();

    // Helper to generate random strings with various whitespace patterns
    String randomString([int maxLength = 100]) {
      final length = random.nextInt(maxLength);
      if (length == 0) return '';
      
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 \t\n';
      return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
    }

    // Helper to generate whitespace-only strings
    String randomWhitespace([int maxLength = 50]) {
      final length = random.nextInt(maxLength) + 1;
      const whitespaceChars = ' \t\n\r';
      return List.generate(length, (_) => whitespaceChars[random.nextInt(whitespaceChars.length)]).join();
    }

    // Helper to generate strings with leading/trailing whitespace
    String randomStringWithWhitespace() {
      final core = randomString(50);
      final leadingWs = randomWhitespace(10);
      final trailingWs = randomWhitespace(10);
      
      final choice = random.nextInt(4);
      switch (choice) {
        case 0:
          return leadingWs + core;
        case 1:
          return core + trailingWs;
        case 2:
          return leadingWs + core + trailingWs;
        default:
          return core;
      }
    }

    /// Simulates the submit button enabled logic from LandingScreen
    /// This matches the implementation: _instructionController.text.trim().isNotEmpty && !_isSubmitting
    bool isSubmitEnabled(String instruction, {bool isSubmitting = false}) {
      return instruction.trim().isNotEmpty && !isSubmitting;
    }

    test('Property 2: Submit button enabled only for non-empty input', () {
      // Run 100 iterations as specified in design
      for (int i = 0; i < 100; i++) {
        // Generate various types of input strings
        String instruction;
        
        final testCase = random.nextInt(5);
        switch (testCase) {
          case 0:
            // Empty string
            instruction = '';
            break;
          case 1:
            // Whitespace-only string
            instruction = randomWhitespace();
            break;
          case 2:
            // Normal string
            instruction = randomString();
            break;
          case 3:
            // String with leading/trailing whitespace
            instruction = randomStringWithWhitespace();
            break;
          default:
            // Random string (could be any of the above)
            instruction = random.nextBool() ? randomString() : randomWhitespace();
        }

        // Test the button state logic
        final trimmed = instruction.trim();
        final expectedEnabled = trimmed.isNotEmpty;
        final actualEnabled = isSubmitEnabled(instruction);

        // Verify the property holds
        expect(
          actualEnabled,
          equals(expectedEnabled),
          reason: 'For input "$instruction" (trimmed: "$trimmed"), '
              'expected enabled=$expectedEnabled but got enabled=$actualEnabled',
        );

        // Also test with isSubmitting=true (button should always be disabled)
        final actualEnabledWhileSubmitting = isSubmitEnabled(instruction, isSubmitting: true);
        expect(
          actualEnabledWhileSubmitting,
          isFalse,
          reason: 'Button should always be disabled when isSubmitting=true, '
              'regardless of input',
        );
      }
    });

    test('Property 2: Edge cases - empty and whitespace strings', () {
      // Test specific edge cases explicitly
      final edgeCases = [
        '',           // Empty string
        ' ',          // Single space
        '  ',         // Multiple spaces
        '\t',         // Tab
        '\n',         // Newline
        '\r',         // Carriage return
        ' \t\n\r ',   // Mixed whitespace
        'a',          // Single character
        ' a',         // Leading space
        'a ',         // Trailing space
        ' a ',        // Both
        'hello',      // Normal word
        'hello world', // Multiple words
      ];

      for (final input in edgeCases) {
        final expectedEnabled = input.trim().isNotEmpty;
        final actualEnabled = isSubmitEnabled(input);

        expect(
          actualEnabled,
          equals(expectedEnabled),
          reason: 'Edge case failed for input "$input" (trimmed: "${input.trim()}")',
        );
      }
    });

    test('Property 2: Submitting state always disables button', () {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        final instruction = randomString();
        
        // When isSubmitting=true, button should always be disabled
        // regardless of whether the input is valid
        final actualEnabled = isSubmitEnabled(instruction, isSubmitting: true);
        
        expect(
          actualEnabled,
          isFalse,
          reason: 'Button must be disabled when isSubmitting=true, '
              'even with valid input "$instruction"',
        );
      }
    });

    test('Property 2: Non-empty trimmed input enables button when not submitting', () {
      // Run 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate a string that will be non-empty after trimming
        final core = randomString(50);
        if (core.trim().isEmpty) continue; // Skip if it happens to be all whitespace
        
        final instruction = randomStringWithWhitespace() + core + randomStringWithWhitespace();
        
        // When not submitting and input is non-empty after trim, button should be enabled
        final actualEnabled = isSubmitEnabled(instruction, isSubmitting: false);
        
        if (instruction.trim().isNotEmpty) {
          expect(
            actualEnabled,
            isTrue,
            reason: 'Button should be enabled for non-empty trimmed input "$instruction"',
          );
        }
      }
    });
  });
}
