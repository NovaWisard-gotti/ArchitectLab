import 'dart:convert';

/// Naturaleza de un atributo dentro del modelo entidad-relación.
enum AttrKind { normal, primaryKey, foreignKey, multivalued, derived }

extension AttrKindLabel on AttrKind {
  String get label {
    switch (this) {
      case AttrKind.normal:
        return 'Simple';
      case AttrKind.primaryKey:
        return 'Clave primaria';
      case AttrKind.foreignKey:
        return 'Clave foránea';
      case AttrKind.multivalued:
        return 'Multivaluado';
      case AttrKind.derived:
        return 'Derivado';
    }
  }

  String get badge {
    switch (this) {
      case AttrKind.primaryKey:
        return 'PK';
      case AttrKind.foreignKey:
        return 'FK';
      case AttrKind.multivalued:
        return 'M';
      case AttrKind.derived:
        return 'D';
      case AttrKind.normal:
        return '';
    }
  }
}

enum Cardinality { one, many }

extension CardinalityLabel on Cardinality {
  String get symbol => this == Cardinality.one ? '1' : 'N';
}

class ErAttribute {
  ErAttribute({
    required this.name,
    this.kind = AttrKind.normal,
    this.type = 'TEXT',
    this.nullable = true,
  });

  String name;
  AttrKind kind;
  String type;
  bool nullable;

  Map<String, dynamic> toJson() => {
        'n': name,
        'k': kind.index,
        't': type,
        'u': nullable,
      };

  static ErAttribute fromJson(Map<String, dynamic> j) => ErAttribute(
        name: j['n'] as String,
        kind: AttrKind.values[(j['k'] as num).toInt()],
        type: (j['t'] as String?) ?? 'TEXT',
        nullable: (j['u'] as bool?) ?? true,
      );

  ErAttribute copy() =>
      ErAttribute(name: name, kind: kind, type: type, nullable: nullable);
}

class ErEntity {
  ErEntity({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    List<ErAttribute>? attributes,
    this.isWeak = false,
  }) : attributes = attributes ?? <ErAttribute>[];

  final String id;
  String name;
  double x;
  double y;
  bool isWeak;
  List<ErAttribute> attributes;

  bool get hasPrimaryKey =>
      attributes.any((a) => a.kind == AttrKind.primaryKey);

  Map<String, dynamic> toJson() => {
        'id': id,
        'n': name,
        'x': x,
        'y': y,
        'w': isWeak,
        'a': attributes.map((e) => e.toJson()).toList(),
      };

