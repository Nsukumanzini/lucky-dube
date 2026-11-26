import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../app/localization/app_language.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
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
                        size: 16, color: Color(0xff4c5fe8)),
                    const SizedBox(width: 6),
                    LText('$unreadCount',
                        style: const TextStyle(
                            color: Color(0xff4c5fe8),
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 4),
                    const LText('unread',
                        style: TextStyle(
                            color: Color(0xff4c5fe8),
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
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
                        ? const Color(0xff4c5fe8)
                        : const Color(0xff0ca995),
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
            final accent = learnerAccents[i];
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
                                      color: const Color(0xff4c5fe8),
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
                                  ],
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
                  color: Color(0xff9a5de0),
                  size: 52,
                ),
                const SizedBox(height: 12),
                const LText('No conversations',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                if (query.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => query = ''),
                    child: const LText('Clear search'),
                  ),
              ],
            ),
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
  final recorder = AudioRecorder();
  StreamSubscription<Uint8List>? recordingSubscription;
  Completer<void>? recordingDone;
  BytesBuilder recordingBytes = BytesBuilder(copy: false);
  Timer? recordingTimer;
  int recordingSeconds = 0;
  bool recording = false;
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
      if (names.isNotEmpty)
        '${names[0].split(' • ').first} • 08:21\nAttachment • image\nStudy reference.jpg • 1.2 MB',
      if (names.length > 1)
        '${names[1].split(' • ').first} • 08:26\nAttachment • video\nPractice clip.mp4 • 8.4 MB',
      'Educator • 08:29\nAttachment • file\nTerm 4 learning guide.pdf • 640 KB',
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
    recordingTimer?.cancel();
    recordingSubscription?.cancel();
    unawaited(recorder.dispose());
    super.dispose();
  }

  Future<void> startVoiceRecording() async {
    try {
      if (!await recorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: LText(
                'Microphone permission is needed to record a voice message.'),
          ));
        }
        return;
      }
      recordingBytes = BytesBuilder(copy: false);
      recordingDone = Completer<void>();
      final stream = await recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ));
      recordingSubscription = stream.listen(
        recordingBytes.add,
        onError: (Object error, StackTrace stack) {
          if (recordingDone?.isCompleted == false) {
            recordingDone!.completeError(error, stack);
          }
        },
        onDone: () {
          if (recordingDone?.isCompleted == false) {
            recordingDone!.complete();
          }
        },
      );
      if (!mounted) return;
      setState(() {
        recording = true;
        recordingSeconds = 0;
      });
      recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() => recordingSeconds++);
        if (recordingSeconds >= 30) stopVoiceRecording();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: LText('Voice recording could not start on this device.'),
        ));
      }
    }
  }

  Future<void> stopVoiceRecording({bool discard = false}) async {
    recordingTimer?.cancel();
    recordingTimer = null;
    try {
      if (discard) {
        await recorder.cancel();
        await recordingSubscription?.cancel();
        recordingSubscription = null;
        if (mounted) setState(() => recording = false);
        return;
      }
      await recorder.stop();
      final done = recordingDone;
      if (done != null && !done.isCompleted) {
        await done.future.timeout(const Duration(seconds: 2), onTimeout: () {});
      }
      final pcm = recordingBytes.takeBytes();
      final seconds = recordingSeconds;
      recordingSubscription = null;
      if (mounted) setState(() => recording = false);
      if (pcm.isEmpty) return;
      final wav = _wavBytes(pcm);
      send('Voice • ${seconds.clamp(1, 30)}s • ${base64Encode(wav)}');
    } catch (_) {
      if (mounted) {
        setState(() => recording = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: LText('Voice message could not be saved.'),
        ));
      }
    }
  }

  Uint8List _wavBytes(Uint8List pcm) {
    const sampleRate = 16000;
    const channels = 1;
    const bitsPerSample = 16;
    final header = ByteData(44)
      ..setUint32(0, 0x46464952, Endian.little) // RIFF
      ..setUint32(4, 36 + pcm.length, Endian.little)
      ..setUint32(8, 0x45564157, Endian.little) // WAVE
      ..setUint32(12, 0x20746d66, Endian.little) // fmt
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, channels, Endian.little)
      ..setUint32(24, sampleRate, Endian.little)
      ..setUint32(28, sampleRate * channels * bitsPerSample ~/ 8, Endian.little)
      ..setUint16(32, channels * bitsPerSample ~/ 8, Endian.little)
      ..setUint16(34, bitsPerSample, Endian.little)
      ..setUint32(36, 0x61746164, Endian.little) // data
      ..setUint32(40, pcm.length, Endian.little);
    return Uint8List.fromList([...header.buffer.asUint8List(), ...pcm]);
  }

  Future<void> attachFiles() async {
    final selection = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: false,
    );
    if (selection == null || !mounted) return;
    final tooLargeVideos = selection.files.where((file) {
      final extension = (file.extension ?? '').toLowerCase();
      return const {'mp4', 'mov', 'm4v', 'webm', 'avi', 'mkv'}
              .contains(extension) &&
          file.size >= 20 * 1024 * 1024;
    }).toList();
    if (tooLargeVideos.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: LText('Videos must be smaller than 20 MB.'),
      ));
    }
    final accepted = selection.files
        .where((file) => !tooLargeVideos.contains(file))
        .toList();
    for (final file in accepted) {
      final extension = (file.extension ?? '').toLowerCase();
      final type =
          const {'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(extension)
              ? 'image'
              : const {'mp4', 'mov', 'm4v', 'webm', 'avi', 'mkv'}
                      .contains(extension)
                  ? 'video'
                  : 'file';
      send('Attachment • $type\n${file.name} • ${_formatFileSize(file.size)}');
    }
  }

  String _formatFileSize(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).ceil()} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  void send(String body) {
    if (body.trim().isEmpty) return;
    final key = 'chat-${widget.channel}';
    final list = List<String>.from(widget.repo.value(key, <String>[]));
    if (list.isEmpty && !widget.channel.contains('Class teacher')) {
      list.addAll(initialGroupMessages());
    }
    list.add('You • 10:20\n${body.trim()}\nSaved on this device');
    list.add(
        'Learning guide • 10:21 • Suggested reply\nThank you for sharing. Review the study guide and bring your questions to your next lesson.');
    widget.repo.put(key, list);
    widget.repo.put('read-${widget.channel}', false);
    widget.repo.notify('A learning guide response is ready');
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
                    color: const Color(0xff4c5fe8),
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
                    'This report remains on this device and has not been sent. For real support, speak directly to a responsible adult.',
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
                              color: Color(0xff0ca995),
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
                                      color: Color(0xff4c5fe8),
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
                      if (recording) ...[
                        Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                  color: Color(0xffdc2626),
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            LText(
                                'Recording voice message • 00:${recordingSeconds.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    color: Color(0xffdc2626),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () =>
                                  stopVoiceRecording(discard: true),
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 17),
                              label: const LText('Discard'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: tr(context, 'Share attachment'),
                            onPressed: recording ? null : attachFiles,
                            icon: const Icon(Icons.add_circle_outline_rounded),
                          ),
                          Expanded(
                            child: TextField(
                              controller: text,
                              enabled: !recording,
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
                              onSubmitted: recording ? null : send,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: tr(
                                context,
                                recording
                                    ? 'Stop and send voice message'
                                    : 'Record voice message'),
                            onPressed: recording
                                ? stopVoiceRecording
                                : startVoiceRecording,
                            color: recording
                                ? const Color(0xffdc2626)
                                : const Color(0xff0ca995),
                            icon: Icon(recording
                                ? Icons.stop_circle_rounded
                                : Icons.mic_rounded),
                          ),
                          IconButton.filled(
                            tooltip: tr(context, 'Send message'),
                            onPressed: recording || text.text.trim().isEmpty
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
                    color: Color(0xff4c5fe8),
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
                            ? const Color(0xff0ca995)
                            : const Color(0xff4c5fe8),
                      ),
                    ),
                    title: LText(widget.members[i].split(' • ').first),
                    subtitle: LText(widget.members[i].split(' • ').last),
                    trailing: i == 0
                        ? const Icon(Icons.verified_user_rounded,
                            color: Color(0xff0ca995), size: 18)
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
    final body =
        parts.skip(1).where((s) => s != 'Saved on this device').join('\n');
    final header = parts.first.split(' • ');
    final educator = !sent;
    final automated = parts.first.contains('Suggested reply');
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
                      ? 'Learning guide • Suggested reply'
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
                if (body.startsWith('Voice • '))
                  VoiceMessagePlayer(
                    encodedAudio: body.split(' • ').skip(2).join(' • '),
                    durationLabel: body.split(' • ').elementAtOrNull(1) ?? '',
                    sent: sent,
                  )
                else if (body.startsWith('Attachment •'))
                  ChatAttachmentCard(body: body, sent: sent)
                else if (body.startsWith('Attachment:'))
                  ChatAttachmentCard(body: body, sent: sent)
                else
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
                        'On this device',
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
                      size: 16, color: Color(0xff0ca995))
                  : Text(
                      sender.trim().isEmpty
                          ? '?'
                          : sender.trim()[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xff4c5fe8),
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

class ChatAttachmentCard extends StatelessWidget {
  final String body;
  final bool sent;
  const ChatAttachmentCard({super.key, required this.body, required this.sent});

  @override
  Widget build(BuildContext context) {
    final lines = body.split('\n');
    final header = lines.first.split(' • ');
    final type = header.length > 1 ? header[1].toLowerCase() : 'file';
    final detail = lines.length > 1
        ? lines.skip(1).join(' ')
        : body.replaceFirst('Attachment:', '').trim();
    final icon = type == 'image'
        ? Icons.image_rounded
        : type == 'video'
            ? Icons.video_file_rounded
            : Icons.insert_drive_file_rounded;
    return Container(
      constraints: const BoxConstraints(minWidth: 190, maxWidth: 290),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: sent
            ? Colors.white.withValues(alpha: .13)
            : const Color(0xffedf3ff),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: sent ? Colors.white24 : const Color(0x223156d8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: sent ? Colors.white.withValues(alpha: .15) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: sent ? Colors.white : const Color(0xff4c5fe8), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LText(
                    type == 'file'
                        ? 'File'
                        : type[0].toUpperCase() + type.substring(1),
                    style: TextStyle(
                      color: sent ? Colors.white : const Color(0xff4c5fe8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: sent ? Colors.white : const Color(0xff27364d),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VoiceMessagePlayer extends StatefulWidget {
  final String encodedAudio;
  final String durationLabel;
  final bool sent;
  const VoiceMessagePlayer({
    super.key,
    required this.encodedAudio,
    required this.durationLabel,
    required this.sent,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  late final AudioPlayer player = AudioPlayer();
  StreamSubscription<PlayerState>? stateSubscription;
  StreamSubscription<Duration>? durationSubscription;
  StreamSubscription<Duration>? positionSubscription;
  StreamSubscription<void>? completionSubscription;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool playing = false;

  @override
  void initState() {
    super.initState();
    stateSubscription = player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => playing = state == PlayerState.playing);
    });
    durationSubscription = player.onDurationChanged.listen((value) {
      if (mounted) setState(() => duration = value);
    });
    positionSubscription = player.onPositionChanged.listen((value) {
      if (mounted) setState(() => position = value);
    });
    completionSubscription = player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => position = Duration.zero);
    });
  }

  @override
  void dispose() {
    stateSubscription?.cancel();
    durationSubscription?.cancel();
    positionSubscription?.cancel();
    completionSubscription?.cancel();
    unawaited(player.dispose());
    super.dispose();
  }

  Future<void> toggle() async {
    try {
      if (playing) {
        await player.pause();
      } else {
        final bytes = base64Decode(widget.encodedAudio);
        if (position >= duration && duration > Duration.zero) {
          await player.seek(Duration.zero);
        }
        await player.play(BytesSource(bytes, mimeType: 'audio/wav'));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: LText('This voice message could not be played.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.sent ? Colors.white : const Color(0xff26364f);
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 210, maxWidth: 300),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: toggle,
            style: IconButton.styleFrom(
              backgroundColor: widget.sent
                  ? Colors.white.withValues(alpha: .2)
                  : const Color(0xffdce8ff),
              foregroundColor:
                  widget.sent ? Colors.white : const Color(0xff4c5fe8),
            ),
            icon:
                Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LText('Voice message',
                    style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    color: widget.sent ? Colors.white : const Color(0xff4c5fe8),
                    backgroundColor:
                        widget.sent ? Colors.white24 : const Color(0x223156d8),
                  ),
                ),
                const SizedBox(height: 4),
                LText(widget.durationLabel,
                    style: TextStyle(
                        color: widget.sent
                            ? Colors.white70
                            : const Color(0xff64748b),
                        fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
