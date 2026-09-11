import '../models/activity.dart';
import 'module_cases.dart';
import 'module_er.dart';
import 'module_nosql.dart';
import 'module_norm.dart';
import 'module_postgres.dart';
import 'module_sql.dart';

/// Ruta completa del laboratorio, en el orden pedagógico previsto.
class Curriculum {
  static final List<LabModule> modules = [
    moduleEr,
    moduleNorm,
    moduleSql,
    modulePostgres,
    moduleNoSql,
    moduleCases,
  ];

  static final List<Activity> allActivities =
      modules.expand((m) => m.activities).toList(growable: false);

  static LabModule? moduleOf(String activityId) {
    for (final m in modules) {
      if (m.activities.any((a) => a.id == activityId)) return m;
    }
    return null;
  }

  static Activity? activityById(String id) {
    for (final a in allActivities) {
      if (a.id == id) return a;
    }
    return null;
  }

  static int get totalPoints =>
      allActivities.fold<int>(0, (sum, a) => sum + a.maxScore);

  static const competencies = <String>[
    Competency.modeling,
    Competency.normalization,
    Competency.sql,
    Competency.management,
  ];
}
