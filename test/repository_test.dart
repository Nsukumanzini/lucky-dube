import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucky_dube_learner/data/repository.dart';

void main() {
  late MockRepository repo;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = MockRepository(await SharedPreferences.getInstance());
  });
  test('only configured credentials can start a session', () async {
    expect(await repo.signIn('LD80001', 'wrong', true), false);
    expect(await repo.signIn('LD80001', 'Learn123!', true), true);
    expect(repo.learner.grade, 8);
  });
  test('grade switching scopes content and submissions', () async {
    await repo.signIn('LD80001', 'Learn123!', true);
    final id = repo.content('Assignment').first.id;
    repo.submit(id, 'My response', []);
    expect(repo.submitted, 1);
    await repo.signIn('LD90001', 'Learn123!', true);
    expect(repo.submitted, 0);
    expect(repo.content('Resource').every((e) => e.grade == 9), true);
  });
  test('quiz scoring checks answers independently', () {
    expect(MockRepository.score([1, 0, 2]), 3);
    expect(MockRepository.score([-1, 1, 0]), 0);
    expect(MockRepository.score([1, 1, 2]), 2);
  });
  test('theme and messages survive repository reload', () async {
    repo.setValue('theme', 2);
    repo.put('chat-class', ['Hello']);
    await repo.save();
    final restored = MockRepository(await SharedPreferences.getInstance());
    expect(restored.state['theme'], 2);
    expect(restored.value('chat-class'), ['Hello']);
  });
  test('notifications and lesson completion are learner scoped', () {
    repo.notify('New assignment');
    expect(repo.value('notifications'), ['New assignment']);
    repo.put(repo.content('Lesson').first.id, true);
    expect(repo.completed, 1);
  });
  test(
    'school configuration has reusable identity and dataset relationships',
    () {
      expect(MockRepository.school.grades, [8, 9, 10]);
      expect(repo.learners.length, 9);
      expect(MockRepository.teachers.length, 12);
      expect(
        repo.items.where((e) => e.kind == 'Resource').length,
        greaterThanOrEqualTo(20),
      );
      expect(repo.items.map((e) => e.id).toSet().length, repo.items.length);
    },
  );
}
