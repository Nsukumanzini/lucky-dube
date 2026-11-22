// Retain compatibility with Flutter versions before the Material package split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../main.dart';
import '../features/screens.dart';
import '../features/learning_screens.dart';

class LuckyApp extends ConsumerStatefulWidget {
  const LuckyApp({super.key});
  @override
  ConsumerState<LuckyApp> createState() => _LuckyAppState();
}

class _LuckyAppState extends ConsumerState<LuckyApp> {
  late final router = GoRouter(
    initialLocation: '/home',
    redirect: (context, state) =>
        ref.read(repositoryProvider).state['session'] == null &&
                (state.uri.path.startsWith('/subject/') ||
                    state.uri.path.startsWith('/learning/') ||
                    state.uri.path.startsWith('/conversation/'))
            ? '/home'
            : null,
    routes: [
      GoRoute(
          path: '/subject/:name',
          builder: (c, s) => SubjectScreen(subject: s.pathParameters['name']!)),
      GoRoute(
          path: '/learning/:id',
          builder: (c, s) => LearningRoute(id: s.pathParameters['id']!)),
      GoRoute(
          path: '/conversation/:channel',
          builder: (c, s) =>
              ConversationRoute(channel: s.pathParameters['channel']!)),
      GoRoute(
        path: '/:page',
        builder: (c, s) => Portal(page: s.pathParameters['page']!),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    return MaterialApp.router(
      title: 'Lucky Dube',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: ThemeMode.values[(repo.state['theme'] as int?) ?? 0],
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            (repo.state['textScale'] as num?)?.toDouble() ?? 1,
          ),
        ),
        child: child!,
      ),
    );
  }

  ThemeData theme(Brightness b) => ThemeData(
        useMaterial3: true,
        brightness: b,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2563eb),
          brightness: b,
        ),
        scaffoldBackgroundColor: b == Brightness.light
            ? const Color(0xfff8fafc)
            : const Color(0xff0f172a),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: b == Brightness.light
                  ? const Color(0xffe2e8f0)
                  : Colors.white12,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        appBarTheme: const AppBarTheme(centerTitle: false),
      );
}
