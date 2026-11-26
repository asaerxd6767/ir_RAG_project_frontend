import 'package:flutter/foundation.dart';

import '../core/api_config.dart';
import '../core/api_exception.dart';
import '../core/settings_store.dart';
import '../data/models/ask_response.dart';
import '../data/models/health_status.dart';
import '../data/services/rag_api_client.dart';

enum AskState { idle, loading, success, refusal, error }

/// Holds everything the UI needs and exposes it through [Listenable].
class AskController extends ChangeNotifier {
  AskController({
    required this._config,
    required this._client,
    SettingsStore? settings,
  }) : _settings = settings ?? SettingsStore();

  ApiConfig _config;
  RagApiClient _client;
  final SettingsStore _settings;

  AskState state = AskState.idle;
  AskResponse? response;
  String? errorMessage;
  HealthStatus? health;
  String? healthError;
  bool isCheckingHealth = false;
  final List<String> recentQuestions = <String>[];

  ApiConfig get config => _config;
  bool get isLoading => state == AskState.loading;
  bool get isBackendHealthy => health?.isOk ?? false;

  Future<void> initialize() async {
    final saved = await _settings.readBaseUrl();
    if (saved != null && saved.trim().isNotEmpty) {
      try {
        await applyBaseUrl(saved, checkHealth: false);
      } on FormatException {
        // Ignore a stale/invalid saved URL and fall back to the default.
      }
    }
    await refreshHealth();
  }

  Future<void> refreshHealth() async {
    isCheckingHealth = true;
    healthError = null;
    notifyListeners();
    try {
      health = await _client.getHealth();
      if (!health!.isOk) {
        healthError = health?.detail ?? 'Backend reported an unhealthy state.';
      }
    } on ApiException catch (error) {
      health = null;
      healthError = error.message;
    } finally {
      isCheckingHealth = false;
      notifyListeners();
    }
  }

  Future<void> ask(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    state = AskState.loading;
    response = null;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _client.ask(trimmed);
      response = result;
      state = result.isRefusal ? AskState.refusal : AskState.success;
      if (!recentQuestions.contains(trimmed)) {
        recentQuestions.insert(0, trimmed);
        if (recentQuestions.length > 5) recentQuestions.removeLast();
      }
    } on ApiException catch (error) {
      state = AskState.error;
      errorMessage = error.message;
      health = null;
      healthError = error.message;
    } finally {
      notifyListeners();
    }
  }

  Future<void> applyBaseUrl(String rawUrl, {bool checkHealth = true}) async {
    final config = ApiConfig.from(rawUrl);
    _client.dispose();
    _config = config;
    _client = RagApiClient(config: config);
    await _settings.saveBaseUrl(config.baseUrl);
    if (checkHealth) {
      await refreshHealth();
    } else {
      notifyListeners();
    }
  }

  void reset() {
    state = AskState.idle;
    response = null;
    errorMessage = null;
    notifyListeners();
  }
}
