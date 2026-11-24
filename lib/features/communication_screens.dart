import '../app/localization/app_language.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../main.dart';
import '../data/repository.dart';
import '../shared/components/feature_page.dart';
import '../shared/components/learner_visuals.dart';
import '../shared/components/premium_surface.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});
  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String query = '', filter = 'All';
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final channels = [
      '${MockRepository.teachers[0]} • Class teacher',
      '${repo.learner.group} • Moderated class group',
      'Mathematics discussion',
      'Performing arts ensemble'
    ];
    final hints = [
      'Ask a question or get learning support',
      'Your class updates, together in one place',
      'Share ideas and work through questions',
      'Rehearsals, creative work and collaboration'
    ];
    final icons = [
      Icons.person_rounded,
      Icons.groups_rounded,
      Icons.functions_rounded,
      Icons.theater_comedy_rounded
    ];
    final unreadCount = channels.where((channel) {
      final messages =
          List<String>.from(repo.value('chat-$channel', <String>[]));
      return messages.isNotEmpty && repo.value('read-$channel', false) != true;
    }).length;
    final filtered = channels.asMap().entries.where((e) =>
        e.value.toLowerCase().contains(query) &&
        (filter == 'All' ||
            filter == 'Staff' && e.key == 0 ||
            filter == 'Groups' && e.key > 0));
    final width = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LText(
                    'YOUR LEARNING CIRCLE',
                    style: TextStyle(
                      color: Color(0xff0d9488),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 5),
                  LText(
                    'Messages',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.7,
                        ),
                  ),
                ],
              ),
            ),
            if (unreadCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xffe9efff),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mark_chat_unread_rounded,
                        size: 16, color: Color(0xff3156d8)),
                    const SizedBox(width: 6),
                    LText('$unreadCount',
                        style: const TextStyle(
                            color: Color(0xff3156d8),
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 4),
                    const LText('unread',
                        style: TextStyle(
                            color: Color(0xff3156d8),
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const LText(
            'Your learning circle. Helpful conversations, in the right place.'),
        const SizedBox(height: 18),
        LiquidGlassSurface(
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(24),
          tint: Theme.of(context).brightness == Brightness.light
              ? const Color(0xeaf2f6ff)
              : const Color(0xe51b2c49),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  right: -28,
                  top: -38,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xff59b7aa).withValues(alpha: .12),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(width < 600 ? 17 : 22),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const LText(
                              'Connected, with care',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            const LText(
                              'Staff-managed channels and moderated learning groups.',
                              style: TextStyle(height: 1.45, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0x1c0d9488),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_user_rounded,
                                      size: 14, color: Color(0xff0d9488)),
                                  SizedBox(width: 6),
                                  LText('A thoughtful space to learn',
                                      style: TextStyle(
                                          color: Color(0xff0d776d),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (width >= 380)
                        const AnimatedIconBadge(
                          icon: Icons.forum_rounded,
                          color: Color(0xff3156d8),
                          background: Color(0x263156d8),
                          size: 56,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: InputDecoration(
            hintText: tr(context, 'Search conversations'),
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: tr(context, 'Clear search'),
                    onPressed: () => setState(() => query = ''),
                    icon: const Icon(Icons.close_rounded),
                  ),
            filled: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) => setState(() => query = value.toLowerCase()),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in [
                ('All', channels.length),
                ('Staff', 1),
                ('Groups', channels.length - 1),
              ]) ...[
                ChoiceChip(
                  selected: filter == option.$1,
                  onSelected: (_) => setState(() => filter = option.$1),
                  avatar: Icon(
                    option.$1 == 'All'
                        ? Icons.forum_outlined
                        : option.$1 == 'Staff'
                            ? Icons.person_outline_rounded
                            : Icons.groups_outlined,
                    size: 16,
                    color: filter == option.$1
                        ? const Color(0xff3156d8)
                        : const Color(0xff0d9488),
                  ),
                  label: LText('${option.$1}  ${option.$2}'),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final entry in filtered)
          Builder(builder: (context) {
            final i = entry.key, channel = entry.value;
            final messages =
                List<String>.from(repo.value('chat-$channel', <String>[]));
            final unread = messages.isNotEmpty &&
                repo.value('read-$channel', false) != true;
            final preview = messages.isEmpty
                ? hints[i]
                : messages.last
                    .split('\n')
                    .skip(1)
                    .where((s) => s != 'Delivered locally')
                    .join(' ');
            final accent = learnerAccents[i];
            final metadata = messages.isEmpty
                ? ''
                : messages.last
                        .split('\n')
                        .first
                        .split(' • ')
                        .skip(1)
                        .firstOrNull ??
                    '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LiquidGlassSurface(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(22),
                tint: unread
                    ? (Theme.of(context).brightness == Brightness.light
                        ? const Color(0xebf8faff)
                        : const Color(0xeb1c2d49))
                    : null,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      repo.put('read-$channel', true);
                      context.push(
                          '/conversation/${Uri.encodeComponent(channel)}');
                    },
                    child: Padding(
                      padding: EdgeInsets.all(width < 600 ? 14 : 17),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedIconBadge(
                                  icon: icons[i], color: accent, size: 50),
                              if (unread)
                                Positioned(
                                  right: -1,
                                  bottom: -1,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: const Color(0xff3156d8),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: LText(
                                        channel.split(' • ').first,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: unread
                                              ? FontWeight.w800
                                              : FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (metadata.isNotEmpty)
                                      LText(metadata,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xff64748b))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      i == 0
                                          ? Icons.badge_outlined
                                          : Icons.shield_outlined,
                                      size: 13,
                                      color: accent,
                                    ),
                                    const SizedBox(width: 5),
                                    LText(
                                      i == 0
                                          ? 'STAFF CONVERSATION'
                                          : 'MODERATED LEARNING GROUP',
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .7,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  messages.isEmpty ||
                                          messages.last.startsWith('Educator')
                                      ? tr(context, preview)
                                      : preview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: unread
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                    fontWeight: unread
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded,
                              color: accent, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        if (filtered.isEmpty)
          LiquidGlassSurface(
            width: double.infinity,
            child: Column(
              children: [
                const AnimatedIconBadge(
                  icon: Icons.search_off_rounded,
                  color: Color(0xff8055d9),
                  size: 52,
                ),
                const SizedBox(height: 12),
                const LText('No conversations found',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                const LText(
                    'Try another name or switch the conversation filter.'),
                if (query.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => query = ''),
                    child: const LText('Clear search'),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 14, color: Color(0xff0d9488)),
            SizedBox(width: 6),
            Expanded(
              child: LText(
                'Conversations stay within school-managed channels.',
                style: TextStyle(fontSize: 10, color: Color(0xff64748b)),
              ),
            ),
          ],
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
  final scroll = ScrollController();
  bool muted = false;
  List<String> get groupMembers {
    final learner = widget.repo.learner;
    final classOnly = widget.channel.contains('Moderated class group');
    final learners = widget.repo.learners.where((person) => classOnly
        ? person.group == learner.group
        : person.grade == learner.grade);
    return [
      '${MockRepository.teachers[0]} • Educator',
      ...learners.map((person) => '${person.name} • Grade ${person.grade}'),
    ];
  }

  List<String> initialGroupMessages() {
    final names = groupMembers.skip(1).take(2).toList();
    final prompt = widget.channel.contains('Mathematics')
        ? 'I checked my pattern rule with a second example. That helped me spot a small mistake.'
        : widget.channel.contains('Performing arts')
            ? 'I am practising the rhythm slowly first, then putting the parts together.'
            : 'I wrote my main idea in my own words before starting the task.';
    final reply = widget.channel.contains('Performing arts')
        ? 'That sounds helpful. I am going to try the same warm-up before rehearsal.'
        : 'That is a good approach. Checking each step makes the answer clearer.';
    return [
      'Educator • 08:00\nWelcome! Keep this space respectful, ask questions and help each other learn.',
      if (names.isNotEmpty) '${names[0].split(' • ').first} • 08:12\n$prompt',
      if (names.length > 1) '${names[1].split(' • ').first} • 08:16\n$reply',
    ];
  }

  @override
  void initState() {
    super.initState();
    muted = widget.repo.value('mute-${widget.channel}', false) as bool;
    if (!widget.channel.contains('Class teacher') &&
        widget.repo.value('chat-${widget.channel}') == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.repo.value('chat-${widget.channel}') == null) {
          widget.repo.put('chat-${widget.channel}', initialGroupMessages());
        }
      });
    }
  }

  @override
  void dispose() {
    text.dispose();
    scroll.dispose();
    super.dispose();
  }

  void send(String body) {
    if (body.trim().isEmpty) return;
    final key = 'chat-${widget.channel}';
    final list = List<String>.from(widget.repo.value(key, <String>[]));
    if (list.isEmpty && !widget.channel.contains('Class teacher')) {
      list.addAll(initialGroupMessages());
    }
    list.add('You • 10:20\n${body.trim()}\nDelivered locally');
    list.add(
        'Educator • 10:21 • Automated practice reply\nThank you for your message. Review the study guide and bring your questions to our next lesson.');
    widget.repo.put(key, list);
    widget.repo.put('read-${widget.channel}', false);
    widget.repo.notify('New automated practice reply');
    text.clear();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scroll.hasClients) {
        scroll.animateTo(scroll.position.maxScrollExtent,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final group = !widget.channel.contains('Class teacher');
    final members = group ? groupMembers : const <String>[];
    final messages = List<String>.from(
        widget.repo.value('chat-${widget.channel}', <String>[]));
    if (group && messages.isEmpty) messages.addAll(initialGroupMessages());
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        flexibleSpace: const LiquidGlassBar(),
        leading: BackButton(
          onPressed: () {
            widget.repo.put('read-${widget.channel}', true);
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/messages');
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xffe7efff),
                  child: Icon(
                    group ? Icons.groups_rounded : Icons.person_rounded,
                    color: const Color(0xff3156d8),
                  ),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xff16a34a),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  LText(
                    widget.channel.split(' • ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  LText(
                    group
                        ? 'Learning group • ${members.length} members'
                        : 'Class teacher • Staff-managed',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff64748b),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (group)
            IconButton(
              tooltip: tr(context, 'Group information'),
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => GroupChatDetailsScreen(
                    channel: widget.channel,
                    members: members,
                    muted: muted,
                    onMuteChanged: (value) {
                      setState(() => muted = value);
                      widget.repo.put('mute-${widget.channel}', value);
                    },
                  ),
                ),
              ),
            ),
          PopupMenuButton<String>(
            tooltip: tr(context, 'Conversation options'),
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) {
              if (action == 'mute') {
                setState(() => muted = !muted);
                widget.repo.put('mute-${widget.channel}', muted);
              } else {
                widget.repo.put('reported-${widget.channel}', true);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: LText(
                    'Report saved locally only. For real support, contact a responsible adult.',
                  ),
                ));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'mute',
                child:
                    LText(muted ? 'Unmute conversation' : 'Mute conversation'),
              ),
              const PopupMenuItem(
                value: 'report',
                child: LText('Report communication'),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: LiquidGlassSurface(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    borderRadius: BorderRadius.circular(18),
                    blur: 12,
                    tint: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xdff0fbf7)
                        : const Color(0xdc153c38),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AnimatedIconBadge(
                              icon: Icons.shield_rounded,
                              color: Color(0xff0d9488),
                              size: 34,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LText(
                                    'School-managed conversation',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12),
                                  ),
                                  SizedBox(height: 3),
                                  LText(
                                    'Automated practice replies may appear here.',
                                    style:
                                        TextStyle(fontSize: 11, height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                            if (muted)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.notifications_off_rounded,
                                    size: 18),
                              ),
                          ],
                        ),
                        if (group) ...[
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withValues(alpha: .5),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              for (final member in members.take(4)) ...[
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: const Color(0xffe9efff),
                                  child: Text(
                                    member
                                        .split(' • ')
                                        .first
                                        .split(' ')
                                        .take(2)
                                        .map((part) =>
                                            part.isEmpty ? '' : part[0])
                                        .join(),
                                    style: const TextStyle(
                                      color: Color(0xff3156d8),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              const SizedBox(width: 5),
                              Expanded(
                                child: LText(
                                  '${members.length} participants • Educator moderated',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xff64748b),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).push<void>(
                                  MaterialPageRoute(
                                    builder: (_) => GroupChatDetailsScreen(
                                      channel: widget.channel,
                                      members: members,
                                      muted: muted,
                                      onMuteChanged: (value) {
                                        setState(() => muted = value);
                                        widget.repo.put(
                                            'mute-${widget.channel}', value);
                                      },
                                    ),
                                  ),
                                ),
                                child: const LText('View group'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
                    children: [
                      if (group)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: LiquidGlassSurface(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            borderRadius: BorderRadius.circular(16),
                            blur: 8,
                            tint:
                                Theme.of(context).brightness == Brightness.light
                                    ? const Color(0xdffef8e8)
                                    : const Color(0xd944351a),
                            child: const Row(
                              children: [
                                Icon(Icons.push_pin_rounded,
                                    size: 16, color: Color(0xffd18a00)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: LText(
                                    'Pinned • Keep the conversation helpful, respectful and on topic.',
                                    style: TextStyle(fontSize: 11, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? const Color(0xdfffffff)
                                    : const Color(0xc91a2740),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x223156d8)),
                          ),
                          child: const LText(
                            'Thursday, 26 November',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      for (var i = 0; i < messages.length; i++)
                        MessageBubble(
                          key: ValueKey('$i-${messages[i]}'),
                          message: messages[i],
                        ),
                    ],
                  ),
                ),
                LiquidGlassSurface(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  blur: 20,
                  tint: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xeaffffff)
                      : const Color(0xe016233a),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: tr(context, 'Share attachment'),
                            onPressed: () async {
                              final files =
                                  await FilePicker.platform.pickFiles();
                              if (files != null && mounted) {
                                send('Attachment: ${files.names.join(', ')}');
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline_rounded),
                          ),
                          Expanded(
                            child: TextField(
                              controller: text,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              decoration: InputDecoration(
                                hintText:
                                    tr(context, 'Write a thoughtful message…'),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 13),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(22),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: send,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: tr(context, 'Send message'),
                            onPressed: text.text.trim().isEmpty
                                ? null
                                : () => send(text.text),
                            icon: const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded,
                              size: 13, color: Color(0xff64748b)),
                          SizedBox(width: 5),
                          LText(
                            'School-authorised conversations • Stored on this device',
                            style: TextStyle(
                                fontSize: 10, color: Color(0xff64748b)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GroupChatDetailsScreen extends StatefulWidget {
  final String channel;
  final List<String> members;
  final bool muted;
  final ValueChanged<bool> onMuteChanged;

  const GroupChatDetailsScreen({
    super.key,
    required this.channel,
    required this.members,
    required this.muted,
    required this.onMuteChanged,
  });

  @override
  State<GroupChatDetailsScreen> createState() => _GroupChatDetailsScreenState();
}

class _GroupChatDetailsScreenState extends State<GroupChatDetailsScreen> {
  late bool muted = widget.muted;

  @override
  Widget build(BuildContext context) => FeaturePage(
        title: const LText('Group information'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const AnimatedIconBadge(
                    icon: Icons.groups_rounded,
                    color: Color(0xff3156d8),
                    background: Color(0x263156d8),
                    size: 76,
                  ),
                  const SizedBox(height: 14),
                  LText(widget.channel.split(' • ').first,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 5),
                  LText(
                      '${widget.members.length} members • Moderated learning group',
                      style: const TextStyle(color: Color(0xff64748b))),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const LText('Members',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 10),
            for (var i = 0; i < widget.members.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LiquidGlassSurface(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: i == 0
                          ? const Color(0xffddf4ec)
                          : const Color(0xffe9efff),
                      child: Icon(
                        i == 0 ? Icons.school_rounded : Icons.person_rounded,
                        color: i == 0
                            ? const Color(0xff0d9488)
                            : const Color(0xff3156d8),
                      ),
                    ),
                    title: LText(widget.members[i].split(' • ').first),
                    subtitle: LText(widget.members[i].split(' • ').last),
                    trailing: i == 0
                        ? const Icon(Icons.verified_user_rounded,
                            color: Color(0xff0d9488), size: 18)
                        : null,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            const LiquidGlassSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LText('Group guidelines',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 8),
                  LText(
                    'Keep messages kind, relevant to learning and respectful of everyone. This school-managed group is moderated; do not share personal contact details.',
                    style: TextStyle(height: 1.55),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              setState(() => muted = !muted);
              widget.onMuteChanged(muted);
            },
            icon: Icon(muted
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined),
            label: LText(muted ? 'Unmute group' : 'Mute group'),
          ),
        ],
      );
}

class MessageBubble extends StatelessWidget {
  final String message;
  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final sent = message.startsWith('You');
    final parts = message.split('\n');
    final body = parts
        .skip(1)
        .where((s) => s != 'Delivered locally')
        .join('\n')
        .replaceFirst('Demonstration attachment:', 'Attachment:');
    final header = parts.first.split(' • ');
    final educator = !sent;
    final automated =
        parts.first.contains('Automated') || parts.first.contains('Simulated');
    final sender = header.first;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 570),
      child: Column(
        crossAxisAlignment:
            sent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
            child: LText(
              sent
                  ? 'You'
                  : automated
                      ? 'Educator • Automated practice reply'
                      : sender,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xff64748b),
              ),
            ),
          ),
          LiquidGlassSurface(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(sent ? 20 : 6),
              bottomRight: Radius.circular(sent ? 6 : 20),
            ),
            blur: sent ? 8 : 12,
            tint: sent
                ? const Color(0xe63156d8)
                : Theme.of(context).brightness == Brightness.light
                    ? const Color(0xeaffffff)
                    : const Color(0xd91a2740),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (body.startsWith('Attachment:')) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insert_drive_file_rounded,
                        size: 18,
                        color: sent ? Colors.white : const Color(0xff3156d8),
                      ),
                      const SizedBox(width: 7),
                      LText(
                        'Attachment',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: sent ? Colors.white : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  message.startsWith('Educator') ? tr(context, body) : body,
                  style: TextStyle(
                    color: sent
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LText(
                      header.length > 1 ? header[1] : '08:00',
                      style: TextStyle(
                        fontSize: 10,
                        color: sent ? Colors.white70 : const Color(0xff64748b),
                      ),
                    ),
                    if (sent) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.done_all_rounded,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      const LText(
                        'Saved locally',
                        style: TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment:
            sent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (educator) ...[
            CircleAvatar(
              radius: 15,
              backgroundColor:
                  automated ? const Color(0xffdff3ed) : const Color(0xffe9efff),
              child: automated
                  ? const Icon(Icons.auto_awesome_rounded,
                      size: 16, color: Color(0xff0d9488))
                  : Text(
                      sender.trim().isEmpty
                          ? '?'
                          : sender.trim()[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xff3156d8),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: FractionallySizedBox(
              widthFactor: sent ? .9 : .94,
              alignment: sent ? Alignment.centerRight : Alignment.centerLeft,
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}
