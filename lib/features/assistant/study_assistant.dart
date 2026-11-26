import 'dart:math' as math;

// Retain compatibility with Flutter versions before the Material package split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_language.dart';
import '../../data/repository.dart';
import '../../main.dart';
import '../../shared/components/premium_surface.dart';

/// Movable assistant launcher. Its position is stored per learner and clamped
/// to the available viewport so it remains reachable after resizing.
class FloatingStudyAssistant extends ConsumerStatefulWidget {
  const FloatingStudyAssistant({super.key});

  @override
  ConsumerState<FloatingStudyAssistant> createState() =>
      _FloatingStudyAssistantState();
}

class _FloatingStudyAssistantState
    extends ConsumerState<FloatingStudyAssistant> {
  Offset? draggedPosition;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(repositoryProvider);
    return LayoutBuilder(builder: (context, constraints) {
      const size = 66.0;
      final maxLeft =
          math.max(8.0, constraints.maxWidth - size - 12).toDouble();
      final maxTop =
          math.max(8.0, constraints.maxHeight - size - 108).toDouble();
      final stored = repository.value('studyAssistantPosition');
      final saved = stored is Map
          ? Offset(
              (stored['x'] as num?)?.toDouble() ?? maxLeft,
              (stored['y'] as num?)?.toDouble() ?? maxTop,
            )
          : Offset(maxLeft, maxTop);
      final proposed = draggedPosition ?? saved;
      final current = Offset(
        proposed.dx.clamp(8.0, maxLeft).toDouble(),
        proposed.dy.clamp(8.0, maxTop).toDouble(),
      );

      return Positioned.fill(
        child: LayoutBuilder(
            builder: (context, _) => Stack(children: [
                  Positioned(
                    left: current.dx,
                    top: current.dy,
                    child: Semantics(
                      button: true,
                      label:
                          tr(context, 'Open AI Study Assistant. Drag to move.'),
                      child: GestureDetector(
                        onTap: () => context.push('/study-assistant'),
                        onPanUpdate: (details) => setState(() {
                          draggedPosition = Offset(
                            (current.dx + details.delta.dx)
                                .clamp(8.0, maxLeft)
                                .toDouble(),
                            (current.dy + details.delta.dy)
                                .clamp(8.0, maxTop)
                                .toDouble(),
                          );
                        }),
                        onPanEnd: (_) {
                          final position = draggedPosition ?? current;
                          repository.put('studyAssistantPosition', {
                            'x': position.dx,
                            'y': position.dy,
                          });
                        },
                        child: Tooltip(
                          message:
                              tr(context, 'Ask a question about your lessons'),
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xff596cf2), Color(0xff3274e9)],
                              ),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x453252b5),
                                  blurRadius: 22,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ])),
      );
    });
  }
}

class StudyAssistantScreen extends ConsumerStatefulWidget {
  const StudyAssistantScreen({super.key});

  @override
  ConsumerState<StudyAssistantScreen> createState() =>
      _StudyAssistantScreenState();
}

