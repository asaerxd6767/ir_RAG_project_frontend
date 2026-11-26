import 'package:flutter_test/flutter_test.dart';
import 'package:ir_rag_project/core/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('normalises trailing slashes', () {
      expect(
        ApiConfig.from('http://localhost:8000///').baseUrl,
        'http://localhost:8000',
      );
    });

    test('keeps an explicit port', () {
      expect(
        ApiConfig.from('https://rag.example.com:8443').baseUrl,
        'https://rag.example.com:8443',
      );
    });

    test('rejects incomplete, unsupported or path-bearing URLs', () {
      expect(() => ApiConfig.from('not a url'), throwsFormatException);
      expect(() => ApiConfig.from('ftp://example.com'), throwsFormatException);
      expect(() => ApiConfig.from('http://example.com/ask'), throwsFormatException);
      expect(() => ApiConfig.from('   '), throwsFormatException);
    });

    test('builds endpoint URIs from the base URL', () {
      final config = ApiConfig.from('http://127.0.0.1:8000/');
      expect(config.endpoint('/health').toString(), 'http://127.0.0.1:8000/health');
      expect(config.endpoint('/ask').toString(), 'http://127.0.0.1:8000/ask');
    });
  });
}
