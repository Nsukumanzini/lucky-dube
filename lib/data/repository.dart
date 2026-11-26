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
    this.contact = 'Application support',
    this.logoAsset = 'assets/icon.svg',
    this.primaryColor = 0xff4c5fe8,
    this.secondaryColor = 0xff0ca995,
    this.grades = const [8, 9, 10],
    this.terms = const ['Term 1', 'Term 2', 'Term 3', 'Term 4'],
    this.modules = const [
      'Subjects',
      'Lessons',
      'Quizzes',
      'Resources',
      'Homework',
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
  final String? workType;
  const LearningItem(
    this.id,
    this.title,
    this.subject,
    this.kind,
    this.body,
    this.grade, {
    this.term = 4,
    this.workType,
  });
}

@immutable
class LessonMaterial {
  final String id, title, subject, topic, type, description, body;
  final int grade;
  final String? searchQuery;
  const LessonMaterial({
    required this.id,
    required this.title,
    required this.subject,
    required this.topic,
    required this.type,
    required this.description,
    required this.body,
    required this.grade,
    this.searchQuery,
  });
}

abstract class LearnerRepository extends ChangeNotifier {
  List<Learner> get learners;
  List<LearningItem> get items;
  Map<String, dynamic> get state;
  List<String> get friends;
  List<String> get incomingFriendRequests;
  List<String> get outgoingFriendRequests;
  Future<void> save();
  Future<bool> signIn(String id, String password, bool remember);
  void setValue(String key, dynamic value);
  bool sendFriendRequest(String learnerId);
  void respondToFriendRequest(String learnerId, {required bool accept});
  void cancelFriendRequest(String learnerId);
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

  Map<String, List<String>> _relationshipMap(String name) {
    final raw = state[name];
    if (raw is! Map) return {};
    return raw.map((key, value) => MapEntry(
          key.toString(),
          value is List ? List<String>.from(value) : <String>[],
        ));
  }

  @override
  List<String> get friends =>
      _relationshipMap('friendships')[learner.id] ?? const <String>[];

  @override
  List<String> get incomingFriendRequests =>
      _relationshipMap('friendRequests')[learner.id] ?? const <String>[];

  @override
  List<String> get outgoingFriendRequests {
    final requests = _relationshipMap('friendRequests');
    return requests.entries
        .where((entry) => entry.value.contains(learner.id))
        .map((entry) => entry.key)
        .toList();
  }

  Learner? classmate(String id) {
    for (final person in learners) {
      if (person.id == id &&
          person.id != learner.id &&
          person.group == learner.group) {
        return person;
      }
    }
    return null;
  }

  @override
  bool sendFriendRequest(String learnerId) {
    final peer = classmate(learnerId);
    if (peer == null || friends.contains(peer.id)) return false;
    final requests = _relationshipMap('friendRequests');
    final outgoing = requests[learner.id] ?? <String>[];
    if (outgoing.contains(peer.id)) return false;
    outgoing.add(peer.id);
    requests[learner.id] = outgoing;
    state['friendRequests'] = requests;
    save();
    notifyListeners();
    return true;
  }

  @override
  void respondToFriendRequest(String learnerId, {required bool accept}) {
    if (classmate(learnerId) == null) return;
    final requests = _relationshipMap('friendRequests');
    final incoming = requests[learner.id] ?? <String>[];
    if (!incoming.remove(learnerId)) return;
    requests[learner.id] = incoming;
    state['friendRequests'] = requests;
    if (accept) {
      final relations = _relationshipMap('friendships');
      final mine = relations[learner.id] ?? <String>[];
      final peers = relations[learnerId] ?? <String>[];
      if (!mine.contains(learnerId)) mine.add(learnerId);
      if (!peers.contains(learner.id)) peers.add(learner.id);
      relations[learner.id] = mine;
      relations[learnerId] = peers;
      state['friendships'] = relations;
    }
    save();
    notifyListeners();
  }

