import '../app/localization/app_language.dart';
// Retain compatibility with Flutter versions before the Material package split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../data/repository.dart';
import '../shared/components/feature_page.dart';
import '../shared/components/learner_visuals.dart';
import 'communication_screens.dart';
import '../shared/components/language_selector.dart';
import '../shared/components/premium_surface.dart';

class Portal extends ConsumerStatefulWidget {
  final String page;
  const Portal({super.key, required this.page});
  @override
  ConsumerState<Portal> createState() => _PortalState();
}

class _PortalState extends ConsumerState<Portal> {
  String query = '', filter = 'All';
  String? lessonSubject;
  int onboarding = 0, week = 0, workTab = -1;
  DateTime day = DateTime(2026, 11, 26);
  bool weekly = false;
  final number = TextEditingController(text: 'LD80001'),
      password = TextEditingController(text: 'Learn123!');
  bool obscure = true, remember = true;
  String? error;
  MockRepository get r => ref.read(repositoryProvider);
  void go(String page) {
    if (MediaQuery.sizeOf(context).width < 768) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      query = '';
      filter = 'All';
      lessonSubject = null;
    });
    context.go('/$page');
  }

  @override
  void dispose() {
    number.dispose();
    password.dispose();
    super.dispose();
  }

  void toast(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: LText(text)));
  Future<bool> confirm(String title) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => LiquidGlassSurface(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(28),
          blur: 24,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: LText(title),
            content: const LText(
              'This changes only the information saved on this device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const LText('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const LText('Confirm'),
              ),
            ],
          ),
        ),
      ) ??
      false;
  Future<String?> input(String title, {String hint = 'Enter details'}) =>
      Navigator.of(context).push<String>(MaterialPageRoute(
          builder: (_) => EntryScreen(title: title, hint: hint)));

  Future<void> detail(String title, Widget content) =>
      Navigator.of(context).push<void>(MaterialPageRoute(
          builder: (_) => FeaturePage(title: LText(title), content: content)));
  Widget panel(String title, Widget child, {String? eyebrow}) {
    final accent = learnerAccents[
        title.codeUnits.fold<int>(0, (a, b) => a + b) % learnerAccents.length];
    return FrostedSurface(
      padding: const EdgeInsets.all(18),
      tint: Theme.of(context).brightness == Brightness.light
          ? Color.lerp(Colors.white, accent, .035)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LText(eyebrow,
                  style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900)),
            ),
          Row(children: [
            AnimatedIconBadge(
                icon: _sectionIcon(title), color: accent, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: LText(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800, height: 1.12)),
            ),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget tile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback action, {
    Widget? trailing,
  }) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        leading: AnimatedIconBadge(
          icon: icon,
          color: Theme.of(context).colorScheme.primary,
          size: 44,
        ),
        title: LText(title),
        subtitle: LText(subtitle),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: action,
      );
  @override
  Widget build(BuildContext context) {
    ref.watch(repositoryProvider);
    if (r.state['onboarded'] != true) return intro();
    if (r.state['session'] == null) return login();
    final wide = MediaQuery.sizeOf(context).width >= 768;
    final phone = MediaQuery.sizeOf(context).width < 600;
    final nav = ['home', 'subjects', 'work', 'messages', 'profile'];
    final selected =
        nav.indexOf(widget.page == 'homework' ? 'work' : widget.page);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: phone ? 60 : null,
        flexibleSpace: const LiquidGlassBar(),
        title: Row(
          children: [
            CircleAvatar(
              radius: phone ? 18 : 20,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: LText(
                'LD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: phone ? 13 : 14,
                ),
              ),
            ),
            SizedBox(width: phone ? 8 : 12),
            Expanded(
                child: LText(
              MockRepository.school.displayName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: phone ? 16 : 19),
            )),
            if (MediaQuery.sizeOf(context).width > 1000) ...[
              const SizedBox(width: 20),
              const Chip(label: LText('LEARNER PORTAL')),
            ],
          ],
        ),
        actions: [
          LanguageSelector(compact: phone),
          IconButton(
            tooltip: tr(context, 'Notifications'),
            onPressed: () => go('notifications'),
            icon: Badge(
              isLabelVisible: r.value('notificationsRead', false) != true,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          SizedBox(width: phone ? 4 : 12),
        ],
      ),
      body: Row(
        children: [
          if (wide)
            LiquidGlassSurface(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.zero,
              blur: 18,
              tint: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xbfffffff)
                  : const Color(0xc9111d31),
              child: NavigationRail(
                extended: MediaQuery.sizeOf(context).width > 1150,
                selectedIndex: selected < 0 ? null : selected,
                onDestinationSelected: (i) => go(nav[i]),
                leading: const Padding(
                  padding: EdgeInsets.all(16),
                  child: LText(
                    'YOUR WORKSPACE',
                    style: TextStyle(fontSize: 10, letterSpacing: 2),
                  ),
                ),
                destinations: List.generate(
                  5,
                  (i) => NavigationRailDestination(
                    icon: Icon(
                      [
                        Icons.dashboard_outlined,
                        Icons.auto_stories_outlined,
                        Icons.assignment_turned_in_outlined,
                        Icons.forum_outlined,
                        Icons.person_outline,
                      ][i],
                    ),
                    label: LText(
                      ['Home', 'Subjects', 'Work', 'Messages', 'Profile'][i],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
                toast('Your learner workspace is up to date');
              },
              child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: Theme.of(context).brightness == Brightness.light
                          ? const [
                              Color(0x30ffffff),
                              Color(0x19e6efff),
                              Color(0x1bdbf5ee)
                            ]
                          : const [Color(0x22111d31), Color(0x18254156)],
                    ),
                  ),
                  child: ListView(
                    padding: EdgeInsets.all(wide ? 32 : 16),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1240),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PageReveal(
                                key: ValueKey(widget.page),
                                child: content(),
                              ),
                              const SizedBox(height: 36),
                              const LText(
                                'Optimal Growth Technologies SA',
                                style:
                                    TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )),
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : LiquidGlassSurface(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.zero,
              blur: 22,
              tint: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xc5ffffff)
                  : const Color(0xcf14213a),
              child: NavigationBar(
                height: 76,
                selectedIndex: selected < 0 ? 0 : selected,
                onDestinationSelected: (i) => go(nav[i]),
                destinations: List.generate(
                  5,
                  (i) => NavigationDestination(
                    icon: Icon(
                      [
                        Icons.home_outlined,
                        Icons.menu_book,
                        Icons.assignment_turned_in_rounded,
                        Icons.chat_bubble_outline,
                        Icons.person_outline,
                      ][i],
                    ),
                    label: tr(
                        context,
                        [
                          'Home',
                          'Subjects',
                          'Work',
                          'Messages',
                          'Profile',
                        ][i]),
                  ),
                ),
              ),
            ),
    );
  }

  Widget intro() => Scaffold(
        appBar: AppBar(
          flexibleSpace: const LiquidGlassBar(),
          actions: const [LanguageSelector()],
        ),
        body: Center(
            child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const LText(
                      'LD',
                      style: TextStyle(color: Colors.white, fontSize: 32),
                    ),
                  ),
                  const SizedBox(height: 30),
                  LText(
                    MockRepository.school.displayName,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 30),
                  AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 360),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Container(
                      key: ValueKey(onboarding),
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            learnerAccents[onboarding].withValues(alpha: .18),
                            learnerAccents[
                                    (onboarding + 1) % learnerAccents.length]
                                .withValues(alpha: .09),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(38),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x192b4d83),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        [
                          Icons.menu_book_rounded,
                          Icons.forum_rounded,
                          Icons.insights_rounded
                        ][onboarding],
                        size: 66,
                        color: learnerAccents[onboarding],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => AnimatedContainer(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        width: i == onboarding ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: i == onboarding
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  LText(
                    [
                      'Your learning, all together',
                      'Stay connected to your school',
                      'Make progress every day',
                    ][onboarding],
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  LText(
                    [
                      'Explore lessons, original study guides and homework at your own pace.',
                      'Follow announcements and school-managed conversations.',
                      'Track your learning, plan your week and bring your creativity to life.',
                    ][onboarding],
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  FilledButton(
                    onPressed: () {
                      if (onboarding < 2) {
                        setState(() => onboarding++);
                      } else {
                        r.setValue('onboarded', true);
                      }
                    },
                    child: LText(onboarding == 2 ? 'Get started' : 'Next'),
                  ),
                  TextButton(
                    onPressed: () => r.setValue('onboarded', true),
                    child: const LText('Skip introduction'),
                  ),
                  const SizedBox(height: 24),
                  const LText('Powered by OG Technologies SA'),
                ],
              ),
            ),
          ),
        )),
      );
  Widget login() => Scaffold(
        appBar: AppBar(
          flexibleSpace: const LiquidGlassBar(),
          actions: const [LanguageSelector()],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: panel(
                'Welcome back',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const LText(
                      'Sign in to your learner workspace. Accounts are managed by the school.',
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: number,
                      decoration: InputDecoration(
                        labelText: tr(context, 'Learner number'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: password,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: tr(context, 'Password'),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => obscure = !obscure),
                          icon: Icon(
                            obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      value: remember,
                      onChanged: (v) => setState(() => remember = v!),
                      title: const LText('Remember me'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (error != null)
                      LText(error!, style: const TextStyle(color: Colors.red)),
                    FilledButton(
                      onPressed: () async {
                        final ok = await r.signIn(
                          number.text.trim(),
                          password.text,
                          remember,
                        );
                        if (!ok) {
                          setState(
                            () => error =
                                'Invalid learner number or password. Check your details or choose a learner profile below.',
                          );
                        }
                      },
                      child: const LText('Sign in'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final id = await input(
                          'Password recovery',
                          hint: 'Learner number',
                        );
                        if (id != null && mounted) {
                          detail(
                            'Recovery request',
                            const LText(
                              'No recovery request has been sent. Contact your school account administrator for assistance. Access password: Learn123!',
                            ),
                          );
                        }
                      },
                      child: const LText('Forgot password?'),
                    ),
                    const Divider(),
                    const LText('QUICK SIGN-IN'),
                    const LText('Password for all accounts: Learn123!'),
                    Wrap(
                      spacing: 8,
                      children: [8, 9, 10]
                          .map(
                            (g) => ActionChip(
                              label: LText('Grade $g'),
                              onPressed: () {
                                number.text =
                                    g == 10 ? 'LD10001' : 'LD${g}0001';
                                password.text = 'Learn123!';
                                r.signIn(number.text, password.text, remember);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                eyebrow: 'LUCKY DUBE · LEARNER PORTAL',
              ),
            ),
          ),
        ),
      );
  IconData _sectionIcon(String title) {
    final value = title.toLowerCase();
    if (value.contains('calendar') || value.contains('week')) {
      return Icons.calendar_month_rounded;
    }
    if (value.contains('message') || value.contains('conversation')) {
      return Icons.forum_rounded;
    }
    if (value.contains('art') ||
        value.contains('creative') ||
        value.contains('performance')) {
      return Icons.palette_rounded;
    }
    if (value.contains('progress') ||
        value.contains('result') ||
        value.contains('average')) {
      return Icons.auto_graph_rounded;
    }
    if (value.contains('homework') ||
        value.contains('task') ||
        value.contains('assignment')) {
      return Icons.edit_note_rounded;
    }
    if (value.contains('attendance')) {
      return Icons.event_available_rounded;
    }
    if (value.contains('subject') ||
        value.contains('lesson') ||
        value.contains('learning')) {
      return Icons.auto_stories_rounded;
    }
    if (value.contains('announcement') || value.contains('notice')) {
      return Icons.campaign_rounded;
    }
    if (value.contains('profile')) {
      return Icons.face_rounded;
    }
    if (value.contains('support') || value.contains('help')) {
      return Icons.favorite_rounded;
    }
    return Icons.auto_awesome_rounded;
  }

  Widget heading(String title, String subtitle) {
    final accent = learnerAccents[
        title.codeUnits.fold<int>(0, (a, b) => a + b) % learnerAccents.length];
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 460;
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LText(title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.8,
                      height: 1.1)),
              const SizedBox(height: 7),
              LText(subtitle,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45)),
            ]),
          ),
          SizedBox(width: compact ? 8 : 18),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: .78, end: 1),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 520),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: Container(
              width: compact ? 54 : 68,
              height: compact ? 54 : 68,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: accent.withValues(alpha: .2)),
              ),
              child: Icon(_sectionIcon(title),
                  color: accent, size: compact ? 27 : 34),
            ),
          ),
        ]);
      }),
    );
  }

  Widget content() {
    switch (widget.page) {
      case 'home':
        return home();
      case 'subjects':
        return catalogue();
      case 'lessons':
        return lessons();
      case 'quizzes':
      case 'assessments':
        return quizzes();
      case 'calendar':
        return calendar();
      case 'work':
      case 'homework':
        return work();
      case 'messages':
        return messages();
      case 'profile':
        return profile();
      case 'settings':
        return settings();
      case 'resources':
      case 'results':
        return catalogue();
      case 'timetable':
        return timetable();
      case 'attendance':
        return attendance();
      case 'announcements':
        return announcements();
      case 'performing-arts':
        return arts();
      case 'notifications':
        return notifications();
      case 'support':
        return support();
      default:
        return heading(
          'Page not found',
          'Use the navigation to return to your workspace.',
        );
    }
  }

  Widget home() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading(
            'Good morning, ${r.learner.name.split(' ').first} 👋',
            'Thursday, 26 November 2026  •  Grade ${r.learner.grade} ${r.learner.group}  •  Term 4',
          ),
          WelcomeBanner(onContinue: () => go('subjects')),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (c, b) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                stat(
                  'Learning progress',
                  '${r.completed}/${r.content('Lesson').length}',
                  'Lessons completed',
                  b.maxWidth,
                ),
                stat('Attendance', '96%', '48 of 50 school days', b.maxWidth),
                stat(
                  'Homework',
                  '${r.content('Assignment').length - r.submitted}',
                  'Tasks to complete',
                  b.maxWidth,
                ),
                stat(
                  'Published average',
                  '76%',
                  'Term 4',
                  b.maxWidth,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          panel(
            'Your learning toolkit',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...MockRepository.school.modules.where((s) => s != 'Subjects'),
                'School calendar',
              ]
                  .map(
                    (s) => ActionChip(
                      avatar: const Icon(Icons.arrow_outward, size: 16),
                      label: LText(s),
                      onPressed: () => go(slug(s)),
                    ),
                  )
                  .toList(),
            ),
          ),
          panel(
            'Up next',
            Column(
              children: [
                tile(
                  'Mathematics • Patterns and relationships',
                  '10:15–11:00 • Room B2 • ${MockRepository.teachers[2]}',
                  Icons.functions,
                  () => go('timetable'),
                ),
                tile(
                  'Creative showcase rehearsal',
                  '14:30 • Performing arts studio',
                  Icons.theater_comedy_outlined,
                  () => go('performing-arts'),
                ),
              ],
            ),
          ),
          panel(
            'Stay on track',
            Column(
              children: [
                tile(
                  'Term 4 tasks',
                  '${r.submitted} submitted • deadlines 27–30 November',
                  Icons.task_alt,
                  () => go('homework'),
                ),
                tile(
                  'End-of-year creative showcase',
                  'Pinned • Performing arts • 26 November',
                  Icons.campaign_outlined,
                  () => go('announcements'),
                ),
                tile(
                  'Your school conversations',
                  'Staff and moderated groups',
                  Icons.chat_outlined,
                  () => go('messages'),
                ),
              ],
            ),
          ),
        ],
      );
  String slug(String s) =>
      {
        'Lessons': 'lessons',
        'Quizzes': 'quizzes',
        'Homework': 'homework',
        'School calendar': 'calendar',
        'Assessments': 'assessments',
        'Performing arts': 'performing-arts',
      }[s] ??
      s.toLowerCase();

  Widget lessons() {
    final subjects = r.subjects(r.learner.grade);
    final materials = r
        .lessonMaterials()
        .where((item) => filter == 'All' || item.type == filter)
        .where((item) => lessonSubject == null || item.subject == lessonSubject)
        .where((item) =>
            query.isEmpty ||
            '${item.title} ${item.subject} ${item.topic} ${item.type}'
                .toLowerCase()
                .contains(query));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'Lessons',
          'Videos, lesson slides and study notes • Grade ${r.learner.grade}',
        ),
        search(['All', 'Video', 'Slides', 'Notes']),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<String?>(
            initialValue: lessonSubject,
            decoration: const InputDecoration(labelText: 'Filter by subject'),
            items: [
              const DropdownMenuItem<String?>(
                  value: null, child: LText('All subjects')),
              for (final subject in subjects)
                DropdownMenuItem<String?>(
                    value: subject, child: LText(subject)),
            ],
            onChanged: (value) => setState(() => lessonSubject = value),
          ),
        ),
        for (final item in materials)
          LiquidGlassSurface(
            padding: EdgeInsets.zero,
            child: tile(
              item.title,
              '${item.subject} • ${item.type} • ${item.description}',
              item.type == 'Video'
                  ? Icons.play_circle_fill_rounded
                  : item.type == 'Slides'
                      ? Icons.slideshow_rounded
                      : Icons.notes_rounded,
              () => openLessonMaterial(item),
            ),
          ),
        if (materials.isEmpty)
          const LiquidGlassSurface(
            child: LText(
                'No lessons match those filters. Try another subject or search.'),
          ),
      ],
    );
  }

  void openLessonMaterial(LessonMaterial item) {
    Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => FeaturePage(
        title: LText(item.type == 'Video' ? 'Video lesson' : item.type),
        content: _lessonMaterialDetail(item),
        actions: [
          if (item.type == 'Video')
            FilledButton.icon(
              onPressed: () async {
                final uri = Uri.https('www.youtube.com', '/results', {
                  'search_query': item.searchQuery,
                });
                final opened = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!opened && mounted) {
                  toast('YouTube could not be opened on this device.');
                }
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const LText('Find videos on YouTube'),
            ),
        ],
      ),
    ));
  }

  Widget _lessonMaterialDetail(LessonMaterial item) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.subject.toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              )),
          const SizedBox(height: 8),
          LText(item.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          LText(item.description),
          const SizedBox(height: 20),
          if (item.type == 'Video') ...[
            const LiquidGlassSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.video_library_rounded, size: 34),
                  SizedBox(height: 12),
                  LText('Explore a video lesson',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  LText(
                      'Search YouTube for a topic-specific video. Video results open outside the app when you choose to continue.'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            LText('Suggested search: ${item.searchQuery}'),
            const SizedBox(height: 18),
            LText(item.body),
          ] else if (item.type == 'Slides') ...[
            InteractiveSlideDeck(
                slides: item.body.split('\n\n'), subject: item.subject),
          ] else
            LiquidGlassSurface(
              child: LText(item.body,
                  style: const TextStyle(height: 1.8, fontSize: 15)),
            ),
        ],
      );

  Widget quizzes() {
    final quizzes = r.content('Quiz').where((item) {
      final score = r.value('quiz-${item.id}');
      final matchesStatus = filter == 'All' ||
          (filter == 'Completed' && score != null) ||
          (filter == 'To practise' && score == null);
      final matchesQuery = query.isEmpty ||
          '${item.title} ${item.subject}'.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'Practice quizzes',
          'Build confidence with short, self-marking practice • Grade ${r.learner.grade}',
        ),
        search(['All', 'To practise', 'Completed']),
        for (final item in quizzes)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LiquidGlassSurface(
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                leading: AnimatedIconBadge(
                  icon: Icons.quiz_rounded,
                  color: learnerAccents[
                      r.subjects(r.learner.grade).indexOf(item.subject) %
                          learnerAccents.length],
                  size: 48,
                ),
                title: LText(item.title),
                subtitle: LText(
                  '${item.subject} • Term ${item.term} • 5 min • Practice only'
                  '${r.value('quiz-${item.id}') == null ? '' : ' • Last score ${r.value('quiz-${item.id}')}/3'}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => openItem(item),
              ),
            ),
          ),
        if (quizzes.isEmpty)
          const LiquidGlassSurface(
            child: LText(
                'No quizzes match those filters. Try another search or status.'),
          ),
      ],
    );
  }

  Widget stat(String title, String value, String sub, double width) {
    final index = [
      'Learning progress',
      'Attendance',
      'Homework',
      'Published average'
    ].indexOf(title);
    final accent = learnerAccents[index < 0 ? 0 : index];
    return SizedBox(
        width: width < 550 ? (width - 12) / 2 : (width - 36) / 4,
        child: FrostedSurface(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedIconBadge(
                  icon: [
                    Icons.auto_stories_outlined,
                    Icons.check_circle_outline,
                    Icons.edit_note_rounded,
                    Icons.insights_rounded
                  ][index < 0 ? 0 : index],
                  size: 40,
                  color: accent),
              const SizedBox(height: 16),
              LText(title,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent)),
              const SizedBox(height: 8),
              LText(value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              LText(sub,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xff64748b), height: 1.5)),
            ])));
  }

  Widget search(List<String> filters) => Column(
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: tr(context, 'Search your workspace'),
            ),
            onChanged: (v) => setState(() => query = v.toLowerCase()),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: filters
                .map(
                  (f) => ChoiceChip(
                    label: LText(f),
                    selected: filter == f,
                    onSelected: (_) => setState(() => filter = f),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
      );
  Widget catalogue() {
    final kind = {
      'resources': 'Resource',
      'homework': 'Assignment',
      'assessments': 'Quiz',
      'results': 'Result',
    }[widget.page];
    final subjectMode = kind == null;
    final list = subjectMode
        ? r.subjects(r.learner.grade)
        : r.content(kind).map((e) => e.title).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          subjectMode
              ? 'Your subjects'
              : {
                  'Resource': 'Learning library',
                  'Assignment': 'Homework & assignments',
                  'Quiz': 'Practice assessments',
                  'Result': 'Academic results',
                }[kind]!,
          subjectMode
              ? 'Choose a subject to continue learning'
              : 'Learning content • Grade ${r.learner.grade}',
        ),
        if (kind == 'Result')
          panel(
            '76% published average',
            Column(
              children: [
                for (var t = 1; t <= 4; t++)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        LText('Term $t  '),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (68 + t * 2) / 100,
                          ),
                        ),
                        LText(' ${68 + t * 2}%'),
                      ],
                    ),
                  ),
                TextButton(
                  onPressed: () => detail(
                    'Unofficial report preview',
                    LText(
                      '${r.learner.name}\nGrade ${r.learner.grade} • 2026\n\nUNOFFICIAL LEARNING SUMMARY — NOT AN OFFICIAL SCHOOL REPORT\n\n${r.subjects(r.learner.grade).map((s) => '$s: 76%').join('\n')}',
                    ),
                  ),
                  child: const LText('Preview unofficial report'),
                ),
              ],
            ),
          ),
        if (subjectMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: tr(context, 'Search subjects'),
              ),
              onChanged: (value) => setState(() => query = value.toLowerCase()),
            ),
          )
        else
          search(
            kind == 'Assignment'
                ? ['All', 'Upcoming', 'Submitted', 'Overdue', 'Marked']
                : ['All', 'Term 4', 'Saved'],
          ),
        ...list.where((s) => s.toLowerCase().contains(query)).where((s) {
          if (subjectMode) return filter != 'Saved';
          final e = r.content(kind).firstWhere((e) => e.title == s);
          if (filter == 'Saved') {
            return r.value('saved-${e.id}', false) == true;
          }
          if (kind == 'Assignment') {
            final submitted = (r.value(e.id, {}) as Map)['submitted'] == true;
            if (filter == 'Submitted') return submitted;
            if (filter == 'Upcoming') return !submitted;
            if (filter == 'Marked' || filter == 'Overdue') return false;
          }
          return true;
        }).map((s) {
          if (subjectMode) {
            return _subjectCard(s, r.subjects(r.learner.grade).indexOf(s));
          }
          final e = r.content(kind).firstWhere((e) => e.title == s);
          return LiquidGlassSurface(
            padding: EdgeInsets.zero,
            child: tile(
              e.title,
              '${e.subject} • Term ${e.term}${kind == 'Assignment' ? ' • Due 27 Nov, 16:00 • ${(r.value(e.id, {}) as Map)['submitted'] == true ? 'Submitted' : 'Upcoming'}' : ''}',
              kind == 'Resource'
                  ? Icons.description_outlined
                  : kind == 'Quiz'
                      ? Icons.quiz_outlined
                      : Icons.task_outlined,
              () => openItem(e),
            ),
          );
        }),
        if (list.where((s) => s.toLowerCase().contains(query)).isEmpty)
          const LText('No matching content. Try another search.'),
      ],
    );
  }

  Widget _subjectCard(String name, int index) {
    final color = learnerAccents[index % learnerAccents.length];
    final icon = switch (name) {
      'Mathematics' => Icons.functions_rounded,
      'English' || 'IsiZulu' => Icons.menu_book_rounded,
      'Natural Sciences' => Icons.science_rounded,
      'Social Sciences' || 'Geography' => Icons.public_rounded,
      'Technology' => Icons.precision_manufacturing_rounded,
      'Creative Arts' || 'Music' || 'Dramatic Arts' => Icons.palette_rounded,
      'Life Orientation' => Icons.favorite_rounded,
      _ => Icons.auto_stories_rounded,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: LiquidGlassSurface(
        padding: EdgeInsets.zero,
        tint: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(23),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(23),
            onTap: () => subject(name),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
              child: Row(children: [
                AnimatedIconBadge(
                    icon: icon,
                    color: color,
                    background: color.withValues(alpha: .14),
                    size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: LText(name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
                Icon(Icons.arrow_forward_rounded, color: color),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget work() {
    final all = r.content('Assignment');
    final classwork =
        all.where((item) => item.workType == 'Classwork').toList();
    final homework = all.where((item) => item.workType == 'Homework').toList();
    final selected = workTab >= 0
        ? workTab
        : widget.page == 'homework'
            ? 1
            : 0;
    final items = selected == 0 ? classwork : homework;
    final visible = items.where((item) {
      final status = r.value(item.id, {}) as Map;
      final submitted = status['submitted'] == true;
      final matchesFilter = filter == 'All' ||
          filter == 'Submitted' && submitted ||
          filter == 'Upcoming' && !submitted ||
          filter == 'Overdue' && !submitted && item.term < 4 ||
          filter == 'Marked' && status['marked'] == true;
      final matchesQuery = query.isEmpty ||
          '${item.title} ${item.subject}'.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
    final submittedCount = items
        .where((item) => (r.value(item.id, {}) as Map)['submitted'] == true)
        .length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading('Work', 'Classwork and homework • Grade ${r.learner.grade}'),
      LayoutBuilder(
          builder: (context, constraints) =>
              Wrap(spacing: 10, runSpacing: 10, children: [
                _workStat(
                    'To complete',
                    '${items.length - submittedCount}',
                    Icons.edit_note_rounded,
                    const Color(0xfff08756),
                    constraints.maxWidth),
                _workStat(
                    'Submitted',
                    '$submittedCount',
                    Icons.task_alt_rounded,
                    const Color(0xff0ca995),
                    constraints.maxWidth),
                _workStat(
                    'Due next',
                    items.isEmpty ? '—' : '27 Nov',
                    Icons.calendar_today_rounded,
                    const Color(0xff4c5fe8),
                    constraints.maxWidth),
              ])),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? const Color(0xdfffffff)
              : const Color(0xb923344c),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: .75)),
        ),
        child: Row(children: [
          _workTabChip('Classwork', Icons.edit_document, classwork.length, 0),
          _workTabChip('Homework', Icons.home_work_rounded, homework.length, 1),
        ]),
      ),
      const SizedBox(height: 16),
      search(['All', 'Upcoming', 'Submitted', 'Overdue', 'Marked']),
      for (final item in visible)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LiquidGlassSurface(
            padding: EdgeInsets.zero,
            tint: learnerAccents[items.indexOf(item) % learnerAccents.length]
                .withValues(alpha: .055),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => openItem(item),
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Row(children: [
                    AnimatedIconBadge(
                      icon: Icons.assignment_outlined,
                      color: learnerAccents[
                          items.indexOf(item) % learnerAccents.length],
                      size: 48,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          LText(item.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          LText(
                              '${item.subject} • Term ${item.term} • Due 27 Nov, 16:00',
                              style: Theme.of(context).textTheme.bodySmall),
                        ])),
                    const SizedBox(width: 8),
                    _workStatus(
                        (r.value(item.id, {}) as Map)['submitted'] == true),
                  ]),
                ),
              ),
            ),
          ),
        ),
      if (visible.isEmpty)
        LiquidGlassSurface(
          child: Column(children: [
            const Icon(Icons.inbox_rounded, size: 38, color: Color(0xff0ca995)),
            const SizedBox(height: 9),
            LText(
                query.isEmpty
                    ? 'You’re all caught up here'
                    : 'No work matches your search',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ]),
        ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: () => go('calendar'),
        icon: const Icon(Icons.calendar_month_rounded),
        label: const LText('Open school calendar'),
      ),
    ]);
  }

  Widget _workTabChip(String title, IconData icon, int count, int index) {
    final active = (workTab >= 0
            ? workTab
            : widget.page == 'homework'
                ? 1
                : 0) ==
        index;
    final color =
        index == 0 ? const Color(0xff4c5fe8) : const Color(0xff0ca995);
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        child: InkWell(
          onTap: () => setState(() => workTab = index),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
            decoration: BoxDecoration(
              color: active ? color.withValues(alpha: .14) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: active
                      ? color.withValues(alpha: .25)
                      : Colors.transparent),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                  child: LText(title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: active
                              ? color
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w800))),
              const SizedBox(width: 5),
              Text('$count',
                  style: TextStyle(
                      color: active
                          ? color
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _workStat(String title, String value, IconData icon, Color color,
          double width) =>
      SizedBox(
        width: width < 560 ? width : (width - 20) / 3,
        child: LiquidGlassSurface(
          padding: const EdgeInsets.all(14),
          tint: color.withValues(alpha: .08),
          child: Row(children: [
            AnimatedIconBadge(icon: icon, color: color, size: 40),
            const SizedBox(width: 9),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(value,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  LText(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall),
                ])),
          ]),
        ),
      );

  Widget _workStatus(bool submitted) {
    final color = submitted ? const Color(0xff159465) : const Color(0xffe99328);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(submitted ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 14, color: color),
        const SizedBox(width: 4),
        LText(submitted ? 'Done' : 'To do',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  void subject(String subject) =>
      context.push('/subject/${Uri.encodeComponent(subject)}');
  Future<void> openItem(LearningItem e) =>
      context.push<void>('/learning/${Uri.encodeComponent(e.id)}');

  Widget timetable() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading(
            'Your timetable',
            '${r.learner.group} • Week ${48 + week} • Africa/Johannesburg',
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => week--),
                icon: const Icon(Icons.chevron_left),
              ),
              LText(
                  'Week of ${DateTime(2026, 11, 23).add(Duration(days: week * 7)).day}/${DateTime(2026, 11, 23).add(Duration(days: week * 7)).month}'),
              IconButton(
                onPressed: () => setState(() => week++),
                icon: const Icon(Icons.chevron_right),
              ),
              FilterChip(
                label: const LText('Weekly'),
                selected: weekly,
                onSelected: (v) => setState(() => weekly = v),
              ),
            ],
          ),
          for (final d in weekly
              ? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
              : ['Thursday'])
            panel(
              d,
              Column(
                children: [
                  for (var i = 0; i < 6; i++)
                    tile(
                      i == 2
                          ? 'Break'
                          : r.subjects(r.learner.grade)[
                              i % r.subjects(r.learner.grade).length],
                      '${8 + i}:15 – ${9 + i}:00 • ${i == 2 ? 'Courtyard' : 'Room B${i + 1} • ${MockRepository.teachers[i]}'}',
                      i == 2 ? Icons.coffee : Icons.schedule,
                      () => detail(
                        'Schedule details',
                        LText(
                          'Grade ${r.learner.grade} • ${r.learner.group}\n${i == 2 ? 'Break period' : 'Bring your workbook. Topic: term consolidation. Teacher: ${MockRepository.teachers[i]}'}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
  Widget attendance() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading('Attendance', 'Attendance overview • Read-only'),
          panel(
            '96% attendance',
            const LText(
              '48 present • 2 absent • 3 late arrivals\n50 recorded school days',
            ),
          ),
          panel(
            'November 2026',
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: List.generate(
                30,
                (i) => Tooltip(
                  message: i == 9
                      ? 'Absent'
                      : i == 16
                          ? 'Late'
                          : 'Present',
                  child: CircleAvatar(
                    backgroundColor: i == 9
                        ? Colors.red.shade100
                        : i == 16
                            ? Colors.amber.shade100
                            : Colors.green.shade100,
                    child: LText(
                      '${i + 1}',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),
          ),
          tile(
            'Explain an absence',
            'A private note saved on this device',
            Icons.edit_note,
            () async {
              final text = await input('Absence explanation');
              if (text != null) {
                r.put('absence', text);
                toast(
                    'Your note is saved on this device and has not been sent for review.');
              }
            },
          ),
          panel(
            'Attendance history',
            const LText(
              '10 Nov • Absent\n17 Nov • Late, 08:12\n24 Nov • Present\n25 Nov • Present\n26 Nov • Present',
            ),
          ),
        ],
      );
  static const events = [
    'Creative showcase rehearsal',
    'Mathematics revision session',
    'Term 4 assignment deadline',
    'Parent feedback meeting',
    'End-of-year performance',
    'School holiday planning',
  ];
  Widget calendar() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading('Your calendar', 'Plan your learning and creative practice'),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(
                  () => day = DateTime(day.year, day.month - 1, day.day),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: LText(
                  '${day.year} / ${day.month}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => setState(
                  () => day = DateTime(day.year, day.month + 1, day.day),
                ),
                icon: const Icon(Icons.chevron_right),
              ),
              FilterChip(
                label: const LText('Week'),
                selected: weekly,
                onSelected: (v) => setState(() => weekly = v),
              ),
            ],
          ),
          search(['All', 'Academic', 'Performing arts']),
          panel(
            weekly ? 'Selected week' : 'Month overview',
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 48,
              ),
              itemCount: weekly ? 7 : DateTime(day.year, day.month + 1, 0).day,
              itemBuilder: (c, i) {
                final n = weekly ? day.day - day.weekday + i + 1 : i + 1;
                return TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: n == day.day
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    foregroundColor: n == day.day ? Colors.white : null,
                  ),
                  onPressed: () =>
                      setState(() => day = DateTime(day.year, day.month, n)),
                  child: LText('$n'),
                );
              },
            ),
          ),
          panel(
            '${day.day} / ${day.month} • Agenda',
            Column(
              children: [
                ...events
                    .where((e) => e.toLowerCase().contains(query))
                    .where(
                      (e) =>
                          filter == 'All' ||
                          (filter == 'Academic'
                              ? !e.contains('showcase') &&
                                  !e.contains('performance')
                              : e.contains('showcase') ||
                                  e.contains('performance')),
                    )
                    .map(
                      (e) => tile(
                        e,
                        '${day.day}/${day.month}/${day.year} • 14:30 • School activity',
                        Icons.event,
                        () => detail(
                          e,
                          const LText(
                            'School activity. Location: Arts studio / school hall. Bring your learning materials and arrive ten minutes early.',
                          ),
                        ),
                      ),
                    ),
                ...List<String>.from(r.value('reminders', <String>[])).map(
                  (e) => tile(
                    e,
                    'Personal reminder',
                    Icons.alarm,
                    () => detail('Personal reminder', LText(e)),
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () async {
              final text = await input('Add personal reminder');
              if (text != null) {
                r.put('reminders', [
                  ...List<String>.from(r.value('reminders', <String>[])),
                  '${day.day}/${day.month}: $text',
                ]);
              }
            },
            icon: const Icon(Icons.add),
            label: const LText('Personal reminder'),
          ),
        ],
      );
  Widget announcements() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading(
            'Announcement centre',
            'News for Grade ${r.learner.grade} and the school community',
          ),
          search(
              ['All', 'General', 'Academic', 'Performing arts', 'Important']),
          for (final e in [
            'Creative showcase • Pinned',
            'Term 4 study guidance',
            'Examination preparation',
            'School closing arrangements',
            'Important learner safety notice',
          ].where((e) => e.toLowerCase().contains(query)))
            LiquidGlassSurface(
              padding: EdgeInsets.zero,
              child: tile(
                e,
                '${MockRepository.teachers[0]} • 25 Nov 2026 • ${r.value('read-$e', false) == true ? 'Read' : 'Unread'}',
                Icons.campaign_outlined,
                () {
                  r.put('read-$e', true);
                  detail(
                    e,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LText(
                          'Please prepare your learning materials for the final activities of Term 4. Learners should follow the published timetable and speak to their class teacher if they need support.\n\nThis announcement is fictional and is not an official school notice.',
                        ),
                        TextButton(
                          onPressed: () {
                            r.put('bookmark-$e', true);
                            toast('Announcement bookmarked');
                          },
                          child: const LText('Bookmark announcement'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      );
  Widget messages() => const InboxScreen();
  Widget arts() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading(
            'The performing arts centre',
            'Find your voice. Develop your craft. Share your creativity.',
          ),
          panel(
            'On stage • Creative futures',
            const LText(
              '26 November 2026 • 14:30\nFinal ensemble rehearsal • Arts studio\nUpcoming production: Voices of Tomorrow • 30 November',
            ),
          ),
          Wrap(
            spacing: 8,
            children: MockRepository.school.disciplines
                .map(
                  (e) => ActionChip(
                    label: LText(e),
                    onPressed: () => detail(
                      e,
                      LText(
                        '$e practice studio\n\nWarm up safely, rehearse a short original sequence and reflect on expression, timing and collaboration.\n\nEducator feedback: Strong commitment. Practise transitions and support your ensemble.',
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          panel(
            'Performance preparation',
            Column(
              children: [
                for (final e in [
                  'Warm-up completed',
                  'Materials prepared',
                  'Rehearsal notes reviewed',
                  'Creative work ready',
                ])
                  CheckboxListTile(
                    title: LText(e),
                    value: r.value(e, false) as bool,
                    onChanged: (v) => r.put(e, v),
                  ),
                TextButton(
                  onPressed: () {
                    r.put('rehearsal-request', true);
                    toast(
                      'Rehearsal attendance request recorded locally; awaiting review',
                    );
                  },
                  child:
                      const LText('Request rehearsal attendance confirmation'),
                ),
              ],
            ),
          ),
          panel(
            'Your private portfolio',
            Column(
              children: [
                const LText('Private by default • never publicly published'),
                ...List<String>.from(r.value('portfolio', <String>[])).map(
                  (e) => tile(
                    e,
                    'Original creative work • Private',
                    Icons.palette_outlined,
                    () => detail('Portfolio project', LText(e)),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final title = await input(
                      'Add creative project',
                      hint: 'Project title and description',
                    );
                    if (title == null) return;
                    final files = await FilePicker.platform.pickFiles(
                      type: FileType.media,
                    );
                    r.put('portfolio', [
                      ...List<String>.from(r.value('portfolio', <String>[])),
                      '$title${files == null ? '' : '\nMedia: ${files.names.join(', ')}'}',
                    ]);
                  },
                  icon: const Icon(Icons.add),
                  label: const LText('Add creative project'),
                ),
              ],
            ),
          ),
        ],
      );
  Widget notifications() {
    final list = [
      ...List<String>.from(r.value('notifications', <String>[])),
      'New Term 4 assignments',
      'Published results available',
      'Creative showcase rehearsal reminder',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading('Notifications', 'Updates from your learning workspace'),
        TextButton(
          onPressed: () => r.put('notificationsRead', true),
          child: const LText('Mark all as read'),
        ),
        for (final n in list.where((n) => r.value('dismiss-$n', false) != true))
          LiquidGlassSurface(
            padding: EdgeInsets.zero,
            child: tile(
              n,
              r.value('notificationsRead', false) == true ? 'Read' : 'Unread',
              Icons.notifications_outlined,
              () => go(
                n.contains('result')
                    ? 'results'
                    : n.contains('rehearsal')
                        ? 'performing-arts'
                        : 'homework',
              ),
              trailing: IconButton(
                tooltip: tr(context, 'Dismiss notification'),
                onPressed: () => r.put('dismiss-$n', true),
                icon: const Icon(Icons.close),
              ),
            ),
          ),
      ],
    );
  }

  Widget profile() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading('Your profile', 'Official learner details are read-only'),
          panel(
            r.learner.name,
            LText(
              '${r.learner.id} • Grade ${r.learner.grade} • ${r.learner.group}\n${MockRepository.school.name}\nAcademic year 2026 • Class teacher ${MockRepository.teachers[0]}\nAttendance: 96%\n\nEnrolled subjects: ${r.subjects(r.learner.grade).join(', ')}',
            ),
          ),
          for (final s in [
            'Resources',
            'Performing arts',
            'Settings',
            'Support'
          ])
            tile(
              s,
              s == 'Resources' ? 'Saved and downloaded materials' : 'Open $s',
              Icons.arrow_outward,
              () => go(slug(s)),
            ),
          tile(
            'Privacy & about',
            'Developer, ownership and application information',
            Icons.privacy_tip_outlined,
            () => detail(
              'About Lucky Dube',
              LText(
                '${MockRepository.school.owner}\n\nDeveloped and owned by Optimal Growth Technologies SA. No school endorsement is implied. Learner and teacher profiles are fictional. Information is stored on this device; do not enter sensitive personal information. Messages and requests are not delivered to school staff.',
              ),
            ),
          ),
          TextButton(
              onPressed: () => r.logout(), child: const LText('Sign out')),
        ],
      );
  Widget settings() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading('Settings', 'Make this workspace yours'),
          panel('Language', const LanguageSelector()),
          panel(
            'Appearance & accessibility',
            Column(
              children: [
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: (r.state['theme'] as int?) ?? 1,
                  items: const [
                    DropdownMenuItem(value: 0, child: LText('System theme')),
                    DropdownMenuItem(value: 1, child: LText('Light mode')),
                    DropdownMenuItem(value: 2, child: LText('Dark mode')),
                  ],
                  onChanged: (v) => r.setValue('theme', v),
                ),
                const SizedBox(height: 16),
                const LText('Text size'),
                Slider(
                  value: (r.state['textScale'] as num?)?.toDouble() ?? 1,
                  min: 1,
                  max: 1.5,
                  divisions: 5,
                  onChanged: (v) => r.setValue('textScale', v),
                ),
                SwitchListTile(
                  title: const LText('Local notification preferences'),
                  value: r.value('notificationPreference', true) as bool,
                  onChanged: (v) => r.put('notificationPreference', v),
                ),
              ],
            ),
          ),
          panel(
            'Learner profiles',
            Wrap(
              spacing: 8,
              children: [8, 9, 10]
                  .map(
                    (g) => ActionChip(
                      label: LText('Grade $g'),
                      onPressed: () => r.signIn(
                        g == 10 ? 'LD10001' : 'LD${g}0001',
                        'Learn123!',
                        true,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          tile(
            'Download management',
            'Remove locally marked downloads',
            Icons.download,
            () async {
              if (await confirm('Clear downloaded material markers?')) {
                r.state.removeWhere((k, v) => k.contains('download-'));
                await r.save();
                setState(() {});
              }
            },
          ),
          tile(
            'Clear local cache',
            'Clear recently viewed resources',
            Icons.cleaning_services,
            () async {
              if (await confirm('Clear recently viewed history?')) {
                r.state.removeWhere((k, v) => k.contains('recent-'));
                await r.save();
                setState(() {});
              }
            },
          ),
          tile(
            'Reset local information',
            'Removes sessions, submissions and local preferences',
            Icons.restart_alt,
            () async {
              if (await confirm('Reset all local information?')) {
                await r.reset();
              }
            },
          ),
        ],
      );
  Widget support() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading('Help & learner safety', 'Support for your learning journey'),
          panel(
            'Need help right now?',
            const LText(
              'For real emergencies, contact a responsible adult or appropriate emergency service immediately. Reports saved here are not delivered to staff or emergency services.',
            ),
          ),
          for (final q in [
            'How do I sign in?',
            'Where can I find saved learning content?',
            'How do I submit homework?',
            'Who can read my portfolio?',
          ])
            ExpansionTile(
              title: LText(q),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: LText(
                    {
                      'How do I sign in?':
                          'Use your provided learner number and Learn123!; no self-registration is available.',
                      'Where can I find saved learning content?':
                          'Open Resources to browse your learning guides and saved materials.',
                      'How do I submit homework?':
                          'Open Homework, select a task, enter your response and submit. Drafts stay on this device.',
                      'Who can read my portfolio?':
                          'Your portfolio is private and stored on this device.',
                    }[q]!,
                  ),
                ),
              ],
            ),
          panel(
            'Report a concern privately',
            Column(
              children: [
                for (final cat in [
                  'Bullying',
                  'Harassment',
                  'Academic concerns',
                  'Safety concerns',
                  'Inappropriate communication',
                  'Technical issues',
                ])
                  tile(
                    cat,
                    'Write a private concern note',
                    Icons.support_agent,
                    () async {
                      final body = await input(
                        cat,
                        hint:
                            'Describe your concern (avoid sensitive personal data)',
                      );
                      if (body != null) {
                        final id =
                            'LD-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
                        r.put('concern-$id', {'category': cat, 'body': body});
                        if (mounted) {
                          detail(
                            'Request $id',
                            const LText(
                              'Saved privately on this device only. This has NOT been delivered to real school staff or emergency services. Speak directly to a responsible adult for real support.',
                            ),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      );
}
