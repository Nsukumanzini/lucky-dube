import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class SchoolConfiguration {
  final String id, name, displayName, owner, language, contact, logoAsset;
  final int primaryColor, secondaryColor;
  final List<int> grades;
  final List<String> languages;
  final List<String> terms, modules, disciplines;
  const SchoolConfiguration({
    this.id = 'ld-demo',
    this.name = 'Lucky Dube Secondary School of Performing Arts',
    this.displayName = 'Lucky Dube',
    this.owner = 'Optimal Growth Technologies SA',
    this.language = 'English',
    this.languages = const ['en', 'zu'],
    this.contact = 'Demonstration support only',
    this.logoAsset = 'assets/icon.svg',
    this.primaryColor = 0xff14213d,
    this.secondaryColor = 0xff2563eb,
    this.grades = const [8, 9, 10],
    this.terms = const ['Term 1', 'Term 2', 'Term 3', 'Term 4'],
    this.modules = const [
      'Subjects',
      'Resources',
      'Homework',
      'Assessments',
      'Results',
      'Timetable',
      'Attendance',
      'Announcements',
      'Performing arts',
    ],
    this.disciplines = const [
      'Music',
      'Dance',
      'Drama',
      'Technical production',
      'Sound and lighting',
    ],
  });
}

@immutable
class Learner {
  final String id, name, group;
  final int grade;
  const Learner(this.id, this.name, this.grade, this.group);
}

@immutable
class LearningItem {
  final String id, title, subject, kind, body;
  final int grade, term;
  const LearningItem(
    this.id,
    this.title,
    this.subject,
    this.kind,
    this.body,
    this.grade, {
    this.term = 4,
  });
}

abstract class LearnerRepository extends ChangeNotifier {
  List<Learner> get learners;
  List<LearningItem> get items;
  Map<String, dynamic> get state;
  Future<void> save();
  Future<bool> signIn(String id, String password, bool remember);
  void setValue(String key, dynamic value);
}

class MockRepository extends LearnerRepository {
  final SharedPreferences preferences;
  @override
  final Map<String, dynamic> state;
  MockRepository(this.preferences)
      : state = jsonDecode(
          preferences.getString('demo') ?? '{}',
        ) as Map<String, dynamic>;
  static const school = SchoolConfiguration();
  static const teachers = [
    'N. Maseko',
    'T. Nkosi',
    'A. Dlamini',
    'P. Khumalo',
    'S. Molefe',
    'L. Botha',
    'B. Zulu',
    'M. Naidoo',
    'J. Mokoena',
    'K. Dube',
    'R. Jacobs',
    'F. Ndlovu',
  ];
  @override
  List<Learner> get learners => const [
        Learner('LD80001', 'Ayanda Mokoena', 8, '8A'),
        Learner('LD90001', 'Lethabo Nkosi', 9, '9A'),
        Learner('LD10001', 'Sipho Dlamini', 10, '10A'),
        Learner('LD80002', 'Zanele Mthembu', 8, '8B'),
        Learner('LD80003', 'Thabo Sithole', 8, '8A'),
        Learner('LD90002', 'Naledi Molefe', 9, '9B'),
        Learner('LD90003', 'Sibusiso Zulu', 9, '9A'),
        Learner('LD10002', 'Anele Jacobs', 10, '10B'),
        Learner('LD10003', 'Bongani Ndlovu', 10, '10A'),
      ];
  Learner get learner => learners.firstWhere(
        (l) => l.id == state['session'],
        orElse: () => learners.first,
      );
  List<String> subjects(int grade) => grade == 10
      ? [
          'English',
          'IsiZulu',
          'Mathematics',
          'Life Orientation',
          'Geography',
          'Music',
          'Dramatic Arts',
        ]
      : [
          'English',
          'IsiZulu',
          'Mathematics',
          'Natural Sciences',
          'Social Sciences',
          'Technology',
          'Economic and Management Sciences',
          'Life Orientation',
          'Creative Arts',
        ];
  @override
  List<LearningItem> get items => [
        for (final grade in school.grades)
          for (final subject in subjects(grade))
            for (final kind in [
              'Lesson',
              'Resource',
              'Assignment',
              'Quiz',
              'Result',
            ])
              LearningItem(
                '$grade-$subject-$kind',
                kind == 'Lesson'
                    ? 'Explore ${subject.toLowerCase()}'
                    : kind == 'Resource'
                        ? '$subject revision guide'
                        : kind == 'Assignment'
                            ? '$subject • Term 4 task'
                            : kind == 'Quiz'
                                ? '$subject practice quiz'
                                : '$subject term assessment',
                subject,
                kind,
                'Learning objective: explain key ideas, apply them to a real example and reflect on your method.\n\n1. Read the question carefully and identify what is known.\n2. Describe the principle in your own words.\n3. Work through an example and check your answer.\n\nOriginal demonstration material by Optimal Growth Technologies SA. No textbook content is reproduced.',
                grade,
              ),
      ];
  List<LearningItem> content(String kind) =>
      items.where((e) => e.grade == learner.grade && e.kind == kind).toList();
  String key(String id) => '${learner.id}:$id';
  dynamic value(String id, [dynamic fallback]) => state[key(id)] ?? fallback;
  @override
  void setValue(String key, dynamic value) {
    state[key] = value;
    save();
    notifyListeners();
  }

  void put(String id, dynamic value) => setValue(key(id), value);
  @override
  Future<void> save() async {
    await preferences.setString('demo', jsonEncode(state));
  }

  @override
  Future<bool> signIn(String id, String password, bool remember) async {
    if (!learners.any((l) => l.id == id) || password != 'Demo123!') {
      return false;
    }
    state['session'] = id;
    state.putIfAbsent(key('language'), () => state['language'] ?? 'en');
    state['remember'] = remember;
    await save();
    notifyListeners();
    return true;
  }

  String get language =>
      (state['session'] == null ? null : state[key('language')]) as String? ??
      state['language'] as String? ??
      'en';
  void setLanguage(String code) {
    if (!school.languages.contains(code)) return;
    state['language'] = code;
    if (state['session'] != null) state[key('language')] = code;
    save();
    notifyListeners();
  }

  void logout() {
    state.remove('session');
    save();
    notifyListeners();
  }

  int get completed =>
      content('Lesson').where((e) => value(e.id, false) == true).length;
  int get submitted => content('Assignment')
      .where((e) => value(e.id) is Map && value(e.id)['submitted'] == true)
      .length;
  void notify(String text) {
    if (value('notificationPreference', true) != true) return;
    final list = List<String>.from(value('notifications', <String>[]));
    list.insert(0, text);
    put('notifications', list);
  }

  void submit(String id, String response, List<String> files) {
    put(id, {
      'response': response,
      'files': files,
      'submitted': true,
      'date': '26 Nov 2026',
      'history': [
        ...List<dynamic>.from((value(id, {}) as Map)['history'] ?? []),
        'Submitted 26 Nov 2026',
      ],
    });
    notify('Assignment submitted for review');
  }

  static int score(List<int> answers) => List.generate(
        answers.length,
        (i) => answers[i] == [1, 0, 2][i % 3] ? 1 : 0,
      ).fold(0, (a, b) => a + b);
  Future<void> reset() async {
    state.clear();
    await save();
    notifyListeners();
  }
}
