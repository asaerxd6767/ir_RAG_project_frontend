import 'package:material_ui/material_ui.dart';

import 'core/api_config.dart';
import 'data/services/rag_api_client.dart';
import 'state/ask_controller.dart';
import 'theme/app_theme.dart';

import 'state/changelog_controller.dart';
import 'state/evaluation_controller.dart';
import 'state/library_controller.dart';
import 'ui/friendly_error_view.dart';
import 'ui/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails details) =>
      FriendlyErrorView(details: details);

  final config = ApiConfig.from(kDefaultApiBaseUrl);
  final controller = AskController(
    config: config,
    client: RagApiClient(config: config),
  );

  runApp(IrRagApp(controller: controller));
}

class IrRagApp extends StatefulWidget {
  const IrRagApp({super.key, required this.controller});

  final AskController controller;

  @override
  State<IrRagApp> createState() => _IrRagAppState();
}

class _IrRagAppState extends State<IrRagApp> {
  ThemeMode _themeMode = ThemeMode.system;
  final ChangelogController _changelog = ChangelogController();
  // The dialog must use a context below MaterialApp, where a Navigator exists.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final LibraryController _library;
  late final EvaluationController _evaluation;
  bool _changelogShown = false;

  @override
  void initState() {
    super.initState();
    _library = LibraryController(client: widget.controller.client);
    _evaluation = EvaluationController(client: widget.controller.client);
    widget.controller.initialize();
    _changelog.addListener(_showChangelogIfNeeded);
    _changelog.initialize();
    _showChangelogIfNeeded(); // No-op until the controller reports changes.
  }

  @override
  void dispose() {
    _changelog.removeListener(_showChangelogIfNeeded);
    _library.dispose();
    _evaluation.dispose();
    super.dispose();
  }

  void _showChangelogIfNeeded() {
    final changes = _changelog.changes;
    if (changes == null || changes.isEmpty || _changelogShown) return;
    _changelogShown = true;
    _presentChangelog(changes);
  }

  void _presentChangelog(List<String> changes) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigatorContext = _navigatorKey.currentState?.context;
      if (navigatorContext == null || !navigatorContext.mounted) {
        // The first frame may finish after the async version check. Retry on
        // the next frame instead of showing a dialog with the wrong context.
        _presentChangelog(changes);
        return;
      }
      showDialog<void>(
        context: navigatorContext,
        builder: (dialogContext) => AlertDialog(
          title: const Text("What's new"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final change in changes)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('• $change'),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                _changelog.dismiss();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'IR RAG Assistant',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: MainShell(
        askController: widget.controller,
        libraryController: _library,
        evaluationController: _evaluation,
        onToggleTheme: () {
          setState(() {
            _themeMode = _themeMode == ThemeMode.dark
                ? ThemeMode.light
                : ThemeMode.dark;
          });
        },
      ),
    );
  }
}
