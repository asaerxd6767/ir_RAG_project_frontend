import 'package:material_ui/material_ui.dart';

import '../state/ask_controller.dart';
import '../state/evaluation_controller.dart';
import '../state/library_controller.dart';
import 'ask_screen.dart';
import 'evaluation_screen.dart';
import 'library_screen.dart';
import 'settings_dialog.dart';

/// App shell with the three top-level tabs: Ask, Corpus and Evaluation.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.askController,
    required this.libraryController,
    required this.evaluationController,
    required this.onToggleTheme,
  });

  final AskController askController;
  final LibraryController libraryController;
  final EvaluationController evaluationController;
  final VoidCallback onToggleTheme;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _titles = <String>[
    'IR RAG Assistant',
    'Corpus library',
    'Evaluation',
  ];

  @override
  void initState() {
    super.initState();
    widget.libraryController.load();
    widget.evaluationController.load();
  }

  void _select(int index) {
    setState(() => _index = index);
    if (index == 1) widget.libraryController.load();
    if (index == 2) widget.evaluationController.load();
  }

  Future<void> _openSettings() async {
    FocusScope.of(context).unfocus();
    await showDialog<void>(
      context: context,
      builder: (_) => SettingsDialog(controller: widget.askController),
    );
    if (!mounted) return;
    // The URL may have changed; refresh data on the other tabs as well.
    await Future.wait([
      widget.libraryController.load(),
      widget.evaluationController.load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_tree_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Text(_titles[_index]),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Backend settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: _openSettings,
          ),
          IconButton(
            tooltip: 'Toggle light / dark theme',
            icon: const Icon(Icons.brightness_6_outlined),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          AskScreen(controller: widget.askController),
          LibraryScreen(controller: widget.libraryController),
          EvaluationScreen(controller: widget.evaluationController),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.question_answer_outlined),
            selectedIcon: Icon(Icons.question_answer_rounded),
            label: 'Ask',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books_rounded),
            label: 'Corpus',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Evaluation',
          ),
        ],
      ),
    );
  }
}
