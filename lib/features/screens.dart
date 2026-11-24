import '../app/localization/app_language.dart';
// Retain compatibility with Flutter versions before the Material package split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../main.dart';
import '../data/repository.dart';
import '../shared/components/feature_page.dart';
import '../shared/components/learner_visuals.dart';
import 'communication_screens.dart';
import '../shared/components/language_selector.dart';

class Portal extends ConsumerStatefulWidget {
  final String page;
  const Portal({super.key, required this.page});
  @override
  ConsumerState<Portal> createState() => _PortalState();
}

class _PortalState extends ConsumerState<Portal> {
  String query = '', filter = 'All';
  int onboarding = 0, week = 0;
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
        builder: (c) => AlertDialog(
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
      ) ??
      false;
  Future<String?> input(String title, {String hint = 'Enter details'}) =>
      Navigator.of(context).push<String>(MaterialPageRoute(
          builder: (_) => EntryScreen(title: title, hint: hint)));

  Future<void> detail(String title, Widget content) =>
      Navigator.of(context).push<void>(MaterialPageRoute(
          builder: (_) => FeaturePage(title: LText(title), content: content)));
  Widget panel(String title, Widget child, {String? eyebrow}) => Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null)
                LText(
                  eyebrow,
                  style: const TextStyle(
                    color: Color(0xff2563eb),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              LText(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      );
  Widget tile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback action, {
    Widget? trailing,
  }) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: const Color(0xffeff6ff),
          child: Icon(icon, color: const Color(0xff2563eb)),
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
    final nav = ['home', 'subjects', 'calendar', 'messages', 'profile'];
    final selected = nav.indexOf(widget.page);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: phone ? 60 : null,
        title: Row(
          children: [
            CircleAvatar(
              radius: phone ? 18 : 20,
              backgroundColor: const Color(0xff2563eb),
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
            NavigationRail(
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
                      Icons.calendar_month_outlined,
                      Icons.forum_outlined,
                      Icons.person_outline,
                    ][i],
                  ),
                  label: LText(
                    ['Home', 'Subjects', 'Calendar', 'Messages', 'Profile'][i],
                  ),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
                toast('Your offline workspace is up to date');
              },
              child: ListView(
                padding: EdgeInsets.all(wide ? 32 : 16),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          content(),
                          const SizedBox(height: 36),
                          const LText(
                            'Optimal Growth Technologies SA',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
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
                      Icons.calendar_month,
                      Icons.chat_bubble_outline,
                      Icons.person_outline,
                    ][i],
                  ),
                  label: tr(
                      context,
                      [
                        'Home',
                        'Subjects',
                        'Calendar',
                        'Messages',
                        'Profile',
                      ][i]),
                ),
              ),
            ),
    );
  }

  Widget intro() => Scaffold(
        appBar: AppBar(actions: const [LanguageSelector()]),
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
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Color(0xff2563eb),
                    child: LText(
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
                  Icon(
                    [Icons.menu_book, Icons.forum, Icons.insights][onboarding],
                    size: 80,
                    color: const Color(0xff2563eb),
                  ),
                  const SizedBox(height: 24),
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
                      'Explore lessons, original study guides and homework offline.',
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
        appBar: AppBar(actions: const [LanguageSelector()]),
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
  Widget heading(String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LText(
              title,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LText(subtitle, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
  Widget content() {
    switch (widget.page) {
      case 'home':
        return home();
      case 'subjects':
        return catalogue();
      case 'calendar':
        return calendar();
      case 'messages':
        return messages();
      case 'profile':
        return profile();
      case 'settings':
        return settings();
      case 'resources':
      case 'homework':
      case 'assessments':
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
              children: MockRepository.school.modules
                  .where((s) => s != 'Subjects')
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
        'Homework': 'homework',
        'Assessments': 'assessments',
        'Performing arts': 'performing-arts',
      }[s] ??
      s.toLowerCase();
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
        child: Card(
            child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: accent.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(
                              [
                                Icons.auto_stories_outlined,
                                Icons.check_circle_outline,
                                Icons.edit_note_rounded,
                                Icons.insights_rounded
                              ][index < 0 ? 0 : index],
                              size: 20,
                              color: accent)),
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
                              fontSize: 11,
                              color: Color(0xff64748b),
                              height: 1.5)),
                    ]))));
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
              ? 'Your enrolled subjects • Term 4'
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
            return Card(
              child: tile(
                s,
                '${MockRepository.teachers[r.subjects(r.learner.grade).indexOf(s) % 12]} • ${r.completed} lessons complete\n1 pending task • Latest result 76% • Next lesson 10:15',
                Icons.auto_stories,
                () => subject(s),
              ),
            );
          }
          final e = r.content(kind).firstWhere((e) => e.title == s);
          return Card(
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
            'Private request • Saved on this device; not delivered',
            Icons.edit_note,
            () async {
              final text = await input('Absence explanation');
              if (text != null) {
                r.put('absence', text);
                toast('Saved locally • Awaiting simulated staff review');
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
                    backgroundColor:
                        n == day.day ? const Color(0xff2563eb) : null,
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
            Card(
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
        heading('Notifications', 'Local in-app updates'),
        TextButton(
          onPressed: () => r.put('notificationsRead', true),
          child: const LText('Mark all as read'),
        ),
        for (final n in list.where((n) => r.value('dismiss-$n', false) != true))
          Card(
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
            'Can I learn offline?',
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
                      'Can I learn offline?':
                          'Learning guides and resources are available on this device.',
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
            'Report a concern • Private simulation',
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
                    'Save a private simulated support request',
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
