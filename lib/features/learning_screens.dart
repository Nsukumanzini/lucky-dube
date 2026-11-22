import 'dart:async';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../data/repository.dart';
import '../main.dart';
import '../shared/components/feature_page.dart';

class AssignmentScreen extends StatefulWidget {
  final LearningItem item;
  final MockRepository repo;
  const AssignmentScreen({super.key, required this.item, required this.repo});
  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  late final TextEditingController response;
  List<String> files = [];
  bool submitted = false;
  @override
  void initState() {
    super.initState();
    final saved = widget.repo.value(widget.item.id, {}) as Map;
    response = TextEditingController(text: saved['response'] as String?);
    files = List<String>.from(saved['files'] ?? []);
    submitted = saved['submitted'] == true;
  }

  @override
  void dispose() {
    response.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FeaturePage(
        title: Text(widget.item.title),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.item.subject} • ${MockRepository.teachers[0]}\nDue 27 November 2026, 16:00 SAST • 50 marks\n\nExplain the topic in your own words, give one example and describe how you checked your answer. Submit a written response or a local attachment. Resubmission is permitted.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: response,
                  maxLines: 5,
                  decoration:
                      const InputDecoration(labelText: 'Written response'),
                ),
                for (final f in files)
                  ListTile(
                    title: Text(f),
                    trailing: IconButton(
                      onPressed: () => setState(() => files.remove(f)),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                TextButton.icon(
                  onPressed: () async {
                    final selected = await FilePicker.platform.pickFiles(
                      allowMultiple: true,
                      withData: false,
                    );
                    if (selected != null) {
                      setState(
                        () => files.addAll(selected.names.whereType<String>()),
                      );
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Select local attachments'),
                ),
                if (submitted)
                  const Text(
                    'Submission received locally • Awaiting marking.\nTeacher feedback will appear after simulated review.',
                  ),
                ...List<dynamic>.from(
                  (widget.repo.value(widget.item.id, {}) as Map)['history'] ??
                      [],
                ).map((e) => Text('$e')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              widget.repo.put(widget.item.id, {
                ...Map<String, dynamic>.from(
                    widget.repo.value(widget.item.id, {}) as Map),
                'response': response.text,
                'files': files,
                'submitted': submitted,
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                  const SnackBar(content: Text('Draft saved locally')));
            },
            child: const Text('Save draft'),
          ),
          FilledButton(
            onPressed: () {
              if (response.text.trim().isEmpty && files.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Add a written response or attachment before submitting.')));
                return;
              }
              widget.repo.submit(widget.item.id, response.text, files);
              setState(() => submitted = true);
            },
            child: Text(submitted ? 'Resubmit' : 'Submit assignment'),
          ),
        ],
      );
}

class QuizScreen extends StatefulWidget {
  final LearningItem item;
  final MockRepository repo;
  const QuizScreen({super.key, required this.item, required this.repo});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int index = 0, seconds = 300;
  bool done = false;
  final answers = [-1, -1, -1];
  final flags = <int>{};
  Timer? timer;
  final written = TextEditingController();
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds <= 1) {
        finish();
      } else {
        setState(() => seconds--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    written.dispose();
    super.dispose();
  }

  void finish() {
    timer?.cancel();
    widget.repo.put('quiz-${widget.item.id}', MockRepository.score(answers));
    widget.repo.notify('Practice quiz completed');
    setState(() => done = true);
  }

  @override
  Widget build(BuildContext context) {
    final questions = [
      'Which approach best supports reliable learning?',
      'True or false: checking your work can reveal mistakes.',
      'Which is the strongest evidence for a conclusion?',
      'Explain how you would apply this idea to your subject.',
    ];
    final options = [
      ['Copy without checking', 'Practise and reflect', 'Guess quickly'],
      ['True', 'False'],
      [
        'A rumour',
        'An unsupported opinion',
        'A worked example and clear reasoning',
      ],
    ];
    return FeaturePage(
      title: Text(done ? 'Practice completion summary' : widget.item.title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: done
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${MockRepository.score(answers)} / 3 objective marks • ${(MockRepository.score(answers) / 3 * 100).round()}%',
                    ),
                    const Text(
                      'Written response: pending simulated marking. Practice only; this does not alter official published records.',
                    ),
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '${i + 1}. ${answers[i] == [
                                1,
                                0,
                                2
                              ][i] ? 'Correct' : 'Incorrect'} • ${options[i][[
                            1,
                            0,
                            2
                          ][i]]}\nExplanation: reliable learning uses practice, verification and evidence.',
                        ),
                      ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice only • 1 mark per objective question\n${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} remaining • Question ${index + 1} of 4',
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: (index + 1) / 4),
                    const SizedBox(height: 16),
                    Text(questions[index]),
                    if (index < 3)
                      for (var i = 0; i < options[index].length; i++)
                        ListTile(
                          leading: Icon(answers[index] == i
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked),
                          onTap: () => setState(() => answers[index] = i),
                          title: Text(options[index][i]),
                        ),
                    if (index == 3)
                      TextField(
                        controller: written,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Written answer • manual marking',
                        ),
                      ),
                    FilterChip(
                      label: const Text('Flag for review'),
                      selected: flags.contains(index),
                      onSelected: (v) => setState(() {
                        if (v) {
                          flags.add(index);
                        } else {
                          flags.remove(index);
                        }
                      }),
                    ),
                  ],
                ),
        ),
      ),
      actions: done
          ? [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Exit practice'),
              ),
              if (index > 0)
                TextButton(
                  onPressed: () => setState(() => index--),
                  child: const Text('Previous'),
                ),
              if (index < 3)
                FilledButton(
                  onPressed: () => setState(() => index++),
                  child: const Text('Next'),
                ),
              if (index == 3)
                FilledButton(
                  onPressed: () async {
                    final yes = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Submit practice quiz?'),
                        content: Text(
                          '${answers.where((a) => a < 0).length} unanswered objective questions. ${flags.length} flagged for review.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Review'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Submit'),
                          ),
                        ],
                      ),
                    );
                    if (yes == true) finish();
                  },
                  child: const Text('Submit quiz'),
                ),
            ],
    );
  }
}

