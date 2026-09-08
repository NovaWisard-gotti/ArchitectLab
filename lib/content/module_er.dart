import '../models/activity.dart';
import '../models/er_model.dart';

/// Modulo 1 - Modelo entidad-relacion.
final LabModule moduleEr = LabModule(
  id: 'm1',
  title: 'Modelo entidad-relacion',
  subtitle: 'Del enunciado al diagrama',
  goal: 'Traducir un requerimiento escrito en entidades, atributos, claves y '
      'cardinalidades defendibles.',
  activities: [
    ConceptActivity(
      id: 'm1a1',
      title: 'Que es una entidad y que no lo es',
      summary: 'Distinguir entidades, atributos y valores antes de dibujar.',
      competencies: const [Competency.modeling],
      minutes: 8,
      questions: const [
        Question(
          id: 'm1a1q1',
          prompt: 'Un sistema de biblioteca registra libros, autores y '
              'prestamos. "Titulo" es:',
          choices: [
            Choice('Una entidad, porque aparece en el enunciado'),
            Choice('Un atributo de la entidad Libro',
                correct: true,
                why: 'No guardamos informacion adicional sobre un titulo: es '
                    'un dato que describe al libro.'),
            Choice('Una relacion entre Libro y Autor'),
            Choice('Una clave foranea'),
          ],
          takeaway: 'Regla practica: si necesitas guardar datos *sobre* ese '
              'concepto, es entidad; si solo describe a otro, es atributo.',
        ),
        Question(
          id: 'm1a1q2',
          prompt: 'Un estudiante puede registrar varios numeros de telefono. '
              'Modelar "telefono" como un atributo de Estudiante:',
          choices: [
            Choice('Es correcto si se separan con comas'),
            Choice('Rompe la primera forma normal al pasar a tablas',
                correct: true,
                why: 'Una celda debe contener un solo valor atomico. Varios '
                    'telefonos en un campo impiden buscar, contar y validar.'),
            Choice('Es correcto porque el telefono describe al estudiante'),
            Choice('Obliga a usar una base NoSQL'),
          ],
          takeaway: 'Un atributo multivaluado se extrae a una entidad propia '
              'relacionada 1:N.',
        ),
        Question(
          id: 'm1a1q3',
          prompt: 'Cual es la mejor clave primaria para Estudiante en una '
              'universidad?',
          choices: [
            Choice('El correo institucional'),
            Choice('El nombre completo'),
            Choice('El codigo de estudiante emitido por la universidad',
                correct: true,
                why: 'Es unico, obligatorio y estable durante toda la vida '
                    'academica del alumno.'),
            Choice('El numero de celular'),
          ],
          takeaway: 'Una clave primaria debe ser unica, no nula, minima y '
              'estable en el tiempo.',
        ),
        Question(
          id: 'm1a1q4',
          prompt: 'Una entidad debil es aquella que:',
          choices: [
            Choice('Tiene pocos atributos'),
            Choice('No se usa con frecuencia en el sistema'),
            Choice(
                'No puede identificarse sin la clave de otra entidad de la '
                'que depende',
                correct: true,
                why: 'Su identificacion es parcial: necesita la clave de la '
                    'entidad fuerte para completarse.'),
            Choice('Solo existe en bases NoSQL'),
          ],
          takeaway: 'Ejemplo tipico: Detalle de pedido no existe sin Pedido.',
        ),
        Question(
          id: 'm1a1q5',
          prompt: 'En el modelo relacional, una relacion N:M entre Estudiante '
              'y Curso se implementa:',
          choices: [
            Choice('Repitiendo la columna curso_id en Estudiante'),
            Choice('Con una tabla asociativa que contiene ambas claves '
                'foraneas', correct: true,
                why: 'Es la unica forma de representar muchas combinaciones '
                    'sin duplicar filas ni columnas.'),
            Choice('Con una clave foranea en cada una de las dos tablas'),
            Choice('Guardando una lista de cursos en un campo de texto'),
          ],
          takeaway: 'Si esa relacion tiene datos propios (nota, periodo), la '
              'tabla asociativa se convierte en una entidad con nombre propio.',
        ),
        Question(
          id: 'm1a1q6',
          prompt: 'En una relacion 1:N entre Carrera y Estudiante, la clave '
              'foranea se coloca en:',
          choices: [
            Choice('Carrera, porque es la entidad principal'),
            Choice('Estudiante, el lado N de la relacion',
                correct: true,
                why: 'Cada estudiante pertenece a una sola carrera, asi que el '
                    'valor cabe en una columna.'),
            Choice('Una tercera tabla intermedia'),
            Choice('Ambas tablas, para acelerar las consultas'),
          ],
          takeaway: 'La clave foranea siempre viaja al lado "muchos".',
        ),
      ],
    ),
    ErDesignActivity(
      id: 'm1a2',
      title: 'Laboratorio: biblioteca universitaria',
      summary: 'Primer modelo completo con una relacion N:M y datos propios.',
      competencies: const [Competency.modeling],
      minutes: 20,
      brief: 'La biblioteca de la universidad necesita controlar sus '
          'prestamos. Cada libro tiene un ISBN, titulo y ano de edicion, y '
          'pertenece a una sola editorial. Un libro puede tener varios autores '
          'y un autor escribe varios libros. Los estudiantes, identificados '
          'por su codigo, solicitan prestamos; cada prestamo corresponde a un '
          'estudiante y registra fecha de salida y fecha de devolucion.',
      requirements: const [
        'Modela Libro, Autor, Editorial, Estudiante y Prestamo.',
        'Un libro pertenece a una editorial; una editorial publica muchos '
            'libros.',
        'Libro y Autor se relacionan N:M.',
        'Un estudiante genera muchos prestamos; cada prestamo es de un solo '
            'estudiante.',
        'Un prestamo corresponde a un libro.',
      ],
      hints: const [
        'Subraya los sustantivos del enunciado: son candidatos a entidad.',
        'Las fechas de salida y devolucion describen al prestamo, no al libro.',
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
            note: 'Es el objeto central del prestamo.',
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
                'repetiria en cada ejemplar.',
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
            description: 'Esta relacion se convertira en tabla asociativa.',
          ),
          RequiredRelation(
            fromKey: 'estudiante',
            toKey: 'prestamo',
            fromCard: Cardinality.one,
            toCard: Cardinality.many,
            description: 'Un estudiante puede tener muchos prestamos.',
          ),
          RequiredRelation(
            fromKey: 'libro',
            toKey: 'prestamo',
            fromCard: Cardinality.one,
            toCard: Cardinality.many,
            description: 'Cada prestamo corresponde a un libro.',
          ),
        ],
      ),
    ),
    ErDesignActivity(
      id: 'm1a3',
      title: 'Laboratorio: clinica veterinaria',
      summary: 'Entidad debil, relacion identificadora y atributos de relacion.',
      competencies: const [Competency.modeling],
      minutes: 22,
      brief: 'Una clinica veterinaria atiende mascotas. Cada duenio, '
          'identificado por su DNI, puede registrar varias mascotas, y cada '
          'mascota pertenece a un solo duenio. La mascota se identifica por un '
          'numero correlativo dentro de la ficha del duenio, por lo que no '
          'tiene identificador propio. Cada mascota recibe consultas atendidas '
          'por un veterinario; en la consulta se registra fecha, motivo y '
          'diagnostico. Un veterinario atiende muchas consultas.',
      requirements: const [
        'Modela Duenio, Mascota, Consulta y Veterinario.',
        'Mascota es una entidad debil que depende de Duenio.',
        'La relacion Duenio - Mascota debe marcarse como identificadora.',
        'Una consulta pertenece a una mascota y a un veterinario.',
      ],
      hints: const [
        'Marca Mascota como debil en su ficha de edicion.',
        'La relacion identificadora se activa al editar la relacion.',
        'Fecha, motivo y diagnostico describen a la consulta.',
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
            note: 'Debe existir como entidad debil.',
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
                'su duenio.',
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
      title: 'Cardinalidad y participacion',
      summary: 'Decidir el numero correcto antes de escribir una sola tabla.',
      competencies: const [Competency.modeling, Competency.management],
      minutes: 9,
      questions: const [
        Question(
          id: 'm1a4q1',
          prompt: 'Participacion total de Prestamo en la relacion con Libro '
              'significa que:',
          choices: [
            Choice('Todos los libros deben estar prestados'),
            Choice('Ningun prestamo puede existir sin un libro asociado',
                correct: true,
                why: 'La participacion total obliga a que cada instancia de '
                    'esa entidad participe en la relacion.'),
            Choice('La relacion es N:M'),
            Choice('El prestamo necesita clave compuesta'),
          ],
          takeaway: 'En tablas, la participacion total se traduce en una '
              'clave foranea NOT NULL.',
        ),
        Question(
          id: 'm1a4q2',
          prompt: 'Una relacion 1:1 entre Empleado y Credencial normalmente:',
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
          takeaway: 'Separar 1:1 es una decision de diseno, no una regla.',
        ),
        Question(
          id: 'm1a4q3',
          prompt: 'La nota de un estudiante en un curso debe guardarse en:',
          choices: [
            Choice('La tabla Estudiante'),
            Choice('La tabla Curso'),
            Choice('La tabla asociativa Matricula',
                correct: true,
                why: 'La nota no depende solo del estudiante ni solo del '
                    'curso: depende de la combinacion de ambos.'),
            Choice('Una tabla de configuracion'),
          ],
          takeaway: 'Los atributos de una relacion N:M viven en la tabla que '
              'representa esa relacion.',
        ),
        Question(
          id: 'm1a4q4',
          prompt: 'Un empleado supervisa a otros empleados. Esto se modela '
              'como:',
          choices: [
            Choice('Dos tablas: Empleado y Supervisor'),
            Choice('Una relacion recursiva sobre Empleado con una clave '
                'foranea supervisor_id', correct: true,
                why: 'Supervisor y supervisado son el mismo tipo de objeto, '
                    'con roles distintos dentro de la misma relacion.'),
            Choice('Una relacion N:M obligatoria'),
            Choice('Una entidad debil'),
          ],
          takeaway: 'Nombrar los roles evita ambiguedad en relaciones '
              'recursivas.',
        ),
        Question(
          id: 'm1a4q5',
          prompt: 'Un modelo tiene 14 entidades y una de ellas no participa '
              'en ninguna relacion. Lo mas probable es que:',
          choices: [
            Choice('El modelo esta bien: no toda entidad se relaciona'),
            Choice('Falta una relacion o esa entidad no pertenece al alcance '
                'del sistema', correct: true,
                why: 'Los datos que no se pueden cruzar con nada rara vez '
                    'responden una pregunta del negocio.'),
            Choice('Se necesita normalizar hasta 3FN'),
            Choice('Hay que convertir esa entidad en atributo multivaluado'),
          ],
          takeaway: 'Una entidad aislada es una senal de alcance mal definido.',
        ),
      ],
    ),
  ],
);
