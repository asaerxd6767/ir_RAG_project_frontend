import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../data/models/library_models.dart';
import '../../state/library_controller.dart';

/// A visual walkthrough of the real backend ingestion pipeline.
///
/// The stage shown is driven by `GET /ingest/{job_id}`; the animation only
/// decorates that state, so it never claims a step finished before it did.
class IngestionProgressDialog extends StatefulWidget {
  const IngestionProgressDialog({
    super.key,
    required this.controller,
    required this.url,
  });

  final LibraryController controller;
  final String url;

  @override
  State<IngestionProgressDialog> createState() =>
      _IngestionProgressDialogState();
}

enum _StageStatus { done, active, pending, failed }

class _Step {
  const _Step({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;
}

const List<_Step> _steps = <_Step>[
  _Step(
    icon: Icons.hourglass_top_rounded,
    title: 'Queued',
    detail: 'Preparing the ingestion job',
    color: Color(0xFF607D8B),
  ),
  _Step(
    icon: Icons.public_rounded,
    title: 'Crawling',
    detail: 'Fetching the page politely',
    color: Color(0xFF2979FF),
  ),
  _Step(
    icon: Icons.text_snippet_outlined,
    title: 'Extraction',
    detail: 'Removing navigation and boilerplate',
    color: Color(0xFF00897B),
  ),
  _Step(
    icon: Icons.tune_rounded,
    title: 'Preprocessing',
    detail: 'Deduplicating, cleaning and chunking',
    color: Color(0xFF7B1FA2),
  ),
  _Step(
    icon: Icons.account_tree_outlined,
    title: 'Indexing',
    detail: 'Building the TF-IDF search index',
    color: Color(0xFFEF6C00),
  ),
];

int _stageIndex(String stage) {
  switch (stage) {
    case 'crawling':
      return 1;
    case 'extracting':
      return 2;
    case 'preprocessing':
      return 3;
    case 'indexing':
      return 4;
    case 'completed':
      return _steps.length;
    default:
      return 0;
  }
}

class _IngestionProgressDialogState extends State<IngestionProgressDialog>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _success;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _success = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    widget.controller.addListener(_onControllerChanged);
    _onControllerChanged();
  }

  void _onControllerChanged() {
    final job = widget.controller.job;
    if (job != null &&
        job.isDone &&
        _success.status != AnimationStatus.completed) {
      _success.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _pulse.dispose();
    _success.dispose();
    super.dispose();
  }

  String get _host {
    final uri = Uri.tryParse(widget.url);
    return uri == null || uri.host.isEmpty ? widget.url : uri.host;
  }

  String _readyTitle(IngestJob job) {
    for (final document in widget.controller.library?.documents ?? const []) {
      if (document.id == job.documentId) return document.displayTitle;
    }
    return 'Document';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final job = widget.controller.job;
        final done = job?.isDone ?? false;
        final failed = job?.isFailed ?? false;
        final current = done
            ? _steps.length
            : _stageIndex(job?.stage ?? 'queued');
        final scheme = Theme.of(context).colorScheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Banner(
                    done: done,
                    failed: failed,
                    host: _host,
                    pulse: _pulse,
                    success: _success,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (done)
                          _ReadyPanel(
                            animation: _success,
                            title: job != null ? _readyTitle(job) : 'Document',
                          )
                        else ...[
                          if (failed) ...[
                            _FailurePanel(message: job?.message ?? ''),
                            const SizedBox(height: 18),
                          ],
                          for (var i = 0; i < _steps.length; i++)
                            _StepTile(
                              step: _steps[i],
                              status: failed && i == current
                                  ? _StageStatus.failed
                                  : i < current
                                  ? _StageStatus.done
                                  : i == current
                                  ? _StageStatus.active
                                  : _StageStatus.pending,
                              pulse: _pulse,
                              isLast: i == _steps.length - 1,
                            ),
                          if (!failed) ...[
                            const SizedBox(height: 6),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0,
                                end: job?.progress ?? 0,
                              ),
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) =>
                                  LinearProgressIndicator(
                                    value: value,
                                    minHeight: 7,
                                    backgroundColor: scheme.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    color: scheme.primary,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              job?.message ?? 'Starting ingestion…',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            done || failed
                                ? 'Done'
                                : 'Keep working in background',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.done,
    required this.failed,
    required this.host,
    required this.pulse,
    required this.success,
  });

  final bool done;
  final bool failed;
  final String host;
  final Animation<double> pulse;
  final Animation<double> success;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: failed
              ? <Color>[scheme.error, scheme.error.withValues(alpha: 0.72)]
              : <Color>[scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[pulse, success]),
            builder: (context, child) {
              if (done) {
                return ScaleTransition(
                  scale: CurvedAnimation(
                    parent: success,
                    curve: Curves.elasticOut,
                  ),
                  child: child,
                );
              }
              return RotationTransition(turns: pulse, child: child);
            },
            child: Icon(
              done
                  ? Icons.check_circle_rounded
                  : failed
                  ? Icons.error_outline_rounded
                  : Icons.sync_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done
                      ? 'Document is ready'
                      : failed
                      ? 'Ingestion failed'
                      : 'Adding to corpus',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.step,
    required this.status,
    required this.pulse,
    required this.isLast,
  });

  final _Step step;
  final _StageStatus status;
  final Animation<double> pulse;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final complete = status == _StageStatus.done;
    final active = status == _StageStatus.active;
    final failed = status == _StageStatus.failed;
    final color = failed ? scheme.error : step.color;
    final labelColor = status == _StageStatus.pending
        ? scheme.onSurfaceVariant.withValues(alpha: 0.6)
        : failed
        ? scheme.error
        : scheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Column(
            children: [
              AnimatedBuilder(
                animation: pulse,
                builder: (context, child) {
                  final bounce = 0.5 + 0.5 * sin(pulse.value * 2 * pi);
                  return Transform.scale(
                    scale: active ? 1 + 0.09 * bounce : 1,
                    child: child,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: complete || failed
                        ? color
                        : color.withValues(alpha: active ? 0.18 : 0.07),
                    border: Border.all(
                      color: color,
                      width: active || failed ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    complete
                        ? Icons.check_rounded
                        : failed
                        ? Icons.close_rounded
                        : step.icon,
                    color: complete || failed ? Colors.white : color,
                    size: 18,
                  ),
                ),
              ),
              if (!isLast)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 2,
                  height: 30,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: complete
                      ? color.withValues(alpha: 0.55)
                      : color.withValues(alpha: 0.16),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 7, bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: active || complete || failed
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadyPanel extends StatelessWidget {
  const _ReadyPanel({required this.animation, required this.title});

  final Animation<double> animation;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle_rounded, color: scheme.primary, size: 38),
            const SizedBox(height: 10),
            Text(
              'Document is ready',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '“$title” is indexed and can now be asked about in the Ask tab.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailurePanel extends StatelessWidget {
  const _FailurePanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.error, size: 34),
          const SizedBox(height: 10),
          Text(
            message.isEmpty
                ? 'The ingestion job could not be completed.'
                : message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.error),
          ),
        ],
      ),
    );
  }
}
