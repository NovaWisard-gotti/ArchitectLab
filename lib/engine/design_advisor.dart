import '../models/activity.dart';
import '../models/er_model.dart';

enum Severity { error, warning, info, praise }

class Diagnostic {
  const Diagnostic({
    required this.rule,
    required this.severity,
    required this.title,
    required this.message,
    this.fix = '',
    this.target = '',
  });

  final String rule;
  final Severity severity;
  final String title;
  final String message;
  final String fix;
  final String target;
}

class RubricItem {
  const RubricItem({
    required this.label,
    required this.earned,
    required this.possible,
    required this.comment,
  });

  final String label;
  final int earned;
  final int possible;
  final String comment;

  bool get complete => earned >= possible;
}

class RubricReport {
  const RubricReport({
    required this.items,
    required this.earned,
    required this.possible,
    required this.diagnostics,
  });

  final List<RubricItem> items;
  final int earned;
  final int possible;
  final List<Diagnostic> diagnostics;

  double get ratio => possible == 0 ? 0 : earned / possible;
  bool get passed => ratio >= 0.7;
}

/// Analizador estatico de modelos entidad-relacion.
///
/// No es un corrector de texto: recorre la estructura del modelo y aplica
/// reglas de diseno que un docente revisaria a mano.
class DesignAdvisor {
  static List<Diagnostic> analyze(ErModel model) {
    final out = <Diagnostic>[];

    if (model.entities.isEmpty) {
      out.add(const Diagnostic(
        rule: 'empty-model',
        severity: Severity.info,
        title: 'El lienzo esta vacio',
        message: 'Empieza identificando los sustantivos del enunciado: '
            'cada objeto del que necesitas guardar datos suele ser una entidad.',
        fix: 'Agrega tu primera entidad con el boton "Entidad".',
      ));
      return out;
    }

    final seenNames = <String, int>{};
    for (final e in model.entities) {
      final key = normalize(e.name);
      seenNames[key] = (seenNames[key] ?? 0) + 1;

      if (e.attributes.isEmpty) {
        out.add(Diagnostic(
          rule: 'entity-no-attributes',
          severity: Severity.warning,
          title: '${e.name} no tiene atributos',
          message:
              'Una entidad sin atributos no aporta informacion al sistema.',
          fix: 'Define al menos su identificador y un dato descriptivo.',
          target: e.name,
        ));
      }

      if (!e.hasPrimaryKey && !e.isWeak) {
        out.add(Diagnostic(
          rule: 'entity-no-pk',
          severity: Severity.error,
          title: '${e.name} no tiene clave primaria',
          message: 'Sin clave primaria no se puede identificar una fila de '
              'forma unica ni referenciarla desde otra tabla.',
          fix: 'Marca un atributo como PK. Prefiere un identificador estable '
              '(codigo o id) antes que un dato que puede cambiar.',
          target: e.name,
        ));
      }

      final pks =
          e.attributes.where((a) => a.kind == AttrKind.primaryKey).toList();
      if (pks.length > 3) {
        out.add(Diagnostic(
          rule: 'wide-pk',
          severity: Severity.warning,
          title: 'Clave primaria muy amplia en ${e.name}',
          message: 'Una clave compuesta por ${pks.length} atributos suele '
              'indicar que la entidad mezcla mas de un concepto.',
          fix: 'Revisa si parte de esos atributos pertenece a otra entidad.',
          target: e.name,
        ));
      }

      final attrNames = <String>{};
      for (final a in e.attributes) {
        final an = normalize(a.name);
        if (!attrNames.add(an)) {
          out.add(Diagnostic(
            rule: 'duplicate-attribute',
            severity: Severity.error,
            title: 'Atributo repetido en ${e.name}',
            message: 'El atributo "${a.name}" aparece mas de una vez.',
            fix: 'Elimina el duplicado o diferencia su nombre.',
            target: e.name,
          ));
        }
        if (a.kind == AttrKind.multivalued) {
          out.add(Diagnostic(
            rule: 'multivalued',
            severity: Severity.warning,
            title: '"${a.name}" es multivaluado',
            message: 'Un atributo con varios valores rompe la primera forma '
                'normal cuando se traduce a tablas.',
            fix: 'Extrae "${a.name}" a una entidad propia relacionada 1:N '
                'con ${e.name}.',
            target: e.name,
          ));
        }
        if (a.kind == AttrKind.primaryKey && a.nullable) {
          out.add(Diagnostic(
            rule: 'nullable-pk',
            severity: Severity.error,
            title: 'Clave primaria opcional en ${e.name}',
            message: 'Una clave primaria nunca puede aceptar valores nulos.',
            fix: 'Desmarca "acepta nulos" en ${a.name}.',
            target: e.name,
          ));
        }
        if (_looksVolatile(an) && a.kind == AttrKind.primaryKey) {
          out.add(Diagnostic(
            rule: 'volatile-pk',
            severity: Severity.warning,
            title: 'Clave primaria inestable en ${e.name}',
            message: '"${a.name}" es un dato que suele cambiar con el tiempo.',
            fix: 'Usa un identificador emitido por el sistema y deja '
                '"${a.name}" como UNIQUE.',
            target: e.name,
          ));
        }
      }

      if (e.attributes.length > 12) {
        out.add(Diagnostic(
          rule: 'fat-entity',
          severity: Severity.info,
          title: '${e.name} concentra ${e.attributes.length} atributos',
          message: 'Entidades muy anchas suelen esconder mas de un concepto.',
          fix: 'Verifica si hay grupos de atributos que dependen de algo '
              'distinto a la clave primaria.',
          target: e.name,
        ));
      }

      if (model.relationsOf(e.id).isEmpty && model.entities.length > 1) {
        out.add(Diagnostic(
          rule: 'isolated-entity',
          severity: Severity.warning,
          title: '${e.name} esta aislada',
          message: 'Ninguna relacion conecta esta entidad con el resto del '
              'modelo, asi que sus datos no se pueden cruzar.',
          fix: 'Conectala con la entidad de la que depende o elimina la que '
              'no aporta al problema.',
          target: e.name,
        ));
      }

      if (e.isWeak) {
        final identifying = model
            .relationsOf(e.id)
            .any((r) => r.identifying);
        if (!identifying) {
          out.add(Diagnostic(
            rule: 'weak-without-identifying',
            severity: Severity.error,
            title: '${e.name} es debil pero no depende de nadie',
            message: 'Una entidad debil necesita una relacion identificadora '
                'con la entidad fuerte que completa su clave.',
            fix: 'Marca la relacion correspondiente como identificadora.',
            target: e.name,
          ));
        }
      }
    }

    seenNames.forEach((key, count) {
      if (count > 1) {
        out.add(Diagnostic(
          rule: 'duplicate-entity',
          severity: Severity.error,
          title: 'Entidades con el mismo nombre',
          message: 'Hay $count entidades llamadas "$key".',
          fix: 'Renombra o fusiona las entidades duplicadas.',
        ));
      }
    });

    for (final r in model.relationships) {
      final from = model.entityById(r.fromId);
      final to = model.entityById(r.toId);
      if (from == null || to == null) continue;

      if (r.name.trim().isEmpty) {
        out.add(Diagnostic(
          rule: 'unnamed-relation',
          severity: Severity.info,
          title: 'Relacion sin nombre entre ${from.name} y ${to.name}',
          message: 'El nombre de la relacion documenta la regla de negocio.',
          fix: 'Usa un verbo: "matricula", "contiene", "solicita".',
        ));
      }

      if (r.isManyToMany) {
        out.add(Diagnostic(
          rule: 'many-to-many',
          severity: Severity.info,
          title: 'Relacion N:M entre ${from.name} y ${to.name}',
          message: 'Al pasar a tablas, esta relacion se convierte en una '
              'tabla asociativa con las dos claves foraneas.',
          fix: 'Si la relacion tiene datos propios (fecha, nota, cantidad), '
              'modelala explicitamente como entidad asociativa.',
        ));
      }

      if (r.isOneToOne) {
        out.add(Diagnostic(
          rule: 'one-to-one',
          severity: Severity.info,
          title: 'Relacion 1:1 entre ${from.name} y ${to.name}',
          message: 'Las relaciones 1:1 muchas veces se resuelven fusionando '
              'ambas entidades en una sola tabla.',
          fix: 'Mantenlas separadas solo si tienen ciclos de vida, permisos '
              'o volumenes distintos.',
        ));
      }

      if (r.fromId == r.toId) {
        out.add(Diagnostic(
          rule: 'recursive',
          severity: Severity.info,
          title: 'Relacion recursiva en ${from.name}',
          message: 'La entidad se relaciona consigo misma.',
          fix: 'Nombra los dos roles (por ejemplo, supervisor y supervisado) '
              'para que el modelo se entienda.',
        ));
      }
    }

    final manualFks = <String>[];
    for (final e in model.entities) {
      for (final a in e.attributes) {
        if (a.kind == AttrKind.foreignKey &&
            model.relationsOf(e.id).isEmpty) {
          manualFks.add('${e.name}.${a.name}');
        }
      }
    }
    if (manualFks.isNotEmpty) {
      out.add(Diagnostic(
        rule: 'fk-without-relation',
        severity: Severity.warning,
        title: 'Claves foraneas sin relacion dibujada',
        message: '${manualFks.join(', ')} apunta a otra tabla, pero el modelo '
            'no muestra esa conexion.',
        fix: 'Dibuja la relacion para que la dependencia quede documentada.',
      ));
    }

    if (out.every((d) => d.severity == Severity.info)) {
      out.insert(
        0,
        const Diagnostic(
          rule: 'clean',
          severity: Severity.praise,
          title: 'Estructura sin errores graves',
          message: 'Todas las entidades tienen identificador y participan en '
              'al menos una relacion.',
          fix: 'Revisa ahora si las cardinalidades reflejan las reglas del '
              'enunciado.',
        ),
      );
    }
    return out;
  }

