// TJ-ARCH-MOB-001 compliant
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:__APP_CRATE___mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('creates a persisted note through the real Rust bridge', (
    tester,
  ) async {
    final verifyRestart =
        const bool.fromEnvironment('VERIFY_RESTART') ||
        PlatformDispatcher.instance.defaultRouteName == '/verify-restart';
    await app.main();
    await tester.pumpAndSettle();
    const title = 'Native note restart proof';
    if (verifyRestart) {
      expect(find.text(title), findsAtLeastNWidgets(1));
      File(
        '${Directory.systemTemp.path}/knowme-builder-restart-pass',
      ).writeAsStringSync('PASS: rendered persisted note after relaunch\n', flush: true);
      return;
    }
    await tester.enterText(find.byKey(const Key('note-title')), title);
    await tester.tap(find.byKey(const Key('save-note')));
    await tester.pumpAndSettle();
    expect(find.text(title), findsOneWidget);
  });
}
