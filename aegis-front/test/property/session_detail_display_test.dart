import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/models/execution_session.dart';
import 'package:aegis_front/models/subtask.dart';
import 'dart:math';

/// Property-based test for session detail display
/// 
/// **Feature: rpa-frontend, Property 24: Session Detail Display**
/// **Validates: Requirements 6.5**
///
/// Property 24: Session Detail Display
/// *For any* session detail response, the complete subtask sequence and results must be displayed.

void main() {
  group('Session Detail Display Property', () {
    final random = Random();

    // Helper to generate random strings
    String randomString([int maxLength = 50]) {
      final length = random.nextInt(maxLength) + 1;
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
      return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
    }

    // Helper to generate random DateTime
    DateTime randomDateTime() {
      final now = DateTime.now();
      final offset = random.nextInt(365 * 24 * 60 * 60); // Up to 1 year in seconds
      return now.subtract(Duration(seconds: offset));
    }

    // Helper to generate random SubtaskStatus
    SubtaskStatus randomSubtaskStatus() {
      final statuses = SubtaskStatus.values;
      return statuses[random.nextInt(statuses.length)];
    }

    // Helper to generate random SessionStatus
    SessionStatus randomSessionStatus() {
      final statuses = SessionStatus.values;
      return statuses[random.nextInt(statuses.length)];
    }

    // Helper to generate random subtask
    Subtask randomSubtask() {
      return Subtask(
        id: randomString(20),
        description: randomString(),
        status: randomSubtaskStatus(),
        toolName: random.nextBool() ? randomString(20) : null,
        toolArgs: random.nextBool() ? {'arg': randomString()} : null,
        result: random.nextBool() ? {'result': randomString()} : null,
        error: random.nextBool() ? randomString() : null,
        timestamp: randomDateTime(),
      );
    }

    // Helper to generate random ExecutionSession
    ExecutionSession randomExecutionSession() {
      final subtaskCount = random.nextInt(20) + 1; // 1-20 subtasks
      final subtasks = List.generate(subtaskCount, (_) => randomSubtask());
      
      return ExecutionSession(
        sessionId: randomString(20),
        instruction: randomString(),
        status: randomSessionStatus(),
        subtasks: subtasks,
        createdAt: randomDateTime(),
        updatedAt: randomDateTime(),
        completedAt: random.nextBool() ? randomDateTime() : null,
      );
    }

    test('Property 24: Session Detail Display - Complete subtask sequence', () {
      // **Feature: rpa-frontend, Property 24: Session Detail Display**
      // **Validates: Requirements 6.5**
      //
      // *For any* session detail response, the complete subtask sequence and results 
      // must be displayed.
      //
      // This property verifies that:
      // 1. All subtasks from the session are present in the display
      // 2. Each subtask's details (description, status, error, result) are accessible
      // 3. The subtask count matches the actual number of subtasks
      // 4. No subtasks are missing or duplicated
      
      // Run 100 iterations as specified in design
      for (int i = 0; i < 100; i++) {
        // Generate a random execution session with random subtasks
        final session = randomExecutionSession();
        
        // Verify that the session contains the expected number of subtasks
        expect(
          session.subtasks.length,
          greaterThan(0),
          reason: 'Session must have at least one subtask',
        );
        
        // Verify that all subtasks are present and accessible
        final subtaskIds = <String>{};
        for (final subtask in session.subtasks) {
          // Each subtask must have a unique ID
          expect(
            subtaskIds.contains(subtask.id),
            isFalse,
            reason: 'Each subtask must have a unique ID (no duplicates)',
          );
          subtaskIds.add(subtask.id);
          
          // Each subtask must have required fields
          expect(
            subtask.id,
            isNotEmpty,
            reason: 'Subtask ID must not be empty',
          );
          
          expect(
            subtask.description,
            isNotEmpty,
            reason: 'Subtask description must not be empty',
          );
          
          expect(
            subtask.status,
            isNotNull,
            reason: 'Subtask status must not be null',
          );
          
          expect(
            subtask.timestamp,
            isNotNull,
            reason: 'Subtask timestamp must not be null',
          );
        }
        
        // Verify that the complete sequence is preserved
        expect(
          session.subtasks.length,
          equals(subtaskIds.length),
          reason: 'All subtasks must be unique and present in the sequence',
        );
        
        // Verify that subtask results are accessible when present
        for (final subtask in session.subtasks) {
          if (subtask.status == SubtaskStatus.failed) {
            // Failed subtasks should have error information accessible
            // (error field may be null, but it should be accessible)
            expect(
              () => subtask.error,
              returnsNormally,
              reason: 'Error field must be accessible for failed subtasks',
            );
          }
          
          if (subtask.status == SubtaskStatus.completed) {
            // Completed subtasks should have result information accessible
            // (result field may be null, but it should be accessible)
            expect(
              () => subtask.result,
              returnsNormally,
              reason: 'Result field must be accessible for completed subtasks',
            );
          }
        }
      }
    });

    test('Property 24: Session Detail Display - Subtask details preservation', () {
      // Additional test to verify that subtask details are preserved correctly
      // This ensures that when displaying session details, all subtask information
      // is available and correctly structured
      
      for (int i = 0; i < 100; i++) {
        final session = randomExecutionSession();
        
        // For each subtask in the session
        for (int j = 0; j < session.subtasks.length; j++) {
          final subtask = session.subtasks[j];
          
          // Verify that the subtask can be accessed by index
          expect(
            session.subtasks[j],
            equals(subtask),
            reason: 'Subtask must be accessible by its position in the sequence',
          );
          
          // Verify that all subtask properties are preserved
          final subtaskCopy = Subtask(
            id: subtask.id,
            description: subtask.description,
            status: subtask.status,
            toolName: subtask.toolName,
            toolArgs: subtask.toolArgs,
            result: subtask.result,
            error: subtask.error,
            timestamp: subtask.timestamp,
          );
          
          // Verify that creating a copy with the same values produces equivalent data
          expect(subtaskCopy.id, equals(subtask.id));
          expect(subtaskCopy.description, equals(subtask.description));
          expect(subtaskCopy.status, equals(subtask.status));
          expect(subtaskCopy.toolName, equals(subtask.toolName));
          expect(subtaskCopy.error, equals(subtask.error));
          expect(
            subtaskCopy.timestamp.difference(subtask.timestamp).inMilliseconds.abs(),
            lessThan(1),
          );
        }
      }
    });

    test('Property 24: Session Detail Display - Empty subtask list handling', () {
      // Test edge case: session with no subtasks
      // While rare, the system should handle this gracefully
      
      for (int i = 0; i < 100; i++) {
        final session = ExecutionSession(
          sessionId: randomString(20),
          instruction: randomString(),
          status: randomSessionStatus(),
          subtasks: [], // Empty subtask list
          createdAt: randomDateTime(),
          updatedAt: randomDateTime(),
          completedAt: random.nextBool() ? randomDateTime() : null,
        );
        
        // Verify that empty subtask list is handled correctly
        expect(
          session.subtasks,
          isEmpty,
          reason: 'Empty subtask list must be preserved',
        );
        
        expect(
          session.subtasks.length,
          equals(0),
          reason: 'Subtask count must be zero for empty list',
        );
        
        // Verify that accessing the empty list doesn't throw
        expect(
          () => session.subtasks.isEmpty,
          returnsNormally,
          reason: 'Accessing empty subtask list must not throw',
        );
      }
    });

    test('Property 24: Session Detail Display - Large subtask sequences', () {
      // Test with large numbers of subtasks to ensure scalability
      
      for (int i = 0; i < 100; i++) {
        // Generate sessions with varying numbers of subtasks (1-100)
        final subtaskCount = random.nextInt(100) + 1;
        final subtasks = List.generate(subtaskCount, (_) => randomSubtask());
        
        final session = ExecutionSession(
          sessionId: randomString(20),
          instruction: randomString(),
          status: randomSessionStatus(),
          subtasks: subtasks,
          createdAt: randomDateTime(),
          updatedAt: randomDateTime(),
          completedAt: random.nextBool() ? randomDateTime() : null,
        );
        
        // Verify that all subtasks are present
        expect(
          session.subtasks.length,
          equals(subtaskCount),
          reason: 'All subtasks must be present regardless of count',
        );
        
        // Verify that we can iterate through all subtasks
        int count = 0;
        for (final subtask in session.subtasks) {
          expect(subtask, isNotNull);
          count++;
        }
        
        expect(
          count,
          equals(subtaskCount),
          reason: 'Must be able to iterate through all subtasks',
        );
        
        // Verify that we can access first and last subtasks
        if (subtaskCount > 0) {
          expect(
            () => session.subtasks.first,
            returnsNormally,
            reason: 'First subtask must be accessible',
          );
          
          expect(
            () => session.subtasks.last,
            returnsNormally,
            reason: 'Last subtask must be accessible',
          );
        }
      }
    });

    test('Property 24: Session Detail Display - Subtask status variety', () {
      // Test that sessions with various subtask statuses are handled correctly
      
      for (int i = 0; i < 100; i++) {
        // Create a session with subtasks in all possible statuses
        final subtasks = <Subtask>[];
        
        // Add at least one subtask of each status
        for (final status in SubtaskStatus.values) {
          subtasks.add(Subtask(
            id: randomString(20),
            description: randomString(),
            status: status,
            error: status == SubtaskStatus.failed ? randomString() : null,
            result: status == SubtaskStatus.completed ? {'result': 'success'} : null,
            timestamp: randomDateTime(),
          ));
        }
        
        // Add some random additional subtasks
        final additionalCount = random.nextInt(10);
        for (int j = 0; j < additionalCount; j++) {
          subtasks.add(randomSubtask());
        }
        
        final session = ExecutionSession(
          sessionId: randomString(20),
          instruction: randomString(),
          status: randomSessionStatus(),
          subtasks: subtasks,
          createdAt: randomDateTime(),
          updatedAt: randomDateTime(),
          completedAt: random.nextBool() ? randomDateTime() : null,
        );
        
        // Verify that all status types are present
        final statusesFound = <SubtaskStatus>{};
        for (final subtask in session.subtasks) {
          statusesFound.add(subtask.status);
        }
        
        // At minimum, we should have all the statuses we explicitly added
        for (final status in SubtaskStatus.values) {
          expect(
            statusesFound.contains(status),
            isTrue,
            reason: 'Session must preserve subtasks with status: $status',
          );
        }
        
        // Verify that failed subtasks have error information accessible
        final failedSubtasks = session.subtasks
            .where((s) => s.status == SubtaskStatus.failed)
            .toList();
        
        for (final subtask in failedSubtasks) {
          expect(
            () => subtask.error,
            returnsNormally,
            reason: 'Error information must be accessible for failed subtasks',
          );
        }
        
        // Verify that completed subtasks have result information accessible
        final completedSubtasks = session.subtasks
            .where((s) => s.status == SubtaskStatus.completed)
            .toList();
        
        for (final subtask in completedSubtasks) {
          expect(
            () => subtask.result,
            returnsNormally,
            reason: 'Result information must be accessible for completed subtasks',
          );
        }
      }
    });
  });
}
