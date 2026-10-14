import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _filesToCheck = [
  'lib/screens/auth/auth_screen.dart',
  'lib/screens/auth/verify_email_screen.dart',
  'lib/screens/auth/forgot_password_dialog.dart',
  'lib/screens/auth/widgets/auth_segmented_control.dart',
  'lib/screens/auth/widgets/password_strength_meter.dart',
  'lib/screens/onboarding/onboarding_screen.dart',
  'lib/screens/orders/new_order_screen.dart',
  'lib/core/widgets/dynamic_fields_form.dart',
  'lib/core/widgets/dynamic_field_widget.dart',
  'lib/screens/settings/settings_screen.dart',
  'lib/screens/settings/app_settings_screen.dart',
  'lib/screens/settings/widgets/settings_group.dart',
];

final _hardcodedColorPatterns = <(String, RegExp)>[
  ('AtelierProColors palette constant', RegExp(r'AtelierProColors\.')),
  (
    'literal Color(0x...) value',
    RegExp(r'Color\s*\(\s*0x', caseSensitive: false)
  ),
  (
    'Colors.white or Colors.black',
    RegExp(r'Colors\.(?:white|black)(?![A-Za-z0-9_])')
  ),
  ('Colors.red/green/blue/grey', RegExp(r'Colors\.(?:red|green|blue|grey)\b')),
];

void main() {
  test('the authentication, order, and settings flows use theme colors', () {
    final violations = <String>[];
    for (final path in _filesToCheck) {
      final lines = File(path).readAsLinesSync();
      var inBlockComment = false;
      for (var index = 0; index < lines.length; index++) {
        final originalLine = lines[index];
        if (originalLine.contains('// theme-ok')) continue;
        var source = originalLine;
        if (inBlockComment) {
          final end = source.indexOf('*/');
          if (end == -1) continue;
          source = source.substring(end + 2);
          inBlockComment = false;
        }
        while (source.contains('/*')) {
          final start = source.indexOf('/*');
          final end = source.indexOf('*/', start + 2);
          if (end == -1) {
            source = source.substring(0, start);
            inBlockComment = true;
            break;
          }
          source = source.replaceRange(start, end + 2, '');
        }
        source = source.replaceFirst(RegExp(r'//.*$'), '');
        for (final (rule, pattern) in _hardcodedColorPatterns) {
          if (pattern.hasMatch(source)) {
            violations.add('$path:${index + 1}: $rule');
          }
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
