import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resultado guardado de una actividad.
class ActivityResult {
  ActivityResult({
    required this.activityId,
    required this.score,
    required this.max,
    required this.updatedAt,
  });

  final String activityId;
  final int score;
  final int max;
  final DateTime updatedAt;

  double get ratio => max == 0 ? 0 : score / max;
  bool get passed => ratio >= 0.7;

  Map<String, dynamic> toJson() => {
        'id': activityId,
        's': score,
        'm': max,
        't': updatedAt.millisecondsSinceEpoch,
      };

  static ActivityResult fromJson(Map<String, dynamic> j) => ActivityResult(
        activityId: j['id'] as String,
        score: (j['s'] as num).toInt(),
        max: (j['m'] as num).toInt(),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch((j['t'] as num).toInt()),
      );
}

/// Persistencia local de progreso y borradores de modelos ER.
class ProgressStore extends ChangeNotifier {
  ProgressStore._();
  static final ProgressStore instance = ProgressStore._();

  static const _kResults = 'dal_results_v1';
  static const _kDrafts = 'dal_drafts_v1';

  final Map<String, ActivityResult> _results = {};
  final Map<String, String> _drafts = {};
  SharedPreferences? _prefs;

  Map<String, ActivityResult> get results => Map.unmodifiable(_results);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_kResults);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final item in decoded) {
          final r = ActivityResult.fromJson(item as Map<String, dynamic>);
          _results[r.activityId] = r;
        }
      } catch (_) {
        _results.clear();
      }
    }
    final rawDrafts = _prefs?.getString(_kDrafts);
    if (rawDrafts != null && rawDrafts.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawDrafts) as Map<String, dynamic>;
        decoded.forEach((k, v) => _drafts[k] = v as String);
      } catch (_) {
        _drafts.clear();
      }
    }
    notifyListeners();
  }

  ActivityResult? resultFor(String activityId) => _results[activityId];

  /// Guarda el mejor intento: nunca degrada un puntaje anterior.
  Future<void> record(String activityId, int score, int max) async {
    final previous = _results[activityId];
    if (previous != null && previous.score >= score && previous.max == max) {
      return;
    }
    _results[activityId] = ActivityResult(
      activityId: activityId,
      score: score,
      max: max,
      updatedAt: DateTime.now(),
    );
    await _persistResults();
    notifyListeners();
  }

  Future<void> _persistResults() async {
    final list = _results.values.map((e) => e.toJson()).toList();
    await _prefs?.setString(_kResults, jsonEncode(list));
  }

  String? draft(String key) => _drafts[key];

  Future<void> saveDraft(String key, String value) async {
    _drafts[key] = value;
    await _prefs?.setString(_kDrafts, jsonEncode(_drafts));
  }

  Future<void> clearDraft(String key) async {
    _drafts.remove(key);
    await _prefs?.setString(_kDrafts, jsonEncode(_drafts));
  }

  Future<void> resetAll() async {
    _results.clear();
    _drafts.clear();
    await _prefs?.remove(_kResults);
    await _prefs?.remove(_kDrafts);
    notifyListeners();
  }
}
