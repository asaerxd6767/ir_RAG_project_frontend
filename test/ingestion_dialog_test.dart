import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ir_rag_project/core/api_config.dart';
import 'package:ir_rag_project/data/models/library_models.dart';
import 'package:ir_rag_project/data/services/rag_api_client.dart';
import 'package:ir_rag_project/state/library_controller.dart';
import 'package:ir_rag_project/ui/library_screen.dart';
import 'package:ir_rag_project/ui/widgets/ingestion_progress_dialog.dart';
import 'package:material_ui/material_ui.dart';

RagApiClient _client(MockClient mock) {
  return RagApiClient(
    config: ApiConfig.from('http://127.0.0.1:8000'),
    httpClient: mock,
  );
}

IngestJob _job({
  required String status,
  required String stage,
  required double progress,
  String? documentId,
}) {
  return IngestJob(
    id: 'job1',
    url: 'https://example.com/tutorial',
    status: status,
    stage: stage,
    progress: progress,
    message: stage,
    documentId: documentId,
  );
}

DocumentLibrary _library() {
  return DocumentLibrary.fromJson({
    'documents': [
      {
        'id': 'doc1',
        'url': 'https://example.com/tutorial',
        'title': 'Example Tutorial',
        'chunk_count': 3,
        'word_count': 120,
        'size_bytes': 2400,
        'created_at': '2026-11-27T00:00:00Z',
        'status': 'ready',
      },
    ],
    'counts': {'documents': 1, 'chunks': 3, 'words': 120, 'ready_documents': 1},
  });
}

void main() {
  testWidgets('dialog shows the pipeline stages while the job runs', (
    tester,
  ) async {
    final controller = LibraryController(
      client: _client(MockClient((request) async => http.Response('{}', 200))),
    );
    controller.job = _job(status: 'running', stage: 'crawling', progress: 0.2);

    await tester.pumpWidget(
      MaterialApp(
        home: IngestionProgressDialog(
          controller: controller,
          url: 'https://example.com/tutorial',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Adding to corpus'), findsOneWidget);
    expect(find.text('example.com'), findsOneWidget);
    expect(find.text('Crawling'), findsOneWidget);
    expect(find.text('Preprocessing'), findsOneWidget);
    expect(find.text('Indexing'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('dialog replaces the pipeline with a ready message', (
    tester,
  ) async {
    final controller = LibraryController(
      client: _client(MockClient((request) async => http.Response('{}', 200))),
    );
    controller.library = _library();
    controller.job = _job(
      status: 'completed',
      stage: 'completed',
      progress: 1,
      documentId: 'doc1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: IngestionProgressDialog(
          controller: controller,
          url: 'https://example.com/tutorial',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Document is ready'), findsNWidgets(2));
    expect(find.textContaining('Example Tutorial'), findsOneWidget);
    expect(find.text('Crawling'), findsNothing);
  });

  testWidgets('dialog shows a clear failure state', (tester) async {
    final controller = LibraryController(
      client: _client(MockClient((request) async => http.Response('{}', 200))),
    );
    controller.job = _job(status: 'failed', stage: 'extracting', progress: 0.5);

    await tester.pumpWidget(
      MaterialApp(
        home: IngestionProgressDialog(
          controller: controller,
          url: 'https://example.com/tutorial',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Ingestion failed'), findsOneWidget);
    expect(find.text('extracting'), findsOneWidget);
    expect(find.text('Extraction'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('submitting a URL opens the animated dialog', (tester) async {
    final client = _client(
      MockClient((request) async {
        if (request.url.path == '/ingest') {
          return http.Response(
            jsonEncode({
              'job_id': 'job1',
              'url': 'https://example.com/tutorial',
              'status': 'queued',
              'stage': 'queued',
              'progress': 0.0,
              'message': 'Queued',
            }),
            202,
          );
        }
        if (request.url.path.startsWith('/ingest/')) {
          return http.Response(
            jsonEncode({
              'job_id': 'job1',
              'url': 'https://example.com/tutorial',
              'status': 'running',
              'stage': 'crawling',
              'progress': 0.2,
              'message': 'Fetching the page',
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'documents': [],
            'counts': {
              'documents': 0,
              'chunks': 0,
              'words': 0,
              'ready_documents': 0,
            },
          }),
          200,
        );
      }),
    );
    final controller = LibraryController(
      client: client,
      pollInterval: const Duration(milliseconds: 50),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: LibraryScreen(controller: controller)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(
      find.byType(TextField).first,
      'https://example.com/tutorial',
    );
    await tester.tap(find.text('Add to corpus'));

    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(IngestionProgressDialog), findsOneWidget);
    expect(find.text('Adding to corpus'), findsOneWidget);
    expect(find.text('Crawling'), findsOneWidget);
  });
}
