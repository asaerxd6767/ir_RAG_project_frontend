import 'package:material_ui/material_ui.dart';

import '../../data/models/ask_response.dart';
import '../../state/ask_controller.dart';
import 'answer_card.dart';
import 'refusal_card.dart';
import 'sources_section.dart';

class ResultPanel extends StatelessWidget {
  const ResultPanel({
    super.key,
    required this.controller,
    required this.onSuggestionTap,
    required this.onRetry,
  });

  final AskController controller;
  final ValueChanged<String> onSuggestionTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      child: switch (controller.state) {
        AskState.loading => const _LoadingView(key: ValueKey('loading')),
        AskState.success => _SuccessView(
            key: const ValueKey('success'),
            response: controller.response!,
          ),
        AskState.refusal => RefusalCard(
            key: const ValueKey('refusal'),
            onSuggestionTap: onSuggestionTap,
          ),
        AskState.error => _ErrorView(
            key: const ValueKey('error'),
            message: controller.errorMessage ?? 'Something went wrong.',
            onRetry: onRetry,
          ),
        AskState.idle || _ => const _EmptyView(key: ValueKey('idle')),
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 320),
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        color: scheme.surface.withValues(alpha: 0.6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology_alt_outlined, size: 52, color: scheme.primary.withValues(alpha: 0.65)),
          const SizedBox(height: 18),
          Text(
            'Answers grounded in your corpus',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              'Ask a question to retrieve the most relevant course material and generate an answer with traceable sources.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Retrieving chunks and generating an answer…',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({super.key, required this.response});

  final AskResponse response;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnswerCard(response: response),
        const SizedBox(height: 22),
        SourcesSection(sources: response.sources),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_off_rounded, color: scheme.error, size: 26),
                const SizedBox(width: 10),
                Text(
                  'Could not get an answer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.error,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Check backend again'),
            ),
          ],
        ),
      ),
    );
  }
}
