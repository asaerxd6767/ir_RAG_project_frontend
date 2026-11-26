import 'package:material_ui/material_ui.dart';

import '../state/ask_controller.dart';
import 'settings_dialog.dart';
import 'widgets/health_badge.dart';
import 'widgets/question_composer.dart';
import 'widgets/result_panel.dart';

class AskScreen extends StatefulWidget {
  const AskScreen({
    super.key,
    required this.controller,
    required this.onToggleTheme,
  });

  final AskController controller;
  final VoidCallback onToggleTheme;

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_tree_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                const Text('IR RAG Assistant'),
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
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 980;
                final side = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Hero(compact: !isWide),
                    const SizedBox(height: 18),
                    _HealthRow(controller: controller),
                    const SizedBox(height: 18),
                    QuestionComposer(
                      onSubmit: controller.ask,
                      isLoading: controller.isLoading,
                      recentQuestions: controller.recentQuestions,
                    ),
                    const SizedBox(height: 18),
                    const _HowItWorks(),
                  ],
                );
                final results = ResultPanel(
                  controller: controller,
                  onSuggestionTap: controller.ask,
                  onRetry: controller.refreshHealth,
                );

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 16,
                    vertical: isWide ? 24 : 12,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: side),
                              const SizedBox(width: 28),
                              Expanded(flex: 3, child: results),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              side,
                              const SizedBox(height: 20),
                              results,
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSettings() async {
    await showDialog<void>(
      context: context,
      builder: (_) => SettingsDialog(controller: widget.controller),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ask your course corpus',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                fontSize: compact ? 26 : 36,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Retrieval-grounded answers built from the indexed course material. '
          'Every answer comes with the chunks it used.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.55,
                fontSize: compact ? 13 : 14,
              ),
        ),
      ],
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({required this.controller});

  final AskController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        HealthBadge(
          controller: controller,
          onRefresh: controller.refreshHealth,
        ),
        Text(
          controller.config.baseUrl,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        if (controller.healthError != null)
          Tooltip(
            message: controller.healthError!,
            child: Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.primary.withValues(alpha: 0.05),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How answers are produced',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.primary),
          ),
          const SizedBox(height: 10),
          Text(
            'Query preprocessing → TF-IDF retrieval → grounded prompt → local LLM '
            '→ answer with citations. If nothing relevant is retrieved, the app '
            'shows a refusal instead of guessing.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