class ConversationScreen extends StatefulWidget {
  final String channel;
  final MockRepository repo;
  const ConversationScreen(
      {super.key, required this.channel, required this.repo});
  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final text = TextEditingController();
  bool muted = false;
  @override
  void initState() {
    super.initState();
    muted = widget.repo.value('mute-${widget.channel}', false) as bool;
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  void send(String body) {
    final key = 'chat-${widget.channel}';
    final list = List<String>.from(widget.repo.value(key, <String>[]));
    list.add('You • 10:20\n$body\nDelivered locally');
    list.add(
      'Educator • 10:21 • Simulated response\nThank you for your message. Review the study guide and bring your questions to our next lesson.',
    );
    widget.repo.put(key, list);
    widget.repo.notify('New simulated educator reply');
    text.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => FeaturePage(
        title: Text(widget.channel),
        scrollable: false,
        content: Column(
          children: [
            const Text(
              '26 November 2026 • School-authorised demonstration channel',
            ),
            Expanded(
              child: ListView(
                children: [
                  const ListTile(
                    title: Text('Educator • 08:00'),
                    subtitle: Text(
                      'Welcome! Please keep discussions respectful and focused on learning.',
                    ),
                  ),
                  for (final m in List<String>.from(
                    widget.repo.value('chat-${widget.channel}', <String>[]),
                  ))
                    Card(
                      color: m.startsWith('You')
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(m),
                      ),
                    ),
                ],
              ),
            ),
            TextField(
              controller: text,
              decoration: const InputDecoration(
                labelText: 'Reply to this channel',
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) send(v);
              },
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Share attachment',
                  onPressed: () async {
                    final f = await FilePicker.platform.pickFiles();
                    if (f != null) {
                      send('Demonstration attachment: ${f.names.join(', ')}');
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                ),
                TextButton(
                  onPressed: () {
                    muted = !muted;
                    widget.repo.put('mute-${widget.channel}', muted);
                    setState(() {});
                  },
                  child: Text(muted ? 'Unmute' : 'Mute'),
                ),
                TextButton(
                  onPressed: () {
                    widget.repo.put('reported-${widget.channel}', true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Report saved locally only. Contact a responsible adult for real support.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Report'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Send message',
                  onPressed: () {
                    if (text.text.trim().isNotEmpty) send(text.text.trim());
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
}

class LearningRoute extends ConsumerWidget {
  final String id;
  const LearningRoute({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    final matches =
        repo.items.where((e) => e.id == id && e.grade == repo.learner.grade);
    if (matches.isEmpty) {
      return const FeaturePage(
          title: Text('Learning content'),
          content: Text(
              'This content is not assigned to your learner profile. Return to your subjects to select an available item.'));
    }
    final item = matches.first;
    if (item.kind == 'Assignment') {
      return AssignmentScreen(key: ValueKey(item.id), item: item, repo: repo);
    }
    if (item.kind == 'Quiz') {
      return QuizScreen(key: ValueKey(item.id), item: item, repo: repo);
    }
    return LearningContentScreen(item: item, repo: repo);
  }
}

class LearningContentScreen extends StatefulWidget {
  final LearningItem item;
  final MockRepository repo;
  const LearningContentScreen(
      {super.key, required this.item, required this.repo});
  @override
  State<LearningContentScreen> createState() => _LearningContentScreenState();
}

class _LearningContentScreenState extends State<LearningContentScreen> {
  bool downloading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.repo.put('recent-${widget.item.id}', true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.item;
    final r = widget.repo;
    return FeaturePage(
        title: Text(e.title),
        content:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, children: [
            Chip(label: Text(e.kind)),
            Chip(label: Text(e.subject)),
            Chip(label: Text('Term ${e.term}'))
          ]),
          const SizedBox(height: 24),
          Text(e.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          if (e.kind == 'Result') ...[
            const Text('Published result',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('76%', style: Theme.of(context).textTheme.displayMedium),
            const Text('38 / 50 marks • Published 26 November 2026'),
            const Divider(height: 40),
            const Text('Teacher feedback',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
                'Clear reasoning. Show each step to improve accuracy. This published demonstration record is read-only.')
          ] else ...[
            Text(
                e.kind == 'Lesson'
                    ? 'Learning objectives'
                    : 'Original offline revision guide',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(e.body,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.8)),
            const SizedBox(height: 28),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(e.kind == 'Lesson'
                        ? 'Reflect: explain one idea you learned and one question you would like to ask in class.'
                        : 'Text guide • Bundled locally • Demonstration preview\nAll content on this screen is available without an external document or video service.'))),
            if (downloading)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: LinearProgressIndicator()),
          ]
        ]),
        actions: [
          if (e.kind == 'Lesson')
            FilledButton.icon(
                onPressed: () {
                  r.put(e.id, true);
                  setState(() {});
                },
                icon: const Icon(Icons.check),
                label: Text(r.value(e.id, false) == true
                    ? 'Completed'
                    : 'Mark as complete')),
          if (e.kind == 'Resource') ...[
            OutlinedButton.icon(
                onPressed: () {
                  r.put('saved-${e.id}',
                      !(r.value('saved-${e.id}', false) as bool));
                  setState(() {});
                },
                icon: const Icon(Icons.bookmark_outline),
                label: Text(r.value('saved-${e.id}', false) == true
                    ? 'Bookmarked'
                    : 'Bookmark')),
            FilledButton.icon(
                onPressed: downloading
                    ? null
                    : () async {
                        setState(() => downloading = true);
                        await Future<void>.delayed(
                            const Duration(milliseconds: 600));
                        r.put('download-${e.id}', true);
                        if (mounted) setState(() => downloading = false);
                      },
                icon: const Icon(Icons.download),
                label: Text(r.value('download-${e.id}', false) == true
                    ? 'Available offline'
                    : 'Download for offline'))
          ]
        ]);
  }
}

class ConversationRoute extends ConsumerWidget {
  final String channel;
  const ConversationRoute({super.key, required this.channel});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(repositoryProvider);
    final authorised = [
      '${MockRepository.teachers[0]} • Class teacher',
      '${r.learner.group} • Moderated class group',
      'Mathematics discussion',
      'Performing arts ensemble'
    ];
    if (!authorised.contains(channel)) {
      return const FeaturePage(
          title: Text('Conversation unavailable'),
          content:
              Text('This channel is not assigned to your learner profile.'));
    }
    return ConversationScreen(
        key: ValueKey('${r.learner.id}-$channel'), channel: channel, repo: r);
  }
}

class SubjectScreen extends ConsumerWidget {
  final String subject;
  const SubjectScreen({super.key, required this.subject});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    if (!repo.subjects(repo.learner.grade).contains(subject)) {
      return const FeaturePage(
          title: Text('Subject unavailable'),
          content:
              Text('This subject is not assigned to your learner profile.'));
    }
    final teacher = MockRepository.teachers[
        repo.subjects(repo.learner.grade).indexOf(subject) %
            MockRepository.teachers.length];
    final kinds = ['Lesson', 'Resource', 'Assignment', 'Quiz', 'Result'];
    return DefaultTabController(
        length: 7,
        child: FeaturePage(
            title: Text(subject),
            scrollable: false,
            content:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  'Grade ${repo.learner.grade} • ${repo.learner.group} • $teacher',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
              const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Lessons'),
                    Tab(text: 'Materials'),
                    Tab(text: 'Assignments'),
                    Tab(text: 'Assessments'),
                    Tab(text: 'Results'),
                    Tab(text: 'Discussions')
                  ]),
              const SizedBox(height: 20),
              Expanded(
                  child: TabBarView(children: [
                ListView(children: [
                  Text('Your subject workspace',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  const Text(
                      'Term 4 • Consolidation and creative application\nExplore your lessons, prepare assignments and practise before the final assessments.'),
                  const SizedBox(height: 24),
                  for (final kind in kinds)
                    Card(
                        child: ListTile(
                            leading: const Icon(Icons.arrow_forward),
                            title: Text({
                              'Lesson': 'Continue learning',
                              'Resource': 'Learning materials',
                              'Assignment': 'Homework tasks',
                              'Quiz': 'Practice assessments',
                              'Result': 'Published results'
                            }[kind]!),
                            subtitle: Text(
                                '${repo.content(kind).where((e) => e.subject == subject).length} available'),
                            onTap: () => context.push(
                                '/learning/${Uri.encodeComponent(repo.content(kind).firstWhere((e) => e.subject == subject).id)}')))
                ]),
                for (final kind in kinds)
                  ListView(children: [
                    for (final item in repo
                        .content(kind)
                        .where((e) => e.subject == subject))
                      Card(
                          child: ListTile(
                              contentPadding: const EdgeInsets.all(20),
                              title: Text(item.title),
                              subtitle: Text('Term ${item.term} • $teacher'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push(
                                  '/learning/${Uri.encodeComponent(item.id)}')))
                  ]),
                ListView(children: [
                  const Text(
                      'Discuss learning with your school-authorised group. Demonstration educator responses are clearly labelled.'),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                      onPressed: () => context.push(
                          '/conversation/${Uri.encodeComponent('${repo.learner.group} • Moderated class group')}'),
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text('Open class discussion'))
                ])
              ]))
            ])));
  }
}
