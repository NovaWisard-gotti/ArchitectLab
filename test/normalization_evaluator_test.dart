import 'package:database_architect_lab/engine/normalization_evaluator.dart';
import 'package:database_architect_lab/models/activity.dart';
import 'package:flutter_test/flutter_test.dart';

NormalizationActivity _activity() => NormalizationActivity(
      id: 'test',
      title: 'Boletas',
      summary: '',
      competencies: const [Competency.normalization],
      brief: '',
      sampleRows: const [],
      attributes: const [
        'num_boleta',
        'fecha',
        'dni_cliente',
        'nombre_cliente',
        'cod_producto',
        'cantidad',
      ],
      fds: const [
        Fd(['num_boleta'], ['fecha', 'dni_cliente']),
        Fd(['dni_cliente'], ['nombre_cliente']),
        Fd(['num_boleta', 'cod_producto'], ['cantidad']),
      ],
      expected: const [
        ExpectedTable(
          name: 'cliente',
          primaryKey: ['dni_cliente'],
          attributes: ['dni_cliente', 'nombre_cliente'],
        ),
        ExpectedTable(
          name: 'boleta',
          primaryKey: ['num_boleta'],
          attributes: ['num_boleta', 'fecha', 'dni_cliente'],
        ),
        ExpectedTable(
          name: 'detalle',
          primaryKey: ['num_boleta', 'cod_producto'],
          attributes: ['num_boleta', 'cod_producto', 'cantidad'],
        ),
      ],
    );

void main() {
  test('descomposicion correcta aprueba y alcanza 3FN', () {
    final report = NormalizationEvaluator.evaluate(
      activity: _activity(),
      tables: [
        StudentTable(
          name: 'cliente',
          attributes: {'dni_cliente', 'nombre_cliente'},
          pk: {'dni_cliente'},
        ),
        StudentTable(
          name: 'boleta',
          attributes: {'num_boleta', 'fecha', 'dni_cliente'},
          pk: {'num_boleta'},
        ),
        StudentTable(
          name: 'detalle',
          attributes: {'num_boleta', 'cod_producto', 'cantidad'},
          pk: {'num_boleta', 'cod_producto'},
        ),
      ],
    );
    expect(report.passed, isTrue);
    expect(report.reachedForm, '3FN');
  });

  test('tabla unica revela dependencia parcial', () {
    final report = NormalizationEvaluator.evaluate(
      activity: _activity(),
      tables: [
        StudentTable(
          name: 'ventas',
          attributes: {
            'num_boleta',
            'fecha',
            'dni_cliente',
            'nombre_cliente',
            'cod_producto',
            'cantidad',
          },
          pk: {'num_boleta', 'cod_producto'},
        ),
      ],
    );
    expect(report.reachedForm, '1FN');
    expect(
      report.issues.any((i) => i.title.contains('Dependencia parcial')),
      isTrue,
    );
    expect(report.passed, isFalse);
  });

  test('atributos sin ubicar se reportan', () {
    final report = NormalizationEvaluator.evaluate(
      activity: _activity(),
      tables: [
        StudentTable(
          name: 'cliente',
          attributes: {'dni_cliente', 'nombre_cliente'},
          pk: {'dni_cliente'},
        ),
      ],
    );
    expect(
      report.issues.any((i) => i.title.contains('sin ubicar')),
      isTrue,
    );
  });
}
