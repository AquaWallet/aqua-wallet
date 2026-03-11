import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Ensure no one changes the welcome screen taglines. Without manual review.
// It's easy to miss and breaks the splash screen expected UI.
void main() {
  group('Welcome Screen Descriptions', () {
    test('should have expected tagline values in app_en.arb', () async {
      final file = File('lib/l10n/app_en.arb');
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      expect(
        json['welcomeScreenDesc1'],
        'Be Like\n**Water**',
        reason: 'welcomeScreenDesc1 was changed unexpectedly',
      );
      expect(
        json['welcomeScreenDesc2'],
        '**Bitcoin**\nand Tether\nWallet',
        reason: 'welcomeScreenDesc2 was changed unexpectedly',
      );
      expect(
        json['welcomeScreenDesc3'],
        '**Bitcoin**\nLightning\nLiquid\nTether',
        reason: 'welcomeScreenDesc3 was changed unexpectedly',
      );
      expect(
        json['welcomeScreenDesc4'],
        '**Bitcoin**\nand Layer 2\nWallet',
        reason: 'welcomeScreenDesc4 was changed unexpectedly',
      );
      expect(
        json['welcomeScreenDesc5'],
        'Swim\nwith the\n**Dolphins**',
        reason: 'welcomeScreenDesc5 was changed unexpectedly',
      );
      expect(
        json['welcomeScreenDesc6'],
        'Powering \n**Bitcoin** \nCircular \nEconomies',
        reason: 'welcomeScreenDesc6 was changed unexpectedly',
      );
    });
  });
}
