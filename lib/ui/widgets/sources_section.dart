import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/ask_response.dart';

class SourcesSection extends StatelessWidget {
  const SourcesSection({super.key, required this.sources});

  final List<RagSource> sources;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.library_books_outlined, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              'Sources',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${sources.length}',
                style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth < 560
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final source in sources)
                  SizedBox(width: cardWidth, child: SourceCard(source: source)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class SourceCard extends StatelessWidget {
  const SourceCard({super.key, required this.source});

  final RagSource source;

  Future<void> _open() async {
    final uri = Uri.tryParse(source.url);
    if (uri == null || !uri.hasScheme) return;
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final score = (source.score * 100).clamp(0, 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.article_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    source.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$score%',
                    style: TextStyle(
                      color: scheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (source.section.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                source.section,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    source.host,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                if (source.url.isNotEmpty)
                  IconButton(
                    tooltip: 'Open source',
                    icon: const Icon(Icons.open_in_new_rounded, size: 17),
                    visualDensity: VisualDensity.compact,
                    onPressed: _open,
                  ),
                IconButton(
                  tooltip: 'Copy link',
                  icon: const Icon(Icons.link_rounded, size: 17),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: source.url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Source link copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            if (source.chunkId.isNotEmpty)
              Text(
                'chunk: ${source.chunkId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
