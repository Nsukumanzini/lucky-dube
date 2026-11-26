// Retain compatibility with Flutter versions before the Material package split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'localization/app_language.dart';

import '../main.dart';
import '../features/screens.dart';
import '../features/communication_screens.dart';
import '../features/learning_screens.dart';
import '../features/splash/splash_screen.dart';
import '../shared/components/premium_surface.dart';

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
    initialLocation: '/splash',
    redirect: (context, state) =>
        ref.read(repositoryProvider).state['session'] == null &&
                (state.uri.path.startsWith('/subject/') ||
                    state.uri.path.startsWith('/learning/') ||
                    state.uri.path.startsWith('/conversation/') ||
                    state.uri.path == '/friend-requests')
            ? '/home'
            : null,
    routes: [
      GoRoute(
          path: '/splash',
          pageBuilder: (c, s) => _screenPage(s, const SplashScreen())),
      GoRoute(
          path: '/friend-requests',
          pageBuilder: (c, s) => _screenPage(s, const FriendRequestsScreen())),
      GoRoute(
          path: '/subject/:name',
          pageBuilder: (c, s) => _screenPage(
              s, SubjectScreen(subject: s.pathParameters['name']!))),
      GoRoute(
          path: '/learning/:id',
          pageBuilder: (c, s) =>
              _screenPage(s, LearningRoute(id: s.pathParameters['id']!))),
      GoRoute(
          path: '/conversation/:channel',
          pageBuilder: (c, s) => _screenPage(
              s, ConversationRoute(channel: s.pathParameters['channel']!))),
      GoRoute(
        path: '/:page',
        pageBuilder: (c, s) => _screenPage(
            s,
            Portal(
                key: ValueKey(s.pathParameters['page']),
                page: s.pathParameters['page']!)),
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
      builder: (context, child) => BackdropGroup(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: LiquidGlassBackdrop(
                dark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
            LearnerScrollArt(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    (repo.state['textScale'] as num?)?.toDouble() ?? 1,
                  ),
                ),
                child: child!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  CustomTransitionPage<void> _screenPage(GoRouterState state, Widget child) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final reduce = MediaQuery.disableAnimationsOf(context);
          if (reduce) return child;
          final eased = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: eased,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(.035, 0),
                end: Offset.zero,
              ).animate(eased),
              child: child,
            ),
          );
        },
      );

  ThemeData theme(Brightness b) => ThemeData(
        useMaterial3: true,
        brightness: b,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff4c5fe8),
          brightness: b,
        ).copyWith(
            primary: const Color(0xff4c5fe8),
            secondary: const Color(0xff0ca995),
            tertiary: const Color(0xfff08756),
            error: const Color(0xffdc4268),
            primaryFixed: const Color(0xffe9eaff),
            secondaryFixed: const Color(0xffdcf8f1),
            tertiaryFixed: const Color(0xffffeed6),
            onPrimary: Colors.white,
            surface: b == Brightness.light
                ? const Color(0xfffdfdff)
                : const Color(0xff18253a),
            onSurface: b == Brightness.light
                ? const Color(0xff22334b)
                : const Color(0xffedf4ff),
            primaryContainer: b == Brightness.light
                ? const Color(0xffe9efff)
                : const Color(0xff214675)),
        // Give otherwise unstyled Material icons a deliberate accent so the
        // iconography remains colourful and consistent throughout the app.
        iconTheme: const IconThemeData(color: Color(0xff4c5fe8)),
        primaryIconTheme: const IconThemeData(color: Color(0xff4c5fe8)),
        scaffoldBackgroundColor: Colors.transparent,
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xff0ca995),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(foregroundColor: const Color(0xff0ca995)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: b == Brightness.light
              ? const Color(0xcfffffff)
              : const Color(0xc91a2740),
          shadowColor: const Color(0x24314b79),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: b == Brightness.light
                  ? const Color(0xffe5eaf3)
                  : Colors.white12,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          prefixIconColor: const Color(0xff4c5fe8),
          suffixIconColor: const Color(0xff0ca995),
          filled: true,
          fillColor: b == Brightness.light
              ? const Color(0xc5f9fbff)
              : const Color(0xb923344c),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
                color: b == Brightness.light
                    ? const Color(0xbfffffff)
                    : Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xff4c5fe8), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: b == Brightness.light
              ? const Color(0xc8ffffff)
              : const Color(0xb923344c),
          selectedColor: b == Brightness.light
              ? const Color(0xc9e3ebff)
              : const Color(0xc9214675),
          side: BorderSide(
            color: b == Brightness.light
                ? Colors.white.withValues(alpha: .9)
                : Colors.white.withValues(alpha: .12),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          labelStyle: TextStyle(
            color: b == Brightness.light
                ? const Color(0xff20304a)
                : const Color(0xffedf4ff),
            fontWeight: FontWeight.w600,
          ),
        ),
        tabBarTheme: TabBarThemeData(
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor:
              b == Brightness.light ? const Color(0xff58667f) : Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          overlayColor: WidgetStateProperty.all(const Color(0x124c5fe8)),
          indicatorSize: TabBarIndicatorSize.tab,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: b == Brightness.light
              ? const Color(0xe8ffffff)
              : const Color(0xe51a2740),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: b == Brightness.light ? Colors.white : Colors.white24,
            ),
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: b == Brightness.light
              ? const Color(0xe8ffffff)
              : const Color(0xe51a2740),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: b == Brightness.light
              ? const Color(0xe8293f62)
              : const Color(0xe8e7efff),
          contentTextStyle: TextStyle(
            color:
                b == Brightness.light ? Colors.white : const Color(0xff18253a),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        appBarTheme: AppBarTheme(
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            foregroundColor: b == Brightness.light
                ? const Color(0xff20304a)
                : const Color(0xffedf4ff),
            iconTheme: const IconThemeData(color: Color(0xff0ca995))),
        navigationRailTheme: NavigationRailThemeData(
            backgroundColor: Colors.transparent,
            selectedIconTheme: const IconThemeData(color: Color(0xff4c5fe8)),
            unselectedIconTheme: const IconThemeData(color: Color(0xff0ca995)),
            indicatorColor: b == Brightness.light
                ? const Color(0xffe1eaff)
                : const Color(0xff214675)),
        navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            elevation: 2,
            surfaceTintColor: Colors.transparent,
            iconTheme: WidgetStateProperty.resolveWith((states) =>
                IconThemeData(
                    color: states.contains(WidgetState.selected)
                        ? const Color(0xff4c5fe8)
                        : const Color(0xff0ca995))),
            indicatorColor: b == Brightness.light
                ? const Color(0xffe1eaff)
                : const Color(0xff214675),
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
