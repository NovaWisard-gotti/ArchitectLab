import '../models/activity.dart';
import '../models/er_model.dart';

/// Módulo 1 - Modelo entidad-relación.
final LabModule moduleEr = LabModule(
  id: 'm1',
  title: 'Modelo entidad-relación',
  subtitle: 'Del enunciado al diagrama',
  goal: 'Traducir un requerimiento escrito en entidades, atributos, claves y '
      'cardinalidades defendibles.',
  activities: [
    ConceptActivity(
      id: 'm1a1',
      title: 'Qué es una entidad y qué no lo es',
      summary: 'Distinguir entidades, atributos y valores antes de dibujar.',
      competencies: const [Competency.modeling],
      minutes: 8,
      questions: const [
        Question(
          id: 'm1a1q1',
          prompt: 'Un sistema de biblioteca registra libros, autores y '
              'préstamos. "Título" es:',
          choices: [
            Choice('Una entidad, porque aparece en el enunciado'),
            Choice('Un atributo de la entidad Libro',
                correct: true,
                why: 'No guardamos información adicional sobre un título: es '
                    'un dato que describe al libro.'),
            Choice('Una relación entre Libro y Autor'),
            Choice('Una clave foránea'),
          ],
          takeaway: 'Regla práctica: si necesitas guardar datos *sobre* ese '
              'concepto, es entidad; si solo describe a otro, es atributo.',
        ),
        Question(
          id: 'm1a1q2',
          prompt: 'Un estudiante puede registrar varios números de teléfono. '
              'Modelar "teléfono" como un atributo de Estudiante:',
          choices: [
            Choice('Es correcto si se separan con comas'),
            Choice('Rompe la primera forma normal al pasar a tablas',
                correct: true,
                why: 'Una celda debe contener un solo valor atómico. Varios '
                    'teléfonos en un campo impiden buscar, contar y validar.'),
            Choice('Es correcto porque el teléfono describe al estudiante'),
            Choice('Obliga a usar una base NoSQL'),
          ],
          takeaway: 'Un atributo multivaluado se extrae a una entidad propia '
              'relacionada 1:N.',
        ),
        Question(
          id: 'm1a1q3',
          prompt: '¿Cuál es la mejor clave primaria para Estudiante en una '
              'universidad?',
          choices: [
            Choice('El correo institucional'),
            Choice('El nombre completo'),
            Choice('El código de estudiante emitido por la universidad',
                correct: true,
                why: 'Es único, obligatorio y estable durante toda la vida '
                    'académica del alumno.'),
            Choice('El número de celular'),
          ],
          takeaway: 'Una clave primaria debe ser única, no nula, mínima y '
              'estable en el tiempo.',
        ),
        Question(
          id: 'm1a1q4',
          prompt: 'Una entidad débil es aquella que:',
          choices: [
            Choice('Tiene pocos atributos'),
            Choice('No se usa con frecuencia en el sistema'),
            Choice(
                'No puede identificarse sin la clave de otra entidad de la '
                'que depende',
                correct: true,
                why: 'Su identificación es parcial: necesita la clave de la '
                    'entidad fuerte para completarse.'),
            Choice('Solo existe en bases NoSQL'),
          ],
          takeaway: 'Ejemplo típico: Detalle de pedido no existe sin Pedido.',
        ),
        Question(
          id: 'm1a1q5',
          prompt: 'En el modelo relacional, una relación N:M entre Estudiante '
              'y Curso se implementa:',
          choices: [
            Choice('Repitiendo la columna curso_id en Estudiante'),
            Choice('Con una tabla asociativa que contiene ambas claves '
                'foráneas', correct: true,
                why: 'Es la única forma de representar muchas combinaciones '
                    'sin duplicar filas ni columnas.'),
            Choice('Con una clave foránea en cada una de las dos tablas'),
            Choice('Guardando una lista de cursos en un campo de texto'),
          ],
          takeaway: 'Si esa relación tiene datos propios (nota, periodo), la '
              'tabla asociativa se convierte en una entidad con nombre propio.',
        ),
        Question(
          id: 'm1a1q6',
          prompt: 'En una relación 1:N entre Carrera y Estudiante, la clave '
              'foránea se coloca en:',
          choices: [
            Choice('Carrera, porque es la entidad principal'),
            Choice('Estudiante, el lado N de la relación',
                correct: true,
                why: 'Cada estudiante pertenece a una sola carrera, así que el '
                    'valor cabe en una columna.'),
            Choice('Una tercera tabla intermedia'),
            Choice('Ambas tablas, para acelerar las consultas'),
          ],
          takeaway: 'La clave foránea siempre viaja al lado "muchos".',
        ),
      ],
    ),
    ErDesignActivity(
      id: 'm1a2',
      title: 'Laboratorio: biblioteca universitaria',
      summary: 'Primer modelo completo con una relación N:M y datos propios.',
      competencies: const [Competency.modeling],
      minutes: 20,
      brief: 'La biblioteca de la universidad necesita controlar sus '
          'préstamos. Cada libro tiene un ISBN, título y año de edición, y '
          'pertenece a una sola editorial. Un libro puede tener varios autores '
          'y un autor escribe varios libros. Los estudiantes, identificados '
          'por su código, solicitan préstamos; cada préstamo corresponde a un '
          'estudiante y registra fecha de salida y fecha de devolución.',
      requirements: const [
        'Modela Libro, Autor, Editorial, Estudiante y Préstamo.',
        'Un libro pertenece a una editorial; una editorial publica muchos '
            'libros.',
        'Libro y Autor se relacionan N:M.',
        'Un estudiante genera muchos préstamos; cada préstamo es de un solo '
            'estudiante.',
        'Un préstamo corresponde a un libro.',
      ],
      hints: const [
        'Subraya los sustantivos del enunciado: son candidatos a entidad.',
        'Las fechas de salida y devolución describen al préstamo, no al libro.',
        'Si un autor puede escribir varios libros y un libro tener varios '
            'autores, ninguna de las dos tablas puede guardar la referencia.',
      ],
      rubric: const ErRubric(
        entities: [
          RequiredEntity(
            key: 'libro',
            aliases: ['Libro'],
            attributes: [
              RequiredAttribute(['isbn'], mustBePk: true),
              RequiredAttribute(['titulo']),
            ],
            note: 'Es el objeto central del préstamo.',
          ),
          RequiredEntity(
            key: 'autor',
            aliases: ['Autor'],
            attributes: [RequiredAttribute(['nombre'])],
          ),
          RequiredEntity(
            key: 'editorial',
            aliases: ['Editorial'],
            note: 'Si la editorial fuera solo un texto dentro de Libro, se '
                'repetiría en cada ejemplar.',
          ),
          RequiredEntity(
            key: 'estudiante',
            aliases: ['Estudiante', 'Alumno', 'Lector'],
            attributes: [RequiredAttribute(['codigo'], mustBePk: true)],
          ),
          RequiredEntity(
            key: 'prestamo',
            aliases: ['Prestamo', 'Préstamo'],
            attributes: [
              RequiredAttribute(['fecha salida', 'fechasalida', 'salida']),
              RequiredAttribute(
                  ['fecha devolucion', 'fechadevolucion', 'devolucion']),
            ],
          ),
        ],
        relations: [
          RequiredRelation(
            fromKey: 'editorial',
            toKey: 'libro',
            fromCard: Cardinality.one,
            toCard: Cardinality.many,
            description: 'Una editorial publica muchos libros.',
          ),
          RequiredRelation(
            fromKey: 'libro',
            toKey: 'autor',
            fromCard: Cardinality.many,
            toCard: Cardinality.many,
            points: 4,
            description: 'Esta relación se convertirá en tabla asociativa.',
          ),
          RequiredRelation(
            fromKey: 'estudiante',
            toKey: 'prestamo',
            fromCard: Cardinality.one,
            toCard: Cardinality.many,
            description: 'Un estudiante puede tener muchos préstamos.',
          ),
          RequiredRelation(
            fromKey: 'libro',
            toKey: 'prestamo',
            fromCard: Cardinality.one,
            toCard: Cardinality.many,
            description: 'Cada préstamo corresponde a un libro.',
          ),
        ],
      ),
    ),
    ErDesignActivity(
      id: 'm1a3',
      title: 'Laboratorio: clínica veterinaria',
      summary: 'Entidad débil, relación identificadora y atributos de relación.',
      competencies: const [Competency.modeling],
      minutes: 22,
      brief: 'Una clínica veterinaria atiende mascotas. Cada dueño, '
          'identificado por su DNI, puede registrar varias mascotas, y cada '
          'mascota pertenece a un solo dueño. La mascota se identifica por un '
          'número correlativo dentro de la ficha del dueño, por lo que no '
          'tiene identificador propio. Cada mascota recibe consultas atendidas '
          'por un veterinario; en la consulta se registra fecha, motivo y '
          'diagnóstico. Un veterinario atiende muchas consultas.',
      requirements: const [
        'Modela Dueño, Mascota, Consulta y Veterinario.',
        'Mascota es una entidad débil que depende de Dueño.',
        'La relación Dueño - Mascota debe marcarse como identificadora.',
        'Una consulta pertenece a una mascota y a un veterinario.',
      ],
      hints: const [
        'Marca Mascota como débil en su ficha de edición.',
        'La relación identificadora se activa al editar la relación.',
        'Fecha, motivo y diagnóstico describen a la consulta.',
      ],
      rubric: const ErRubric(
        entities: [
          RequiredEntity(
            key: 'duenio',
            aliases: ['Duenio', 'Dueño', 'Propietario', 'Cliente'],
            attributes: [RequiredAttribute(['dni'], mustBePk: true)],
          ),
          RequiredEntity(
            key: 'mascota',
            aliases: ['Mascota'],
            needsPrimaryKey: false,
            attributes: [RequiredAttribute(['nombre'])],
            note: 'Debe existir como entidad débil.',
          ),
          RequiredEntity(
            key: 'consulta',
            aliases: ['Consulta', 'Atencion'],
            attributes: [
              RequiredAttribute(['fecha']),
              RequiredAttribute(['diagnostico']),
            ],
          ),
          RequiredEntity(
            key: 'veterinario',
            aliases: ['Veterinario', 'Medico'],
          ),
        ],
        relations: [
          RequiredRelation(
            fromKey: 'duenio',
            toKey: 'mascota',
            fromCard: Cardinality.one,
            toCard: Cardinality.many,
            points: 4,
            description: 'Debe ser identificadora: la mascota no existe sin '
                'su dueño.',
          ),
          RequiredRelation(
            fromKey: 'mascota',
            toKey: 'consulta',
            fromCard: Cardinality.one,
            toCard: Cardinality.many,
          ),
          RequiredRelation(
            fromKey: 'veterinario',
            toKey: 'consulta',
            fromCard: Cardinality.one,
            toCard: Cardinality.many,
          ),
        ],
      ),
    ),
    ConceptActivity(
      id: 'm1a4',
      title: 'Cardinalidad y participación',
      summary: 'Decidir el número correcto antes de escribir una sola tabla.',
      competencies: const [Competency.modeling, Competency.management],
      minutes: 9,
      questions: const [
        Question(
          id: 'm1a4q1',
          prompt: 'Participación total de Préstamo en la relación con Libro '
              'significa que:',
          choices: [
            Choice('Todos los libros deben estar prestados'),
            Choice('Ningún préstamo puede existir sin un libro asociado',
                correct: true,
                why: 'La participación total obliga a que cada instancia de '
                    'esa entidad participe en la relación.'),
            Choice('La relación es N:M'),
            Choice('El préstamo necesita clave compuesta'),
          ],
          takeaway: 'En tablas, la participación total se traduce en una '
              'clave foránea NOT NULL.',
        ),
        Question(
          id: 'm1a4q2',
          prompt: 'Una relación 1:1 entre Empleado y Credencial normalmente:',
          choices: [
            Choice('Se resuelve fusionando ambas en una sola tabla, salvo '
                'que tengan ciclos de vida o accesos distintos',
                correct: true,
                why: 'Mantener dos tablas 1:1 obliga a unir siempre; solo se '
                    'justifica por seguridad, volumen o opcionalidad.'),
            Choice('Siempre exige una tabla intermedia'),
            Choice('Es un error de modelado'),
            Choice('Se implementa con dos claves primarias iguales en tablas '
                'separadas obligatoriamente'),
          ],
          takeaway: 'Separar 1:1 es una decisión de diseño, no una regla.',
        ),
        Question(
          id: 'm1a4q3',
          prompt: 'La nota de un estudiante en un curso debe guardarse en:',
          choices: [
            Choice('La tabla Estudiante'),
            Choice('La tabla Curso'),
            Choice('La tabla asociativa Matrícula',
                correct: true,
                why: 'La nota no depende solo del estudiante ni solo del '
                    'curso: depende de la combinación de ambos.'),
            Choice('Una tabla de configuración'),
          ],
          takeaway: 'Los atributos de una relación N:M viven en la tabla que '
              'representa esa relación.',
        ),
        Question(
          id: 'm1a4q4',
          prompt: 'Un empleado supervisa a otros empleados. Esto se modela '
              'como:',
          choices: [
            Choice('Dos tablas: Empleado y Supervisor'),
            Choice('Una relación recursiva sobre Empleado con una clave '
                'foránea supervisor_id', correct: true,
                why: 'Supervisor y supervisado son el mismo tipo de objeto, '
                    'con roles distintos dentro de la misma relación.'),
            Choice('Una relación N:M obligatoria'),
            Choice('Una entidad débil'),
          ],
          takeaway: 'Nombrar los roles evita ambigüedad en relaciones '
              'recursivas.',
        ),
        Question(
          id: 'm1a4q5',
          prompt: 'Un modelo tiene 14 entidades y una de ellas no participa '
              'en ninguna relación. Lo más probable es que:',
          choices: [
            Choice('El modelo está bien: no toda entidad se relaciona'),
            Choice('Falta una relación o esa entidad no pertenece al alcance '
                'del sistema', correct: true,
                why: 'Los datos que no se pueden cruzar con nada rara vez '
                    'responden una pregunta del negocio.'),
            Choice('Se necesita normalizar hasta 3FN'),
            Choice('Hay que convertir esa entidad en atributo multivaluado'),
          ],
          takeaway: 'Una entidad aislada es una señal de alcance mal definido.',
        ),
      ],
    ),
  ],
);
