/// A document that has been added to the retrieval corpus.
class LibraryDocument {
  const LibraryDocument({
    required this.id,
    required this.url,
    required this.title,
    required this.chunkCount,
    required this.wordCount,
    required this.sizeBytes,
    required this.createdAt,
    required this.status,
    this.error,
  });

  final String id;
  final String url;
  final String title;
  final int chunkCount;
  final int wordCount;
  final int sizeBytes;
  final String createdAt;
  final String status;
  final String? error;

  bool get isReady => status == 'ready';

  String get host {
    final uri = Uri.tryParse(url);
    return uri == null || uri.host.isEmpty ? url : uri.host;
  }

  String get displayTitle => title.isEmpty ? 'Untitled document' : title;

  factory LibraryDocument.fromJson(Map<String, dynamic> json) {
    return LibraryDocument(
      id: _string(json['id']),
      url: _string(json['url']),
      title: _string(json['title']),
      chunkCount: _int(json['chunk_count']),
      wordCount: _int(json['word_count']),
      sizeBytes: _int(json['size_bytes']),
      createdAt: _string(json['created_at']),
      status: _string(json['status'], fallback: 'unknown'),
      error: _optionalString(json['error']),
    );
  }
}

/// Corpus totals returned alongside the document list.
class LibraryCounts {
  const LibraryCounts({
    required this.documents,
    required this.chunks,
    required this.words,
    required this.readyDocuments,
  });

  final int documents;
  final int chunks;
  final int words;
  final int readyDocuments;

  factory LibraryCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const LibraryCounts(
        documents: 0,
        chunks: 0,
        words: 0,
        readyDocuments: 0,
      );
    }
    return LibraryCounts(
      documents: _int(json['documents']),
      chunks: _int(json['chunks']),
      words: _int(json['words']),
      readyDocuments: _int(json['ready_documents']),
    );
  }
}

class DocumentLibrary {
  const DocumentLibrary({required this.documents, required this.counts});

  final List<LibraryDocument> documents;
  final LibraryCounts counts;

  factory DocumentLibrary.fromJson(Map<String, dynamic> json) {
    final raw = json['documents'];
    final documents = <LibraryDocument>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          documents.add(
            LibraryDocument.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return DocumentLibrary(
      documents: List.unmodifiable(documents),
      counts: LibraryCounts.fromJson(
        json['counts'] is Map
            ? Map<String, dynamic>.from(json['counts'] as Map)
            : null,
      ),
    );
  }
}

/// A background ingestion job returned by `POST /ingest` and `GET /ingest/{id}`.
class IngestJob {
  const IngestJob({
    required this.id,
    required this.url,
    required this.status,
    required this.stage,
    required this.progress,
    required this.message,
    this.documentId,
    this.error,
  });

  final String id;
  final String url;
  final String status;
  final String stage;
  final double progress;
  final String message;
  final String? documentId;
  final String? error;

  bool get isDone => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isTerminal => isDone || isFailed;

  String get stageLabel {
    switch (stage) {
      case 'crawling':
        return 'Fetching the page';
      case 'extracting':
        return 'Extracting readable text';
      case 'preprocessing':
        return 'Cleaning and chunking';
      case 'indexing':
        return 'Building the search index';
      case 'completed':
        return 'Done';
      case 'failed':
        return 'Failed';
      default:
        return 'Queued';
    }
  }

  factory IngestJob.fromJson(Map<String, dynamic> json) {
    final rawProgress = json['progress'];
    final progress = rawProgress is num
        ? rawProgress.toDouble()
        : double.tryParse(rawProgress?.toString() ?? '') ?? 0;
    return IngestJob(
      id: _string(json['job_id'] ?? json['id']),
      url: _string(json['url']),
      status: _string(json['status'], fallback: 'queued'),
      stage: _string(json['stage'], fallback: 'queued'),
      progress: progress.clamp(0.0, 1.0),
      message: _string(json['message'], fallback: 'Queued'),
      documentId: _optionalString(json['document_id']),
      error: _optionalString(json['error']),
    );
  }
}

/// Aggregated evaluation snapshot returned by `GET /evaluation`.
class EvaluationSnapshot {
  const EvaluationSnapshot({
    required this.generatedAt,
    required this.corpus,
    required this.retrieval,
    required this.answers,
    required this.quality,
    required this.documents,
  });

  final String generatedAt;
  final EvaluationCorpus corpus;
  final RetrievalMetrics retrieval;
  final AnswerMetrics answers;
  final QualityMetrics quality;
  final List<DocumentMetric> documents;

