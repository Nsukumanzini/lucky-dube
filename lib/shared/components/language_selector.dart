// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import '../../app/localization/app_language.dart';

class LanguageSelector extends ConsumerWidget {
  final bool compact;
  const LanguageSelector({super.key, this.compact = false});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    return PopupMenuButton<String>(
        tooltip: 'Language / Ulimi',
        initialValue: repo.language,
        onSelected: repo.setLanguage,
        itemBuilder: (_) => ['en', 'zu']
            .map((code) => PopupMenuItem(
                value: code,
                child: Row(children: [
                  Expanded(child: Text(code == 'zu' ? 'isiZulu' : 'English')),
                  if (repo.language == code) const Icon(Icons.check, size: 18)
                ])))
            .toList(),
        child: Padding(
            padding: EdgeInsets.all(compact ? 14 : 12),
            child: compact
                ? const Icon(Icons.translate, size: 20)
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.translate, size: 19),
                    const SizedBox(width: 6),
                    LText(repo.language == 'zu' ? 'isiZulu' : 'English',
                        style: const TextStyle(fontSize: 12))
                  ])));
  }
}
