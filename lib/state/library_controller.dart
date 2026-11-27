import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/services/rag_api_client.dart';
import '../data/models/library_models.dart';

/// Owns the corpus document list and background URL ingestion jobs.
class LibraryController extends ChangeNotifier {
  LibraryController({
    required this.client,
    this.pollInterval = const Duration(seconds: 1),
  });

  final RagApiClient client;
  final Duration pollInterval;

  DocumentLibrary? library;
  IngestJob? job;
  String? libraryError;
  String? ingestError;
  String? notice;
  String? deletingId;
  bool isLoading = false;
  bool isIngesting = false;

  Timer? _pollTimer;
  bool _polling = false;

  bool get hasDocuments => library?.documents.isNotEmpty ?? false;

  Future<void> load() async {
    isLoading = true;
    libraryError = null;
    notifyListeners();
    try {
      library = await client.getLibrary();
    } on Object catch (error) {
      libraryError = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> ingest(String rawUrl) async {
    final url = rawUrl.trim();
    final uri = Uri.tryParse(url);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      ingestError = 'Enter a full http:// or https:// URL, e.g. https://example.com/tutorial';
      notifyListeners();
      return false;
    }

    isIngesting = true;
    ingestError = null;
    notice = null;
    job = IngestJob(
      id: '',
      url: url,
      status: 'queued',
      stage: 'queued',
      progress: 0,
      message: 'Starting ingestion…',
    );
    notifyListeners();

    try {
      job = await client.startIngest(url);
      notifyListeners();
      _startPolling(job!.id);
      return true;
    } on Object catch (error) {
      isIngesting = false;
      job = null;
      ingestError = error.toString();
      notifyListeners();
      return false;
    }
  }

  void _startPolling(String jobId) {
    _pollTimer?.cancel();
    if (jobId.isEmpty) {
      isIngesting = false;
      ingestError = 'The backend did not return a job id.';
      notifyListeners();
      return;
    }
    _pollTimer = Timer.periodic(pollInterval, (_) => _checkJob(jobId));
  }

  Future<void> _checkJob(String jobId) async {
    if (_polling) return;
    _polling = true;
    try {
      final updated = await client.getIngestJob(jobId);
      job = updated;
      if (!updated.isTerminal) return;

      _pollTimer?.cancel();
      _pollTimer = null;
      isIngesting = false;
      if (updated.isDone) {
        notice = '“${updated.documentId ?? 'Document'}” is now searchable.';
        await load();
      } else {
        ingestError = updated.error ?? updated.message;
      }
    } on Object catch (error) {
      _pollTimer?.cancel();
      _pollTimer = null;
      isIngesting = false;
      ingestError = error.toString();
    } finally {
      _polling = false;
      notifyListeners();
    }
  }

  Future<bool> delete(String documentId) async {
    deletingId = documentId;
    notice = null;
    notifyListeners();
    try {
      await client.deleteDocument(documentId);
      notice = 'Document removed and the index was rebuilt.';
      await load();
      return true;
    } on Object catch (error) {
      ingestError = error.toString();
      return false;
    } finally {
      deletingId = null;
      notifyListeners();
    }
  }

  void clearMessages() {
    notice = null;
    ingestError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