  factory EvaluationSnapshot.fromJson(Map<String, dynamic> json) {
    final rawDocs = json['documents'];
    final docs = <DocumentMetric>[];
    if (rawDocs is List) {
      for (final item in rawDocs) {
        if (item is Map) {
          docs.add(DocumentMetric.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return EvaluationSnapshot(
      generatedAt: _string(json['generated_at']),
      corpus: EvaluationCorpus.fromJson(json['corpus']),
      retrieval: RetrievalMetrics.fromJson(json['retrieval']),
      answers: AnswerMetrics.fromJson(json['answers']),
      quality: QualityMetrics.fromJson(json['quality']),
      documents: List.unmodifiable(docs),
    );
  }
}

class EvaluationCorpus {
  const EvaluationCorpus({
    required this.documents,
    required this.chunks,
    required this.words,
    required this.indexReady,
    required this.modelReady,
  });

  final int documents;
  final int chunks;
  final int words;
  final bool indexReady;
  final bool modelReady;

  factory EvaluationCorpus.fromJson(Object? json) {
    if (json is! Map) {
      return const EvaluationCorpus(
        documents: 0,
        chunks: 0,
        words: 0,
        indexReady: false,
        modelReady: false,
      );
    }
    final map = Map<String, dynamic>.from(json);
    return EvaluationCorpus(
      documents: _int(map['documents']),
      chunks: _int(map['chunks']),
      words: _int(map['words']),
      indexReady: map['index_ready'] == true,
      modelReady: map['model_ready'] == true,
    );
  }
}

class RetrievalMetrics {
  const RetrievalMetrics({
    required this.queries,
    required this.hitAtOne,
    required this.hitAtK,
    required this.mrr,
    required this.ndcgAtK,
    required this.meanTopScore,
    required this.meanLatencyMs,
  });

  final int queries;
  final double hitAtOne;
  final double hitAtK;
  final double mrr;
  final double ndcgAtK;
  final double meanTopScore;
  final double meanLatencyMs;

  bool get hasData => queries > 0;

  factory RetrievalMetrics.fromJson(Object? json) {
    if (json is! Map) {
      return const RetrievalMetrics(
        queries: 0,
        hitAtOne: 0,
        hitAtK: 0,
        mrr: 0,
        ndcgAtK: 0,
        meanTopScore: 0,
        meanLatencyMs: 0,
      );
    }
    final map = Map<String, dynamic>.from(json);
    return RetrievalMetrics(
      queries: _int(map['queries']),
      hitAtOne: _double(map['hit_at_1']),
      hitAtK: _double(map['hit_at_k']),
      mrr: _double(map['mrr']),
      ndcgAtK: _double(map['ndcg_at_k']),
      meanTopScore: _double(map['mean_top_score']),
      meanLatencyMs: _double(map['mean_latency_ms']),
    );
  }
}

class AnswerMetrics {
  const AnswerMetrics({
    required this.total,
    required this.answered,
    required this.refusals,
    required this.refusalRate,
    required this.averageSources,
    required this.averageTopScore,
    required this.averageLatencyMs,
  });

  final int total;
  final int answered;
  final int refusals;
  final double refusalRate;
  final double averageSources;
  final double averageTopScore;
  final double averageLatencyMs;

  bool get hasData => total > 0;

  factory AnswerMetrics.fromJson(Object? json) {
    if (json is! Map) {
      return const AnswerMetrics(
        total: 0,
        answered: 0,
        refusals: 0,
        refusalRate: 0,
        averageSources: 0,
        averageTopScore: 0,
        averageLatencyMs: 0,
      );
    }
    final map = Map<String, dynamic>.from(json);
    return AnswerMetrics(
      total: _int(map['total']),
      answered: _int(map['answered']),
      refusals: _int(map['refusals']),
      refusalRate: _double(map['refusal_rate']),
      averageSources: _double(map['average_sources']),
      averageTopScore: _double(map['average_top_score']),
      averageLatencyMs: _double(map['average_latency_ms']),
    );
  }
}

class QualityMetrics {
  const QualityMetrics({
    required this.coverage,
    required this.averageChunksPerDocument,
    required this.orphanChunks,
    required this.indexFreshness,
  });

  final double coverage;
  final double averageChunksPerDocument;
  final int orphanChunks;
  final String indexFreshness;

  factory QualityMetrics.fromJson(Object? json) {
    if (json is! Map) {
      return const QualityMetrics(
        coverage: 0,
        averageChunksPerDocument: 0,
        orphanChunks: 0,
        indexFreshness: 'unknown',
      );
    }
    final map = Map<String, dynamic>.from(json);
    return QualityMetrics(
      coverage: _double(map['coverage']),
      averageChunksPerDocument: _double(map['average_chunks_per_document']),
      orphanChunks: _int(map['orphan_chunks']),
      indexFreshness: _string(map['index_freshness'], fallback: 'unknown'),
    );
  }
}

class DocumentMetric {
  const DocumentMetric({
    required this.title,
    required this.chunks,
    required this.words,
  });

  final String title;
  final int chunks;
  final int words;

  factory DocumentMetric.fromJson(Map<String, dynamic> json) {
    return DocumentMetric(
      title: _string(json['title'], fallback: 'Untitled'),
      chunks: _int(json['chunks']),
      words: _int(json['words']),
    );
  }
}

String _string(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String? _optionalString(Object? value) {
  final text = _string(value);
  return text.isEmpty ? null : text;
}

int _int(Object? value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString().trim() ?? '') ?? 0;
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().trim() ?? '') ?? 0;
}
