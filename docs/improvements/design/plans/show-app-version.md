# Fix: There is no way to see which version is installed

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/show-app-version
- **Needs new dependency**: none (`package_info_plus: ^10.2.0` is already declared; read app name, version and build number at runtime)

## Why

When a user reports a problem with the RAG app, nobody can tell which build they are running. The settings dialog is the natural place for a dim version line that shows the version and build number together.

## Where

`lib/ui/settings_dialog.dart:1-4` — current imports:

```dart
import 'package:material_ui/material_ui.dart';

import '../core/api_config.dart';
import '../state/ask_controller.dart';
```

`lib/ui/settings_dialog.dart:15-25` — dialog state and `initState`:

```dart
class _SettingsDialogState extends State<SettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.controller.config.baseUrl);
  }
```

`lib/ui/settings_dialog.dart:122-143` — the last block in the dialog column, where the version line goes after it:

```dart
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      ...
                    ),
                  ],
                ),
```

## The fix

Read `PackageInfo.fromPlatform()` once when the dialog opens and show `appName version (buildNumber)` as a small, dim, left-aligned line at the very bottom of the dialog. There is no Shorebird dependency in this project, so no patch number is shown. Match the existing file's style: `setState` with a `mounted` guard, and colors from `Theme.of(context).colorScheme`.

Add this import after the existing package import:

```dart
import 'package:package_info_plus/package_info_plus.dart';
```

In `_SettingsDialogState`, add the field and start the load in `initState`:

```dart
  String? _versionLabel;
```

```dart
  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.controller.config.baseUrl);
    _loadVersion();
  }
```

Add this method directly after `initState`:

```dart
  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _versionLabel = '${info.appName} ${info.version} (${info.buildNumber})';
    });
  }
```

At the end of the `Column`'s `children` list, immediately after the `Row(...)` shown in "Where", add:

```dart
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
```

Leave the form, the Save & test button and the controller untouched.

## Steps

1. No pubspec change is needed: `package_info_plus: ^10.2.0` is already declared. Run `flutter pub get`.
2. Add the `package_info_plus` import to `lib/ui/settings_dialog.dart`.
3. Add the `_versionLabel` field, the `_loadVersion()` call in `initState`, and the `_loadVersion()` method.
4. Append the conditional version line to the bottom of the dialog's `Column`.
5. Run the checks below.

## Check it

`flutter analyze` exits clean. Scoped greps:

- `grep -c "PackageInfo.fromPlatform" lib/ui/settings_dialog.dart` → 1
- `grep -c "_versionLabel" lib/ui/settings_dialog.dart` → 4
- `grep -c "fontFeatures: const \[FontFeature.tabularFigures()\]" lib/ui/settings_dialog.dart` → 1

## Don't touch

- `lib/ui/ask_screen.dart` — the version line belongs in the settings dialog only.
- `pubspec.yaml` version string — do not bump the app version as part of this fix.
- No other dependencies.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