  static ErEntity fromJson(Map<String, dynamic> j) => ErEntity(
        id: j['id'] as String,
        name: j['n'] as String,
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        isWeak: (j['w'] as bool?) ?? false,
        attributes: ((j['a'] as List<dynamic>?) ?? [])
            .map((e) => ErAttribute.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  ErEntity copy() => ErEntity(
        id: id,
        name: name,
        x: x,
        y: y,
        isWeak: isWeak,
        attributes: attributes.map((e) => e.copy()).toList(),
      );
}

class ErRelationship {
  ErRelationship({
    required this.id,
    required this.name,
    required this.fromId,
    required this.toId,
    this.fromCard = Cardinality.one,
    this.toCard = Cardinality.many,
    this.identifying = false,
  });

  final String id;
  String name;
  String fromId;
  String toId;
  Cardinality fromCard;
  Cardinality toCard;
  bool identifying;

  bool get isManyToMany =>
      fromCard == Cardinality.many && toCard == Cardinality.many;
  bool get isOneToOne =>
      fromCard == Cardinality.one && toCard == Cardinality.one;

  Map<String, dynamic> toJson() => {
        'id': id,
        'n': name,
        'f': fromId,
        't': toId,
        'fc': fromCard.index,
        'tc': toCard.index,
        'i': identifying,
      };

  static ErRelationship fromJson(Map<String, dynamic> j) => ErRelationship(
        id: j['id'] as String,
        name: j['n'] as String,
        fromId: j['f'] as String,
        toId: j['t'] as String,
        fromCard: Cardinality.values[(j['fc'] as num).toInt()],
        toCard: Cardinality.values[(j['tc'] as num).toInt()],
        identifying: (j['i'] as bool?) ?? false,
      );
}

class ErModel {
  ErModel({List<ErEntity>? entities, List<ErRelationship>? relationships})
      : entities = entities ?? <ErEntity>[],
        relationships = relationships ?? <ErRelationship>[];

  final List<ErEntity> entities;
  final List<ErRelationship> relationships;

  ErEntity? entityById(String id) {
    for (final e in entities) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<ErRelationship> relationsOf(String entityId) => relationships
      .where((r) => r.fromId == entityId || r.toId == entityId)
      .toList();

  bool get isEmpty => entities.isEmpty;

  Map<String, dynamic> toJson() => {
        'e': entities.map((e) => e.toJson()).toList(),
        'r': relationships.map((e) => e.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  static ErModel decode(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return ErModel.fromJson(j);
  }

  static ErModel fromJson(Map<String, dynamic> j) => ErModel(
        entities: ((j['e'] as List<dynamic>?) ?? [])
            .map((e) => ErEntity.fromJson(e as Map<String, dynamic>))
            .toList(),
        relationships: ((j['r'] as List<dynamic>?) ?? [])
            .map((e) => ErRelationship.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  ErModel copy() => ErModel(
        entities: entities.map((e) => e.copy()).toList(),
        relationships: relationships
            .map((r) => ErRelationship(
                  id: r.id,
                  name: r.name,
                  fromId: r.fromId,
                  toId: r.toId,
                  fromCard: r.fromCard,
                  toCard: r.toCard,
                  identifying: r.identifying,
                ))
            .toList(),
      );

  /// Traducción didáctica del modelo ER a esquema relacional (DDL).
  String toDdl() {
    final buffer = StringBuffer();
    for (final e in entities) {
      buffer.writeln('CREATE TABLE ${_snake(e.name)} (');
      final lines = <String>[];
      final pks = <String>[];
      for (final a in e.attributes) {
        if (a.kind == AttrKind.multivalued) continue;
        if (a.kind == AttrKind.derived) continue;
        final notNull = a.kind == AttrKind.primaryKey || !a.nullable
            ? ' NOT NULL'
            : '';
        lines.add('  ${_snake(a.name)} ${a.type}$notNull');
        if (a.kind == AttrKind.primaryKey) pks.add(_snake(a.name));
      }
      for (final r in relationships) {
        if (r.toId == e.id &&
            r.fromCard == Cardinality.one &&
            r.toCard == Cardinality.many) {
          final parent = entityById(r.fromId);
          if (parent != null) {
            lines.add('  ${_snake(parent.name)}_id INTEGER NOT NULL');
          }
        }
      }
      if (pks.isNotEmpty) {
        lines.add('  PRIMARY KEY (${pks.join(', ')})');
      }
      buffer.writeln(lines.join(',\n'));
      buffer.writeln(');');
      buffer.writeln();
    }
    for (final r in relationships) {
      if (!r.isManyToMany) continue;
      final a = entityById(r.fromId);
      final b = entityById(r.toId);
      if (a == null || b == null) continue;
      final table = _snake(r.name.isEmpty ? '${a.name}_${b.name}' : r.name);
      buffer.writeln('-- Relación N:M convertida en tabla asociativa');
      buffer.writeln('CREATE TABLE $table (');
      buffer.writeln('  ${_snake(a.name)}_id INTEGER NOT NULL,');
      buffer.writeln('  ${_snake(b.name)}_id INTEGER NOT NULL,');
      buffer.writeln(
          '  PRIMARY KEY (${_snake(a.name)}_id, ${_snake(b.name)}_id)');
      buffer.writeln(');');
      buffer.writeln();
    }
    for (final e in entities) {
      for (final a in e.attributes) {
        if (a.kind != AttrKind.multivalued) continue;
        buffer.writeln('-- Atributo multivaluado extraído a su propia tabla');
        buffer.writeln('CREATE TABLE ${_snake(e.name)}_${_snake(a.name)} (');
        buffer.writeln('  ${_snake(e.name)}_id INTEGER NOT NULL,');
        buffer.writeln('  ${_snake(a.name)} ${a.type} NOT NULL');
        buffer.writeln(');');
        buffer.writeln();
      }
    }
    return buffer.toString().trimRight();
  }

  static String _snake(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final trimmed = cleaned.replaceAll(RegExp(r'^_+|_+$'), '');
    return trimmed.isEmpty ? 'tabla' : trimmed;
  }
}
