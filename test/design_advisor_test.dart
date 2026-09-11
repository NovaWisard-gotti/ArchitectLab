import 'package:database_architect_lab/engine/design_advisor.dart';
import 'package:database_architect_lab/models/activity.dart';
import 'package:database_architect_lab/models/er_model.dart';
import 'package:flutter_test/flutter_test.dart';

ErEntity _entity(String id, String name,
        {List<ErAttribute>? attributes, bool weak = false}) =>
    ErEntity(
      id: id,
      name: name,
      x: 0,
      y: 0,
      isWeak: weak,
      attributes: attributes ?? [],
    );

void main() {
  group('normalize', () {
    test('ignora tildes, mayusculas y plurales simples', () {
      expect(DesignAdvisor.normalize('Estudiantes'),
          DesignAdvisor.normalize('estudiante'));
      expect(DesignAdvisor.normalize('Préstamo'),
          DesignAdvisor.normalize('prestamo'));
      expect(DesignAdvisor.normalize('fecha_salida'), 'fechasalida');
    });
  });

  group('analyze', () {
    test('detecta entidad sin clave primaria', () {
      final model = ErModel(entities: [
        _entity('e1', 'Libro', attributes: [ErAttribute(name: 'titulo')]),
      ]);
      final diagnostics = DesignAdvisor.analyze(model);
      expect(
        diagnostics.any((d) => d.rule == 'entity-no-pk'),
        isTrue,
      );
    });

    test('detecta atributo multivaluado', () {
      final model = ErModel(entities: [
        _entity('e1', 'Estudiante', attributes: [
          ErAttribute(name: 'codigo', kind: AttrKind.primaryKey, nullable: false),
          ErAttribute(name: 'telefono', kind: AttrKind.multivalued),
        ]),
      ]);
      final diagnostics = DesignAdvisor.analyze(model);
      expect(diagnostics.any((d) => d.rule == 'multivalued'), isTrue);
    });

    test('detecta entidad aislada', () {
      final model = ErModel(entities: [
        _entity('e1', 'A', attributes: [
          ErAttribute(name: 'id', kind: AttrKind.primaryKey, nullable: false)
        ]),
        _entity('e2', 'B', attributes: [
          ErAttribute(name: 'id', kind: AttrKind.primaryKey, nullable: false)
        ]),
      ]);
      final diagnostics = DesignAdvisor.analyze(model);
      expect(diagnostics.where((d) => d.rule == 'isolated-entity').length, 2);
    });

    test('entidad debil sin relacion identificadora es un error', () {
      final model = ErModel(
        entities: [
          _entity('e1', 'Duenio', attributes: [
            ErAttribute(name: 'dni', kind: AttrKind.primaryKey, nullable: false)
          ]),
          _entity('e2', 'Mascota', weak: true, attributes: [
            ErAttribute(name: 'nombre'),
          ]),
        ],
        relationships: [
          ErRelationship(id: 'r1', name: 'tiene', fromId: 'e1', toId: 'e2'),
        ],
      );
      final diagnostics = DesignAdvisor.analyze(model);
      expect(
        diagnostics.any((d) => d.rule == 'weak-without-identifying'),
        isTrue,
      );
    });
  });

  group('evaluate', () {
    final rubric = ErRubric(
      entities: const [
        RequiredEntity(
          key: 'libro',
          aliases: ['Libro'],
          attributes: [RequiredAttribute(['isbn'], mustBePk: true)],
        ),
        RequiredEntity(key: 'autor', aliases: ['Autor']),
      ],
      relations: const [
        RequiredRelation(
          fromKey: 'libro',
          toKey: 'autor',
          fromCard: Cardinality.many,
          toCard: Cardinality.many,
        ),
      ],
    );

    test('modelo correcto obtiene puntaje aprobatorio', () {
      final model = ErModel(
        entities: [
          _entity('e1', 'Libros', attributes: [
            ErAttribute(
                name: 'ISBN', kind: AttrKind.primaryKey, nullable: false),
          ]),
          _entity('e2', 'Autor', attributes: [
            ErAttribute(name: 'id', kind: AttrKind.primaryKey, nullable: false),
          ]),
        ],
        relationships: [
          ErRelationship(
            id: 'r1',
            name: 'escribe',
            fromId: 'e1',
            toId: 'e2',
            fromCard: Cardinality.many,
            toCard: Cardinality.many,
          ),
        ],
      );
      final report = DesignAdvisor.evaluate(model, rubric);
      expect(report.passed, isTrue);
      expect(report.earned, greaterThan(0));
      expect(report.possible, rubric.total);
    });

    test('cardinalidad equivocada otorga puntaje parcial', () {
      final model = ErModel(
        entities: [
          _entity('e1', 'Libro', attributes: [
            ErAttribute(
                name: 'isbn', kind: AttrKind.primaryKey, nullable: false),
          ]),
          _entity('e2', 'Autor', attributes: [
            ErAttribute(name: 'id', kind: AttrKind.primaryKey, nullable: false),
          ]),
        ],
        relationships: [
          ErRelationship(
            id: 'r1',
            name: 'escribe',
            fromId: 'e1',
            toId: 'e2',
            fromCard: Cardinality.one,
            toCard: Cardinality.many,
          ),
        ],
      );
      final report = DesignAdvisor.evaluate(model, rubric);
      final relationItem =
          report.items.firstWhere((i) => i.label.startsWith('Relación'));
      expect(relationItem.earned, greaterThan(0));
      expect(relationItem.earned, lessThan(relationItem.possible));
    });

    test('modelo vacio no obtiene puntaje de rubrica', () {
      final report = DesignAdvisor.evaluate(ErModel(), rubric);
      expect(report.earned, lessThan(report.possible));
    });
  });
}
