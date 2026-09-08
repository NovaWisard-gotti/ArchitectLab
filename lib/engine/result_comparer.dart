import 'sql_engine.dart';

/// Veredicto de la evaluacion automatica de una consulta.
class SqlVerdict {
  const SqlVerdict({
    required this.passed,
    required this.title,
    required this.detail,
    this.hintsFailed = const <String>[],
  });

  final bool passed;
  final String title;
  final String detail;
  final List<String> hintsFailed;
}

/// Comparacion de conjuntos de resultados. Es logica pura: se puede probar
/// sin dispositivo ni base de datos.
class ResultComparer {
  static const double tolerance = 1e-6;

  static SqlVerdict compare({
    required SqlResult student,
    required SqlResult expected,
    required bool ordered,
  }) {
    if (student.hasError) {
      return SqlVerdict(
        passed: false,
        title: 'La consulta no se pudo ejecutar',
        detail: student.error!,
      );
    }
    if (student.columns.length != expected.columns.length) {
      return SqlVerdict(
        passed: false,
        title: 'Numero de columnas distinto',
        detail:
            'Se esperaban ${expected.columns.length} columna(s) y tu consulta '
            'devuelve ${student.columns.length}. Revisa la lista del SELECT.',
      );
    }
    if (student.rows.length != expected.rows.length) {
      return SqlVerdict(
        passed: false,
        title: 'Numero de filas distinto',
        detail:
            'Se esperaban ${expected.rows.length} fila(s) y obtuviste '
            '${student.rows.length}. Revisa el filtro WHERE, el tipo de JOIN '
            'o el agrupamiento.',
      );
    }

    final a = _normalize(student.rows);
    final b = _normalize(expected.rows);
    if (ordered) {
      for (var i = 0; i < a.length; i++) {
        if (!_rowEquals(a[i], b[i])) {
          return SqlVerdict(
            passed: false,
            title: 'El orden de las filas no coincide',
            detail: 'La fila ${i + 1} no corresponde. Revisa el ORDER BY.',
          );
        }
      }
      return const SqlVerdict(
        passed: true,
        title: 'Resultado correcto',
        detail: 'Filas, columnas y orden coinciden con la solucion esperada.',
      );
    }

    final pending = List<List<String>>.from(b);
    for (final row in a) {
      final idx = pending.indexWhere((candidate) => _rowEquals(row, candidate));
      if (idx < 0) {
        return SqlVerdict(
          passed: false,
          title: 'Los datos devueltos no coinciden',
          detail:
              'La fila [${row.join(' | ')}] no forma parte del resultado '
              'esperado. Revisa las condiciones y las columnas seleccionadas.',
        );
      }
      pending.removeAt(idx);
    }
    return const SqlVerdict(
      passed: true,
      title: 'Resultado correcto',
      detail: 'El conjunto de filas coincide con la solucion esperada.',
    );
  }

  /// Reglas de forma: obligan a practicar la construccion pedida y no solo
  /// a llegar al numero correcto por otro camino.
  static List<String> checkShape(
    String sql, {
    required List<String> mustContain,
    required List<String> forbid,
  }) {
    final normalized = sql.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final failures = <String>[];
    for (final token in mustContain) {
      if (!normalized.contains(token.toLowerCase())) {
        failures.add('Tu consulta debe usar "$token".');
      }
    }
    for (final token in forbid) {
      if (normalized.contains(token.toLowerCase())) {
        failures.add('En esta tarea no se permite usar "$token".');
      }
    }
    return failures;
  }

  static List<List<String>> _normalize(List<List<Object?>> rows) {
    final out = rows.map(_normalizeRow).toList();
    out.sort((x, y) => x.join('\u0001').compareTo(y.join('\u0001')));
    return out;
  }

  static List<String> _normalizeRow(List<Object?> row) =>
      row.map(_normalizeValue).toList();

  static String _normalizeValue(Object? value) {
    if (value == null) return '\u0000NULL';
    if (value is num) {
      final d = value.toDouble();
      final rounded = (d / tolerance).round() * tolerance;
      if ((rounded - rounded.roundToDouble()).abs() < tolerance) {
        return rounded.roundToDouble().toStringAsFixed(0);
      }
      return rounded.toStringAsFixed(6);
    }
    return value.toString().trim();
  }

  static bool _rowEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