  /// Evalua el modelo contra la rubrica de una actividad de diseno.
  static RubricReport evaluate(ErModel model, ErRubric rubric) {
    final diagnostics = analyze(model);
    final items = <RubricItem>[];
    var earned = 0;

    final matched = <String, ErEntity>{};
    for (final req in rubric.entities) {
      final entity = _findEntity(model, req.aliases);
      if (entity != null) matched[req.key] = entity;

      if (entity == null) {
        items.add(RubricItem(
          label: 'Entidad ${req.aliases.first}',
          earned: 0,
          possible: req.points,
          comment: 'No se encontro. ${req.note.isEmpty ? 'Revisa el enunciado: '
              'este concepto necesita existir como entidad.' : req.note}',
        ));
      } else {
        earned += req.points;
        items.add(RubricItem(
          label: 'Entidad ${req.aliases.first}',
          earned: req.points,
          possible: req.points,
          comment: 'Modelada como "${entity.name}".',
        ));
      }

      if (req.needsPrimaryKey) {
        final ok = entity != null && entity.hasPrimaryKey;
        if (ok) earned += 1;
        items.add(RubricItem(
          label: 'Clave primaria de ${req.aliases.first}',
          earned: ok ? 1 : 0,
          possible: 1,
          comment: ok
              ? 'Identificador definido.'
              : 'Falta marcar un atributo como clave primaria.',
        ));
      }

      for (final attr in req.attributes) {
        final found = entity == null
            ? null
            : _findAttribute(entity, attr.aliases);
        final ok = found != null &&
            (!attr.mustBePk || found.kind == AttrKind.primaryKey);
        if (ok) earned += attr.points;
        items.add(RubricItem(
          label: '${req.aliases.first}.${attr.display}',
          earned: ok ? attr.points : 0,
          possible: attr.points,
          comment: found == null
              ? 'Atributo ausente.'
              : (attr.mustBePk && found.kind != AttrKind.primaryKey
                  ? 'Existe, pero deberia ser la clave primaria.'
                  : 'Correcto.'),
        ));
      }
    }

