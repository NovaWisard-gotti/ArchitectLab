import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/er_model.dart';
import 'design_advisor.dart';

/// Explicacion pedagogica de un error.
class TutorAdvice {
  const TutorAdvice({
    required this.title,
    required this.explanation,
    required this.nextStep,
    this.remote = false,
  });

  final String title;
  final String explanation;
  final String nextStep;
  final bool remote;
}

/// Asistente de diagnostico.
///
/// Capa 1 (siempre disponible, sin red): reglas deterministas que traducen
/// el error del motor o del analizador a lenguaje de estudiante.
/// Capa 2 (opcional): endpoint remoto de tutoria. La clave del modelo vive
/// en el servidor, nunca dentro del APK.
class AiTutor {
  static const String endpoint =
      String.fromEnvironment('TUTOR_ENDPOINT', defaultValue: '');

  static bool get remoteEnabled => endpoint.isNotEmpty;

  /// Traduce un error de SQLite a una explicacion accionable.
  static TutorAdvice explainSqlError(String sql, String error) {
    final e = error.toLowerCase();
    final q = sql.toLowerCase();

    if (e.contains('no such table')) {
      final table = _extractAfter(error, 'no such table:');
      return TutorAdvice(
        title: 'La tabla no existe',
        explanation: 'El motor no encuentra "$table". O el nombre esta mal '
            'escrito, o esa tabla pertenece a otro esquema del laboratorio.',
        nextStep: 'Abre el visor de esquema y copia el nombre exacto.',
      );
    }
    if (e.contains('no such column')) {
      final col = _extractAfter(error, 'no such column:');
      return TutorAdvice(
        title: 'La columna no existe',
        explanation: 'No hay ninguna columna "$col" en las tablas del FROM. '
            'Si la columna vive en otra tabla, falta incluirla con un JOIN.',
        nextStep: 'Revisa el esquema y verifica el prefijo tabla.columna.',
      );
    }
    if (e.contains('ambiguous column name')) {
      final col = _extractAfter(error, 'ambiguous column name:');
      return TutorAdvice(
        title: 'Columna ambigua',
        explanation: '"$col" existe en mas de una tabla del JOIN, asi que el '
            'motor no sabe cual quieres.',
        nextStep: 'Escribe el nombre calificado, por ejemplo '
            'estudiante.$col, o usa alias de tabla.',
      );
    }
    if (e.contains('syntax error')) {
      return TutorAdvice(
        title: 'Error de sintaxis',
        explanation: _syntaxHint(q),
        nextStep: 'Lee la consulta en voz alta siguiendo el orden '
            'SELECT - FROM - JOIN - WHERE - GROUP BY - HAVING - ORDER BY.',
      );
    }
    if (e.contains('unique constraint failed')) {
      return TutorAdvice(
        title: 'Restriccion UNIQUE violada',
        explanation: 'Intentas insertar un valor que ya existe en una columna '
            'declarada como unica o como clave primaria.',
        nextStep: 'Cambia el valor duplicado o actualiza la fila existente '
            'con UPDATE.',
      );
    }
    if (e.contains('not null constraint failed')) {
      final col = _extractAfter(error, 'NOT NULL constraint failed:');
      return TutorAdvice(
        title: 'Falta un valor obligatorio',
        explanation: 'La columna $col fue declarada NOT NULL y el INSERT no '
            'le esta dando valor.',
        nextStep: 'Incluye esa columna en la lista del INSERT.',
      );
    }
    if (e.contains('foreign key constraint failed')) {
      return TutorAdvice(
        title: 'Integridad referencial rota',
        explanation: 'La fila que intentas insertar o borrar apunta a un '
            'registro padre que no existe, o tiene hijos que dependen de ella.',
        nextStep: 'Inserta primero el registro padre, o define el '
            'comportamiento ON DELETE.',
      );
    }
    if (e.contains('datatype mismatch')) {
      return TutorAdvice(
        title: 'Tipo de dato incompatible',
        explanation: 'El valor no corresponde al tipo declarado de la columna.',
        nextStep: 'Revisa comillas: los textos van entre comillas simples, '
            'los numeros no.',
      );
    }
    return TutorAdvice(
      title: 'La consulta fue rechazada',
      explanation: error,
      nextStep: 'Ejecuta primero una version mas simple (solo SELECT y FROM) '
          'y agrega una clausula a la vez.',
    );
  }

