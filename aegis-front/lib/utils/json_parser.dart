import 'dart:developer' as developer;

/// Custom exception for JSON parsing errors
class ParsingException implements Exception {
  final String message;
  final String? fieldName;
  final dynamic receivedValue;
  final Type? expectedType;
  final dynamic originalError;

  ParsingException(
    this.message, {
    this.fieldName,
    this.receivedValue,
    this.expectedType,
    this.originalError,
  });

  @override
  String toString() {
    final buffer = StringBuffer('ParsingException: $message');
    if (fieldName != null) {
      buffer.write(' (field: $fieldName)');
    }
    if (expectedType != null) {
      buffer.write(' (expected: $expectedType)');
    }
    if (receivedValue != null) {
      buffer.write(' (received: $receivedValue)');
    }
    if (originalError != null) {
      buffer.write(' (cause: $originalError)');
    }
    return buffer.toString();
  }
}

/// Utility class for safe JSON parsing with error handling
class JsonParser {
  /// Safely parse a required string field from JSON
  static String parseString(
    Map<String, dynamic> json,
    String fieldName, {
    String? defaultValue,
  }) {
    try {
      final value = json[fieldName];
      
      if (value == null) {
        if (defaultValue != null) {
          developer.log(
            'Missing field "$fieldName", using default: $defaultValue',
            name: 'JsonParser',
          );
          return defaultValue;
        }
        throw ParsingException(
          'Required field is missing',
          fieldName: fieldName,
          expectedType: String,
        );
      }

      if (value is! String) {
        throw ParsingException(
          'Field has wrong type',
          fieldName: fieldName,
          expectedType: String,
          receivedValue: value,
        );
      }

      return value;
    } catch (e) {
      if (e is ParsingException) {
        developer.log(
          'Parsing error: $e',
          name: 'JsonParser',
          error: e,
        );
        rethrow;
      }
      throw ParsingException(
        'Failed to parse string field',
        fieldName: fieldName,
        expectedType: String,
        originalError: e,
      );
    }
  }

  /// Safely parse an optional string field from JSON
  static String? parseOptionalString(
    Map<String, dynamic> json,
    String fieldName,
  ) {
    try {
      final value = json[fieldName];
      
      if (value == null) {
        return null;
      }

      if (value is! String) {
        developer.log(
          'Optional field "$fieldName" has wrong type, ignoring',
          name: 'JsonParser',
        );
        return null;
      }

      return value;
    } catch (e) {
      developer.log(
        'Error parsing optional string field "$fieldName": $e',
        name: 'JsonParser',
        error: e,
      );
      return null;
    }
  }