  @override
  void cancelFriendRequest(String learnerId) {
    final requests = _relationshipMap('friendRequests');
    final outgoing = requests[learner.id] ?? <String>[];
    if (!outgoing.remove(learnerId)) return;
    requests[learner.id] = outgoing;
    state['friendRequests'] = requests;
    save();
    notifyListeners();
  }

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
                'Learning objective: explain key ideas, apply them to a real example and reflect on your method.\n\n1. Read the question carefully and identify what is known.\n2. Describe the principle in your own words.\n3. Work through an example and check your answer.\n\nOriginal learning material by Optimal Growth Technologies SA. No textbook content is reproduced.',
                grade,
                workType: kind == 'Assignment'
                    ? subjects(grade).indexOf(subject).isEven
                        ? 'Classwork'
                        : 'Homework'
                    : null,
              ),
      ];
  List<LearningItem> content(String kind) =>
      items.where((e) => e.grade == learner.grade && e.kind == kind).toList();
  List<LessonMaterial> lessonMaterials([int? grade]) {
    final selectedGrade = grade ?? learner.grade;
    return [
      for (final subject in subjects(selectedGrade)) ...[
        LessonMaterial(
          id: '$selectedGrade-$subject-video',
          title: '$subject: ${_topic(subject)}',
          subject: subject,
          topic: _topic(subject),
          type: 'Video',
          description: 'Teacher selected YouTube learning search',
          body:
              'Use this search to find a video lesson for Grade $selectedGrade on ${_topic(subject)}. Preview the title and channel before watching, then write down one new idea and one question to discuss in class.',
          grade: selectedGrade,
          searchQuery:
              '$subject Grade $selectedGrade South Africa ${_topic(subject)} lesson',
        ),
        LessonMaterial(
          id: '$selectedGrade-$subject-slides',
          title: '${_topic(subject)} • lesson slides',
          subject: subject,
          topic: _topic(subject),
          type: 'Slides',
          description: '4 slide learning outline',
          body:
              'Slide 1 • Start with what you already know about ${_topic(subject)}.\n\nSlide 2 • Identify the key terms and describe each one in your own words.\n\nSlide 3 • Work through a clear example, showing each step.\n\nSlide 4 • Check your understanding: explain one idea and create a question for your next lesson.',
          grade: selectedGrade,
        ),
        LessonMaterial(
          id: '$selectedGrade-$subject-notes',
          title: '${_topic(subject)} • study notes',
          subject: subject,
          topic: _topic(subject),
          type: 'Notes',
          description: 'Original revision notes • 5 min read',
          body:
              'Learning focus\n${_topic(subject)}\n\nKey idea\nBreak the topic into smaller parts. Connect each new term to an example you understand, then explain how the parts fit together.\n\nStudy steps\n1. Read the lesson objective.\n2. Make a short glossary in your own words.\n3. Practise with an example.\n4. Check your reasoning and correct any gaps.\n\nReflection\nWhat can you now explain clearly? What would you like your educator to explain again?',
          grade: selectedGrade,
        ),
      ],
    ];
  }

  String _topic(String subject) => switch (subject) {
        'Mathematics' => 'Patterns and relationships',
        'English' => 'Reading for meaning',
        'IsiZulu' => 'Ukufunda nokuqonda',
        'Natural Sciences' => 'Matter and materials',
        'Social Sciences' => 'People, places and change',
        'Technology' => 'Design process',
        'Economic and Management Sciences' => 'Needs, wants and choices',
        'Life Orientation' => 'Healthy choices and wellbeing',
        'Creative Arts' || 'Music' => 'Rhythm and creative expression',
        'Geography' => 'Map skills and place',
        'Dramatic Arts' => 'Character and performance',
        _ => 'Core ideas and practice',
      };
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
    if (!learners.any((l) => l.id == id) ||
        !const ['Learn123!', 'Demo123!'].contains(password)) {
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