  /// Comentario global sobre un modelo ER, priorizando el error mas grave.
  static TutorAdvice reviewDesign(ErModel model) {
    final diagnostics = DesignAdvisor.analyze(model);
    final errors =
        diagnostics.where((d) => d.severity == Severity.error).toList();
    final warnings =
        diagnostics.where((d) => d.severity == Severity.warning).toList();

    if (errors.isNotEmpty) {
      final first = errors.first;
      return TutorAdvice(
        title: first.title,
        explanation: '${first.message}\n\nHay ${errors.length} error(es) de '
            'este tipo en el modelo. Corrige primero los identificadores: '
            'sin claves, el resto del diseno no se puede traducir a tablas.',
        nextStep: first.fix,
      );
    }
    if (warnings.isNotEmpty) {
      final first = warnings.first;
      return TutorAdvice(
        title: first.title,
        explanation: '${first.message}\n\nEl modelo ya es traducible a tablas, '
            'pero quedan ${warnings.length} punto(s) de mejora.',
        nextStep: first.fix,
      );
    }
    final nm = model.relationships.where((r) => r.isManyToMany).length;
    return TutorAdvice(
      title: 'Modelo estructuralmente correcto',
      explanation: 'Todas las entidades tienen clave primaria y participan en '
          'el modelo. ${nm > 0 ? 'Recuerda que las $nm relacion(es) N:M se '
              'convertiran en tablas asociativas.' : ''}',
      nextStep: 'Compara ahora cada cardinalidad con las reglas del enunciado: '
          'ahi es donde se pierden mas puntos.',
    );
  }

  /// Consulta opcional al tutor remoto. Si no hay endpoint configurado o la
  /// red falla, se devuelve null y la interfaz usa la explicacion local.
  static Future<TutorAdvice?> askRemote({
    required String question,
    required String context,
  }) async {
    if (!remoteEnabled) return null;
    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'question': question,
              'context': context,
              'role': 'tutor_bases_de_datos',
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return TutorAdvice(
        title: (body['title'] as String?) ?? 'Comentario del tutor',
        explanation: (body['explanation'] as String?) ?? '',
        nextStep: (body['next_step'] as String?) ?? '',
        remote: true,
      );
    } catch (_) {
      return null;
    }
  }

  static String _syntaxHint(String q) {
    if (q.contains('group by') && !q.contains('select')) {
      return 'Falta la clausula SELECT antes del agrupamiento.';
    }
    if (q.contains('where') && q.contains('count(')) {
      return 'Las funciones de agregacion no se filtran en WHERE: para eso '
          'existe HAVING, que se aplica despues del GROUP BY.';
    }
    if (RegExp(r'\bjoin\b').hasMatch(q) && !q.contains(' on ')) {
      return 'El JOIN necesita una condicion ON que indique por que columnas '
          'se unen las tablas.';
    }
    if (q.contains('"') && !q.contains("'")) {
      return 'En SQLite los literales de texto van entre comillas simples; '
          'las dobles se reservan para nombres de objetos.';
    }
    return 'Hay un token fuera de lugar: coma sobrante, parentesis sin cerrar '
        'o una palabra clave mal escrita.';
  }

  static String _extractAfter(String text, String marker) {
    final idx = text.toLowerCase().indexOf(marker.toLowerCase());
    if (idx < 0) return 'el objeto indicado';
    final rest = text.substring(idx + marker.length).trim();
    final token = rest.split(RegExp(r'[\s,()]')).firstWhere(
          (element) => element.isNotEmpty,
          orElse: () => 'el objeto indicado',
        );
    return token;
  }
}
