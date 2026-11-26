# Fix: A broken widget shows an empty grey box

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/friendly-error-view
- **Needs new dependency**: none

## Why

If a widget fails to build in a release build, people see an empty grey box with no explanation. A friendly view in the app's own colors replaces it, and a hidden long-press copies the real exception for debugging without showing technical text to users.

## Where

`lib/main.dart:1-12` — current imports:

```dart
import 'package:material_ui/material_ui.dart';

import 'core/api_config.dart';
import 'data/services/rag_api_client.dart';
import 'state/ask_controller.dart';
import 'theme/app_theme.dart';
import 'ui/ask_screen.dart';

// ignore: unused_import
import 'package:flutter/foundation.dart';

import 'state/changelog_controller.dart';
```

`lib/main.dart:14-24` — `main()` where `ErrorWidget.builder` must be installed before `runApp`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = ApiConfig.from(kDefaultApiBaseUrl);
  final controller = AskController(
    config: config,
    client: RagApiClient(config: config),
  );

  runApp(IrRagApp(controller: controller));
}
```

There is no `ErrorWidget.builder` anywhere in the project. The previous `package:flutter/foundation.dart` import is redundant because `material_ui` re-exports the needed symbols, so remove it rather than adding or keeping a duplicate.

## The fix

Add a self-contained friendly error widget and install it globally at startup. In release builds show only "Something went wrong" and a restart hint. In debug builds also show the exception and stack trace. Long press anywhere copies the exception and stack to the clipboard with a brief haptic. The view adapts to the space it is given: full layout in a large slot, icon-only badge in a small one, and it supplies its own `Directionality` and transparent `Material` because it can appear outside a normal page tree.

Create `lib/ui/friendly_error_view.dart` with exactly this code:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart' show FlutterErrorDetails, kDebugMode;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Friendly replacement for Flutter's red error screen, installed via
/// [ErrorWidget.builder]. Release builds show no technical details; debug
/// builds add the exception and stack trace. A long press anywhere copies
/// the details to the clipboard.
class FriendlyErrorView extends StatefulWidget {
  const FriendlyErrorView({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  State<FriendlyErrorView> createState() => _FriendlyErrorViewState();
}

class _FriendlyErrorViewState extends State<FriendlyErrorView> {
  Timer? _timer;
  bool _copied = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    HapticFeedback.mediumImpact();

    await Clipboard.setData(
      ClipboardData(
        text: '${widget.details.exceptionAsString()}\n\n${widget.details.stack}',
      ),
    );

    if (!mounted) return;

    setState(() => _copied = true);

    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: Semantics(
          container: true,
          label: 'Something went wrong. Restarting the app should fix it.',
          child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: _copy,
              child: LayoutBuilder(
                builder: (context, c) {
                  final bool full = c.maxHeight.isFinite &&
                      c.maxHeight >= 320 &&
                      c.maxWidth.isFinite &&
                      c.maxWidth >= 300;

                  return Container(
                    width: c.hasBoundedWidth ? c.maxWidth : null,
                    height: c.hasBoundedHeight ? c.maxHeight : null,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(full ? 0 : 28),
                    ),
                    child: full
                        ? _FullView(details: widget.details, copied: _copied)
                        : _CompactView(details: widget.details, copied: _copied),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullView extends StatelessWidget {
  const _FullView({required this.details, required this.copied});

  final FlutterErrorDetails details;
  final bool copied;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    final Widget header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Badge(size: 104, copied: copied),
        const SizedBox(height: 24),
        Text(
          'Something went wrong',
          textAlign: TextAlign.center,
          style: tt.titleLarge?.copyWith(
            color: cs.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Restarting the app should fix it.',
          textAlign: TextAlign.center,
          style: tt.bodyMedium?.copyWith(
            color: cs.onPrimaryContainer.withValues(alpha: 0.75),
          ),
        ),
      ],
    );

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              32,
              (MediaQuery.maybePaddingOf(context)?.top ?? 0) + 32,
              32,
              (MediaQuery.maybePaddingOf(context)?.bottom ?? 0) + 32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                header,
                if (kDebugMode) ...[
                  const SizedBox(height: 32),
                  _DebugText('${details.exceptionAsString()}\n\n${details.stack}'),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactView extends StatelessWidget {
  const _CompactView({required this.details, required this.copied});

  final FlutterErrorDetails details;
  final bool copied;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Badge(size: 48, copied: copied),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: 240,
                  child: _DebugText(
                    details.exceptionAsString(),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.size, required this.copied});

  final double size;
  final bool copied;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: cs.primary,
        shape: const StarBorder(
          points: 12,
          innerRadiusRatio: 0.8,
          pointRounding: 0.7,
          valleyRounding: 0.3,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          copied ? Icons.check_rounded : Icons.priority_high_rounded,
          key: ValueKey<bool>(copied),
          color: cs.onPrimary,
          size: size * 0.4,
        ),
      ),
    );
  }
}

class _DebugText extends StatelessWidget {
  const _DebugText(this.text, {this.maxLines, this.textAlign});

  final String text;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Text(
      text,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: maxLines == null ? TextOverflow.fade : TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'monospace',
        fontFamilyFallback: const ['Menlo', 'Courier'],
        fontSize: 12,
        color: cs.onPrimaryContainer.withValues(alpha: 0.6),
      ),
    );
  }
}
```

In `lib/main.dart`, remove the redundant `package:flutter/foundation.dart` import and add one local import beside the other local imports:

```dart
import 'ui/friendly_error_view.dart';
```

Insert this line in `main()` after `WidgetsFlutterBinding.ensureInitialized();` and before the `config` line:

```dart
  ErrorWidget.builder = (FlutterErrorDetails details) => FriendlyErrorView(details: details);
```

Leave the rest of `main()` and `IrRagApp` unchanged.

## Steps

1. Create `lib/ui/friendly_error_view.dart` with the exact code above.
2. Remove the redundant `package:flutter/foundation.dart` import and add `ui/friendly_error_view.dart` beside the other local imports in `lib/main.dart`.
3. Add the `ErrorWidget.builder` assignment at the start of `main()`.
4. Run the checks below.

## Check it

`flutter analyze` exits clean. Scoped greps:

- `grep -c "ErrorWidget.builder" lib/main.dart` → 1
- `grep -c "package:flutter/foundation.dart" lib/main.dart` → 0
- `grep -c "class FriendlyErrorView" lib/ui/friendly_error_view.dart` → 1
- `grep -c "HitTestBehavior.opaque" lib/ui/friendly_error_view.dart` → 1

## Don't touch

- `lib/ui/widgets/result_panel.dart` — its `_ErrorView` is for backend failures, not widget build failures.
- `lib/theme/app_theme.dart` — the error view reads the existing color scheme; no theme changes.
- `lib/main.dart` beyond removing the redundant foundation import, adding the one `ui/friendly_error_view.dart` import, and the single `ErrorWidget.builder` assignment.
- No new dependencies.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
