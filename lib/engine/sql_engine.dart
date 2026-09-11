import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Resultado de ejecutar SQL en el motor embebido.
class SqlResult {
  SqlResult({
    this.columns = const <String>[],
    this.rows = const <List<Object?>>[],
    this.error,
    this.statementsRun = 0,
  });

  final List<String> columns;
  final List<List<Object?>> rows;
  final String? error;
  final int statementsRun;

  bool get hasError => error != null;
  bool get isEmpty => rows.isEmpty;
}

/// Motor SQL real (SQLite embebido). Cada laboratorio abre su propia base
/// de datos aislada y la reconstruye desde cero antes de cada intento, para
/// que el estudiante pueda equivocarse sin consecuencias.
class SqlEngine {
  SqlEngine(this.slot);

  /// Identificador de la base física; permite tener la base del estudiante
  /// y la base de referencia abiertas al mismo tiempo.
  final String slot;

  Database? _db;
  String? _path;

  bool get isReady => _db != null;

  Future<void> reset(List<String> seed) async {
    await close();
    final dir = await getDatabasesPath();
    _path = p.join(dir, 'dal_$slot.db');
    await deleteDatabase(_path!);
    _db = await openDatabase(_path!);
    for (final statement in seed) {
      final s = statement.trim();
      if (s.isEmpty) continue;
      await _db!.execute(s);
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Ejecuta uno o varios enunciados separados por punto y coma.
  /// Devuelve el resultado del último SELECT encontrado.
  Future<SqlResult> run(String sql) async {
    final db = _db;
    if (db == null) {
      return SqlResult(error: 'El laboratorio aún no está inicializado.');
    }
    final statements = splitStatements(sql);
    if (statements.isEmpty) {
      return SqlResult(error: 'Escribe una sentencia SQL para ejecutar.');
    }
    var executed = 0;
    SqlResult? last;
    for (final statement in statements) {
      try {
        if (isQuery(statement)) {
          final raw = await db.rawQuery(statement);
          last = _toResult(raw, executed + 1);
        } else {
          await db.execute(statement);
          last = SqlResult(statementsRun: executed + 1);
        }
        executed++;
      } on DatabaseException catch (e) {
        return SqlResult(error: _cleanError(e.toString()));
      } catch (e) {
        return SqlResult(error: _cleanError(e.toString()));
      }
    }
    return last ?? SqlResult(statementsRun: executed);
  }

  SqlResult _toResult(List<Map<String, Object?>> raw, int executed) {
    if (raw.isEmpty) {
      return SqlResult(statementsRun: executed);
    }
    final columns = raw.first.keys.toList();
    final rows = raw
        .map((row) => columns.map((c) => row[c]).toList())
        .toList(growable: false);
    return SqlResult(columns: columns, rows: rows, statementsRun: executed);
  }

  /// Lista las tablas y columnas actuales para el visor de esquema.
  Future<Map<String, List<String>>> describe() async {
    final db = _db;
    final schema = <String, List<String>>{};
    if (db == null) return schema;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' "
      "AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );
    for (final t in tables) {
      final name = t['name'] as String;
      try {
        final probe = await db.rawQuery('SELECT * FROM "$name" LIMIT 1');
        if (probe.isNotEmpty) {
          schema[name] = probe.first.keys.toList();
        } else {
          final info = await db.rawQuery('PRAGMA table_info("$name")');
          schema[name] =
              info.map((row) => (row['name'] ?? '').toString()).toList();
        }
      } catch (_) {
        schema[name] = <String>[];
      }
    }
    return schema;
  }

  static String _cleanError(String raw) {
    var message = raw;
    message = message.replaceAll('DatabaseException(', '');
    final idx = message.indexOf('(Sqlite code');
    if (idx > 0) message = message.substring(0, idx);
    message = message.replaceAll(RegExp(r'\)+$'), '').trim();
    return message.isEmpty ? 'Error desconocido en la sentencia SQL.' : message;
  }

  /// Separa sentencias respetando comillas simples y dobles.
  static List<String> splitStatements(String sql) {
    final out = <String>[];
    final buffer = StringBuffer();
    var inSingle = false;
    var inDouble = false;
    for (var i = 0; i < sql.length; i++) {
      final ch = sql[i];
      if (ch == "'" && !inDouble) inSingle = !inSingle;
      if (ch == '"' && !inSingle) inDouble = !inDouble;
      if (ch == ';' && !inSingle && !inDouble) {
        final s = buffer.toString().trim();
        if (s.isNotEmpty) out.add(s);
        buffer.clear();
        continue;
      }
      buffer.write(ch);
    }
    final tail = buffer.toString().trim();
    if (tail.isNotEmpty) out.add(tail);
    return out;
  }

  static bool isQuery(String statement) {
    final s = statement.trimLeft().toLowerCase();
    return s.startsWith('select') ||
        s.startsWith('with') ||
        s.startsWith('pragma') ||
        s.startsWith('explain');
  }
}
