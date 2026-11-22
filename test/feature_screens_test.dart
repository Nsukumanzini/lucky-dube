// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucky_dube_learner/main.dart';
import 'package:lucky_dube_learner/app/app.dart';
import 'package:lucky_dube_learner/data/repository.dart';
import 'package:lucky_dube_learner/features/screens.dart';
import 'package:lucky_dube_learner/shared/components/feature_page.dart';

void main() {
  for (final width in [360.0, 390.0, 768.0, 1024.0, 1440.0]) {
    testWidgets('full feature screens and workflows at $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final repo = MockRepository(await SharedPreferences.getInstance());
      repo.setValue('onboarded', true);
      await repo.signIn('LD80001', 'Learn123!', true);
      await tester.pumpWidget(ProviderScope(
          overrides: [repositoryProvider.overrideWith((ref) => repo)],
          child: const LuckyApp()));
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(Portal)));
      router.push('/subject/Mathematics');
      await tester.pumpAndSettle();
      expect(find.text('Your subject workspace'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
      router.pop();
      await tester.pumpAndSettle();
      for (final kind in [
        'Lesson',
        'Resource',
        'Assignment',
        'Quiz',
        'Result'
      ]) {
        final item = repo.content(kind).first;
        router.push('/learning/${Uri.encodeComponent(item.id)}');
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(FeaturePage), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$kind at $width');
        if (kind == 'Lesson') {
          await tester.tap(find.text('Mark as complete'));
          await tester.pumpAndSettle();
          expect(repo.completed, 1);
        }
        if (kind == 'Assignment') {
          await tester.enterText(find.byType(TextField),
              'My original response with a worked example.');
          await tester.tap(find.text('Save draft'));
          await tester.pumpAndSettle();
          expect((repo.value(item.id) as Map)['submitted'], false);
          await tester.tap(find.text('Submit assignment'));
          await tester.pumpAndSettle();
          expect(repo.submitted, 1);
        }
        router.pop();
        await tester.pumpAndSettle();
      }
      final channel = '${MockRepository.teachers[0]} • Class teacher';
      router.push('/conversation/${Uri.encodeComponent(channel)}');
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextField), 'Could you explain the revision task?');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect((repo.value('chat-$channel') as List).length, 2);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
      router.pop();
      await tester.pumpAndSettle();
      router.push('/learning/10-English-Lesson');
      await tester.pumpAndSettle();
      expect(find.textContaining('not assigned'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('entry forms use screens and validate empty input',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<String>(
                            builder: (_) => const EntryScreen(
                                title: 'Personal reminder',
                                hint: 'Reminder details'))),
                    child: const Text('Open reminder'))))));
    await tester.tap(find.text('Open reminder'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter details before saving.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Bring rehearsal notes');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Open reminder'), findsOneWidget);
  });
}
