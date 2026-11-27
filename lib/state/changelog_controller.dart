import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Map<String, List<String>> _changelog = <String, List<String>>{
  '1.3.0': <String>[
    'New Corpus tab: add pages by URL, follow ingestion progress, and remove documents.',
    'New Evaluation dashboard with retrieval, answer and corpus-health metrics.',
    'Ask, Corpus and Evaluation now share one backend URL setting.',
  ],
  '1.2.1': <String>[
    'Clearer Android connection help and HTTP support in release builds.',
  ],
  '1.2.0': <String>[
    'Brand-matched text selection and handles.',
    'Bottom content stays clear of the system navigation bar.',
    'A progress bar appears while the web app loads.',
    'Shared web links now show a preview card.',
    'Scrolling the question page dismisses the keyboard.',
    'Settings shows the installed app version.',
    'Friendly error view with copyable diagnostics.',
    'What\'s new is shown on the first open after an update.',
  ],
  '1.1.0': <String>[
    'Responsive two-pane layout and source cards.',
    'Configurable backend URL with a live health badge.',
  ],
  '1.0.0': <String>['First grounded IR-RAG answer screen.'],
};

class ChangelogController extends ChangeNotifier {
  String? _currentVersion;
  List<String>? _changes;

  List<String>? get changes => _changes;

  Future<void> initialize() async {
    final info = await PackageInfo.fromPlatform();
    final current = info.version;
    _currentVersion = current;

    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString('last_seen_version');

    if (lastSeen == null) {
      await prefs.setString('last_seen_version', current);
      return;
    }
    if (lastSeen == current) return;

    final changes = _unseenChanges(lastSeen, current);
    if (changes.isEmpty) {
      await prefs.setString('last_seen_version', current);
      return;
    }

    _changes = changes;
    notifyListeners();
  }

  List<String> _unseenChanges(String lastSeen, String current) {
    // A stored value from an older/dev build may not be a valid version. Never
    // let that turn into an unhandled error on app startup.
    Version last;
    Version now;
    try {
      last = Version.parse(lastSeen);
      now = Version.parse(current);
    } on FormatException {
      return <String>[];
    }
    final result = <String>[];
    for (final entry in _changelog.entries) {
      final version = Version.parse(entry.key);
      if (version > last && version <= now) {
        result.addAll(entry.value);
      }
    }
    return result;
  }

  Future<void> dismiss() async {
    final version = _currentVersion;
    if (version != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_seen_version', version);
    }
    _changes = null;
    notifyListeners();
  }
}
