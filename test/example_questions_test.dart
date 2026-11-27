import 'package:flutter_test/flutter_test.dart';
import 'package:ir_rag_project/core/example_questions.dart';
import 'package:ir_rag_project/data/models/library_models.dart';
import 'package:ir_rag_project/ui/widgets/question_composer.dart';
import 'package:material_ui/material_ui.dart';

LibraryDocument _document({
  required String id,
  required String title,
  required String url,
}) {
  return LibraryDocument(
    id: id,
    url: url,
    title: title,
    chunkCount: 3,
    wordCount: 120,
    sizeBytes: 2400,
    createdAt: '2026-11-27T00:00:00Z',
    status: 'ready',
  );
}

void main() {
  test('Python document uses grounded Python examples', () {
    final examples = ExampleQuestions.forDocument(
      _document(
        id: 'p001',
        title: 'The Python Tutorial — Python 3.15.2 documentation',
        url: 'https://docs.python.org/3/tutorial/',
      ),
    );

    expect(examples, ExampleQuestions.python);
    expect(examples, contains('What is Python?'));
    expect(examples, contains('Can Python be extended with C or C++?'));
  });

  test('other documents get title-based examples', () {
    final examples = ExampleQuestions.forText(
      'Cancer - Wikipedia',
      'https://en.wikipedia.org/wiki/Cancer',
    );

    expect(examples, contains('What is Cancer?'));
    expect(examples, contains('What is Cancer - Wikipedia?'));
    expect(examples, contains('What is Cancer used for?'));
  });

  testWidgets('composer shows supplied ideas and prefills pending question', (
    tester,
  ) async {
    String? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: QuestionComposer(
          onSubmit: (question) async {
            submitted = question;
          },
          isLoading: false,
          recentQuestions: const <String>[],
          suggestions: const <String>[
            'What is Python?',
            'What is Python used for?',
          ],
          pendingQuestion: 'Can Python be extended with C or C++?',
        ),
      ),
    );

    expect(find.text('What is Python?'), findsOneWidget);
    expect(find.text('What is Python used for?'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Can Python be extended with C or C++?',
    );

    await tester.tap(find.text('What is Python?'));
    await tester.pump();

    expect(submitted, 'What is Python?');
  });
}
