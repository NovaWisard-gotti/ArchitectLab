import '../models/activity.dart';

/// Modulo 2 - Normalizacion.
final LabModule moduleNorm = LabModule(
  id: 'm2',
  title: 'Normalizacion',
  subtitle: 'Eliminar redundancia con criterio',
  goal: 'Detectar dependencias parciales y transitivas, y descomponer una '
      'tabla sin perder informacion.',
  activities: [
    ConceptActivity(
      id: 'm2a1',
      title: 'Dependencias funcionales',
      summary: 'El lenguaje con el que se justifica cada descomposicion.',
      competencies: const [Competency.normalization],
      minutes: 9,
      questions: const [
        Question(
          id: 'm2a1q1',
          prompt: 'La dependencia funcional dni -> nombre significa que:',
          choices: [
            Choice('El nombre siempre es unico en la tabla'),
            Choice('Para un mismo valor de dni existe un unico valor de '
                'nombre', correct: true,
                why: 'Una dependencia funcional restringe valores, no orden '
                    'ni cantidad de filas.'),
            Choice('Nombre es clave primaria'),
            Choice('Dni y nombre deben ir en tablas separadas siempre'),
          ],
          takeaway: 'Las dependencias funcionales salen de las reglas del '
              'negocio, no de los datos de ejemplo.',
        ),
        Question(
          id: 'm2a1q2',
          prompt: 'En una tabla con clave (num_boleta, cod_producto), la '
              'dependencia cod_producto -> precio_unitario es:',
          choices: [
            Choice('Una dependencia transitiva'),
            Choice('Una dependencia parcial, porque depende de parte de la '
                'clave', correct: true,
                why: 'El determinante es un subconjunto propio de la clave '
                    'compuesta: eso viola la 2FN.'),
            Choice('Una dependencia trivial'),
            Choice('Correcta en 3FN'),
          ],
          takeaway: 'Dependencia parcial = 2FN rota. Solo puede ocurrir con '
              'claves compuestas.',
        ),
        Question(
          id: 'm2a1q3',
          prompt: 'En Empleado(dni, nombre, cod_area, nombre_area), la '
              'dependencia cod_area -> nombre_area es:',
          choices: [
            Choice('Parcial'),
            Choice('Transitiva: un atributo no clave determina a otro',
                correct: true,
                why: 'dni -> cod_area -> nombre_area. El nombre del area '
                    'depende de la clave solo de forma indirecta.'),
            Choice('Trivial'),
            Choice('Imposible en una base relacional'),
          ],
          takeaway: 'Dependencia transitiva = 3FN rota.',
        ),
        Question(
          id: 'm2a1q4',
          prompt: 'Una tabla esta en 2FN cuando:',
          choices: [
            Choice('No tiene valores nulos'),
            Choice('Esta en 1FN y ningun atributo no clave depende solo de '
                'parte de la clave', correct: true,
                why: 'La 2FN se ocupa exclusivamente de las dependencias '
                    'parciales.'),
            Choice('Tiene clave primaria simple'),
            Choice('No tiene claves foraneas'),
          ],
          takeaway: 'Si la clave primaria es simple, la 2FN se cumple '
              'automaticamente.',
        ),
        Question(
          id: 'm2a1q5',
          prompt: 'Diferencia principal entre 3FN y BCNF:',
          choices: [
            Choice('BCNF exige eliminar todas las claves foraneas'),
            Choice('BCNF exige que todo determinante sea superclave, incluso '
                'cuando el dependiente es atributo primo',
                correct: true,
                why: 'La 3FN tolera ese caso; BCNF no. Por eso BCNF es mas '
                    'estricta.'),
            Choice('3FN se aplica solo a bases NoSQL'),
            Choice('No hay diferencia practica'),
          ],
          takeaway: 'En la mayoria de sistemas academicos 3FN es suficiente; '
              'BCNF importa con claves candidatas superpuestas.',
        ),
      ],
    ),
    NormalizationActivity(
      id: 'm2a2',
      title: 'Laboratorio: boletas de venta',
      summary: 'Llevar una tabla plana de ventas hasta 3FN.',
      competencies: const [Competency.normalization, Competency.management],
      minutes: 22,
      brief: 'Una tienda registra sus ventas en una sola hoja de calculo. '
          'Cada fila representa un producto dentro de una boleta. Descompon la '
          'tabla hasta 3FN usando las dependencias funcionales declaradas.',
      sampleRows: const [
        ['num_boleta', 'fecha', 'dni_cliente', 'nombre_cliente',
            'cod_producto', 'descripcion_producto', 'precio_unitario',
            'cantidad'],
        ['B-001', '02/03', '4111', 'Rosa Ayala', 'P10', 'Cuaderno A4', '8.50',
            '3'],
        ['B-001', '02/03', '4111', 'Rosa Ayala', 'P20', 'Lapicero azul',
            '1.20', '5'],
        ['B-002', '03/03', '4222', 'Luis Prado', 'P10', 'Cuaderno A4', '8.50',
            '1'],
        ['B-003', '03/03', '4111', 'Rosa Ayala', 'P30', 'Mochila', '75.00',
            '1'],
      ],
      attributes: const [
        'num_boleta',
        'fecha',
        'dni_cliente',
        'nombre_cliente',
        'cod_producto',
        'descripcion_producto',
        'precio_unitario',
        'cantidad',
      ],
      fds: const [
        Fd(['num_boleta'], ['fecha', 'dni_cliente']),
        Fd(['dni_cliente'], ['nombre_cliente']),
        Fd(['cod_producto'], ['descripcion_producto', 'precio_unitario']),
        Fd(['num_boleta', 'cod_producto'], ['cantidad']),
      ],
      expected: const [
        ExpectedTable(
          name: 'cliente',
          primaryKey: ['dni_cliente'],
          attributes: ['dni_cliente', 'nombre_cliente'],
        ),
        ExpectedTable(
          name: 'producto',
          primaryKey: ['cod_producto'],
          attributes: [
            'cod_producto',
            'descripcion_producto',
            'precio_unitario'
          ],
        ),
        ExpectedTable(
          name: 'boleta',
          primaryKey: ['num_boleta'],
          attributes: ['num_boleta', 'fecha', 'dni_cliente'],
        ),
        ExpectedTable(
          name: 'detalle_boleta',
          primaryKey: ['num_boleta', 'cod_producto'],
          attributes: ['num_boleta', 'cod_producto', 'cantidad'],
        ),
      ],
    ),
    NormalizationActivity(
      id: 'm2a3',
      title: 'Laboratorio: registro de matriculas',
      summary: 'Caso academico con dependencia transitiva encadenada.',
      competencies: const [Competency.normalization],
      minutes: 24,
      brief: 'La oficina academica mantiene un unico archivo de matriculas. '
          'Cada curso tiene un docente asignado. Descompon hasta 3FN y cuida '
          'que la clave de la tabla de matricula permita repetir el curso en '
          'otro periodo.',
      sampleRows: const [
        ['cod_estudiante', 'nombre_estudiante', 'cod_curso', 'nombre_curso',
            'creditos', 'cod_docente', 'nombre_docente', 'periodo', 'nota'],
        ['S001', 'Ana Quispe', 'BD101', 'Base de Datos I', '4', 'D07',
            'M. Palomino', '2025-I', '16'],
        ['S002', 'Bruno Flores', 'BD101', 'Base de Datos I', '4', 'D07',
            'M. Palomino', '2025-I', '11'],
        ['S002', 'Bruno Flores', 'BD101', 'Base de Datos I', '4', 'D07',
            'M. Palomino', '2025-II', '14'],
        ['S001', 'Ana Quispe', 'AL100', 'Algoritmos', '5', 'D12', 'R. Cabrera',
            '2025-I', '18'],
      ],
      attributes: const [
        'cod_estudiante',
        'nombre_estudiante',
        'cod_curso',
        'nombre_curso',
        'creditos',
        'cod_docente',
        'nombre_docente',
        'periodo',
        'nota',
      ],
      fds: const [
        Fd(['cod_estudiante'], ['nombre_estudiante']),
        Fd(['cod_curso'], ['nombre_curso', 'creditos', 'cod_docente']),
        Fd(['cod_docente'], ['nombre_docente']),
        Fd(['cod_estudiante', 'cod_curso', 'periodo'], ['nota']),
      ],
      expected: const [
        ExpectedTable(
          name: 'estudiante',
          primaryKey: ['cod_estudiante'],
          attributes: ['cod_estudiante', 'nombre_estudiante'],
        ),
        ExpectedTable(
          name: 'docente',
          primaryKey: ['cod_docente'],
          attributes: ['cod_docente', 'nombre_docente'],
        ),
        ExpectedTable(
          name: 'curso',
          primaryKey: ['cod_curso'],
          attributes: ['cod_curso', 'nombre_curso', 'creditos', 'cod_docente'],
        ),
        ExpectedTable(
          name: 'matricula',
          primaryKey: ['cod_estudiante', 'cod_curso', 'periodo'],
          attributes: ['cod_estudiante', 'cod_curso', 'periodo', 'nota'],
        ),
      ],
    ),
    ConceptActivity(
      id: 'm2a4',
      title: 'Anomalias y desnormalizacion',
      summary: 'Cuando normalizar deja de ser la respuesta correcta.',
      competencies: const [Competency.normalization, Competency.management],
      minutes: 8,
      questions: const [
        Question(
          id: 'm2a4q1',
          prompt: 'El nombre de un cliente esta repetido en 900 filas y se '
              'corrige solo en 300. Esta es una anomalia de:',
          choices: [
            Choice('Insercion'),
            Choice('Actualizacion', correct: true,
                why: 'La redundancia obliga a modificar el mismo dato en '
                    'muchos lugares, y basta olvidar uno para perder '
                    'consistencia.'),
            Choice('Eliminacion'),
            Choice('Concurrencia'),
          ],
          takeaway: 'La normalizacion ataca principalmente la redundancia que '
              'produce inconsistencia.',
        ),
        Question(
          id: 'm2a4q2',
          prompt: 'No se puede registrar un producto nuevo hasta que alguien '
              'lo compre. Esta es una anomalia de:',
          choices: [
            Choice('Insercion', correct: true,
                why: 'La estructura obliga a tener datos de venta para poder '
                    'guardar datos de producto.'),
            Choice('Actualizacion'),
            Choice('Lectura'),
            Choice('Integridad referencial'),
          ],
          takeaway: 'Cada concepto independiente merece su propia tabla.',
        ),
        Question(
          id: 'm2a4q3',
          prompt: 'Un reporte de ventas tarda demasiado por unir seis tablas. '
              'La opcion mas razonable primero es:',
          choices: [
            Choice('Desnormalizar de inmediato uniendo las seis tablas'),
            Choice('Revisar indices y el plan de ejecucion antes de tocar el '
                'modelo', correct: true,
                why: 'La mayoria de problemas de lentitud se resuelven con '
                    'indices o consultas mejor escritas, sin sacrificar '
                    'integridad.'),
            Choice('Migrar a NoSQL'),
            Choice('Guardar el reporte en un archivo de texto'),
          ],
          takeaway: 'Desnormalizar es una decision de rendimiento medida, no '
              'un atajo de diseno.',
        ),
        Question(
          id: 'm2a4q4',
          prompt: 'Si se decide desnormalizar de forma controlada, el costo '
              'que se acepta es:',
          choices: [
            Choice('Perder la clave primaria'),
            Choice('Mantener redundancia y asumir la responsabilidad de '
                'sincronizarla', correct: true,
                why: 'La copia duplicada debe actualizarse por trigger, '
                    'proceso batch o codigo de aplicacion.'),
            Choice('No poder usar SQL'),
            Choice('Renunciar a las transacciones'),
          ],
          takeaway: 'Desnormalizar cambia complejidad de lectura por '
              'complejidad de escritura.',
        ),
      ],
    ),
  ],
);
