import 'package:flutter/foundation.dart';

import '../data/models/library_models.dart';
import '../data/services/rag_api_client.dart';

/// Loads the evaluation snapshot shown on the dashboard tab.
class EvaluationController extends ChangeNotifier {
  EvaluationController({required this.client});

  final RagApiClient client;

  EvaluationSnapshot? snapshot;
  String? error;
  bool isLoading = false;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      snapshot = await client.getEvaluation();
    } on Object catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
