import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:treasurybox_mobile/flavors/celo/tokens.dart';
import 'package:treasurybox_mobile/flavors/registry.dart';
import 'package:treasurybox_mobile/flavors/twin/tokens.dart';

void main() {
  test('core source does not name a chain, issuer or local token', () {
    final terms = {...celoForbiddenCoreTerms, ...twinForbiddenCoreTerms};
    final pattern = RegExp(
      '(?<![A-Za-z0-9])(?:${terms.map(RegExp.escape).join('|')})(?![A-Za-z0-9])',
      caseSensitive: false,
    );
    final hits = <String>[];
    for (final entity in Directory('lib/core').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = entity.readAsStringSync();
      if (text.contains('toDouble') || text.contains('double.parse') || RegExp(r'\bdouble\b').hasMatch(text)) {
        hits.add('${entity.path} uses binary floating point');
      }
      for (final match in pattern.allMatches(text)) {
        hits.add('${entity.path}: ${match.group(0)}');
      }
    }
    expect(hits, isEmpty);
  });

  test('flavor folders do not import each other', () {
    expect(flavorEcosystemIds['celo'], ['ripio-celo']);
    expect(flavorEcosystemIds['twin'], ['twin-arc']);
    _expectIsolated('lib/flavors/celo', 'twin');
    _expectIsolated('lib/flavors/twin', 'celo');
    expect(File('lib/main_celo.dart').readAsStringSync().contains('twin'), isFalse);
    expect(File('lib/main_twin.dart').readAsStringSync().contains('celo'), isFalse);
  });
}

void _expectIsolated(String dir, String other) {
  for (final entity in Directory(dir).listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final text = entity.readAsStringSync();
    expect(text.contains('flavors/$other'), isFalse, reason: entity.path);
  }
}
