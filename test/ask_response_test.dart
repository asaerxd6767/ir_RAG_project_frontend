import 'package:flutter_test/flutter_test.dart';
import 'package:ir_rag_project/data/models/ask_response.dart';
import 'package:ir_rag_project/data/models/health_status.dart';

void main() {
  group('AskResponse', () {
    test('parses the documented source contract', () {
      final response = AskResponse.fromJson({
        'answer': 'A polite crawler obeys robots.txt.',
        'sources': [
          {
            'url': 'https://example.com/crawling',
            'section': 'Politeness',
            'score': 0.81,
            'chunk_id': 'chunk-12',
            'title': 'Crawling basics',
          },
        ],
      });

      expect(response.isRefusal, isFalse);
      expect(response.sources, hasLength(1));
      expect(response.sources.single.title, 'Crawling basics');
      expect(response.sources.single.section, 'Politeness');
      expect(response.sources.single.chunkId, 'chunk-12');
      expect(response.sources.single.score, 0.81);
      expect(response.sources.single.host, 'example.com');
    });

    test('tolerates sources without title and chunk id', () {
      final response = AskResponse.fromJson({
        'answer': 'Some answer.',
        'sources': [
          {'url': 'https://example.com', 'section': 'Intro', 'score': '0.5'},
        ],
      });

      expect(response.sources.single.title, 'Intro');
      expect(response.sources.single.chunkId, isEmpty);
      expect(response.sources.single.score, 0.5);
    });

    test('detects the exact refusal answer regardless of case', () {
      final response = AskResponse.fromJson({
        'answer': ' NOT FOUND IN THE CORPUS ',
        'sources': [],
      });

      expect(response.isRefusal, isTrue);
      expect(response.sources, isEmpty);
    });
  });

  group('HealthStatus', () {
    test('reports ok only for status ok', () {
      expect(HealthStatus.fromJson({'status': 'ok'}).isOk, isTrue);
      expect(HealthStatus.fromJson({'status': 'degraded'}).isOk, isFalse);
      expect(HealthStatus.fromJson({'status': 'error', 'detail': 'no model'}).detail, 'no model');
    });
  });
}
