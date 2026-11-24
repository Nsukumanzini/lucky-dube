import '../app/localization/app_language.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../main.dart';
import '../data/repository.dart';
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
      Icons.person_outline_rounded,
      Icons.groups_outlined,
      Icons.functions_rounded,
      Icons.theater_comedy_outlined
    ];
    final filtered = channels.asMap().entries.where((e) =>
        e.value.toLowerCase().contains(query) &&
        (filter == 'All' ||
            filter == 'Staff' && e.key == 0 ||
            filter == 'Groups' && e.key > 0));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LText('Messages',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const LText(
          'Your learning circle. Helpful conversations, in the right place.'),
      const SizedBox(height: 24),
      FrostedSurface(
          tint: Theme.of(context).brightness == Brightness.light
              ? const Color(0xe8eaf8f3)
              : const Color(0xe8193b36),
          padding: const EdgeInsets.all(22),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const AnimatedIconBadge(
                icon: Icons.verified_user_outlined,
                color: Color(0xff0c6c5d),
                background: Color(0xffc8eadf),
                size: 48),
            const SizedBox(width: 16),
            const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  LText('Connected, with care',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  SizedBox(height: 6),
                  LText(
                      'Staff-managed channels and moderated groups. Educator replies here are automated practice responses.',
                      style: TextStyle(height: 1.5))
                ]))
          ])),
      const SizedBox(height: 24),
      TextField(
          decoration: InputDecoration(
              hintText: tr(context, 'Search conversations'),
              prefixIcon: Icon(Icons.search_rounded)),
          onChanged: (value) => setState(() => query = value.toLowerCase())),
      const SizedBox(height: 14),
      Wrap(
          spacing: 8,
          children: ['All', 'Staff', 'Groups']
              .map((name) => ChoiceChip(
                  label: LText(name),
                  selected: filter == name,
                  onSelected: (_) => setState(() => filter = name)))
              .toList()),
      const SizedBox(height: 20),
      if (filtered.isEmpty)
        const Padding(
            padding: EdgeInsets.all(32),
            child: LText(
                'No conversations match your search. Try a different name or group.')),
      for (final entry in filtered)
        Builder(builder: (context) {
          final i = entry.key, channel = entry.value;
          final messages =
              List<String>.from(repo.value('chat-$channel', <String>[]));
          final unread =
              messages.isNotEmpty && repo.value('read-$channel', false) != true;
          final preview = messages.isEmpty
              ? hints[i]
              : messages.last
                  .split('\n')
                  .skip(1)
                  .where((s) => s != 'Delivered locally')
                  .join(' ');
          final accent = learnerAccents[i];
          return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LiquidGlassSurface(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(22),
                  child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                          onTap: () {
                            repo.put('read-$channel', true);
                            context.push(
                                '/conversation/${Uri.encodeComponent(channel)}');
                          },
                          child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedIconBadge(
                                        icon: icons[i],
                                        color: accent,
                                        size: 50),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Row(children: [
                                            Expanded(
                                                child: LText(
                                                    channel.split(' • ').first,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 16))),
                                            if (unread)
                                              Container(
                                                  width: 9,
                                                  height: 9,
                                                  decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      shape: BoxShape.circle))
                                          ]),
                                          const SizedBox(height: 5),
                                          LText(
                                              i == 0
                                                  ? 'CLASS TEACHER'
                                                  : 'MODERATED GROUP',
                                              style: TextStyle(
                                                  color: accent,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 1)),
                                          const SizedBox(height: 9),
                                          Text(
                                              messages.isEmpty ||
                                                      messages.last.startsWith(
                                                          'Educator')
                                                  ? tr(context, preview)
                                                  : preview,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  height: 1.5)),
                                          const SizedBox(height: 8),
                                          LText(
                                              messages.isEmpty
                                                  ? 'Start a conversation'
                                                  : 'Latest activity',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xff64748b))),
                                        ])),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right_rounded,
                                        color: Color(0xff94a3b8))
                                  ]))))));
        })
    ]);
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
  @override
  void initState() {
    super.initState();
    muted = widget.repo.value('mute-${widget.channel}', false) as bool;
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
    final messages = List<String>.from(
        widget.repo.value('chat-${widget.channel}', <String>[]));
    return Scaffold(
      appBar: AppBar(
          flexibleSpace: const LiquidGlassBar(),
          leading: BackButton(onPressed: () {
            widget.repo.put('read-${widget.channel}', true);
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/messages');
            }
          }),
          title: Row(children: [
            CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                    group ? Icons.groups_outlined : Icons.person_outline,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  LText(widget.channel.split(' • ').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  LText(
                      group
                          ? 'Moderated learning group'
                          : 'Class teacher • Staff-managed',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xff64748b)))
                ]))
          ]),
          actions: [
            PopupMenuButton<String>(
                tooltip: tr(context, 'Conversation options'),
                onSelected: (action) {
                  if (action == 'mute') {
                    setState(() => muted = !muted);
                    widget.repo.put('mute-${widget.channel}', muted);
                  } else {
                    widget.repo.put('reported-${widget.channel}', true);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: LText(
                            'Report saved locally only. For real support, contact a responsible adult.')));
                  }
                },
                itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'mute',
                          child: LText(muted
                              ? 'Unmute conversation'
                              : 'Mute conversation')),
                      const PopupMenuItem(
                          value: 'report', child: LText('Report communication'))
                    ])
          ]),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Column(children: [
                    LiquidGlassSurface(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        borderRadius: BorderRadius.zero,
                        blur: 14,
                        tint: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xb5eaf8f3)
                            : const Color(0xbc153c38),
                        child: Row(children: [
                          const Icon(Icons.shield_outlined,
                              size: 17, color: Color(0xff0d9488)),
                          const SizedBox(width: 10),
                          const Expanded(
                              child: LText(
                                  'Practice channel • Automated replies',
                                  style: TextStyle(fontSize: 12))),
                          if (muted)
                            const Icon(Icons.notifications_off_outlined,
                                size: 17)
                        ])),
                    Expanded(
                        child: ListView(
                            controller: scroll,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 24),
                            children: [
                          const Center(
                              child: Chip(
                                  label: LText('26 November 2026',
                                      style: TextStyle(fontSize: 11)))),
                          const SizedBox(height: 22),
                          const MessageBubble(
                              message:
                                  'Educator • 08:00\nWelcome! Keep this space respectful, ask questions and help each other learn.'),
                          for (var i = 0; i < messages.length; i++)
                            MessageBubble(
                                key: ValueKey('$i-${messages[i]}'),
                                message: messages[i]),
                        ])),
                    LiquidGlassSurface(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(22)),
                        blur: 20,
                        tint: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xcaffffff)
                            : const Color(0xce16233a),
                        child: Column(children: [
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                    tooltip: tr(context, 'Share attachment'),
                                    onPressed: () async {
                                      final files =
                                          await FilePicker.platform.pickFiles();
                                      if (files != null && mounted) {
                                        send(
                                            'Attachment: ${files.names.join(', ')}');
                                      }
                                    },
                                    icon: const Icon(
                                        Icons.add_circle_outline_rounded)),
                                Expanded(
                                    child: TextField(
                                        controller: text,
                                        minLines: 1,
                                        maxLines: 4,
                                        textInputAction: TextInputAction.send,
                                        decoration: InputDecoration(
                                            hintText: tr(context,
                                                'Write a thoughtful message…'),
                                            labelText: tr(context,
                                                'Reply to this channel')),
                                        onSubmitted: send)),
                                const SizedBox(width: 10),
                                IconButton.filled(
                                    tooltip: tr(context, 'Send message'),
                                    onPressed: () => send(text.text),
                                    icon: const Icon(Icons.send_rounded)),
                              ]),
                          const SizedBox(height: 10),
                          const LText(
                              'School-authorised conversations • Stored on this device',
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xff64748b)))
                        ]))
                  ])))),
    );
  }
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
    return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Align(
            alignment: sent ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 570),
                child: FractionallySizedBox(
                    widthFactor: .92,
                    alignment:
                        sent ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                        crossAxisAlignment: sent
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 6, left: 4, right: 4),
                              child: LText(
                                  sent
                                      ? 'You'
                                      : (parts.first.contains('Simulated') ||
                                              parts.first.contains('Automated'))
                                          ? 'Educator • Automated practice reply'
                                          : 'Educator',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff64748b)))),
                          LiquidGlassSurface(
                              padding: const EdgeInsets.all(17),
                              borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(sent ? 20 : 5),
                                  bottomRight: Radius.circular(sent ? 5 : 20)),
                              blur: 16,
                              tint: sent
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: .82)
                                  : null,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (body.startsWith('Attachment:'))
                                      Icon(Icons.insert_drive_file_outlined,
                                          color: sent
                                              ? Colors.white
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                    Text(
                                        message.startsWith('Educator')
                                            ? tr(context, body)
                                            : body,
                                        style: TextStyle(
                                            color: sent
                                                ? Colors.white
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                            height: 1.6)),
                                    const SizedBox(height: 8),
                                    Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          LText(
                                              parts.first.split(' • ').length >
                                                      1
                                                  ? parts.first.split(' • ')[1]
                                                  : '08:00',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: sent
                                                      ? Colors.white70
                                                      : const Color(
                                                          0xff64748b))),
                                          if (sent) ...[
                                            const SizedBox(width: 6),
                                            const Icon(Icons.done_all,
                                                size: 13,
                                                color: Colors.white70),
                                            const SizedBox(width: 4),
                                            const LText('Saved locally',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white70))
                                          ]
                                        ])
                                  ])),
                        ])))));
  }
}
