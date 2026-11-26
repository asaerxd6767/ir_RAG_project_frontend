import 'package:material_ui/material_ui.dart';

class RefusalCard extends StatelessWidget {
  const RefusalCard({super.key, required this.onSuggestionTap});

  final ValueChanged<String> onSuggestionTap;

  static const _ideas = <String>[
    'How does a polite crawler behave?',
    'What is TF-IDF used for?',
    'How are web pages deduplicated?',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final warning = scheme.tertiary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: warning.withValues(alpha: 0.12),
                  foregroundColor: warning,
                  child: const Icon(Icons.search_off_rounded),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Not found in the corpus',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: warning,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'The retrieved material does not contain an answer to this question. '
              'No answer was invented, and no sources are shown.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final idea in _ideas)
                  ActionChip(
                    avatar: Icon(Icons.lightbulb_outline, size: 16, color: scheme.primary),
                    label: Text(idea, style: const TextStyle(fontSize: 12)),
                    onPressed: () => onSuggestionTap(idea),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
