// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucky_dube_learner/main.dart';
import 'package:lucky_dube_learner/app/app.dart';
import 'package:lucky_dube_learner/data/repository.dart';
import 'package:lucky_dube_learner/features/communication_screens.dart';
import 'package:lucky_dube_learner/shared/components/learner_visuals.dart';

void main() {
  testWidgets('learner app defaults to a light white-surface theme',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = MockRepository(await SharedPreferences.getInstance());
    repo.setValue('onboarded', true);
    await repo.signIn('LD80001', 'Demo123!', true);
    await tester.pumpWidget(ProviderScope(
        overrides: [repositoryProvider.overrideWith((ref) => repo)],
        child: const LuckyApp()));
    await tester.pumpAndSettle();
    final theme = Theme.of(tester.element(find.byType(WelcomeBanner)));
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.surface, Colors.white);
    expect(find.byType(LearningIllustration), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'professional inbox filters staff and groups at mobile text scale',
      (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final repo = MockRepository(await SharedPreferences.getInstance());
    await tester.pumpWidget(ProviderScope(
        overrides: [repositoryProvider.overrideWith((ref) => repo)],
        child: MaterialApp(
            home: MediaQuery(
                data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.3),
                    disableAnimations: true),
                child: const Scaffold(
                    body: SingleChildScrollView(
                        padding: EdgeInsets.all(16), child: InboxScreen()))))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Staff'));
    await tester.pumpAndSettle();
    expect(find.text('N. Maseko'), findsOneWidget);
    expect(find.text('Mathematics discussion'), findsNothing);
    await tester.tap(find.text('Groups'));
    await tester.pumpAndSettle();
    expect(find.text('N. Maseko'), findsNothing);
    expect(find.text('Mathematics discussion'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
