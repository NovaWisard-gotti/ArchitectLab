import '../models/activity.dart';

/// Modulo 5 - Firebase y modelado documental.
final LabModule moduleNoSql = LabModule(
  id: 'm5',
  title: 'Firebase y NoSQL',
  subtitle: 'Modelar por consulta, no por entidad',
  goal: 'Decidir cuando un modelo documental conviene y como estructurarlo '
      'sin arrastrar habitos relacionales.',
  activities: [
    ConceptActivity(
      id: 'm5a1',
      title: 'Modelado documental',
      summary: 'Colecciones, documentos, anidamiento y limites reales.',
      competencies: const [Competency.modeling, Competency.management],
      minutes: 10,
      questions: const [
        Question(
          id: 'm5a1q1',
          prompt: 'En Firestore, la unidad que se lee y escribe es:',
          choices: [
            Choice('La coleccion completa'),
            Choice('El documento', correct: true,
                why: 'Se factura y se transfiere por documento leido, asi que '
                    'el tamano y la forma del documento definen el costo.'),
            Choice('El campo individual'),
            Choice('La subcoleccion'),
          ],
          takeaway: 'Modelar en Firestore es decidir que entra en cada '
              'documento.',
        ),
        Question(
          id: 'm5a1q2',
          context: 'Un curso puede acumular miles de comentarios.',
          prompt: 'Como los guardas?',
          choices: [
            Choice('Como un arreglo dentro del documento del curso'),
            Choice('En una subcoleccion de comentarios dentro del curso',
                correct: true,
                why: 'Un documento tiene un limite de 1 MB y leerlo completo '
                    'por un comentario es caro. La subcoleccion se pagina.'),
            Choice('En un solo campo de texto separado por comas'),
            Choice('En una coleccion por comentario'),
          ],
          takeaway: 'Anida lo que siempre se lee junto; separa lo que crece '
              'sin limite.',
        ),
        Question(
          id: 'm5a1q3',
          prompt: 'Duplicar el nombre del autor dentro de cada comentario es:',
          choices: [
            Choice('Un error grave que rompe la 3FN'),
            Choice('Desnormalizacion intencional para evitar una lectura '
                'extra por comentario', correct: true,
                why: 'En NoSQL se optimiza para la consulta; el precio es '
                    'sincronizar la copia cuando el nombre cambia.'),
            Choice('Imposible en Firestore'),
            Choice('Obligatorio en todos los casos'),
          ],
          takeaway: 'La duplicacion es una decision consciente con costo de '
              'mantenimiento.',
        ),
        Question(
          id: 'm5a1q4',
          prompt: 'Firestore no ofrece JOIN. Eso significa que:',
          choices: [
            Choice('No se pueden relacionar datos'),
            Choice('Las relaciones se resuelven con lecturas adicionales o '
                'duplicando datos en el documento', correct: true,
                why: 'El modelo se disena a partir de las pantallas que la app '
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
              'inscritos leyendo toda la subcoleccion:',
          choices: [
            Choice('Es correcto porque devuelve el numero exacto'),
            Choice('Cuesta 50 000 lecturas: conviene mantener un contador '
                'agregado', correct: true,
                why: 'Los contadores se actualizan con transacciones o '
                    'funciones, y el conteo se lee en una sola operacion.'),
            Choice('Firestore lo cachea gratis para siempre'),
            Choice('Solo funciona con indices compuestos'),
          ],
          takeaway: 'En NoSQL los agregados se preparan al escribir, no al '
              'leer.',
        ),
        Question(
          id: 'm5a2q2',
          prompt: 'Las reglas de seguridad de Firestore:',
          choices: [
            Choice('Se aplican en el cliente, por eso se pueden burlar'),
            Choice('Se evaluan en el servidor y son la unica barrera real de '
                'acceso a los datos', correct: true,
                why: 'La app movil es codigo publico: cualquiera puede llamar '
                    'a la API directamente.'),
            Choice('Reemplazan la autenticacion'),
            Choice('Solo controlan la escritura'),
          ],
          takeaway: 'Validar solo en la app equivale a no validar.',
        ),
        Question(
          id: 'm5a2q3',
          context: 'Sistema de matricula con cupos, prerequisitos y reportes '
              'academicos oficiales.',
          prompt: 'Que motor eliges?',
          choices: [
            Choice('Firestore, por su escalabilidad automatica'),
            Choice('Una base relacional, por las restricciones de integridad '
                'y los reportes con agregaciones', correct: true,
                why: 'Cupos, prerequisitos y consistencia contable son '
                    'exactamente lo que un motor relacional garantiza.'),
            Choice('Archivos JSON en el dispositivo'),
            Choice('Da igual: cualquiera funciona'),
          ],
          takeaway: 'La eleccion se justifica por las reglas del dominio, no '
              'por la moda tecnologica.',
        ),
        Question(
          id: 'm5a2q4',
          context: 'Chat en tiempo real entre estudiantes de un curso.',
          prompt: 'Que motor encaja mejor?',
          choices: [
            Choice('Relacional con consultas cada segundo'),
            Choice('Firestore o Realtime Database, por sus escuchas en tiempo '
                'real y su modelo de escritura simple', correct: true,
                why: 'El caso pide propagacion inmediata de documentos '
                    'pequenos, no integridad transaccional compleja.'),
            Choice('Un archivo compartido'),
            Choice('Una hoja de calculo en la nube'),
          ],
          takeaway: 'Muchos sistemas reales combinan ambos motores segun el '
              'caso de uso.',
        ),
      ],
    ),
  ],
);
