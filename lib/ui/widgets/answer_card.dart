import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../data/models/ask_response.dart';

class AnswerCard extends StatelessWidget {
  const AnswerCard({super.key, required this.response});

  final AskResponse response;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: scheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grounded answer',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'Generated only from retrieved course material',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy answer',
                  icon: const Icon(Icons.copy_all_outlined, size: 19),
                  onPressed: () {
                    awaitCopy(context, response.answer);
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            SelectableText(
              response.answer,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.65),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> awaitCopy(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Answer copied to clipboard'), duration: Duration(seconds: 2)),
  );
}
