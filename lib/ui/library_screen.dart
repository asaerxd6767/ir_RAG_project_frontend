import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/library_models.dart';
import '../state/library_controller.dart';
import 'widgets/bottom_padding.dart';
import 'widgets/ingestion_progress_dialog.dart';

/// Corpus tab: add pages by URL, watch ingestion progress, manage documents.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.controller,
    this.onExampleQuestion,
  });

  final LibraryController controller;
  final void Function(String question)? onExampleQuestion;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final url = _urlController.text.trim();
    final ok = await widget.controller.ingest(url);
    if (!ok || !mounted) return;
    _urlController.clear();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => IngestionProgressDialog(
        controller: widget.controller,
        url: url,
        onExampleQuestion: widget.onExampleQuestion,
      ),
    );
  }

  Future<void> _confirmDelete(LibraryDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove document?'),
        content: Text(
          '“${document.displayTitle}” will be removed from the corpus and the '
          'search index will be rebuilt. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.controller.delete(document.id);
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final scheme = Theme.of(context).colorScheme;
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
                      Icons.library_books_rounded,
                      color: scheme.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Corpus library',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Add a page by URL, then ask questions about everything you have indexed.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh library',
                      onPressed: controller.load,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _IngestCard(
                  controller: _urlController,
                  isBusy: controller.isIngesting,
                  onSubmit: _submit,
                ),
                if (controller.job != null) ...[
                  const SizedBox(height: 12),
                  _JobProgress(job: controller.job!),
                ],
                if (controller.notice != null) ...[
                  const SizedBox(height: 12),
                  _Banner(
                    icon: Icons.check_circle_outline,
                    color: scheme.primary,
                    text: controller.notice!,
                  ),
                ],
                if (controller.ingestError != null) ...[
                  const SizedBox(height: 12),
                  _Banner(
                    icon: Icons.error_outline,
                    color: scheme.error,
                    text: controller.ingestError!,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Indexed documents',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    if (controller.library != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${controller.library!.counts.documents}',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (controller.isLoading && controller.library == null)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.libraryError != null)
                  _Banner(
                    icon: Icons.cloud_off_outlined,
                    color: scheme.error,
                    text: controller.libraryError!,
                  )
                else if (!controller.hasDocuments)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.insert_drive_file_outlined,
                            size: 40,
                            color: scheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No documents yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add a tutorial or article URL above to build your searchable corpus.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth < 620
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final document in controller.library!.documents)
                            SizedBox(
                              width: width,
                              child: _DocumentCard(
                                document: document,
                                isDeleting:
                                    controller.deletingId == document.id,
                                onOpen: () => _open(document.url),
                                onDelete: () => _confirmDelete(document),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IngestCard extends StatelessWidget {
  const _IngestCard({
    required this.controller,
    required this.isBusy,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isBusy;
  final VoidCallback onSubmit;

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
                Icon(Icons.add_link_rounded, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Add a document',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'The backend fetches the page, extracts text, preprocesses and chunks it, '
              'then rebuilds the TF-IDF index. The document becomes question-ready.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              enabled: !isBusy,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                labelText: 'Page URL',
                hintText: 'https://example.com/python-tutorial',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: isBusy ? null : onSubmit,
              icon: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(isBusy ? 'Adding document…' : 'Add to corpus'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobProgress extends StatelessWidget {
  const _JobProgress({required this.job});

  final IngestJob job;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = job.isFailed ? scheme.error : scheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  job.isFailed ? Icons.error_outline : Icons.sync_rounded,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.stageLabel,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${(job.progress * 100).round()}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: job.progress,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
            ),
            const SizedBox(height: 10),
            Text(
              job.message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.isDeleting,
    required this.onOpen,
    required this.onDelete,
  });

  final LibraryDocument document;
  final bool isDeleting;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = document.isReady ? scheme.primary : scheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.article_outlined, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    document.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    document.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    document.host,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.primary, fontSize: 12),
                  ),
                ),
                IconButton(
                  tooltip: 'Open document',
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  visualDensity: VisualDensity.compact,
                  onPressed: onOpen,
                ),
                IconButton(
                  tooltip: 'Copy URL',
                  icon: const Icon(Icons.link_rounded, size: 17),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: document.url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URL copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip(Icons.grid_view_rounded, '${document.chunkCount} chunks'),
                _Chip(Icons.text_fields_rounded, '${document.wordCount} words'),
                _Chip(Icons.storage_rounded, _sizeLabel(document.sizeBytes)),
              ],
            ),
            if (document.error != null) ...[
              const SizedBox(height: 8),
              Text(
                document.error!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.error, fontSize: 11),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dateLabel(document.createdAt),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
                isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton.icon(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 17,
                          color: scheme.error,
                        ),
                        label: Text(
                          'Remove',
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

String _sizeLabel(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
  return '$bytes B';
}

String _dateLabel(String iso) {
  if (iso.isEmpty) return 'Added just now';
  final clean = iso.replaceAll('T', ' ').split('.').first;
  return 'Added $clean';
}
