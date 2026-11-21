// Retain compatibility with Flutter versions before the Material package split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/repository.dart';
import 'app/app.dart';

final repositoryProvider = ChangeNotifierProvider<MockRepository>(
  (ref) => throw UnimplementedError('Override at startup'),
);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final repo = MockRepository(prefs);
  if (repo.state['remember'] != true) repo.state.remove('session');
  runApp(
    ProviderScope(
      overrides: [repositoryProvider.overrideWith((ref) => repo)],
      child: const LuckyApp(),
    ),
  );
}