class _StudyAssistantScreenState extends ConsumerState<StudyAssistantScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  bool sending = false;

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get messages {
    final raw = ref.read(repositoryProvider).value(
      'studyAssistantMessages',
      <Map<String, dynamic>>[],
    );
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .toList();
  }

  Future<void> send([String? prompt]) async {
    final question = (prompt ?? input.text).trim();
    if (question.isEmpty || sending) return;
    setState(() => sending = true);
    input.clear();
    final repository = ref.read(repositoryProvider);
    final conversation = [
      ...messages,
      {'role': 'learner', 'text': question},
      {
        'role': 'assistant',
        'text': StudyAssistantEngine.answer(question, repository),
      },
    ];
    repository.put('studyAssistantMessages', conversation.take(40).toList());
    if (mounted) setState(() => sending = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> clearConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const LText('Clear conversation?'),
        content: const LText('This will remove your conversation history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const LText('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const LText('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(repositoryProvider).put('studyAssistantMessages', <dynamic>[]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(repositoryProvider);
    final chat = messages;
    final subjects = repository.subjects(repository.learner.grade).take(4);
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const LiquidGlassBar(),
        titleSpacing: 12,
        title: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.auto_awesome_rounded,
                color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LText('AI Study Assistant',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                LText('Learning support',
                    style: TextStyle(fontSize: 11, color: Color(0xff66758b))),
              ],
            ),
          ),
        ]),
        actions: [
          if (chat.isNotEmpty)
            IconButton(
              tooltip: tr(context, 'Clear conversation'),
              onPressed: clearConversation,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(children: [
              Expanded(
                child: chat.isEmpty
                    ? _welcome(repository.learner.grade, subjects.toList())
                    : ListView.builder(
                        controller: scroll,
                        padding: EdgeInsets.fromLTRB(
                            wide ? 28 : 16, 24, wide ? 28 : 16, 20),
                        itemCount: chat.length,
                        itemBuilder: (context, index) => _message(chat[index]),
                      ),
              ),
              _composer(wide),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _welcome(int grade, List<String> subjects) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .75, end: 1),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: const AnimatedIconBadge(
                  icon: Icons.auto_awesome_rounded,
                  color: Color(0xff5572ed),
                  size: 76),
            ),
            const SizedBox(height: 22),
            LText(
              'What are you learning today?',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            LText(
              'Ask a question about a Grade $grade lesson. I can help you break down a topic, review key ideas and practise explaining your thinking.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.6),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 9,
              runSpacing: 9,
              children: [
                for (final subject in subjects)
                  ActionChip(
                    avatar: Icon(Icons.menu_book_rounded,
                        size: 17, color: Theme.of(context).colorScheme.primary),
                    label: Text(subject),
                    onPressed: () => send('Help me understand $subject.'),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.lightbulb_outline_rounded, size: 17),
                  label: const LText('Give me a study tip'),
                  onPressed: () => send('Give me a study tip.'),
                ),
              ],
            ),
          ]),
        ),
      );

  Widget _message(Map<String, dynamic> message) {
    final fromLearner = message['role'] == 'learner';
    final color = Theme.of(context).colorScheme.primary;
    return Align(
      alignment: fromLearner ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width < 600
              ? MediaQuery.sizeOf(context).width * .84
              : 680,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: fromLearner
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(22).copyWith(
                      bottomRight: const Radius.circular(7),
                    ),
                  ),
                  child: Text(message['text']?.toString() ?? '',
                      style: const TextStyle(color: Colors.white, height: 1.5)),
                )
              : LiquidGlassSurface(
                  padding: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 17, color: color),
                        const SizedBox(width: 8),
                        const LText('AI Study Assistant',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 10),
                      Text(message['text']?.toString() ?? '',
                          style: const TextStyle(height: 1.65)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _composer(bool wide) => LiquidGlassSurface(
        borderRadius: BorderRadius.zero,
        padding: EdgeInsets.fromLTRB(wide ? 24 : 14, 12, wide ? 24 : 14, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: TextField(
              controller: input,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => send(),
              decoration: InputDecoration(
                hintText: tr(context, 'Ask about a lesson or topic'),
                prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 52,
            width: 52,
            child: FilledButton(
              onPressed: sending ? null : send,
              style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero, shape: const CircleBorder()),
              child: const Icon(Icons.arrow_upward_rounded),
            ),
          ),
        ]),
      );
}

/// Lesson-aware answer generator that searches the learner's bundled class
/// materials and turns the matching topic into a short guided explanation.
/// It has no external service dependency and respects the learner's grade.
class StudyAssistantEngine {
  static String answer(String question, MockRepository repository) {
    final query = _normalise(question);
    final materials = repository.lessonMaterials();
    if (_isStudyTip(query)) {
      if (_inIsiZulu(repository)) {
        return 'Zama le ndlela elula: funda inhloso yesifundo, chaza umqondo oyinhloko ngamazwi akho, sebenzisa isibonelo esisodwa, bese uhlola izinyathelo zakho. Ekugcineni, bhala umbuzo osafuna ukuwubuza.';
      }
      return 'Try this simple routine: read the lesson objective, explain the main idea in your own words, work through one example, then check each step. Finish by writing down one question you still have.';
    }

    final match = _bestMaterial(query, materials, repository);
    if (match == null) {
      if (_inIsiZulu(repository)) {
        return 'Ngingakusiza ngezifundo zakho zeBanga ${repository.learner.grade}. Faka igama lesifundo noma isihloko embuzweni wakho, noma khetha isifundo esingenhla ukuze siqale.';
      }
      return 'I can help with your Grade ${repository.learner.grade} lessons. Include the subject or topic in your question, such as “How do I find a pattern in Mathematics?” or choose a subject above to get started.';
    }

    final explanation = _explanationFor(match.subject, match.topic);
    final followUp = _inIsiZulu(repository)
        ? 'Yizame: ungachaza kanjani lo mqondo ngamazwi akho?'
        : 'Try it: how would you explain this idea in your own words?';
    if (_inIsiZulu(repository)) {
      return 'Ake sihlukanise isihloko esithi ${match.topic} se-${match.subject} sibe izingxenye ezincane.\n\n$explanation\n\n$followUp';
    }
    return 'Let’s break down ${match.topic} in ${match.subject}.\n\n$explanation\n\n$followUp';
  }

