import '../models/activity.dart';

/// Modulo 4 - PostgreSQL en produccion.
final LabModule modulePostgres = LabModule(
  id: 'm4',
  title: 'PostgreSQL',
  subtitle: 'Del ejercicio al motor de produccion',
  goal: 'Elegir tipos, restricciones e indices con criterio, y entender que '
      'garantiza una transaccion.',
  activities: [
    ConceptActivity(
      id: 'm4a1',
      title: 'Tipos y restricciones',
      summary: 'Las decisiones que el motor va a defender por ti.',
      competencies: const [Competency.sql, Competency.management],
      minutes: 10,
      questions: const [
        Question(
          id: 'm4a1q1',
          context: 'Vas a guardar el monto de una factura.',
          prompt: 'Que tipo eliges en PostgreSQL?',
          choices: [
            Choice('FLOAT, porque acepta decimales'),
            Choice('NUMERIC(10,2), porque representa decimales exactos',
                correct: true,
                why: 'FLOAT usa punto flotante binario: 0.1 + 0.2 no da 0.3 '
                    'exacto. En dinero eso produce descuadres contables.'),
            Choice('TEXT, para conservar el formato de moneda'),
            Choice('INTEGER, multiplicando por 100 siempre'),
          ],
          takeaway: 'Dinero se guarda en NUMERIC/DECIMAL, nunca en punto '
              'flotante.',
        ),
        Question(
          id: 'm4a1q2',
          prompt: 'La forma recomendada actualmente de definir un id '
              'autoincremental en PostgreSQL es:',
          choices: [
            Choice('id SERIAL PRIMARY KEY'),
            Choice('id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY',
                correct: true,
                why: 'IDENTITY es el estandar SQL, evita los problemas de '
                    'permisos y propiedad de la secuencia que arrastra SERIAL.'),
            Choice('id INTEGER AUTOINCREMENT'),
            Choice('id UUID DEFAULT random()'),
          ],
          takeaway: 'SERIAL sigue funcionando, pero IDENTITY es la sintaxis '
              'preferida desde PostgreSQL 10.',
        ),
        Question(
          id: 'm4a1q3',
          context: 'La aplicacion se usa en varias zonas horarias.',
          prompt: 'Que tipo usas para la fecha y hora de creacion?',
          choices: [
            Choice('TIMESTAMP sin zona horaria'),
            Choice('TIMESTAMPTZ, que normaliza a UTC y convierte al leer',
                correct: true,
                why: 'Sin zona horaria, el mismo instante se interpreta '
                    'distinto segun el servidor que lo lea.'),
            Choice('TEXT con formato dd/mm/aaaa'),
            Choice('DATE, porque la hora no importa'),
          ],
          takeaway: 'Guarda instantes en TIMESTAMPTZ y formatea solo al '
              'mostrar.',
        ),
        Question(
          id: 'm4a1q4',
          prompt: 'Quieres impedir que se registre una nota fuera del rango '
              '0 a 20. La forma mas robusta es:',
          choices: [
            Choice('Validar solo en la aplicacion movil'),
            Choice('Una restriccion CHECK (nota BETWEEN 0 AND 20) en la tabla',
                correct: true,
                why: 'La restriccion protege el dato aunque entre por otra '
                    'aplicacion, por un script o por consola.'),
            Choice('Un trigger que corrija el valor en silencio'),
            Choice('Un indice unico sobre nota'),
          ],
          takeaway: 'La integridad que vive en la base sobrevive al cambio de '
              'aplicaciones.',
        ),
        Question(
          id: 'm4a1q5',
          prompt: 'Cuando conviene usar una columna JSONB en lugar de tablas '
              'normalizadas?',
          choices: [
            Choice('Siempre, porque evita hacer JOIN'),
            Choice('Para atributos variables o poco consultados, cuando el '
                'esquema real cambia por cliente', correct: true,
                why: 'JSONB da flexibilidad, pero pierdes restricciones, tipos '
                    'y parte de la claridad del modelo.'),
            Choice('Para las claves primarias'),
            Choice('Nunca: PostgreSQL no soporta JSON'),
          ],
          takeaway: 'JSONB es un complemento del modelo relacional, no un '
              'reemplazo.',
        ),
      ],
    ),
    ConceptActivity(
      id: 'm4a2',
      title: 'Indices y rendimiento',
      summary: 'Por que un indice acelera lecturas y encarece escrituras.',
      competencies: const [Competency.sql, Competency.management],
      minutes: 10,
      questions: const [
        Question(
          id: 'm4a2q1',
          prompt: 'Un indice B-tree sobre matricula(estudiante_id) ayuda '
              'sobre todo a:',
          choices: [
            Choice('Insertar filas mas rapido'),
            Choice('Filtrar y unir por estudiante_id sin recorrer toda la '
                'tabla', correct: true,
                why: 'El indice permite ubicar directamente las filas '
                    'candidatas en lugar de leer la tabla completa.'),
            Choice('Reducir el tamano de la base'),
            Choice('Evitar valores nulos'),
          ],
          takeaway: 'Los indices se disenan mirando las consultas frecuentes, '
              'no las tablas.',
        ),
        Question(
          id: 'm4a2q2',
          prompt: 'Costo real de agregar indices a una tabla muy escrita:',
          choices: [
            Choice('Ninguno: los indices son gratis'),
            Choice('Cada INSERT, UPDATE y DELETE debe mantener tambien el '
                'indice, y ocupa espacio adicional', correct: true,
                why: 'Por eso una tabla con diez indices puede volverse lenta '
                    'para escribir.'),
            Choice('Solo aumenta el uso de memoria'),
            Choice('Obliga a normalizar hasta BCNF'),
          ],
          takeaway: 'Indexar de mas es tan danino como no indexar.',
        ),
        Question(
          id: 'm4a2q3',
          context: 'Consultas frecuentes: WHERE carrera_id = ? AND ciclo = ?',
          prompt: 'Que indice compuesto conviene?',
          choices: [
            Choice('(ciclo, carrera_id), porque ciclo tiene menos valores'),
            Choice('(carrera_id, ciclo), poniendo primero la columna mas '
                'selectiva y siempre presente en el filtro',
                correct: true,
                why: 'Un indice compuesto se aprovecha de izquierda a '
                    'derecha: la primera columna debe ser la que casi siempre '
                    'aparece en el WHERE.'),
            Choice('Dos indices separados siempre rinden igual'),
            Choice('Un indice sobre todas las columnas de la tabla'),
          ],
          takeaway: 'En indices compuestos, el orden de las columnas cambia '
              'todo.',
        ),
        Question(
          id: 'm4a2q4',
          prompt: 'Antes de optimizar una consulta lenta, lo primero es:',
          choices: [
            Choice('Agregar un indice por cada columna del WHERE'),
            Choice('Leer el plan de ejecucion con EXPLAIN ANALYZE',
                correct: true,
                why: 'El plan muestra si el motor recorre la tabla completa, '
                    'que indice usa y donde se pierde el tiempo.'),
            Choice('Aumentar la memoria del servidor'),
            Choice('Desnormalizar el modelo'),
          ],
          takeaway: 'Medir primero, cambiar despues.',
        ),
      ],
    ),
    ConceptActivity(
      id: 'm4a3',
      title: 'Transacciones e integridad',
      summary: 'Que garantiza el motor cuando algo falla a la mitad.',
      competencies: const [Competency.management],
      minutes: 10,
      questions: const [
        Question(
          id: 'm4a3q1',
          context: 'Una matricula descuenta una vacante y crea un registro.',
          prompt: 'Si el segundo paso falla, la atomicidad garantiza que:',
          choices: [
            Choice('El primer paso queda aplicado igual'),
            Choice('Ambos pasos se deshacen y la base vuelve al estado previo',
                correct: true,
                why: 'La transaccion es todo o nada: sin atomicidad quedarian '
                    'vacantes descontadas sin matricula.'),
            Choice('El motor reintenta automaticamente'),
            Choice('Se guarda un registro parcial marcado como incompleto'),
          ],
          takeaway: 'Toda operacion que toca varias tablas necesita una '
              'transaccion.',
        ),
        Question(
          id: 'm4a3q2',
          prompt: 'ON DELETE CASCADE en matricula.estudiante_id significa:',
          choices: [
            Choice('Que no se puede borrar un estudiante con matriculas'),
            Choice('Que al borrar un estudiante se borran tambien sus '
                'matriculas', correct: true,
                why: 'Es comodo, pero peligroso con datos historicos: borra '
                    'informacion que quizas debia conservarse.'),
            Choice('Que las matriculas quedan con estudiante_id nulo'),
            Choice('Que se crea automaticamente un indice'),
          ],
          takeaway: 'Para datos historicos suele ser mejor RESTRICT o un '
              'borrado logico.',
        ),
        Question(
          id: 'm4a3q3',
          prompt: 'Dos usuarios matriculan al mismo tiempo en la ultima '
              'vacante. El riesgo tipico es:',
          choices: [
            Choice('Deadlock garantizado'),
            Choice('Una condicion de carrera que deja el cupo en negativo si '
                'no se controla la concurrencia', correct: true,
                why: 'Ambos leen el mismo valor disponible antes de que el '
                    'otro escriba.'),
            Choice('Perdida total de la base'),
            Choice('Un error de sintaxis'),
          ],
          takeaway: 'Se resuelve con transacciones, bloqueos o restricciones '
              'que hagan imposible el estado invalido.',
        ),
        Question(
          id: 'm4a3q4',
          prompt: 'La durabilidad en ACID significa que:',
          choices: [
            Choice('Los datos nunca se borran'),
            Choice('Una vez confirmada la transaccion, el cambio sobrevive a '
                'una caida del servidor', correct: true,
                why: 'El motor escribe el registro de transacciones antes de '
                    'confirmar.'),
            Choice('La base soporta muchos usuarios'),
            Choice('Las copias de seguridad son automaticas'),
          ],
          takeaway: 'Durabilidad no reemplaza a la politica de respaldos.',
        ),
      ],
    ),
  ],
);
