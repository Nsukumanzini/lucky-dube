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
  String query = '';
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final teacher = '${MockRepository.teachers[0]} • Class teacher';
    final groups = <(String, IconData, Color)>[
      (
        '${repo.learner.group} • Moderated class group',
        Icons.groups_rounded,
        const Color(0xff4c5fe8)
      ),
      (
        'Mathematics discussion',
        Icons.functions_rounded,
        const Color(0xff0ca995)
      ),
      (
        'Performing arts ensemble',
        Icons.theater_comedy_rounded,
        const Color(0xff9a5de0)
      ),
    ];
    final contacts = <(String, String, IconData, Color)>[
      (teacher, teacher, Icons.school_rounded, const Color(0xff0ca995)),
      for (final id in repo.friends)
        if (repo.classmate(id) case final person?)
          (
            person.name,
            'friend:${person.id}',
            Icons.person_rounded,
            learnerAccents[person.grade % learnerAccents.length]
          ),
    ];
    final destinations = selectedTab == 0
        ? contacts
            .map((contact) => (
                  contact.$1,
                  contact.$2,
                  contact.$3,
                  contact.$4,
                ))
            .toList()
        : groups
            .map((group) =>
                (group.$1.split(' • ').first, group.$1, group.$2, group.$3))
            .toList();
    final visible = destinations
        .where((item) => item.$1.toLowerCase().contains(query))
        .toList();
    final allChannels = [
      ...contacts.map((contact) => contact.$2),
      ...groups.map((group) => group.$1),
    ];
    final unreadCount = allChannels.where((channel) {
      final messages =
          List<String>.from(repo.value('chat-$channel', <String>[]));
      return messages.isNotEmpty && repo.value('read-$channel', false) != true;
    }).length;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final incomingCount = repo.incomingFriendRequests.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: LText(
              'Messages',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.7,
                  ),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () => context.push('/friend-requests'),
            icon: Badge(
              isLabelVisible: incomingCount > 0,
              label: Text('$incomingCount'),
              child: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            ),
            label: LText(compact ? 'Requests' : 'Friend requests'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
              foregroundColor: const Color(0xff4c5fe8),
              backgroundColor: const Color(0x194c5fe8),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xdfffffff)
                : const Color(0xb923344c),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: Colors.white.withValues(alpha: .75)),
          ),
          child: Row(children: [
            _sectionTab('Friends', Icons.people_alt_rounded, contacts.length, 0,
                const Color(0xff4c5fe8)),
            _sectionTab('Group chats', Icons.forum_rounded, groups.length, 1,
                const Color(0xff0ca995)),
          ]),
        ),
        const SizedBox(height: 14),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) => setState(() => query = value.toLowerCase()),
        ),
        const SizedBox(height: 13),
        if (unreadCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(children: [
              const Icon(Icons.mark_chat_unread_rounded,
                  size: 16, color: Color(0xff4c5fe8)),
              const SizedBox(width: 6),
              LText('$unreadCount unread',
                  style: const TextStyle(
                      color: Color(0xff4c5fe8),
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
        for (final destination in visible)
          Builder(builder: (context) {
            final channel = destination.$2;
            final messages =
                List<String>.from(repo.value('chat-$channel', <String>[]));
            final unread = messages.isNotEmpty &&
                repo.value('read-$channel', false) != true;
            final accent = destination.$4;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LiquidGlassSurface(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(22),
                tint: unread
                    ? (Theme.of(context).brightness == Brightness.light
                        ? Color.lerp(Colors.white, accent, .055)
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
                      padding: EdgeInsets.all(compact ? 14 : 17),
                      child: Row(children: [
                        Stack(clipBehavior: Clip.none, children: [
                          AnimatedIconBadge(
                            icon: destination.$3,
                            color: accent,
                            size: 50,
                          ),
                          if (unread)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 13,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: const Color(0xff4c5fe8),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ]),
                        const SizedBox(width: 13),
                        Expanded(
                          child: LText(
                            destination.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight:
                                    unread ? FontWeight.w900 : FontWeight.w700,
                                fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded,
                            color: accent, size: 21),
                      ]),
                    ),
                  ),
                ),
              ),
            );
          }),
        if (visible.isEmpty)
          LiquidGlassSurface(
            width: double.infinity,
            child: Column(children: [
              AnimatedIconBadge(
                icon: selectedTab == 0
                    ? Icons.person_search_rounded
                    : Icons.forum_outlined,
                color: selectedTab == 0
                    ? const Color(0xff9a5de0)
                    : const Color(0xff0ca995),
                size: 52,
              ),
              const SizedBox(height: 12),
              LText(
                query.isNotEmpty
                    ? 'No conversations match your search'
                    : selectedTab == 0
                        ? 'No friends yet'
                        : 'No group chats',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (selectedTab == 0 && query.isEmpty) ...[
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: () => context.push('/friend-requests'),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const LText('Find classmates'),
                ),
              ],
              if (query.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => query = ''),
                  child: const LText('Clear search'),
                ),
            ]),
          ),
      ],
    );
  }

  Widget _sectionTab(
      String label, IconData icon, int count, int index, Color color) {
    final active = selectedTab == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () => setState(() => selectedTab = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
            decoration: BoxDecoration(
              color: active ? color.withValues(alpha: .14) : Colors.transparent,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                  color: active
                      ? color.withValues(alpha: .23)
                      : Colors.transparent),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 7),
              Flexible(
                child: LText(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: active
                            ? color
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ),
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
}

class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  ConsumerState<FriendRequestsScreen> createState() =>
      _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final classmates = repo.learners
        .where((person) =>
            person.group == repo.learner.group && person.id != repo.learner.id)
        .toList();
    final incoming = repo.incomingFriendRequests
        .map(repo.classmate)
        .whereType<Learner>()
        .toList();
    final outgoing = repo.outgoingFriendRequests
        .map(repo.classmate)
        .whereType<Learner>()
        .toList();
    final available = classmates
        .where((person) =>
            !repo.friends.contains(person.id) &&
            !repo.incomingFriendRequests.contains(person.id) &&
            !repo.outgoingFriendRequests.contains(person.id))
        .toList();
    final people = [incoming, outgoing, available][selectedTab];

    return FeaturePage(
      title: const LText('Friend requests'),
      content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LText('Friends in ${repo.learner.group}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        const LText('You can connect with learners in your class.'),
        const SizedBox(height: 18),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _requestTab('Incoming', incoming.length, 0, const Color(0xff4c5fe8),
              Icons.move_to_inbox_rounded),
          _requestTab('Sent', outgoing.length, 1, const Color(0xff0ca995),
              Icons.outbox_rounded),
          _requestTab('Find classmates', available.length, 2,
              const Color(0xff9a5de0), Icons.person_search_rounded),
        ]),
        const SizedBox(height: 16),
        if (people.isEmpty)
          LiquidGlassSurface(
            width: double.infinity,
            child: Column(children: [
              AnimatedIconBadge(
                icon: selectedTab == 0
                    ? Icons.mark_email_read_rounded
                    : selectedTab == 1
                        ? Icons.outbox_rounded
                        : Icons.people_alt_rounded,
                color:
                    learnerAccents[(selectedTab + 1) % learnerAccents.length],
                size: 54,
              ),
              const SizedBox(height: 12),
              LText(
                selectedTab == 0
                    ? 'No new friend requests'
                    : selectedTab == 1
                        ? 'No sent friend requests'
                        : 'No classmates to add right now',
                style: const TextStyle(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        for (final person in people)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LiquidGlassSurface(
              padding: const EdgeInsets.all(15),
              tint: learnerAccents[person.grade % learnerAccents.length]
                  .withValues(alpha: .05),
              child: Column(children: [
                Row(children: [
                  AnimatedIconBadge(
                    icon: Icons.person_rounded,
                    color: learnerAccents[person.grade % learnerAccents.length],
                    size: 46,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LText(person.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  if (selectedTab == 2)
                    FilledButton.tonalIcon(
                      onPressed: () => repo.sendFriendRequest(person.id),
                      icon:
                          const Icon(Icons.person_add_alt_1_rounded, size: 17),
                      label: const LText('Add'),
                    )
                  else if (selectedTab == 1)
                    TextButton.icon(
                      onPressed: () => repo.cancelFriendRequest(person.id),
                      icon: const Icon(Icons.close_rounded, size: 17),
                      label: const LText('Cancel'),
                    ),
                ]),
                if (selectedTab == 0) ...[
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    OutlinedButton(
                      onPressed: () =>
                          repo.respondToFriendRequest(person.id, accept: false),
                      child: const LText('Decline'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () =>
                          repo.respondToFriendRequest(person.id, accept: true),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const LText('Accept'),
                    ),
                  ]),
                ],
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _requestTab(
      String label, int count, int index, Color color, IconData icon) {
    final active = selectedTab == index;
    return ChoiceChip(
      selected: active,
      selectedColor: color.withValues(alpha: .14),
      side: BorderSide(color: color.withValues(alpha: active ? .32 : .16)),
      avatar: Icon(icon, size: 17, color: color),
      label: LText('$label  $count',
          style: TextStyle(
              color: active ? color : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800)),
      onSelected: (_) => setState(() => selectedTab = index),
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
  bool get isFriendChannel => widget.channel.startsWith('friend:');
  String get friendId => widget.channel.substring('friend:'.length);
  String get conversationTitle => isFriendChannel
      ? widget.repo.classmate(friendId)?.name ?? 'Friend'
      : widget.channel.split(' • ').first;
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
        !isFriendChannel &&
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
    if (list.isEmpty &&
        !widget.channel.contains('Class teacher') &&
        !isFriendChannel) {
      list.addAll(initialGroupMessages());
    }
    list.add('You • 10:20\n${body.trim()}\nSaved on this device');
    if (!isFriendChannel) {
      list.add(
          'Learning guide • 10:21 • Suggested reply\nThank you for sharing. Review the study guide and bring your questions to your next lesson.');
      widget.repo.notify('A learning guide response is ready');
    }
    widget.repo.put(key, list);
    widget.repo.put('read-${widget.channel}', true);
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
    final group = !isFriendChannel && !widget.channel.contains('Class teacher');
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
                    conversationTitle,
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
                        : isFriendChannel
                            ? 'Friend'
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LText(
                                    isFriendChannel
                                        ? 'Friend conversation'
                                        : 'School-managed conversation',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12),
                                  ),
                                  SizedBox(height: 3),
                                  LText(
                                    isFriendChannel
                                        ? 'Messages are saved on this device.'
                                        : 'Automated practice replies may appear here.',
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
