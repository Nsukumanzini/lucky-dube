// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:lucky_dube_learner/main.dart';
import 'package:lucky_dube_learner/app/app.dart';
import 'package:lucky_dube_learner/features/screens.dart';
import 'package:lucky_dube_learner/data/repository.dart';
import 'package:lucky_dube_learner/app/localization/catalog.dart';

void main() {
  test('UI translation keys do not contain presentation status labels', () {
    expect(
        isiZuluCatalog.keys.where((key) =>
            RegExp(r'\bdemo(nstration)?\b|mock data', caseSensitive: false)
                .hasMatch(key)),
        isEmpty);
  });
  for (final code in ['en', 'zu']) {
    testWidgets('learner screens have clean product copy in $code',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repo = MockRepository(await SharedPreferences.getInstance());
      repo.setLanguage(code);
      repo.setValue('onboarded', true);
      await tester.pumpWidget(ProviderScope(
          overrides: [repositoryProvider.overrideWith((ref) => repo)],
          child: const LuckyApp()));
      await tester.pumpAndSettle();
      void checkCopy() {
        final visible = tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data ?? '')
            .join('\n');
        expect(
            RegExp(r'\bdemo(nstration)?\b|mock data|Demo123!',
                    caseSensitive: false)
                .hasMatch(visible),
            false,
            reason: visible);
      }

      checkCopy();
      await repo.signIn('LD80001', 'Learn123!', true);
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(Portal)));
      for (final page in [
        'home',
        'subjects',
        'messages',
        'settings',
        'results',
        'attendance',
        'calendar',
        'resources',
        'support',
        'profile',
        'announcements'
      ]) {
        router.go('/$page');
        await tester.pumpAndSettle();
        checkCopy();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
