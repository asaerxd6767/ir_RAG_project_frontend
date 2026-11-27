import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ir_rag_project/core/api_config.dart';
import 'package:ir_rag_project/data/services/rag_api_client.dart';
import 'package:ir_rag_project/main.dart';
import 'package:ir_rag_project/state/ask_controller.dart';
import 'package:ir_rag_project/theme/app_theme.dart';
import 'package:ir_rag_project/ui/ask_screen.dart';
import 'package:material_ui/material_ui.dart';

AskController _controller(MockClient client) {
  final config = ApiConfig.from('http://127.0.0.1:8000');
  return AskController(
    config: config,
    client: RagApiClient(config: config, httpClient: client),
  );
}

void main() {
  testWidgets('opening settings from the app does not crash', (tester) async {
    final controller = _controller(
      MockClient((request) async => http.Response('{"status":"ok"}', 200)),
    );

    await tester.pumpWidget(IrRagApp(controller: controller));
    await tester.pump();

    await tester.tap(find.byTooltip('Backend settings'));
    await tester.pumpAndSettle();

    expect(find.text('Backend settings'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('settings warns about loopback URLs on Android', (tester) async {
    final controller = _controller(
      MockClient((request) async => http.Response('{"status":"ok"}', 200)),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light().copyWith(platform: TargetPlatform.android),
        home: AskScreen(controller: controller, onToggleTheme: () {}),
      ),
    );
    await tester.tap(find.byTooltip('Backend settings'));
    await tester.pumpAndSettle();

    expect(find.textContaining('127.0.0.1 points to the phone itself'), findsOneWidget);
  });

  testWidgets('the ask button keeps its full-width layout', (tester) async {
    final controller = _controller(
      MockClient((request) async => http.Response('{"status":"ok"}', 200)),
    );

    await tester.pumpWidget(IrRagApp(controller: controller));
    await tester.pump();

    final button = find.widgetWithText(FilledButton, 'Ask the corpus');
    expect(button, findsOneWidget);
    expect(tester.getSize(button).width, greaterThan(240));
  });
}
