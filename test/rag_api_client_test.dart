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
}
