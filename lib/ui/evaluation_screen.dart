import 'package:material_ui/material_ui.dart';

import '../data/models/library_models.dart';
import '../state/evaluation_controller.dart';
import 'widgets/bottom_padding.dart';

/// Dashboard tab: corpus overview, retrieval quality and answer telemetry.
class EvaluationScreen extends StatelessWidget {
  const EvaluationScreen({super.key, required this.controller});

  final EvaluationController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final snapshot = controller.snapshot;
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
          ).copyWith(top: 16, bottom: BottomPadding.of(context, minimum: 96)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_rounded,
                      color: scheme.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Model evaluation',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            snapshot == null
                                ? 'Live measurements from your indexed corpus.'
                                : 'Snapshot generated ${_shortDate(snapshot.generatedAt)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh evaluation',
                      onPressed: controller.load,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (controller.isLoading && snapshot == null)
                  const Padding(
                    padding: EdgeInsets.all(64),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 36,
                            color: scheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            controller.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.error),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: controller.load,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (snapshot == null)
                  const SizedBox.shrink()
                else
                  _Dashboard(snapshot: snapshot),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.snapshot});

  final EvaluationSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final corpus = snapshot.corpus;
    final retrieval = snapshot.retrieval;
    final answers = snapshot.answers;
    final quality = snapshot.quality;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < 520
                ? constraints.maxWidth
                : (constraints.maxWidth - 24) / 3;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: _MetricCard(
                    icon: Icons.description_outlined,
                    label: 'Documents',
                    value: '${corpus.documents}',
                    caption: 'pages in the corpus',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _MetricCard(
                    icon: Icons.grid_view_outlined,
                    label: 'Chunks',
                    value: '${corpus.chunks}',
                    caption: 'searchable passages',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _MetricCard(
                    icon: Icons.text_snippet_outlined,
                    label: 'Words',
                    value: _compact(corpus.words),
                    caption: 'indexed text volume',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _SectionCard(
          icon: Icons.search_rounded,
          title: 'Retrieval quality',
          subtitle: 'Auto-checked by querying the live index with document titles and sections.',
          children: [
            if (!retrieval.hasData)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No documents to evaluate yet. Add a page in the Corpus tab.',
                ),
              )
            else ...[
              _BarMetric(label: 'Hit rate @ 1', value: retrieval.hitAtOne),
              _BarMetric(label: 'Hit rate @ k', value: retrieval.hitAtK),
              _BarMetric(label: 'Mean reciprocal rank', value: retrieval.mrr),
              _BarMetric(label: 'nDCG @ k', value: retrieval.ndcgAtK),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'Queries',
                      value: '${retrieval.queries}',
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'Mean top score',
                      value: '${(retrieval.meanTopScore * 100).round()}%',
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'Mean search time',
                      value: '${retrieval.meanLatencyMs.round()} ms',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          icon: Icons.forum_outlined,
          title: 'Answer quality',
          subtitle: 'Measured from real questions asked through this app.',
          children: [
            if (!answers.hasData)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No answers logged yet. Ask a question in the Ask tab to start tracking.',
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _Stat(label: 'Questions', value: '${answers.total}'),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'Answered',
                      value: '${answers.answered}',
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'Refusals',
                      value: '${answers.refusals}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _BarMetric(
                label: 'Grounded answer rate',
                value: 1 - answers.refusalRate,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'Avg sources',
                      value: answers.averageSources.toStringAsFixed(1),
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'Avg top score',
                      value: '${(answers.averageTopScore * 100).round()}%',
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'Avg response',
                      value: '${answers.averageLatencyMs.round()} ms',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          icon: Icons.health_and_safety_outlined,
          title: 'Corpus health',
          subtitle: 'Coverage and consistency between documents and the index.',
          children: [
            _BarMetric(label: 'Document coverage', value: quality.coverage),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Chunks / document',
                    value: quality.averageChunksPerDocument.toStringAsFixed(1),
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Orphan chunks',
                    value: '${quality.orphanChunks}',
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Index',
                    value: _status(corpus.indexReady),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Index freshness: ${quality.indexFreshness}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (snapshot.documents.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.bar_chart_rounded,
            title: 'Content distribution',
            subtitle: 'Chunks contributed by each document.',
            children: [
              for (final document in snapshot.documents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              document.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${document.chunks}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      _DistributionBar(
                        value: document.chunks,
                        max: snapshot.documents
                            .map((d) => d.chunks)
                            .reduce((a, b) => a > b ? a : b),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: scheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 19, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _BarMetric extends StatelessWidget {
  const _BarMetric({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (value.clamp(0.0, 1.0) * 100).round();
    final color = pct >= 70
        ? scheme.primary
        : pct >= 40
        ? scheme.tertiary
        : scheme.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 12)),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({required this.value, required this.max});

  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final fraction = max == 0 ? 0.0 : value / max;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 7,
        backgroundColor: color.withValues(alpha: 0.1),
        color: color,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

String _compact(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  return '$value';
}

String _shortDate(String iso) {
  if (iso.length < 16) return iso.isEmpty ? 'just now' : iso;
  return iso.replaceAll('T', ' ').substring(0, 16);
}

String _status(bool ready) => ready ? 'Ready' : 'Not ready';