  static LessonMaterial? _bestMaterial(
    String query,
    List<LessonMaterial> materials,
    MockRepository repository,
  ) {
    var bestScore = 0;
    LessonMaterial? best;
    for (final material in materials) {
      final synonyms = _subjectSynonyms[material.subject] ?? const <String>[];
      var score = 0;
      if (query.contains(_normalise(material.subject))) score += 8;
      if (query.contains(_normalise(material.topic))) score += 8;
      for (final synonym in synonyms) {
        if (query.contains(synonym)) score += 5;
      }
      for (final token in _tokens(material.topic)) {
        if (token.length > 3 && query.contains(token)) score += 2;
      }
      if (score > bestScore) {
        best = material;
        bestScore = score;
      }
    }
    if (bestScore > 0) return best;

    final topicMatches = repository.lessonMaterials().where((material) =>
        query.contains(_normalise(material.subject)) ||
        (_subjectSynonyms[material.subject] ?? const <String>[])
            .any(query.contains));
    return topicMatches.isEmpty ? null : topicMatches.first;
  }

  static String _explanationFor(String subject, String topic) =>
      switch (subject) {
        'Mathematics' =>
          'Look for what changes from one value to the next. Describe the rule, test it with another value, and show how you know the rule works. A clear answer includes the pattern, the rule and a check.',
        'English' =>
          'Start with the main idea. Find details in the text that support it, then explain how those details connect. When you make an inference, point to the words or events that helped you reach it.',
        'IsiZulu' =>
          'Qala ngokuthola umqondo oyinhloko. Bheka amagama nemininingwane ebalulekile embhalweni, bese uchaza ukuthi isekela kanjani impendulo yakho.',
        'Natural Sciences' =>
          'Begin by naming the key idea. Describe what you observe, connect it to the scientific concept, and use evidence from the example to support your explanation.',
        'Social Sciences' =>
          'Identify the people, place or change involved. Put the key events in context, then explain one cause and one effect using evidence from the lesson.',
        'Technology' =>
          'A design process starts with a need. Describe the problem, compare possible ideas, choose a solution and explain how you would test and improve it.',
        'Economic and Management Sciences' =>
          'Separate needs from wants, set out the choices available, then compare their costs and benefits. Explain why your choice fits the situation.',
        'Life Orientation' =>
          'Think about the situation, the choices available and how each choice may affect wellbeing. Give a practical example and explain a safe, responsible next step.',
        'Creative Arts' ||
        'Music' =>
          'Notice the patterns in the rhythm or performance. Describe how pace, shape and expression affect the audience, then try the idea in a short creative example.',
        'Geography' =>
          'Read the map title, symbols, scale and direction first. Use those clues to describe location and pattern, then support your conclusion with map evidence.',
        'Dramatic Arts' =>
          'Consider what the character wants, what gets in the way and how their actions change the scene. Use a line, movement or stage direction as evidence.',
        _ =>
          'First explain the key idea in one sentence. Connect it to an example from your lesson, show the steps you used and check whether your conclusion follows from the evidence.',
      };

  static bool _isStudyTip(String query) =>
      query.contains('study tip') ||
      query.contains('revise') ||
      query == 'help me study';

  static bool _inIsiZulu(MockRepository repository) =>
      repository.language == 'zu';

  static String _normalise(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static Set<String> _tokens(String value) => _normalise(value)
      .split(' ')
      .where((token) => !const {
            'about',
            'help',
            'explain',
            'lesson',
            'understand',
            'what',
            'does',
            'mean',
            'how',
            'with',
            'give',
            'please',
          }.contains(token))
      .toSet();

  static const _subjectSynonyms = <String, List<String>>{
    'Mathematics': [
      'math',
      'equation',
      'fraction',
      'algebra',
      'number pattern'
    ],
    'English': ['essay', 'grammar', 'reading', 'comprehension', 'paragraph'],
    'IsiZulu': ['isizulu', 'isi zulu', 'izaga', 'izibongo'],
    'Natural Sciences': [
      'science',
      'photosynthesis',
      'matter',
      'particles',
      'gravity',
      'force',
      'energy',
      'elements',
      'atoms',
      'mixtures',
      'cells',
    ],
    'Social Sciences': [
      'history',
      'society',
      'past events',
      'colonialism',
      'migration',
    ],
    'Technology': ['design', 'prototype', 'structure'],
    'Economic and Management Sciences': [
      'ems',
      'budget',
      'money',
      'business',
      'income',
      'expenses',
      'profit',
    ],
    'Life Orientation': ['wellbeing', 'health', 'relationships'],
    'Creative Arts': ['art', 'music', 'dance', 'drama', 'rhythm'],
    'Geography': ['map', 'climate', 'place', 'landform'],
    'Dramatic Arts': ['theatre', 'character', 'performance', 'stage'],
  };
}
