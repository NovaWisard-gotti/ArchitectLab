import '../models/activity.dart';

/// Módulo 5 - Firebase y modelado documental.
final LabModule moduleNoSql = LabModule(
  id: 'm5',
  title: 'Firebase y NoSQL',
  subtitle: 'Modelar por consulta, no por entidad',
  goal: 'Decidir cuándo un modelo documental conviene y cómo estructurarlo '
      'sin arrastrar hábitos relacionales.',
  activities: [
    ConceptActivity(
      id: 'm5a1',
      title: 'Modelado documental',
      summary: 'Colecciones, documentos, anidamiento y límites reales.',
      competencies: const [Competency.modeling, Competency.management],
      minutes: 10,
      questions: const [
        Question(
          id: 'm5a1q1',
          prompt: 'En Firestore, la unidad que se lee y escribe es:',
          choices: [
            Choice('La colección completa'),
            Choice('El documento', correct: true,
                why: 'Se factura y se transfiere por documento leído, así que '
                    'el tamaño y la forma del documento definen el costo.'),
            Choice('El campo individual'),
            Choice('La subcolección'),
          ],
          takeaway: 'Modelar en Firestore es decidir qué entra en cada '
              'documento.',
        ),
        Question(
          id: 'm5a1q2',
          context: 'Un curso puede acumular miles de comentarios.',
          prompt: '¿Cómo los guardas?',
          choices: [
            Choice('Como un arreglo dentro del documento del curso'),
            Choice('En una subcolección de comentarios dentro del curso',
                correct: true,
                why: 'Un documento tiene un límite de 1 MB y leerlo completo '
                    'por un comentario es caro. La subcolección se pagina.'),
            Choice('En un solo campo de texto separado por comas'),
            Choice('En una colección por comentario'),
          ],
          takeaway: 'Anida lo que siempre se lee junto; separa lo que crece '
              'sin límite.',
        ),
        Question(
          id: 'm5a1q3',
          prompt: 'Duplicar el nombre del autor dentro de cada comentario es:',
          choices: [
            Choice('Un error grave que rompe la 3FN'),
            Choice('Desnormalización intencional para evitar una lectura '
                'extra por comentario', correct: true,
                why: 'En NoSQL se optimiza para la consulta; el precio es '
                    'sincronizar la copia cuando el nombre cambia.'),
            Choice('Imposible en Firestore'),
            Choice('Obligatorio en todos los casos'),
          ],
          takeaway: 'La duplicación es una decisión consciente con costo de '
              'mantenimiento.',
        ),
        Question(
          id: 'm5a1q4',
          prompt: 'Firestore no ofrece JOIN. Eso significa que:',
          choices: [
            Choice('No se pueden relacionar datos'),
            Choice('Las relaciones se resuelven con lecturas adicionales o '
                'duplicando datos en el documento', correct: true,
                why: 'El modelo se diseña a partir de las pantallas que la app '
                    'necesita mostrar.'),
            Choice('Hay que usar SQL desde el cliente'),
            Choice('Solo se pueden guardar datos planos'),
          ],
          takeaway: 'En documental se modela por consulta; en relacional, por '
              'entidad.',
        ),
      ],
    ),
    ConceptActivity(
      id: 'm5a2',
      title: 'Consultas, costos y reglas',
      summary: 'Lo que decide si el proyecto es sostenible.',
      competencies: const [Competency.management],
      minutes: 10,
      questions: const [
        Question(
          id: 'm5a2q1',
          prompt: 'Mostrar el total de estudiantes de un curso con 50 000 '
              'inscritos leyendo toda la subcolección:',
          choices: [
            Choice('Es correcto porque devuelve el número exacto'),
            Choice('Cuesta 50 000 lecturas: conviene mantener un contador '
                'agregado', correct: true,
                why: 'Los contadores se actualizan con transacciones o '
                    'funciones, y el conteo se lee en una sola operación.'),
            Choice('Firestore lo cachea gratis para siempre'),
            Choice('Solo funciona con índices compuestos'),
          ],
          takeaway: 'En NoSQL los agregados se preparan al escribir, no al '
              'leer.',
        ),
        Question(
          id: 'm5a2q2',
          prompt: 'Las reglas de seguridad de Firestore:',
          choices: [
            Choice('Se aplican en el cliente, por eso se pueden burlar'),
            Choice('Se evalúan en el servidor y son la única barrera real de '
                'acceso a los datos', correct: true,
                why: 'La app móvil es código público: cualquiera puede llamar '
                    'a la API directamente.'),
            Choice('Reemplazan la autenticación'),
            Choice('Solo controlan la escritura'),
          ],
          takeaway: 'Validar solo en la app equivale a no validar.',
        ),
        Question(
          id: 'm5a2q3',
          context: 'Sistema de matrícula con cupos, prerrequisitos y reportes '
              'académicos oficiales.',
          prompt: '¿Qué motor eliges?',
          choices: [
            Choice('Firestore, por su escalabilidad automática'),
            Choice('Una base relacional, por las restricciones de integridad '
                'y los reportes con agregaciones', correct: true,
                why: 'Cupos, prerrequisitos y consistencia contable son '
                    'exactamente lo que un motor relacional garantiza.'),
            Choice('Archivos JSON en el dispositivo'),
            Choice('Da igual: cualquiera funciona'),
          ],
          takeaway: 'La elección se justifica por las reglas del dominio, no '
              'por la moda tecnológica.',
        ),
        Question(
          id: 'm5a2q4',
          context: 'Chat en tiempo real entre estudiantes de un curso.',
          prompt: '¿Qué motor encaja mejor?',
          choices: [
            Choice('Relacional con consultas cada segundo'),
            Choice('Firestore o Realtime Database, por sus escuchas en tiempo '
                'real y su modelo de escritura simple', correct: true,
                why: 'El caso pide propagación inmediata de documentos '
                    'pequeños, no integridad transaccional compleja.'),
            Choice('Un archivo compartido'),
            Choice('Una hoja de cálculo en la nube'),
          ],
          takeaway: 'Muchos sistemas reales combinan ambos motores según el '
              'caso de uso.',
        ),
      ],
    ),
  ],
);
