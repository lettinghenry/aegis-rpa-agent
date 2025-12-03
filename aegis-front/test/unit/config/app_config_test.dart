import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_front/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('should have valid default backend URL', () {
      expect(AppConfig.backendUrl, isNotEmpty);
      expect(AppConfig.backendUrl, startsWith('http'));
    });

    test('should have valid default WebSocket URL', () {
      expect(AppConfig.wsUrl, isNotEmpty);
      expect(AppConfig.wsUrl, startsWith('ws'));
    });

    test('should have positive request timeout', () {
      expect(AppConfig.requestTimeoutSeconds, greaterThan(0));
      expect(AppConfig.requestTimeout.inSeconds, equals(AppConfig.requestTimeoutSeconds));
    });

    test('should have positive WebSocket ping interval', () {
      expect(AppConfig.wsPingIntervalSeconds, greaterThan(0));
      expect(AppConfig.wsPingInterval.inSeconds, equals(AppConfig.wsPingIntervalSeconds));
    });

    test('should have non-negative WebSocket reconnect attempts', () {
      expect(AppConfig.wsReconnectAttempts, greaterThanOrEqualTo(0));
    });

    test('should have non-negative WebSocket reconnect delay', () {
      expect(AppConfig.wsReconnectDelaySeconds, greaterThanOrEqualTo(0));
      expect(AppConfig.wsReconnectDelay.inSeconds, equals(AppConfig.wsReconnectDelaySeconds));
    });

    test('should have non-negative HTTP retry attempts', () {
      expect(AppConfig.httpRetryAttempts, greaterThanOrEqualTo(0));
    });

    test('should have non-negative HTTP retry delay', () {
      expect(AppConfig.httpRetryDelaySeconds, greaterThanOrEqualTo(0));
      expect(AppConfig.httpRetryDelay.inSeconds, equals(AppConfig.httpRetryDelaySeconds));
    });

    test('validate should not throw with default configuration', () {
      expect(() => AppConfig.validate(), returnsNormally);
    });
  });

  group('WindowConfig', () {
    test('should have positive minimal window dimensions', () {
      expect(WindowConfig.minimalWidth, greaterThan(0));
      expect(WindowConfig.minimalHeight, greaterThan(0));
    });

    test('should have minimal window size of 300x100', () {
      expect(WindowConfig.minimalWidth, equals(300.0));
      expect(WindowConfig.minimalHeight, equals(100.0));
    });

    test('should have transition duration of 250ms', () {
      expect(WindowConfig.transitionDurationMs, equals(250));
      expect(WindowConfig.transitionDuration.inMilliseconds, equals(250));
    });

    test('should have non-negative position offsets', () {
      expect(WindowConfig.minimalOffsetX, greaterThanOrEqualTo(0));
      expect(WindowConfig.minimalOffsetY, greaterThanOrEqualTo(0));
    });

    test('should have position offsets of 20 pixels', () {
      expect(WindowConfig.minimalOffsetX, equals(20.0));
      expect(WindowConfig.minimalOffsetY, equals(20.0));
    });

    test('should have auto-minimize enabled by default', () {
      expect(WindowConfig.enableAutoMinimize, isTrue);
    });

    test('validate should not throw with default configuration', () {
      expect(() => WindowConfig.validate(), returnsNormally);
    });
  });

  group('ConfigurationException', () {
    test('should format message correctly', () {
      final exception = ConfigurationException('Test error');
      expect(exception.toString(), equals('ConfigurationException: Test error'));
    });
  });
}
