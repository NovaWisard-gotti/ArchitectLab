import '../models/activity.dart';
import 'design_advisor.dart';

/// Tabla propuesta por el estudiante durante la descomposicion.
class StudentTable {
  StudentTable({required this.name, Set<String>? attributes, Set<String>? pk})
      : attributes = attributes ?? <String>{},
        primaryKey = pk ?? <String>{};

  String name;
  final Set<String> attributes;
  final Set<String> primaryKey;

  StudentTable copy() => StudentTable(
        name: name,
        attributes: Set<String>.from(attributes),
        pk: Set<String>.from(primaryKey),
      );
}

class NormIssue {
  const NormIssue({
    required this.severity,
    required this.title,
    required this.message,
    this.fix = '',
  });

  final Severity severity;
  final String title;
  final String message;
  final String fix;
}

class NormReport {
  const NormReport({
    required this.items,
    required this.issues,
    required this.earned,
    required this.possible,
    required this.reachedForm,
  });

  final List<RubricItem> items;
  final List<NormIssue> issues;
  final int earned;
  final int possible;

  /// Forma normal maxima que alcanza la propuesta del estudiante.
  final String reachedForm;

  double get ratio => possible == 0 ? 0 : earned / possible;
  bool get passed => ratio >= 0.7;
}

/// Evaluador de normalizacion.
///
/// No compara solo contra una respuesta modelo: tambien verifica las
/// dependencias funcionales declaradas en el ejercicio, de modo que el
/// estudiante recibe el motivo tecnico de cada violacion.
class NormalizationEvaluator {
  static NormReport evaluate({
    required NormalizationActivity activity,
    required List<StudentTable> tables,
  }) {
    final items = <RubricItem>[];
    final issues = <NormIssue>[];
    final possible = activity.maxScore;
    var earned = 0;

    final usable =
        tables.where((t) => t.attributes.isNotEmpty).toList(growable: false);

    if (usable.isEmpty) {
      return NormReport(
        items: const [],
        issues: const [
          NormIssue(
            severity: Severity.info,
            title: 'Aun no hay tablas',
            message: 'Crea al menos una tabla y asignale atributos.',
          )
        ],
        earned: 0,
        possible: possible,
        reachedForm: 'Sin evaluar',
      );
    }

    // 1. Cobertura de atributos.
    final assigned = <String>{};
    for (final t in usable) {
      assigned.addAll(t.attributes.map(DesignAdvisor.normalize));
    }
    final missing = activity.attributes
        .where((a) => !assigned.contains(DesignAdvisor.normalize(a)))
        .toList();
    if (missing.isNotEmpty) {
      issues.add(NormIssue(
        severity: Severity.error,
        title: 'Atributos sin ubicar',
        message: 'Quedaron fuera del diseno: ${missing.join(', ')}.',
        fix: 'Todo atributo del enunciado debe pertenecer a alguna tabla.',
      ));
    }

    // 2. Claves primarias declaradas.
    for (final t in usable) {
      if (t.primaryKey.isEmpty) {
        issues.add(NormIssue(
          severity: Severity.error,
          title: 'La tabla ${t.name} no tiene clave primaria',
          message: 'Sin clave no se puede evaluar si hay dependencias '
              'parciales o transitivas.',
          fix: 'Marca como PK el atributo (o combinacion) que identifica '
              'cada fila.',
        ));
      }
    }

    // 3. Violaciones de forma normal usando las dependencias del enunciado.
    var has2nfViolation = false;
    var has3nfViolation = false;
    for (final t in usable) {
      final attrs = t.attributes.map(DesignAdvisor.normalize).toSet();
      final key = t.primaryKey.map(DesignAdvisor.normalize).toSet();
      if (key.isEmpty) continue;

      for (final fd in activity.fds) {
        final det = fd.determinant.map(DesignAdvisor.normalize).toSet();
        final dep = fd.dependents.map(DesignAdvisor.normalize).toSet();
        if (!attrs.containsAll(det)) continue;
        final depInside = dep.intersection(attrs);
        if (depInside.isEmpty) continue;
        final nonPrimeDep = depInside.difference(key);
        if (nonPrimeDep.isEmpty) continue;

        final detIsProperSubsetOfKey =
            key.containsAll(det) && det.length < key.length;
        final detIsSuperKey = det.containsAll(key);

        if (detIsProperSubsetOfKey) {
          has2nfViolation = true;
          issues.add(NormIssue(
            severity: Severity.error,
            title: 'Dependencia parcial en ${t.name}',
            message: '${fd.display} depende solo de una parte de la clave '
                '(${t.primaryKey.join(', ')}), lo que rompe la 2FN.',
            fix: 'Mueve ${nonPrimeDep.join(', ')} a una tabla cuya clave sea '
                '${fd.determinant.join(', ')}.',
          ));
        } else if (!detIsSuperKey && !key.containsAll(det)) {
          has3nfViolation = true;
          issues.add(NormIssue(
            severity: Severity.error,
            title: 'Dependencia transitiva en ${t.name}',
            message: '${fd.display} parte de un atributo que no es clave, '
                'lo que rompe la 3FN.',
            fix: 'Separa ${fd.determinant.join(', ')} y sus dependientes en '
                'una tabla propia y deja la referencia como clave foranea.',
          ));
        }
      }
    }

    // 4. Comparacion con la descomposicion de referencia.
    final available = List<StudentTable>.from(usable);
    for (final expected in activity.expected) {
      final expectedAttrs =
          expected.attributes.map(DesignAdvisor.normalize).toSet();
      final expectedPk =
          expected.primaryKey.map(DesignAdvisor.normalize).toSet();

      StudentTable? best;
      var bestScore = 0.0;
      for (final candidate in available) {
        final s = _jaccard(
          candidate.attributes.map(DesignAdvisor.normalize).toSet(),
          expectedAttrs,
        );
        if (s > bestScore) {
          bestScore = s;
          best = candidate;
        }
      }

      if (best == null || bestScore < 0.25) {
        items.add(RubricItem(
          label: 'Tabla ${expected.name}',
          earned: 0,
          possible: 10,
          comment: 'No se identifico una tabla equivalente. Se esperaba una '
              'con ${expected.attributes.join(', ')}.',
        ));
        continue;
      }
      available.remove(best);

      final studentAttrs =
          best.attributes.map(DesignAdvisor.normalize).toSet();
      final studentPk =
          best.primaryKey.map(DesignAdvisor.normalize).toSet();
      final attrPoints = (bestScore * 6).round().clamp(0, 6);
      final pkOk = studentPk.isNotEmpty &&
          studentPk.length == expectedPk.length &&
          studentPk.containsAll(expectedPk);
      final pkPoints = pkOk ? 4 : (studentPk.intersection(expectedPk).isEmpty ? 0 : 2);
      earned += attrPoints + pkPoints;

      final extra = studentAttrs.difference(expectedAttrs);
      final lacking = expectedAttrs.difference(studentAttrs);
      final notes = <String>[];
      if (lacking.isNotEmpty) notes.add('faltan: ${lacking.join(', ')}');
      if (extra.isNotEmpty) notes.add('sobran: ${extra.join(', ')}');
      if (!pkOk) {
        notes.add('clave esperada: ${expected.primaryKey.join(', ')}');
      }

      items.add(RubricItem(
        label: 'Tabla ${expected.name}',
        earned: attrPoints + pkPoints,
        possible: 10,
        comment: notes.isEmpty
            ? 'Descomposicion correcta en "${best.name}".'
            : 'En "${best.name}": ${notes.join(' | ')}.',
      ));
    }

    if (available.isNotEmpty) {
      issues.add(NormIssue(
        severity: Severity.warning,
        title: 'Tablas adicionales',
        message: 'Sobran ${available.length} tabla(s): '
            '${available.map((t) => t.name).join(', ')}.',
        fix: 'Fragmentar de mas obliga a reconstruir la informacion con '
            'uniones innecesarias.',
      ));
      earned = (earned - 2 * available.length).clamp(0, possible);
    }

    if (missing.isNotEmpty) {
      earned = (earned - 3 * missing.length).clamp(0, possible);
    }

    final reached = has2nfViolation
        ? '1FN'
        : has3nfViolation
            ? '2FN'
            : '3FN';

    if (issues.isEmpty) {
      issues.add(const NormIssue(
        severity: Severity.praise,
        title: 'Descomposicion consistente',
        message: 'Ninguna tabla presenta dependencias parciales ni '
            'transitivas segun las dependencias declaradas.',
      ));
    }

    return NormReport(
      items: items,
      issues: issues,
      earned: earned,
      possible: possible,
      reachedForm: reached,
    );
  }

  static double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 1;
    final inter = a.intersection(b).length;
    final union = a.union(b).length;
    return union == 0 ? 0 : inter / union;
  }
}
