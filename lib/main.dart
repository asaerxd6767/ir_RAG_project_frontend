import 'package:material_ui/material_ui.dart';

import 'core/api_config.dart';
import 'data/services/rag_api_client.dart';
import 'state/ask_controller.dart';
import 'theme/app_theme.dart';
import 'ui/ask_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = ApiConfig.from(kDefaultApiBaseUrl);
  final controller = AskController(
    config: config,
    client: RagApiClient(config: config),
  );

  runApp(IrRagApp(controller: controller));
}

class IrRagApp extends StatefulWidget {
  const IrRagApp({super.key, required this.controller});

  final AskController controller;

  @override
  State<IrRagApp> createState() => _IrRagAppState();
}

class _IrRagAppState extends State<IrRagApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    widget.controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IR RAG Assistant',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: AskScreen(
        controller: widget.controller,
        onToggleTheme: () {
          setState(() {
            _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          });
        },
      ),
    );
  }
}
