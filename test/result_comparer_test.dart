import 'package:database_architect_lab/engine/result_comparer.dart';
import 'package:database_architect_lab/engine/sql_engine.dart';
import 'package:flutter_test/flutter_test.dart';

SqlResult _result(List<String> columns, List<List<Object?>> rows) =>
    SqlResult(columns: columns, rows: rows);

void main() {
  group('compare', () {
    test('acepta el mismo conjunto en distinto orden', () {
      final verdict = ResultComparer.compare(
        student: _result(['n'], [
          ['b'],
          ['a'],
        ]),
        expected: _result(['n'], [
          ['a'],
          ['b'],
        ]),
        ordered: false,
      );
      expect(verdict.passed, isTrue);
    });

    test('rechaza distinto orden cuando el ejercicio lo exige', () {
      final verdict = ResultComparer.compare(
        student: _result(['n'], [
          ['b'],
          ['a'],
        ]),
        expected: _result(['n'], [
          ['a'],
          ['b'],
        ]),
        ordered: true,
      );
      expect(verdict.passed, isFalse);
      expect(verdict.title.contains('orden'), isTrue);
    });

    test('detecta diferencia en el numero de columnas', () {
      final verdict = ResultComparer.compare(
        student: _result(['a'], [
          ['x'],
        ]),
        expected: _result(['a', 'b'], [
          ['x', 'y'],
        ]),
        ordered: false,
      );
      expect(verdict.passed, isFalse);
      expect(verdict.title.contains('columnas'), isTrue);
    });

    test('tolera diferencias minimas de punto flotante', () {
      final verdict = ResultComparer.compare(
        student: _result(['p'], [
          [14.3333333331],
        ]),
        expected: _result(['p'], [
          [14.3333333333],
        ]),
        ordered: false,
      );
      expect(verdict.passed, isTrue);
    });

    test('propaga el error del motor', () {
      final verdict = ResultComparer.compare(
        student: SqlResult(error: 'no such table: alumno'),
        expected: _result(['a'], const []),
        ordered: false,
      );
      expect(verdict.passed, isFalse);
      expect(verdict.detail.contains('no such table'), isTrue);
    });
  });

  group('checkShape', () {
    test('exige las construcciones pedidas', () {
      final issues = ResultComparer.checkShape(
        'SELECT * FROM curso',
        mustContain: ['group by'],
        forbid: const [],
      );
      expect(issues.length, 1);
    });

    test('bloquea construcciones prohibidas', () {
      final issues = ResultComparer.checkShape(
        'SELECT * FROM curso WHERE AVG(nota) > 14',
        mustContain: const [],
        forbid: ['where avg'],
      );
      expect(issues.length, 1);
    });
  });

  group('splitStatements', () {
    test('respeta el punto y coma dentro de literales', () {
      final statements = SqlEngine.splitStatements(
        "INSERT INTO t VALUES ('a;b'); SELECT * FROM t;",
      );
      expect(statements.length, 2);
      expect(statements.first.contains('a;b'), isTrue);
    });

    test('identifica consultas de lectura', () {
      expect(SqlEngine.isQuery('  select 1'), isTrue);
      expect(SqlEngine.isQuery('UPDATE t SET a = 1'), isFalse);
    });
  });
}
