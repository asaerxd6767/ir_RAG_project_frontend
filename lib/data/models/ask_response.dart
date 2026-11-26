/// One retrieved chunk used to ground an answer.
class RagSource {
  const RagSource({
    required this.url,
    required this.title,
    required this.section,
    required this.chunkId,
    required this.score,
  });

  final String url;
  final String title;
  final String section;
  final String chunkId;
  final double score;

  factory RagSource.fromJson(Map<String, dynamic> json) {
    return RagSource(
      url: _asString(json['url']),
      title: _asString(
        json['title'],
        fallback: _asString(json['section'], fallback: 'Untitled source'),
      ),
      section: _asString(json['section']),
      chunkId: _asString(json['chunk_id']),
      score: _asDouble(json['score']),
    );
  }

  String get host {
    final uri = Uri.tryParse(url);
    return uri == null || uri.host.isEmpty ? url : uri.host;
  }

  String get displayTitle => title.isEmpty ? 'Untitled source' : title;
}

/// Payload returned by `POST /ask`.
class AskResponse {
  const AskResponse({required this.answer, required this.sources});

  final String answer;
  final List<RagSource> sources;

  /// The backend is required to return this exact answer when the corpus has
  /// no grounded answer. Comparison is case/whitespace tolerant only.
  bool get isRefusal => _normalise(answer) == 'not found in the corpus';

  factory AskResponse.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'];
    final sources = <RagSource>[];
    if (rawSources is List) {
      for (final item in rawSources) {
        if (item is Map) {
          sources.add(RagSource.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return AskResponse(
      answer: _asString(json['answer']),
      sources: List.unmodifiable(sources),
    );
  }

  static String _normalise(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

String _asString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
