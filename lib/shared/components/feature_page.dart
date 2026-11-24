import '../../app/localization/app_language.dart';
// Keep compatibility with Flutter versions before the Material package split.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'premium_surface.dart';

/// A full route with responsive reading width and keyboard-safe action area.
class FeaturePage extends StatelessWidget {
  final Widget title, content;
  final List<Widget> actions;
  final bool scrollable;
  const FeaturePage(
      {super.key,
      required this.title,
      required this.content,
      this.actions = const [],
      this.scrollable = true});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            toolbarHeight: MediaQuery.sizeOf(context).width < 600 ? 60 : 68,
            flexibleSpace: const LiquidGlassBar(),
            title: title,
            leading: BackButton(onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/home');
              }
            })),
        body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.light
                    ? const [
                        Color(0x30ffffff),
                        Color(0x19e6efff),
                        Color(0x1bdbf5ee)
                      ]
                    : const [Color(0x22111d31), Color(0x18254156)],
              ),
            ),
            child: SafeArea(
                child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width >= 1200
                                ? 1200
                                : 960),
                        child: PageReveal(
                            child: Padding(
                                padding: EdgeInsets.all(_pageGutter(context)),
                                child: scrollable
                                    ? SingleChildScrollView(
                                        child: SizedBox(
                                            width: double.infinity,
                                            child: content))
                                    : content)))))),
        bottomNavigationBar: actions.isEmpty
            ? null
            : SafeArea(
                top: false,
                child: LiquidGlassSurface(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    borderRadius: BorderRadius.zero,
                    blur: 20,
                    child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 12,
                        runSpacing: 8,
                        children: actions)),
              ),
      );

  double _pageGutter(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return 16;
    if (width < 1000) return 24;
    return 32;
  }
}

class EntryScreen extends StatefulWidget {
  final String title, hint;
  const EntryScreen({super.key, required this.title, required this.hint});
  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final controller = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FeaturePage(
          title: LText(widget.title),
          content: Form(
              key: form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LText(widget.title,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    const LText(
                        'Your information is saved on this device only.'),
                    const SizedBox(height: 28),
                    TextFormField(
                        controller: controller,
                        maxLines: 6,
                        autofocus: true,
                        decoration: InputDecoration(
                            labelText: widget.hint, alignLabelWithHint: true),
                        validator: (value) => value == null ||
                                value.trim().isEmpty
                            ? tr(context, 'Please enter details before saving.')
                            : null),
                  ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const LText('Cancel')),
            FilledButton(
                onPressed: () {
                  if (form.currentState!.validate()) {
                    Navigator.pop(context, controller.text.trim());
                  }
                },
                child: const LText('Save'))
          ]);
}