    for (final rel in rubric.relations) {
      final a = matched[rel.fromKey];
      final b = matched[rel.toKey];
      var points = 0;
      var comment = 'Faltan las entidades que participan en la relacion.';
      if (a != null && b != null) {
        final found = _findRelation(model, a.id, b.id);
        if (found == null) {
          comment = 'No existe la relacion entre ${a.name} y ${b.name}. '
              '${rel.description}';
        } else {
          final direct = found.fromId == a.id;
          final fromCard = direct ? found.fromCard : found.toCard;
          final toCard = direct ? found.toCard : found.fromCard;
          if (fromCard == rel.fromCard && toCard == rel.toCard) {
            points = rel.points;
            comment = 'Relacion y cardinalidad correctas '
                '(${rel.fromCard.symbol}:${rel.toCard.symbol}).';
          } else {
            points = (rel.points / 2).floor();
            comment = 'La relacion existe, pero la cardinalidad esperada era '
                '${rel.fromCard.symbol}:${rel.toCard.symbol} y modelaste '
                '${fromCard.symbol}:${toCard.symbol}. ${rel.description}';
          }
        }
      }
      earned += points;
      items.add(RubricItem(
        label: 'Relacion ${rel.fromKey} - ${rel.toKey}',
        earned: points,
        possible: rel.points,
        comment: comment,
      ));
    }

