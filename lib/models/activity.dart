import 'er_model.dart';

/// Competencias profesionales que declara el proyecto.
class Competency {
  static const modeling = 'Modelamiento entidad-relacion';
  static const normalization = 'Normalizacion';
  static const sql = 'Diseno y consulta SQL';
  static const management = 'Gestion de datos';
}

enum ActivityKind { concept, erDesign, normalization, sqlLab }

abstract class Activity {
  Activity({
    required this.id,
    required this.title,
    required this.summary,
    required this.competencies,
    this.minutes = 10,
  });

  final String id;
  final String title;
  final String summary;
  final List<String> competencies;
  final int minutes;

  ActivityKind get kind;

  /// Puntaje maximo de la actividad.
  int get maxScore;
}

// ---------------------------------------------------------------------------
// Actividad conceptual (opcion multiple con retroalimentacion razonada)
// ---------------------------------------------------------------------------

class Choice {
  const Choice(this.text, {this.correct = false, this.why = ''});
  final String text;
  final bool correct;
  final String why;
}

class Question {
  const Question({
    required this.id,
    required this.prompt,
    required this.choices,
    this.context = '',
    this.takeaway = '',
  });

  final String id;
  final String prompt;
  final String context;
  final List<Choice> choices;
  final String takeaway;

  int get correctIndex => choices.indexWhere((c) => c.correct);
}

class ConceptActivity extends Activity {
  ConceptActivity({
    required super.id,
    required super.title,
    required super.summary,
    required super.competencies,
    required this.questions,
    super.minutes,
  });

  final List<Question> questions;

  @override
  ActivityKind get kind => ActivityKind.concept;

  @override
  int get maxScore => questions.length;
}

// ---------------------------------------------------------------------------
// Actividad de diseno ER (rubrica automatica)
// ---------------------------------------------------------------------------

class RequiredAttribute {
  const RequiredAttribute(this.aliases, {this.mustBePk = false, this.points = 1});
  final List<String> aliases;
  final bool mustBePk;
  final int points;
  String get display => aliases.first;
}

class RequiredEntity {
  const RequiredEntity({
    required this.key,
    required this.aliases,
    this.attributes = const <RequiredAttribute>[],
    this.needsPrimaryKey = true,
    this.points = 2,
    this.note = '',
  });

  final String key;
  final List<String> aliases;
  final List<RequiredAttribute> attributes;
  final bool needsPrimaryKey;
  final int points;
  final String note;
}

class RequiredRelation {
  const RequiredRelation({
    required this.fromKey,
    required this.toKey,
    required this.fromCard,
    required this.toCard,
    this.points = 3,
    this.description = '',
  });

  final String fromKey;
  final String toKey;
  final Cardinality fromCard;
  final Cardinality toCard;
  final int points;
  final String description;
}

class ErRubric {
  const ErRubric({
    required this.entities,
    required this.relations,
    this.cleanDesignPoints = 4,
  });

  final List<RequiredEntity> entities;
  final List<RequiredRelation> relations;

  /// Puntos otorgados cuando el analizador no encuentra errores graves.
  final int cleanDesignPoints;

  int get total {
    var sum = cleanDesignPoints;
    for (final e in entities) {
      sum += e.points;
      if (e.needsPrimaryKey) sum += 1;
      for (final a in e.attributes) {
        sum += a.points;
      }
    }
    for (final r in relations) {
      sum += r.points;
    }
    return sum;
  }
}

class ErDesignActivity extends Activity {
  ErDesignActivity({
    required super.id,
    required super.title,
    required super.summary,
    required super.competencies,
    required this.brief,
    required this.requirements,
    required this.rubric,
    this.hints = const <String>[],
    super.minutes,
  });

  final String brief;
  final List<String> requirements;
  final ErRubric rubric;
  final List<String> hints;

  @override
  ActivityKind get kind => ActivityKind.erDesign;

  @override
  int get maxScore => rubric.total;
}

// ---------------------------------------------------------------------------
// Actividad de normalizacion
// ---------------------------------------------------------------------------

class Fd {
  const Fd(this.determinant, this.dependents);
  final List<String> determinant;
  final List<String> dependents;

  String get display =>
      '${determinant.join(', ')} -> ${dependents.join(', ')}';
}

class ExpectedTable {
  const ExpectedTable({
    required this.name,
    required this.primaryKey,
    required this.attributes,
  });

  final String name;
  final List<String> primaryKey;
  final List<String> attributes;
}

class NormalizationActivity extends Activity {
  NormalizationActivity({
    required super.id,
    required super.title,
    required super.summary,
    required super.competencies,
    required this.brief,
    required this.sampleRows,
    required this.attributes,
    required this.fds,
    required this.expected,
    this.targetForm = '3FN',
    super.minutes,
  });

  final String brief;

  /// Filas de ejemplo (encabezado + datos) que evidencian las anomalias.
  final List<List<String>> sampleRows;
  final List<String> attributes;
  final List<Fd> fds;
  final List<ExpectedTable> expected;
  final String targetForm;

  @override
  ActivityKind get kind => ActivityKind.normalization;

  @override
  int get maxScore => expected.length * 10;
}

// ---------------------------------------------------------------------------
// Laboratorio SQL
// ---------------------------------------------------------------------------

class SqlTask {
  const SqlTask({
    required this.id,
    required this.prompt,
    required this.solution,
    this.ordered = false,
    this.mustContain = const <String>[],
    this.forbid = const <String>[],
    this.verify,
    this.hint = '',
    this.points = 1,
  });

  final String id;
  final String prompt;

  /// Consulta de referencia. Se ejecuta en el motor para obtener el
  /// resultado esperado: la evaluacion nunca depende de datos escritos a mano.
  final String solution;
  final bool ordered;
  final List<String> mustContain;
  final List<String> forbid;

  /// Para tareas DDL/DML: consulta que verifica el estado final.
  final String? verify;
  final String hint;
  final int points;
}

class SqlLabActivity extends Activity {
  SqlLabActivity({
    required super.id,
    required super.title,
    required super.summary,
    required super.competencies,
    required this.scenario,
    required this.schemaName,
    required this.tasks,
    super.minutes,
  });

  final String scenario;

  /// Nombre del esquema semilla declarado en `content/schemas.dart`.
  final String schemaName;
  final List<SqlTask> tasks;

  @override
  ActivityKind get kind => ActivityKind.sqlLab;

  @override
  int get maxScore =>
      tasks.fold<int>(0, (previous, task) => previous + task.points);
}

// ---------------------------------------------------------------------------
// Modulo
// ---------------------------------------------------------------------------

class LabModule {
  const LabModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.goal,
    required this.activities,
  });

  final String id;
  final String title;
  final String subtitle;
  final String goal;
  final List<Activity> activities;
}
