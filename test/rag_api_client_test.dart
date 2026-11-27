import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ir_rag_project/core/api_config.dart';
import 'package:ir_rag_project/core/api_exception.dart';
import 'package:ir_rag_project/data/services/rag_api_client.dart';

RagApiClient _clientFor(MockClient mock) {
  return RagApiClient(
    config: ApiConfig.from('http://127.0.0.1:8000'),
    httpClient: mock,
  );
}

void main() {
  test('POST /ask sends JSON and parses sources', () async {
    final client = _clientFor(
      MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/ask');
        expect(jsonDecode(request.body), {'question': 'What is TF-IDF?'});
        return http.Response(
          jsonEncode({
            'answer': 'A weighting scheme.',
            'sources': [
              {'url': 'https://example.com', 'title': 'Indexing', 'score': 0.9},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await client.ask(' What is TF-IDF? ');
    expect(result.answer, 'A weighting scheme.');
    expect(result.sources.single.title, 'Indexing');
  });

  test('GET /health parses status', () async {
    final client = _clientFor(
      MockClient((request) async {
        expect(request.url.path, '/health');
        return http.Response('{"status":"ok"}', 200);
      }),
    );

    expect((await client.getHealth()).isOk, isTrue);
  });

  test('explains that loopback is the device on connection failure', () async {
    final client = _clientFor(
      MockClient((request) async => throw Exception('Connection refused')),
    );

    expect(
      () => client.getHealth(),
      throwsA(
        isA<ApiConnectionException>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('127.0.0.1 means the device itself'),
            contains('Wi-Fi IP'),
          ),
        ),
      ),
    );
  });

  test('maps a 404 to a helpful user-facing message', () async {
    final client = _clientFor(
      MockClient((request) async {
        return http.Response('{"detail":"Not Found"}', 404);
      }),
    );

    expect(
      () => client.ask('hello'),
      throwsA(
        isA<ApiResponseException>().having(
          (error) => error.message,
          'message',
          contains('Endpoint not found'),
        ),
      ),
    );
  });

  test('GET /documents parses the corpus library', () async {
    final client = _clientFor(
      MockClient((request) async {
        expect(request.url.path, '/documents');
        return http.Response(
          jsonEncode({
            'documents': [
              {
                'id': 'd1',
                'url': 'https://example.com/python-tutorial',
                'title': 'Python Tutorial',
                'chunk_count': 12,
                'word_count': 1800,
                'size_bytes': 24000,
                'created_at': '2026-11-27T00:00:00Z',
                'status': 'ready',
              },
            ],
            'counts': {
              'documents': 1,
              'chunks': 12,
              'words': 1800,
              'ready_documents': 1,
            },
          }),
          200,
        );
      }),
    );

    final library = await client.getLibrary();
    expect(library.documents.single.title, 'Python Tutorial');
    expect(library.counts.chunks, 12);
  });

  test('ingestion endpoints parse job progress', () async {
    final client = _clientFor(
      MockClient((request) async {
        if (request.method == 'POST') {
          expect(request.url.path, '/ingest');
          expect(jsonDecode(request.body), {
            'url': 'https://example.com/tutorial',
          });
          return http.Response(
            jsonEncode({
              'job_id': 'job1',
              'url': 'https://example.com/tutorial',
              'status': 'running',
              'stage': 'crawling',
              'progress': 0.2,
              'message': 'Fetching the page',
            }),
            202,
          );
        }
        expect(request.url.path, '/ingest/job1');
        return http.Response(
          jsonEncode({
            'job_id': 'job1',
            'url': 'https://example.com/tutorial',
            'status': 'completed',
            'stage': 'completed',
            'progress': 1,
            'message': 'Indexed 3 chunks',
            'document_id': 'd1',
          }),
          200,
        );
      }),
    );

    final started = await client.startIngest('https://example.com/tutorial');
    expect(started.progress, 0.2);
    final finished = await client.getIngestJob('job1');
    expect(finished.isDone, isTrue);
    expect(finished.documentId, 'd1');
  });

  test('DELETE /documents/{id} sends a delete request', () async {
    final client = _clientFor(
      MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/documents/d1');
        return http.Response('{"deleted_id":"d1"}', 200);
      }),
    );

    await client.deleteDocument('d1');
  });

  test('GET /evaluation parses dashboard metrics', () async {
    final client = _clientFor(
      MockClient((request) async {
        expect(request.url.path, '/evaluation');
        return http.Response(
          jsonEncode({
            'generated_at': '2026-11-27T00:00:00Z',
            'corpus': {
              'documents': 1,
              'chunks': 4,
              'words': 500,
              'index_ready': true,
              'model_ready': true,
            },
            'retrieval': {
              'queries': 2,
              'hit_at_1': 1.0,
              'hit_at_k': 1.0,
              'mrr': 1.0,
              'ndcg_at_k': 1.0,
            },
            'answers': {'total': 3, 'answered': 2, 'refusals': 1},
            'quality': {'coverage': 1.0, 'index_freshness': 'fresh'},
            'documents': [
              {'title': 'Python Tutorial', 'chunks': 4, 'words': 500},
            ],
          }),
          200,
        );
      }),
    );

    final snapshot = await client.getEvaluation();
    expect(snapshot.corpus.documents, 1);
    expect(snapshot.retrieval.hitAtOne, 1.0);
    expect(snapshot.answers.refusals, 1);
    expect(snapshot.documents.single.title, 'Python Tutorial');
  });

  test('ask uses a longer timeout than fast endpoints', () async {
    final mock = MockClient((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      if (request.url.path == '/ask') {
        return http.Response(
          '{"answer":"A grounded answer.","sources":[]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{"status":"ok"}', 200);
    });
    final client = RagApiClient(
      config: ApiConfig.from('http://127.0.0.1:8000'),
      httpClient: mock,
      timeout: const Duration(milliseconds: 5),
      askTimeout: const Duration(seconds: 2),
    );

    expect((await client.ask('hello')).answer, 'A grounded answer.');
    expect(() => client.getHealth(), throwsA(isA<ApiTimeoutException>()));
  });
}