    final errors =
        diagnostics.where((d) => d.severity == Severity.error).length;
    final warnings =
        diagnostics.where((d) => d.severity == Severity.warning).length;
    final penalty = (errors * 2 + warnings).clamp(0, rubric.cleanDesignPoints);
    final cleanPoints = rubric.cleanDesignPoints - penalty;
    earned += cleanPoints;
    items.add(RubricItem(
      label: 'Calidad estructural',
      earned: cleanPoints,
      possible: rubric.cleanDesignPoints,
      comment: errors == 0 && warnings == 0
          ? 'Sin errores ni advertencias en el analisis estructural.'
          : 'El analizador encontro $errors error(es) y $warnings '
              'advertencia(s). Revisalos en la pestana de analisis.',
    ));

    return RubricReport(
      items: items,
      earned: earned.clamp(0, rubric.total),
      possible: rubric.total,
      diagnostics: diagnostics,
    );
  }

  static ErEntity? _findEntity(ErModel model, List<String> aliases) {
    final targets = aliases.map(normalize).toList();
    for (final e in model.entities) {
      final n = normalize(e.name);
      for (final t in targets) {
        if (n == t || n.contains(t) || t.contains(n)) return e;
      }
    }
    return null;
  }

  static ErAttribute? _findAttribute(ErEntity entity, List<String> aliases) {
    final targets = aliases.map(normalize).toList();
    for (final a in entity.attributes) {
      final n = normalize(a.name);
      for (final t in targets) {
        if (n == t || n.contains(t) || t.contains(n)) return a;
      }
    }
    return null;
  }

  static ErRelationship? _findRelation(ErModel model, String a, String b) {
    for (final r in model.relationships) {
      if ((r.fromId == a && r.toId == b) || (r.fromId == b && r.toId == a)) {
        return r;
      }
    }
    return null;
  }

  static bool _looksVolatile(String normalized) {
    const volatiles = [
      'correo',
      'email',
      'telefono',
      'celular',
      'direccion',
      'nombre',
      'usuario',
    ];
    return volatiles.any((v) => normalized == v || normalized.startsWith(v));
  }

  /// Normalizacion de nombres: minusculas, sin tildes, sin separadores y
  /// sin plural simple, para comparar "Estudiantes" con "estudiante".
  static String normalize(String value) {
    var v = value.trim().toLowerCase();
    const map = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    map.forEach((k, val) => v = v.replaceAll(k, val));
    v = v.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (v.endsWith('es') && v.length > 4) {
      v = v.substring(0, v.length - 2);
    } else if (v.endsWith('s') && v.length > 3) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }
}
