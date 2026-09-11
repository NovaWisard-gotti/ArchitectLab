import '../models/activity.dart';

/// Módulo 3 - SQL ejecutable sobre el esquema académico.
final LabModule moduleSql = LabModule(
  id: 'm3',
  title: 'SQL',
  subtitle: 'Consultas ejecutadas de verdad',
  goal: 'Escribir consultas correctas sobre un esquema real y leer el error '
      'del motor como información, no como castigo.',
  activities: [
    SqlLabActivity(
      id: 'm3a1',
      title: 'Consultas básicas',
      summary: 'SELECT, WHERE, LIKE, DISTINCT y ORDER BY.',
      competencies: const [Competency.sql],
      minutes: 15,
      schemaName: 'universidad',
      scenario: 'Trabajas con el sistema académico. Cada intento reconstruye '
          'la base desde cero, así que puedes experimentar sin miedo.',
      tasks: const [
        SqlTask(
          id: 'm3a1t1',
          prompt: 'Lista el codigo y el nombre de los estudiantes del ciclo 5, '
              'ordenados alfabéticamente por nombre.',
          solution:
              'SELECT codigo, nombre FROM estudiante WHERE ciclo = 5 '
              'ORDER BY nombre',
          ordered: true,
          mustContain: ['where', 'order by'],
          hint: 'El orden importa en esta tarea: usa ORDER BY nombre.',
        ),
        SqlTask(
          id: 'm3a1t2',
          prompt: 'Muestra el nombre y los creditos de los cursos que tienen '
              'más de 3 creditos.',
          solution: 'SELECT nombre, creditos FROM curso WHERE creditos > 3',
          mustContain: ['where'],
          hint: 'Más de 3 no incluye a 3.',
        ),
        SqlTask(
          id: 'm3a1t3',
          prompt: 'Lista el nombre de los estudiantes cuyo nombre empieza con '
              'la letra M.',
          solution: "SELECT nombre FROM estudiante WHERE nombre LIKE 'M%'",
          mustContain: ['like'],
          hint: 'El comodín % representa cualquier cantidad de caracteres.',
        ),
        SqlTask(
          id: 'm3a1t4',
          prompt: 'Muestra los periodos académicos registrados en matricula, '
              'sin repetirlos.',
          solution: 'SELECT DISTINCT periodo FROM matricula',
          mustContain: ['distinct'],
          hint: 'DISTINCT elimina filas duplicadas del resultado.',
        ),
      ],
    ),
    SqlLabActivity(
      id: 'm3a2',
      title: 'Uniones y agrupamiento',
      summary: 'JOIN, LEFT JOIN, GROUP BY y funciones de agregación.',
      competencies: const [Competency.sql, Competency.management],
      minutes: 20,
      schemaName: 'universidad',
      scenario: 'La oficina académica necesita reportes que cruzan varias '
          'tablas. Usa alias de tabla para escribir menos y leer mejor.',
      tasks: const [
        SqlTask(
          id: 'm3a2t1',
          prompt: 'Muestra el nombre de cada estudiante junto al nombre de su '
              'carrera. Usa los alias estudiante y carrera para las columnas.',
          solution: 'SELECT e.nombre AS estudiante, c.nombre AS carrera '
              'FROM estudiante e JOIN carrera c ON c.id = e.carrera_id',
          mustContain: ['join', 'as'],
          hint: 'Dos columnas se llaman nombre: sin alias el resultado se '
              'colapsa en una sola.',
          points: 2,
        ),
        SqlTask(
          id: 'm3a2t2',
          prompt: 'Cuenta cuántos estudiantes tiene cada carrera. Devuelve el '
              'nombre de la carrera (alias carrera) y el total (alias total). '
              'Incluye solo carreras que tengan estudiantes.',
          solution: 'SELECT c.nombre AS carrera, COUNT(e.id) AS total '
              'FROM carrera c JOIN estudiante e ON e.carrera_id = c.id '
              'GROUP BY c.nombre',
          mustContain: ['group by', 'count('],
          hint: 'Todo lo que va en el SELECT y no es agregado debe estar en '
              'el GROUP BY.',
          points: 2,
        ),
        SqlTask(
          id: 'm3a2t3',
          prompt: 'Calcula el promedio de nota por curso. Devuelve codigo, '
              'nombre y el promedio con alias promedio.',
          solution: 'SELECT cu.codigo, cu.nombre, AVG(m.nota) AS promedio '
              'FROM curso cu JOIN matricula m ON m.curso_id = cu.id '
              'GROUP BY cu.codigo, cu.nombre',
          mustContain: ['avg(', 'group by'],
          hint: 'Los cursos sin matrículas no deben aparecer: usa JOIN, no '
              'LEFT JOIN.',
          points: 2,
        ),
        SqlTask(
          id: 'm3a2t4',
          prompt: 'Lista el nombre de las carreras que no tienen ningún '
              'estudiante registrado.',
          solution: 'SELECT c.nombre FROM carrera c '
              'LEFT JOIN estudiante e ON e.carrera_id = c.id '
              'WHERE e.id IS NULL',
          mustContain: ['left join', 'is null'],
          hint: 'El LEFT JOIN conserva las filas de la izquierda y rellena '
              'con NULL las que no encuentran pareja.',
          points: 2,
        ),
      ],
    ),
    SqlLabActivity(
      id: 'm3a3',
      title: 'Subconsultas y filtros de grupo',
      summary: 'Diferencia práctica entre WHERE y HAVING.',
      competencies: const [Competency.sql],
      minutes: 18,
      schemaName: 'universidad',
      scenario: 'Ahora las preguntas dependen de un valor que hay que '
          'calcular antes de filtrar.',
      tasks: const [
        SqlTask(
          id: 'm3a3t1',
          prompt: 'Muestra el id y la nota de las matriculas cuya nota supera '
              'el promedio general de todas las notas.',
          solution: 'SELECT id, nota FROM matricula '
              'WHERE nota > (SELECT AVG(nota) FROM matricula)',
          mustContain: ['avg('],
          hint: 'La subconsulta devuelve un único valor y se puede usar '
              'directamente en la comparación.',
          points: 2,
        ),
        SqlTask(
          id: 'm3a3t2',
          prompt: 'Lista el codigo del curso y su promedio (alias promedio) '
              'solo para los cursos cuyo promedio supera 14.',
          solution: 'SELECT cu.codigo, AVG(m.nota) AS promedio '
              'FROM curso cu JOIN matricula m ON m.curso_id = cu.id '
              'GROUP BY cu.codigo HAVING AVG(m.nota) > 14',
          mustContain: ['having'],
          forbid: ['where avg'],
          hint: 'WHERE filtra filas antes de agrupar; HAVING filtra grupos '
              'después de agrupar.',
          points: 2,
        ),
        SqlTask(
          id: 'm3a3t3',
          prompt: 'Muestra el nombre y el promedio (alias promedio) del '
              'estudiante con mejor promedio general. Devuelve una sola fila.',
          solution: 'SELECT e.nombre, AVG(m.nota) AS promedio '
              'FROM estudiante e JOIN matricula m ON m.estudiante_id = e.id '
              'GROUP BY e.id, e.nombre ORDER BY promedio DESC LIMIT 1',
          mustContain: ['limit'],
          hint: 'Agrupa por estudiante, ordena de mayor a menor y corta el '
              'resultado.',
          points: 2,
        ),
      ],
    ),
    SqlLabActivity(
      id: 'm3a4',
      title: 'Definición y manipulación de datos',
      summary: 'CREATE TABLE con restricciones, INSERT, UPDATE y DELETE.',
      competencies: const [Competency.sql, Competency.management],
      minutes: 20,
      schemaName: 'universidad',
      scenario: 'Aquí no basta con devolver filas: se evalúa el estado final '
          'de la base después de ejecutar tus sentencias.',
      tasks: const [
        SqlTask(
          id: 'm3a4t1',
          prompt: 'Crea la tabla docente con id (clave primaria entera), '
              'codigo (texto obligatorio y único) y nombre (texto '
              'obligatorio). Luego registra a (1, D07, M. Palomino) y '
              '(2, D12, R. Cabrera).',
          solution: '''
CREATE TABLE docente (
  id INTEGER PRIMARY KEY,
  codigo TEXT NOT NULL UNIQUE,
  nombre TEXT NOT NULL
);
INSERT INTO docente (id, codigo, nombre) VALUES
 (1, 'D07', 'M. Palomino'),
 (2, 'D12', 'R. Cabrera');''',
          verify: 'SELECT id, codigo, nombre FROM docente ORDER BY id',
          ordered: true,
          mustContain: ['create table', 'primary key', 'not null', 'unique'],
          hint: 'Puedes escribir varias sentencias separadas por punto y '
              'coma; se ejecutan en orden.',
          points: 3,
        ),
        SqlTask(
          id: 'm3a4t2',
          prompt: 'Sube 2 puntos las notas de las matrículas del curso BD101 '
              'en el periodo 2025-I, sin que ninguna nota supere 20.',
          solution: '''
UPDATE matricula
SET nota = MIN(nota + 2, 20)
WHERE periodo = '2025-I'
  AND curso_id = (SELECT id FROM curso WHERE codigo = 'BD101');''',
          verify: 'SELECT id, nota FROM matricula ORDER BY id',
          ordered: true,
          mustContain: ['update', 'where'],
          hint: 'MIN con dos argumentos devuelve el menor de los dos valores.',
          points: 3,
        ),
        SqlTask(
          id: 'm3a4t3',
          prompt: 'Elimina todas las matrículas del periodo 2025-II que '
              'pertenecen al estudiante con codigo S002.',
          solution: '''
DELETE FROM matricula
WHERE periodo = '2025-II'
  AND estudiante_id = (SELECT id FROM estudiante WHERE codigo = 'S002');''',
          verify: 'SELECT id, estudiante_id, periodo FROM matricula '
              'ORDER BY id',
          ordered: true,
          mustContain: ['delete', 'where'],
          hint: 'Un DELETE sin WHERE vacia la tabla completa.',
          points: 3,
        ),
      ],
    ),
  ],
);