  /// Safely parse a required integer field from JSON
  static int parseInt(
    Map<String, dynamic> json,
    String fieldName, {
    int? defaultValue,
  }) {
    try {
      final value = json[fieldName];
      
      if (value == null) {
        if (defaultValue != null) {
          developer.log(
            'Missing field "$fieldName", using default: $defaultValue',
            name: 'JsonParser',
          );
          return defaultValue;
        }
        throw ParsingException(
          'Required field is missing',
          fieldName: fieldName,
          expectedType: int,
        );
      }

      if (value is int) {
        return value;
      }

      // Try to convert from string or double
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      } else if (value is double) {
        return value.toInt();
      }

      throw ParsingException(
        'Field has wrong type',
        fieldName: fieldName,
        expectedType: int,
        receivedValue: value,
      );
    } catch (e) {
      if (e is ParsingException) {
        developer.log(
          'Parsing error: $e',
          name: 'JsonParser',
          error: e,
        );
        rethrow;
      }
      throw ParsingException(
        'Failed to parse integer field',
        fieldName: fieldName,
        expectedType: int,
        originalError: e,
      );
    }
  }

  /// Safely parse an optional integer field from JSON
  static int? parseOptionalInt(
    Map<String, dynamic> json,
    String fieldName,
  ) {
    try {
      final value = json[fieldName];
      
      if (value == null) {
        return null;
      }

      if (value is int) {
        return value;
      }

      // Try to convert from string or double
      if (value is String) {
        return int.tryParse(value);
      } else if (value is double) {
        return value.toInt();
      }

      developer.log(
        'Optional field "$fieldName" has wrong type, ignoring',
        name: 'JsonParser',
      );
      return null;
    } catch (e) {
      developer.log(
        'Error parsing optional integer field "$fieldName": $e',
        name: 'JsonParser',
        error: e,
      );
      return null;
    }
  }

  /// Safely parse a required DateTime field from JSON
  static DateTime parseDateTime(
    Map<String, dynamic> json,
    String fieldName, {
    DateTime? defaultValue,
  }) {
    try {
      final value = json[fieldName];
      
      if (value == null) {
        if (defaultValue != null) {
          developer.log(
            'Missing field "$fieldName", using default: $defaultValue',
            name: 'JsonParser',
          );
          return defaultValue;
        }
        throw ParsingException(
          'Required field is missing',
          fieldName: fieldName,
          expectedType: DateTime,
        );
      }

      if (value is! String) {
        throw ParsingException(
          'Field has wrong type',
          fieldName: fieldName,
          expectedType: String,
          receivedValue: value,
        );
      }

      try {
        return DateTime.parse(value);
      } catch (e) {
        throw ParsingException(
          'Invalid datetime format',
          fieldName: fieldName,
          receivedValue: value,
          originalError: e,
        );
      }
    } catch (e) {
      if (e is ParsingException) {
        developer.log(
          'Parsing error: $e',
          name: 'JsonParser',
          error: e,
        );
        rethrow;
      }
      throw ParsingException(
        'Failed to parse datetime field',
        fieldName: fieldName,
        expectedType: DateTime,
        originalError: e,
      );
    }
  }

  /// Safely parse an optional DateTime field from JSON
  static DateTime? parseOptionalDateTime(
    Map<String, dynamic> json,
    String fieldName,
  ) {
    try {
      final value = json[fieldName];
      
      if (value == null) {
        return null;
      }

      if (value is! String) {
        developer.log(
          'Optional field "$fieldName" has wrong type, ignoring',
          name: 'JsonParser',
        );
        return null;
      }

      try {
        return DateTime.parse(value);
      } catch (e) {
        developer.log(
          'Invalid datetime format for "$fieldName": $value',
          name: 'JsonParser',
          error: e,
        );
        return null;
      }
    } catch (e) {
      developer.log(
        'Error parsing optional datetime field "$fieldName": $e',
        name: 'JsonParser',
        error: e,
      );
      return null;
    }
  }

  /// Safely parse a required map field from JSON
  static Map<String, dynamic> parseMap(
    Map<String, dynamic> json,
    String fieldName, {
    Map<String, dynamic>? defaultValue,
  }) {
    try {
      final value = json[fieldName];
      
      if (value == null) {
        if (defaultValue != null) {
          developer.log(
            'Missing field "$fieldName", using default',
            name: 'JsonParser',
          );
          return defaultValue;
        }
        throw ParsingException(
          'Required field is missing',
          fieldName: fieldName,
          expectedType: Map,
        );
      }

      if (value is! Map<String, dynamic>) {
        throw ParsingException(
          'Field has wrong type',
          fieldName: fieldName,
          expectedType: Map,
          receivedValue: value,
        );
      }

      return value;
    } catch (e) {
      if (e is ParsingException) {
        developer.log(
          'Parsing error: $e',
          name: 'JsonParser',
          error: e,
        );
        rethrow;
      }
      throw ParsingException(
        'Failed to parse map field',
        fieldName: fieldName,
        expectedType: Map,
        originalError: e,
      );
    }
  }

  /// Safely parse an optional map field from JSON
  static Map<String, dynamic>? parseOptionalMap(
    Map<String, dynamic> json,
    String fieldName,
  ) {
    try {
      final value = json[fieldName];
      
      if (value == null) {
        return null;
      }

      if (value is! Map<String, dynamic>) {
        developer.log(
          'Optional field "$fieldName" has wrong type, ignoring',
          name: 'JsonParser',
        );
        return null;
      }

      return value;
    } catch (e) {
      developer.log(
        'Error parsing optional map field "$fieldName": $e',
        name: 'JsonParser',
        error: e,
      );
      return null;
    }
  }

  /// Safely parse a required list field from JSON
  static List<T> parseList<T>(
    Map<String, dynamic> json,
    String fieldName,
    T Function(dynamic) itemParser, {
    List<T>? defaultValue,
  }) {
    try {
      final value = json[fieldName];
      
      if (value == null) {
        if (defaultValue != null) {
          developer.log(
            'Missing field "$fieldName", using default',
            name: 'JsonParser',
          );
          return defaultValue;
        }
        throw ParsingException(
          'Required field is missing',
          fieldName: fieldName,
          expectedType: List,
        );
      }

      if (value is! List) {
        throw ParsingException(
          'Field has wrong type',
          fieldName: fieldName,
          expectedType: List,
          receivedValue: value,
        );
      }

      try {
        return value.map((item) => itemParser(item)).toList();
      } catch (e) {
        throw ParsingException(
          'Failed to parse list items',
          fieldName: fieldName,
          originalError: e,
        );
      }
    } catch (e) {
      if (e is ParsingException) {
        developer.log(
          'Parsing error: $e',
          name: 'JsonParser',
          error: e,
        );
        rethrow;
      }
      throw ParsingException(
        'Failed to parse list field',
        fieldName: fieldName,
        expectedType: List,
        originalError: e,
      );
    }
  }

  /// Safely parse an optional list field from JSON
  static List<T>? parseOptionalList<T>(
    Map<String, dynamic> json,
    String fieldName,
    T Function(dynamic) itemParser,
  ) {
    try {
      final value = json[fieldName];
      
      if (value == null) {
        return null;
      }

      if (value is! List) {
        developer.log(
          'Optional field "$fieldName" has wrong type, ignoring',
          name: 'JsonParser',
        );
        return null;
      }

      try {
        return value.map((item) => itemParser(item)).toList();
      } catch (e) {
        developer.log(
          'Failed to parse list items for "$fieldName": $e',
          name: 'JsonParser',
          error: e,
        );
        return null;
      }
    } catch (e) {
      developer.log(
        'Error parsing optional list field "$fieldName": $e',
        name: 'JsonParser',
        error: e,
      );
      return null;
    }
  }
}
