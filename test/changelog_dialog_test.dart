import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ir_rag_project/core/api_config.dart';
import 'package:ir_rag_project/data/services/rag_api_client.dart';
import 'package:ir_rag_project/main.dart';
import 'package:ir_rag_project/state/ask_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

AskController _controller() {
  final config = ApiConfig.from('http://127.0.0.1:8000');
  return AskController(
    config: config,
    client: RagApiClient(
      config: config,
      httpClient: MockClient(
        (request) async => http.Response('{"status":"ok"}', 200),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_seen_version': '1.2.1',
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/package_info'),
          (call) async {
            if (call.method == 'getAll') {
              return <String, dynamic>{
                'appName': 'IR RAG Assistant',
                'packageName': 'com.example.irrag',
                'version': '1.3.0',
                'buildNumber': '5',
              };
            }
            return null;
          },
        );
  });

  testWidgets("What's new renders after an upgrade without a Navigator error", (
    tester,
  ) async {
    await tester.pumpWidget(IrRagApp(controller: _controller()));
    await tester.pumpAndSettle();

    expect(find.text("What's new"), findsOneWidget);
    expect(find.textContaining('New Corpus tab'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets("Got it dismisses the dialog and records the version", (
    tester,
  ) async {
    await tester.pumpWidget(IrRagApp(controller: _controller()));
    await tester.pumpAndSettle();
    expect(find.text("What's new"), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text("What's new"), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('last_seen_version'), '1.3.0');
  });
}
