// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:lucky_dube_learner/main.dart';
import 'package:lucky_dube_learner/app/app.dart';
import 'package:lucky_dube_learner/app/localization/app_language.dart';
import 'package:lucky_dube_learner/app/localization/catalog.dart';
import 'package:lucky_dube_learner/data/repository.dart';
import 'package:lucky_dube_learner/features/screens.dart';

void main() {
  test('catalogue translates navigation, variables and unchanged identities',
      () {
    const zu = AppLanguage(Locale('zu', 'ZA'));
    expect(zu.translate('Home'), 'Ikhaya');
    expect(zu.translate('Good morning, Ayanda 👋'), 'Sawubona, Ayanda 👋');
    expect(zu.translate('Grade 8 • Term 4'), 'Ibanga 8 • Ithemu 4');
    expect(zu.translate('LD80001'), 'LD80001');
    expect(zu.translate('Lucky Dube'), 'Lucky Dube');
    expect(
        zu.translate(MockRepository.school.name), MockRepository.school.name);
    expect(isiZuluCatalog.length, greaterThan(300));
  });
  test('language preferences persist and remain learner-specific', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = MockRepository(prefs);
    repo.setLanguage('zu');
    await repo.signIn('LD80001', 'Learn123!', true);
    expect(repo.language, 'zu');
    await repo.signIn('LD90001', 'Learn123!', true);
    repo.setLanguage('en');
    await repo.signIn('LD80001', 'Learn123!', true);
    expect(repo.language, 'zu');
    await repo.save();
    expect(MockRepository(prefs).language, 'zu');
    repo.setLanguage('unsupported');
    expect(repo.language, 'zu');
  });
  testWidgets('isiZulu can be selected before sign-in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = MockRepository(await SharedPreferences.getInstance());
    repo.setValue('onboarded', true);
    await tester.pumpWidget(ProviderScope(
        overrides: [repositoryProvider.overrideWith((ref) => repo)],
        child: const LuckyApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Language / Ulimi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('isiZulu').last);
    await tester.pumpAndSettle();
    expect(find.text('Ngena'), findsOneWidget);
    expect(find.text('Inombolo yomfundi'), findsOneWidget);
    expect(repo.language, 'zu');
    repo.setLanguage('en');
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
  });
  testWidgets('isiZulu onboarding scrolls on short mobile screens',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final repo = MockRepository(await SharedPreferences.getInstance());
    repo.setLanguage('zu');
    await tester.pumpWidget(ProviderScope(
        overrides: [repositoryProvider.overrideWith((ref) => repo)],
        child: const LuckyApp()));
    await tester.pumpAndSettle();
    expect(find.text('Konke ukufunda kwakho ndawonye'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final width in [360.0, 390.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('isiZulu learner screens fit at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final repo = MockRepository(await SharedPreferences.getInstance());
      repo.setValue('onboarded', true);
      await repo.signIn('LD80001', 'Learn123!', true);
      repo.setLanguage('zu');
      await tester.pumpWidget(ProviderScope(
          overrides: [repositoryProvider.overrideWith((ref) => repo)],
          child: const LuckyApp()));
      await tester.pumpAndSettle();
      expect(find.text('Ikhaya'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final router = GoRouter.of(tester.element(find.byType(Portal)));
      for (final page in [
        'subjects',
        'messages',
        'calendar',
        'settings',
        'homework',
        'assessments',
        'results',
        'resources',
        'support',
        'performing-arts',
        'profile',
        'announcements',
        'attendance',
        'timetable'
      ]) {
        router.go('/$page');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: '$page in isiZulu at $width');
      }
      for (final kind in ['Assignment', 'Quiz', 'Lesson', 'Resource']) {
        router.push(
            '/learning/${Uri.encodeComponent(repo.content(kind).first.id)}');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: kind);
        router.pop();
        await tester.pumpAndSettle();
      }
    });
  }
}
