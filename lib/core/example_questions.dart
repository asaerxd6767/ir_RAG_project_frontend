import '../data/models/library_models.dart';

/// Suggestions that are answerable from documents this app actually indexes.
class ExampleQuestions {
  const ExampleQuestions._();

  /// Questions grounded in the Python tutorial landing page that is kept in
  /// the corpus by default.
  static const List<String> python = <String>[
    'What is Python?',
    'What is Python used for?',
    'Can Python be extended with C or C++?',
    'What topics does the tutorial cover?',
  ];

  /// Turn a page title into the subject it describes, e.g.
  /// `Cancer - Wikipedia` → `Cancer`.
  static String _subject(String title, String url) {
    var text = title.trim();
    for (final separator in <String>[' - ', ' — ', ' – ', ' | ', ': ']) {
      final parts = text.split(separator);
      if (parts.length > 1) {
        text = parts.first.trim();
        break;
      }
    }
    if (text.isEmpty || text.toLowerCase() == 'document') {
      final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
      final last = segments.where((part) => part.isNotEmpty).lastOrNull ?? '';
      text = last
          .replaceAll(RegExp(r'\.(html?|php|aspx?)$'), '')
          .replaceAll(RegExp(r'[_-]+'), ' ')
          .trim();
    }
    return text.isEmpty ? 'this page' : text;
  }

  static List<String> forText(String title, String url) {
    final haystack = '$title $url'.toLowerCase();
    if (haystack.contains('python') || haystack.contains('docs.python.org')) {
      return python;
    }
    final subject = _subject(title, url);
    return <String>{
      'What is $subject?',
      'What is $title?',
      'What is $subject used for?',
    }.toList();
  }

  static List<String> forDocument(LibraryDocument document) =>
      forText(document.displayTitle, document.url);

  static List<String> forLibrary(DocumentLibrary? library) {
    final suggestions = <String>{};
    for (final document in library?.documents ?? const <LibraryDocument>[]) {
      suggestions.addAll(forDocument(document));
    }
    return suggestions.isEmpty ? python : suggestions.toList();
  }
}
