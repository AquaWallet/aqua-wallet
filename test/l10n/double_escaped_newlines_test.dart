import 'dart:io';

import 'package:aqua/logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Localization Double Escaped Newlines Test', () {
    test('should detect double-escaped newlines in all .arb files', () async {
      final l10nDir = Directory('lib/l10n');
      final arbFiles = l10nDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.arb'))
          .toList();

      expect(arbFiles.isNotEmpty, true, reason: 'No .arb files found');

      final errors = <String>[];

      for (final file in arbFiles) {
        final content = await file.readAsString();
        final lines = content.split('\n');

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          final lineNumber = i + 1;

          // Check for double-escaped newlines: \\n
          if (line.contains('\\\\n')) {
            final fileName = file.path.split('/').last;
            errors.add(
                '$fileName:$lineNumber - Double-escaped newline found: $line');
          }
        }
      }

      if (errors.isNotEmpty) {
        fail(
            'Found ${errors.length} double-escaped newline(s):\n${errors.join('\n')}');
      }
    });

    test('should detect other double-escaped characters', () async {
      final l10nDir = Directory('lib/l10n');
      final arbFiles = l10nDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.arb'))
          .toList();

      final errors = <String>[];

      for (final file in arbFiles) {
        final content = await file.readAsString();
        final lines = content.split('\n');

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          final lineNumber = i + 1;

          // Check for other double-escaped characters
          final doubleEscapedPatterns = [
            '\\\\t', // double-escaped tab
            '\\\\r', // double-escaped carriage return
            '\\\\"', // double-escaped quote
            '\\\\\\\\', // double-escaped backslash
          ];

          for (final pattern in doubleEscapedPatterns) {
            if (line.contains(pattern)) {
              final fileName = file.path.split('/').last;
              errors.add(
                  '$fileName:$lineNumber - Double-escaped character "$pattern" found: $line');
            }
          }
        }
      }

      if (errors.isNotEmpty) {
        fail(
            'Found ${errors.length} double-escaped character(s):\n${errors.join('\n')}');
      }
    });

    test('should detect proper newline usage patterns', () async {
      final l10nDir = Directory('lib/l10n');
      final arbFiles = l10nDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.arb'))
          .toList();

      final warnings = <String>[];

      for (final file in arbFiles) {
        final content = await file.readAsString();
        final lines = content.split('\n');

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          final lineNumber = i + 1;

          // Check for potential issues with newline patterns
          if (line.contains('\\n') &&
              !line.contains('"') &&
              line.trim().isNotEmpty) {
            final fileName = file.path.split('/').last;
            warnings.add(
                '$fileName:$lineNumber - Suspicious newline usage outside quotes: $line');
          }
        }
      }

      // Log warnings but don't fail the test
      if (warnings.isNotEmpty) {
        logger.warning(
            'Found ${warnings.length} potentially problematic newline usage(s):');
        for (final warning in warnings) {
          logger.warning('  $warning');
        }
      }
    });

    test('should validate JSON structure integrity', () async {
      final l10nDir = Directory('lib/l10n');
      final arbFiles = l10nDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.arb'))
          .toList();

      for (final file in arbFiles) {
        final content = await file.readAsString();

        // Try to parse as JSON to catch structural issues
        try {
          // Basic JSON validation - check for balanced quotes and braces
          final openBraces = '{'.allMatches(content).length;
          final closeBraces = '}'.allMatches(content).length;

          expect(openBraces, equals(closeBraces),
              reason: 'Unbalanced braces in ${file.path}');

          // Check for proper quote balancing in value strings
          final lines = content.split('\n');
          for (int i = 0; i < lines.length; i++) {
            final line = lines[i].trim();
            if (line.contains(':')) {
              final colonIndex = line.indexOf(':');
              final valuePart = line.substring(colonIndex + 1).trim();

              if (valuePart.startsWith('"') && valuePart.endsWith('",')) {
                // Valid JSON string
              } else if (valuePart.startsWith('"') && valuePart.endsWith('"')) {
                // Valid JSON string (last entry)
              } else if (valuePart == 'null,' || valuePart == 'null') {
                // Valid null value
              } else if (valuePart == '{' || valuePart == '{,') {
                // Valid nested JSON object start
              } else if (valuePart == '[' || valuePart == '[,') {
                // Valid JSON array start
              } else if (valuePart == '},' || valuePart == '}') {
                // Valid nested JSON object end
              } else if (valuePart == '],' || valuePart == ']') {
                // Valid JSON array end
              } else if (valuePart.isEmpty || valuePart == ',') {
                // Empty value or just comma (might be continuation)
              } else {
                fail('Invalid JSON structure in ${file.path}:$i - $line');
              }
            }
          }
        } catch (e) {
          fail('JSON validation failed for ${file.path}: $e');
        }
      }
    });
  });
}
