// Retain compatibility with Flutter versions before the Material package split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'localization/app_language.dart';

import '../main.dart';
import '../features/screens.dart';
import '../features/learning_screens.dart';

class LuckyApp extends ConsumerStatefulWidget {
  const LuckyApp({super.key});
  @override
  ConsumerState<LuckyApp> createState() => _LuckyAppState();
}

class _LuckyAppState extends ConsumerState<LuckyApp> {
  @override
  void initState() {
    super.initState();
    GoRouter.optionURLReflectsImperativeAPIs = true;
  }

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
      locale: Locale(repo.language, 'ZA'),
      supportedLocales: const [Locale('en', 'ZA'), Locale('zu', 'ZA')],
      localizationsDelegates: const [
        AppLanguage.delegate,
        // Compatibility with Flutter SDKs before the UI package split.
        // ignore: deprecated_member_use
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        // ignore: deprecated_member_use
        GlobalCupertinoLocalizations.delegate
      ],
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: ThemeMode.values[(repo.state['theme'] as int?) ?? 1],
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
        ).copyWith(
            primary: const Color(0xff2563eb),
            onPrimary: Colors.white,
            surface:
                b == Brightness.light ? Colors.white : const Color(0xff18253a),
            onSurface: b == Brightness.light
                ? const Color(0xff22334b)
                : const Color(0xffedf4ff),
            primaryContainer: b == Brightness.light
                ? const Color(0xffeaf3ff)
                : const Color(0xff214675)),
        scaffoldBackgroundColor: b == Brightness.light
            ? const Color(0xfff7faff)
            : const Color(0xff0f172a),
        cardTheme: CardThemeData(
          elevation: b == Brightness.light ? 1 : 0,
          color: b == Brightness.light ? Colors.white : const Color(0xff18253a),
          shadowColor: const Color(0x120f172a),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: b == Brightness.light
                  ? const Color(0xffe2e8f0)
                  : Colors.white12,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: b == Brightness.light
              ? const Color(0xfff0f5fb)
              : const Color(0xff22334b),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        appBarTheme: AppBarTheme(
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor:
                b == Brightness.light ? Colors.white : const Color(0xff18253a)),
        navigationRailTheme: NavigationRailThemeData(
            backgroundColor:
                b == Brightness.light ? Colors.white : const Color(0xff18253a),
            indicatorColor: const Color(0xffdcecff)),
        navigationBarTheme: NavigationBarThemeData(
            backgroundColor:
                b == Brightness.light ? Colors.white : const Color(0xff18253a),
            elevation: 2,
            surfaceTintColor: Colors.transparent,
            indicatorColor: const Color(0xffdcecff),
            indicatorShape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            labelTextStyle: WidgetStateProperty.resolveWith((states) =>
                TextStyle(
                    fontSize: 11,
                    fontWeight: states.contains(WidgetState.selected)
                        ? FontWeight.w700
                        : FontWeight.w500))),
      );
}
