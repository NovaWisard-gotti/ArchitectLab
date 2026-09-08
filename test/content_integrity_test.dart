import 'package:database_architect_lab/content/catalog.dart';
import 'package:database_architect_lab/content/schemas.dart';
import 'package:database_architect_lab/models/activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los identificadores de actividad son unicos', () {
    final ids = Curriculum.allActivities.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('cada pregunta tiene exactamente una alternativa correcta', () {
    for (final activity in Curriculum.allActivities) {
      if (activity is! ConceptActivity) continue;
      for (final question in activity.questions) {
        final correct = question.choices.where((c) => c.correct).length;
        expect(correct, 1, reason: 'Pregunta ${question.id}');
        expect(question.choices.length, greaterThanOrEqualTo(3));
        final answer = question.choices[question.correctIndex];
        expect(answer.why.isNotEmpty, isTrue, reason: question.id);
      }
    }
  });

  test('las tareas SQL declaran solucion y esquema conocido', () {
    for (final activity in Curriculum.allActivities) {
      if (activity is! SqlLabActivity) continue;
      expect(LabSchemas.byName(activity.schemaName).isNotEmpty, isTrue);
      for (final task in activity.tasks) {
        expect(task.solution.trim().isNotEmpty, isTrue, reason: task.id);
        expect(task.points, greaterThan(0));
      }
    }
  });

  test('las actividades de normalizacion cubren todos sus atributos', () {
    for (final activity in Curriculum.allActivities) {
      if (activity is! NormalizationActivity) continue;
      final covered = <String>{};
      for (final table in activity.expected) {
        covered.addAll(table.attributes);
        expect(
          table.attributes.toSet().containsAll(table.primaryKey),
          isTrue,
          reason: '${activity.id} / ${table.name}',
        );
      }
      expect(covered.containsAll(activity.attributes), isTrue,
          reason: activity.id);
    }
  });

  test('las rubricas ER tienen puntaje positivo', () {
    for (final activity in Curriculum.allActivities) {
      if (activity is! ErDesignActivity) continue;
      expect(activity.rubric.total, greaterThan(10), reason: activity.id);
      expect(activity.requirements.isNotEmpty, isTrue);
    }
  });

  test('el curriculo declara puntaje total', () {
    expect(Curriculum.totalPoints, greaterThan(100));
    expect(Curriculum.modules.length, 6);
  });
}
