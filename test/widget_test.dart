// Retain compatibility with Flutter versions before the Material package split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucky_dube_learner/features/screens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucky_dube_learner/main.dart';
import 'package:lucky_dube_learner/app/app.dart';
import 'package:lucky_dube_learner/data/repository.dart';

void main() {
  for (final width in [360.0, 390.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('dashboard and navigation at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final repo = MockRepository(await SharedPreferences.getInstance());
      repo.setValue('onboarded', true);
      await repo.signIn('LD80001', 'Learn123!', true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWith((ref) => repo)],
          child: const LuckyApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Good morning'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(width >= 768
          ? find.byIcon(Icons.auto_stories_outlined).first
          : find.text('Subjects').last);
      await tester.pumpAndSettle();
      expect(find.text('Your subjects'), findsOneWidget);
      for (final page in [
        'calendar',
        'messages',
        'profile',
        'settings',
        'resources',
        'homework',
        'assessments',
        'results',
        'timetable',
        'attendance',
        'announcements',
        'performing-arts',
        'notifications',
        'support'
      ]) {
        GoRouter.of(tester.element(find.byType(Portal))).go('/$page');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$page at $width');
      }
      expect(tester.takeException(), isNull);
    });
  }
}
