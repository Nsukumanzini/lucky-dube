import '../app/localization/app_language.dart';
import 'dart:async';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../data/repository.dart';
import '../main.dart';
import '../shared/components/feature_page.dart';
import '../shared/components/learner_visuals.dart';
import '../shared/components/premium_surface.dart';
import 'communication_screens.dart';

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
        title: LText(widget.item.title),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LText(
                  '${widget.item.workType ?? 'Homework'} • ${widget.item.subject} • ${MockRepository.teachers[0]}\nDue 27 November 2026, 16:00 SAST • 50 marks\n\nExplain the topic in your own words, give one example and describe how you checked your answer. Submit a written response or attach a file. Resubmission is permitted.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: response,
                  maxLines: 5,
                  decoration: InputDecoration(
                      labelText: tr(context, 'Written response')),
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
                  label: const LText('Attach files'),
                ),
                if (submitted)
                  const LText(
                    'Submission saved on this device. It has not been sent to your teacher.',
                  ),
                ...List<dynamic>.from(
                  (widget.repo.value(widget.item.id, {}) as Map)['history'] ??
                      [],
                ).map((e) => LText('$e')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const LText('Close'),
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
                  const SnackBar(content: LText('Draft saved on this device')));
            },
            child: const LText('Save draft'),
          ),
          FilledButton(
            onPressed: () {
              if (response.text.trim().isEmpty && files.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: LText(
                        'Add a written response or attachment before submitting.')));
                return;
              }
              widget.repo.submit(widget.item.id, response.text, files);
              setState(() => submitted = true);
            },
            child: LText(submitted ? 'Resubmit' : 'Submit assignment'),
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
    if (done) return;
    timer?.cancel();
    widget.repo.put('quiz-${widget.item.id}', MockRepository.score(answers));
    widget.repo.put('quiz-written-${widget.item.id}', written.text.trim());
    widget.repo.notify('Practice quiz completed');
    if (mounted) setState(() => done = true);
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
    final score = MockRepository.score(answers);
    const correctAnswers = [1, 0, 2];
    return FeaturePage(
      title: LText(done ? 'Quiz results' : widget.item.title),
      content: PageReveal(
        child: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LiquidGlassSurface(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(26),
                  tint: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xeef0f4ff)
                      : const Color(0xd5213150),
                  child: Row(children: [
                    const AnimatedIconBadge(
                        icon: Icons.quiz_rounded,
                        color: Color(0xff526bea),
                        size: 54),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LText(widget.item.subject,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xff566bcb),
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          LText(done
                              ? 'Nice work. Review what you learned.'
                              : 'Take your time and think each answer through.'),
                        ],
                      ),
                    ),
                    if (!done) _timerPill(),
                  ]),
                ),
                const SizedBox(height: 16),
                if (done)
                  _results(score, correctAnswers, options)
                else ...[
                  LiquidGlassSurface(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: LText('Question ${index + 1} of 4',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 15)),
                          ),
                          LText(index < 3 ? '1 point' : 'Written response',
                              style: const TextStyle(
                                  color: Color(0xff64748b), fontSize: 12)),
                        ]),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: (index + 1) / questions.length,
                            minHeight: 8,
                            backgroundColor: const Color(0xffe7ecf8),
                          ),
                        ),
                        const SizedBox(height: 19),
                        Container(
                          padding: const EdgeInsets.all(17),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? const Color(0xfff5f7ff)
                                    : const Color(0xff1b2a43),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x337286d5)),
                          ),
                          child: LText(questions[index],
                              style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.5,
                                  fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 14),
                        if (index < 3)
                          for (var option = 0;
                              option < options[index].length;
                              option++)
                            _answerOption(options[index][option], option),
                        if (index == 3)
                          TextField(
                            controller: written,
                            minLines: 4,
                            maxLines: 7,
                            decoration: InputDecoration(
                              labelText: tr(context,
                                  'Write your response in your own words'),
                              alignLabelWithHint: true,
                              prefixIcon: const Icon(Icons.edit_note_rounded),
                            ),
                          ),
                        const SizedBox(height: 14),
                        Row(children: [
                          const Icon(Icons.lightbulb_outline_rounded,
                              color: Color(0xffed9b2b), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  index == 3
                                      ? 'This question is not included in the automatic score.'
                                      : 'Choose the answer that best explains your thinking.',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xff64748b)))),
                          FilterChip(
                            avatar: Icon(
                                flags.contains(index)
                                    ? Icons.flag_rounded
                                    : Icons.outlined_flag_rounded,
                                size: 16),
                            label: const LText('Review'),
                            selected: flags.contains(index),
                            onSelected: (flag) => setState(() {
                              if (flag) {
                                flags.add(index);
                              } else {
                                flags.remove(index);
                              }
                            }),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, children: [
                    for (var question = 0;
                        question < questions.length;
                        question++)
                      ChoiceChip(
                        label: Text('${question + 1}'),
                        selected: question == index,
                        avatar: flags.contains(question)
                            ? const Icon(Icons.flag_rounded, size: 13)
                            : null,
                        onSelected: (_) => setState(() => index = question),
                      ),
                  ]),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: done
          ? [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const LText('Done'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const LText('Exit practice'),
              ),
              if (index > 0)
                TextButton(
                  onPressed: () => setState(() => index--),
                  child: const LText('Previous'),
                ),
              if (index < 3)
                FilledButton(
                  onPressed: () => setState(() => index++),
                  child: const LText('Next'),
                ),
              if (index == 3)
                FilledButton(
                  onPressed: () async {
                    final yes = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const LText('Submit practice quiz?'),
                        content: LText(
                          '${answers.where((a) => a < 0).length} unanswered objective questions. ${flags.length} flagged for review.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const LText('Review'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const LText('Submit'),
                          ),
                        ],
                      ),
                    );
                    if (yes == true) finish();
                  },
                  child: const LText('Submit quiz'),
                ),
            ],
    );
  }

  Widget _timerPill() {
    final warning = seconds <= 60;
    final color = warning ? const Color(0xffd94c58) : const Color(0xff536be5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timer_outlined, color: color, size: 17),
        const SizedBox(width: 6),
        Text('${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
            style: TextStyle(color: color, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _answerOption(String label, int option) {
    final selected = answers[index] == option;
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: selected
            ? primary.withValues(alpha: .1)
            : Theme.of(context).colorScheme.surface.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () => setState(() => answers[index] = option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                  color: selected ? primary : const Color(0x336b7da5),
                  width: selected ? 1.5 : 1),
            ),
            child: Row(children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? primary : const Color(0xffedf1fb),
                  shape: BoxShape.circle,
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                    : Text(String.fromCharCode(65 + option),
                        style: const TextStyle(
                            color: Color(0xff52617a),
                            fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 13),
              Expanded(child: LText(label)),
              if (selected)
                Icon(Icons.check_circle_rounded, color: primary, size: 20),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _results(
      int score, List<int> correctAnswers, List<List<String>> options) {
    final percent = (score / 3 * 100).round();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LiquidGlassSurface(
        padding: const EdgeInsets.all(21),
        borderRadius: BorderRadius.circular(26),
        tint: Theme.of(context).brightness == Brightness.light
            ? const Color(0xeef0f5ff)
            : const Color(0xd5213150),
        child: Row(children: [
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: score / 3,
                strokeWidth: 8,
                backgroundColor: const Color(0xffdfe6f5),
                color: percent >= 70
                    ? const Color(0xff279a78)
                    : const Color(0xff536be5),
              ),
              Text('$percent%',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LText('$score out of 3 correct',
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                const LText('Review each answer and build on what you know.',
                    style: TextStyle(height: 1.45, color: Color(0xff64748b))),
              ],
            ),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      LiquidGlassSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const LText('Answer review',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          for (var i = 0; i < 3; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                answers[i] == correctAnswers[i]
                    ? Icons.check_circle_rounded
                    : Icons.info_rounded,
                color: answers[i] == correctAnswers[i]
                    ? const Color(0xff23926e)
                    : const Color(0xffe39a27),
              ),
              title: LText(
                  'Question ${i + 1} • ${answers[i] == correctAnswers[i] ? 'Correct' : 'Review this answer'}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: LText(
                  'Answer: ${options[i][correctAnswers[i]]}\nReliable learning grows through practice, checking and clear reasoning.'),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      LiquidGlassSurface(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const Icon(Icons.edit_note_rounded, color: Color(0xff536be5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              written.text.trim().isEmpty
                  ? 'No written response was added.'
                  : 'Your written response is saved with this practice summary.',
              style: const TextStyle(height: 1.5),
            ),
          ),
        ]),
      ),
    ]);
  }
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
          title: LText('Learning content'),
          content: LText(
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
        title: LText(e.title),
        content:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, children: [
            Chip(label: LText(e.kind)),
            Chip(label: LText(e.subject)),
            Chip(label: LText('Term ${e.term}'))
          ]),
          const SizedBox(height: 24),
          LText(e.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          if (e.kind == 'Result') ...[
            const LText('Published result',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LText('76%', style: Theme.of(context).textTheme.displayMedium),
            const LText('38 / 50 marks • Published 26 November 2026'),
            const Divider(height: 40),
            const LText('Teacher feedback',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const LText(
                'Clear reasoning. Show each step to improve accuracy. This learning record is read-only.')
          ] else ...[
            LText(
                e.kind == 'Lesson'
                    ? 'Learning objectives'
                    : 'Original revision guide',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            LText(e.body,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.8)),
            const SizedBox(height: 28),
            LiquidGlassSurface(
                child: LText(e.kind == 'Lesson'
                    ? 'Reflect: explain one idea you learned and one question you would like to ask in class.'
                    : 'Text guide • Available on this device\nAll content on this screen is available without an external document or video service.')),
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
                label: LText(r.value(e.id, false) == true
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
                label: LText(r.value('saved-${e.id}', false) == true
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
                label: LText(r.value('download-${e.id}', false) == true
                    ? 'Saved on this device'
                    : 'Save to this device'))
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
    final friendId = channel.startsWith('friend:')
        ? channel.substring('friend:'.length)
        : null;
    final acceptedFriend = friendId != null &&
        r.classmate(friendId) != null &&
        r.friends.contains(friendId);
    if (!authorised.contains(channel) && !acceptedFriend) {
      return const FeaturePage(
          title: LText('Conversation unavailable'),
          content:
              LText('This channel is not assigned to your learner profile.'));
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
          title: LText('Subject unavailable'),
          content:
              LText('This subject is not assigned to your learner profile.'));
    }
    final teacher = MockRepository.teachers[
        repo.subjects(repo.learner.grade).indexOf(subject) %
            MockRepository.teachers.length];
    final subjectIndex = repo.subjects(repo.learner.grade).indexOf(subject);
    final accent = learnerAccents[subjectIndex % learnerAccents.length];
    final kinds = ['Lesson', 'Resource', 'Assignment', 'Quiz', 'Result'];
    return DefaultTabController(
        length: 7,
        child: FeaturePage(
            title: LText(subject),
            scrollable: false,
            content:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LiquidGlassSurface(
                tint: accent.withValues(alpha: .11),
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  AnimatedIconBadge(
                      icon: _subjectIcon(subject),
                      color: accent,
                      background: Colors.white.withValues(alpha: .78),
                      size: 58),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        LText(subject,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        LText(
                            'Grade ${repo.learner.grade} • ${repo.learner.group} • $teacher',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 10),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: LinearProgressIndicator(
                                value: .68,
                                minHeight: 7,
                                color: accent,
                                backgroundColor:
                                    accent.withValues(alpha: .14))),
                        const SizedBox(height: 3),
                        const LText('68% learning progress',
                            style: TextStyle(fontSize: 11)),
                      ])),
                ]),
              ),
              const SizedBox(height: 14),
              TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      accent,
                      Color.lerp(accent, const Color(0xff4c5fe8), .42)!
                    ]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: accent.withValues(alpha: .24),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 15),
                  overlayColor:
                      WidgetStateProperty.all(accent.withValues(alpha: .08)),
                  tabs: [
                    _subjectTab('Overview', Icons.dashboard_rounded,
                        const Color(0xff4c5fe8)),
                    _subjectTab('Lessons', Icons.auto_stories_rounded,
                        const Color(0xff0ca995)),
                    _subjectTab('Materials', Icons.folder_special_rounded,
                        const Color(0xfff08756)),
                    _subjectTab('Assignments', Icons.edit_note_rounded,
                        const Color(0xffb454d2)),
                    _subjectTab('Assessments', Icons.quiz_rounded,
                        const Color(0xffe5a125)),
                    _subjectTab('Results', Icons.auto_graph_rounded,
                        const Color(0xff22a36a)),
                    _subjectTab('Discussions', Icons.forum_rounded,
                        const Color(0xffec6384)),
                  ]),
              const SizedBox(height: 20),
              Expanded(
                  child: TabBarView(children: [
                ListView(children: [
                  LText('Your subject workspace',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  const LText(
                      'Term 4 • Consolidation and creative application\nExplore your lessons, prepare assignments and practise before the final assessments.'),
                  const SizedBox(height: 24),
                  for (final kind in kinds)
                    LiquidGlassSurface(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                            leading: const Icon(Icons.arrow_forward),
                            title: LText({
                              'Lesson': 'Continue learning',
                              'Resource': 'Learning materials',
                              'Assignment': 'Homework tasks',
                              'Quiz': 'Practice assessments',
                              'Result': 'Published results'
                            }[kind]!),
                            subtitle: LText(
                                '${repo.content(kind).where((e) => e.subject == subject).length} available'),
                            onTap: () => context.push(
                                '/learning/${Uri.encodeComponent(repo.content(kind).firstWhere((e) => e.subject == subject).id)}')))
                ]),
                for (final kind in kinds)
                  ListView(children: [
                    for (final item in repo
                        .content(kind)
                        .where((e) => e.subject == subject))
                      LiquidGlassSurface(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                              contentPadding: const EdgeInsets.all(20),
                              title: LText(item.title),
                              subtitle: LText('Term ${item.term} • $teacher'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push(
                                  '/learning/${Uri.encodeComponent(item.id)}')))
                  ]),
                ListView(children: [
                  const LText(
                      'Discuss learning in your assigned group. Automated practice replies are clearly labelled.'),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                      onPressed: () => context.push(
                          '/conversation/${Uri.encodeComponent('${repo.learner.group} • Moderated class group')}'),
                      icon: const Icon(Icons.forum_outlined),
                      label: const LText('Open class discussion'))
                ])
              ]))
            ])));
  }

  static Tab _subjectTab(String title, IconData icon, Color color) => Tab(
        height: 48,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 7),
          Text(title),
        ]),
      );

  static IconData _subjectIcon(String subject) => switch (subject) {
        'Mathematics' => Icons.functions_rounded,
        'English' || 'IsiZulu' => Icons.menu_book_rounded,
        'Natural Sciences' => Icons.science_rounded,
        'Social Sciences' || 'Geography' => Icons.public_rounded,
        'Technology' => Icons.precision_manufacturing_rounded,
        'Creative Arts' || 'Music' || 'Dramatic Arts' => Icons.palette_rounded,
        'Life Orientation' => Icons.favorite_rounded,
        _ => Icons.auto_stories_rounded,
      };
}
