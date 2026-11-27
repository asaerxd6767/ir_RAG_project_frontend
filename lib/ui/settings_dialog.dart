import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/api_config.dart';
import '../state/ask_controller.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key, required this.controller});

  final AskController controller;

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  String? _error;
  bool _saving = false;
  String? _versionLabel;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: widget.controller.config.baseUrl,
    );
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _versionLabel = '${info.appName} ${info.version} (${info.buildNumber})';
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.applyBaseUrl(_urlController.text);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _saving = false;
      });
    }
  }

  String? _androidConnectionHint(BuildContext context) {
    if (Theme.of(context).platform != TargetPlatform.android) return null;
    final host =
        Uri.tryParse(widget.controller.config.baseUrl)?.host.toLowerCase() ??
        '';
    if (host == '10.0.2.2') {
      return '10.0.2.2 only works in the Android emulator. On a physical phone, '
          'run adb reverse tcp:8000 tcp:8000 and use http://127.0.0.1:8000, '
          'or enter your computer’s Wi-Fi IP (e.g. http://192.168.1.10:8000).';
    }
    if (host == '127.0.0.1' || host == 'localhost' || host == '::1') {
      return 'On Android, 127.0.0.1 points to the phone itself. Run '
          'adb reverse tcp:8000 tcp:8000 to tunnel over USB with this URL, '
          'or enter your computer’s Wi-Fi IP. The emulator uses '
          'http://10.0.2.2:8000.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final androidHint = _androidConnectionHint(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings_ethernet_rounded,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Backend settings',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Point the app at your Python RAG server. The URL is saved on this device.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Backend base URL',
                      hintText: 'http://127.0.0.1:8000',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    validator: (value) {
                      try {
                        ApiConfig.from(value ?? '');
                        return null;
                      } on FormatException catch (error) {
                        return error.message;
                      }
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: TextStyle(color: scheme.error, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (androidHint != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        androidHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onErrorContainer,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'For Wi-Fi use, start the backend on 0.0.0.0:8000. Over USB, '
                      'adb reverse tcp:8000 tcp:8000 works without network changes. '
                      'A build-time default can be set with '
                      '--dart-define=API_BASE_URL=...',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Save & test'),
                      ),
                    ],
                  ),
                  if (_versionLabel != null) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _versionLabel!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: Theme.of(context).colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
