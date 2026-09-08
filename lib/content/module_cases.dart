import '../models/activity.dart';
import '../models/er_model.dart';

/// Modulo 6 - Casos reales integrados.
final LabModule moduleCases = LabModule(
  id: 'm6',
  title: 'Casos reales',
  subtitle: 'Modelo, normalizacion y consultas en un mismo problema',
  goal: 'Resolver un requerimiento completo como se hace en un proyecto: '
      'modelar, descomponer y responder preguntas de negocio.',
  activities: [
    ErDesignActivity(
      id: 'm6a1',
      title: 'Caso: plataforma de delivery',
      summary: 'Modelo completo con entidad asociativa y datos de detalle.',
      competencies: const [Competency.modeling, Competency.management],
      minutes: 30,
      brief: 'Una plataforma local de delivery conecta clientes con '
          'restaurantes. Cada restaurante ofrece varios platos con su precio. '
          'Un cliente realiza pedidos; cada pedido corresponde a un solo '
          'restaurante y contiene varios platos, indicando la cantidad y el '
          'precio con el que se vendio ese dia. Cada pedido entregado es '
          'asignado a un repartidor, que puede atender muchos pedidos.',
      requirements: const [
        'Modela Cliente, Restaurante, Plato, Pedido, DetallePedido y '
            'Repartidor.',
        'Un restaurante ofrece muchos platos.',
        'Un cliente realiza muchos pedidos.',
        'Un pedido contiene muchos detalles; cada detalle referencia un plato.',
        'Un repartidor entrega muchos pedidos.',
      ],
      hints: const [
        'El precio del plato cambia con el tiempo: el detalle debe guardar el '
            'precio con el que se vendio.',
        'DetallePedido es el ejemplo tipico de entidad asociativa con datos '
            'propios.',
        'Un pedido pertenece a un solo restaurante: no modeles esa relacion '
            'como N:M.',
      ],
      rubric: const ErRubric(
        cleanDesignPoints: 6,
        entities: [
          RequiredEntity(key: 'cliente', aliases: ['Cliente', 'Usuario']),
          RequiredEntity(
              key: 'restaurante', aliases: ['Restaurante', 'Local']),
          RequiredEntity(
            key: 'plato',
            aliases: ['Plato', 'Producto', 'Menu'],
            attributes: [RequiredAttribute(['precio'])],
          ),
          RequiredEntity(
            key: 'pedido',
            aliases: ['Pedido', 'Orden'],
            attributes: [RequiredAttribute(['fecha'])],
          ),
          RequiredEntity(
            key: 'detalle',
            aliases: ['DetallePedido', 'Detalle', 'ItemPedido', 'LineaPedido'],
            attributes: [
              RequiredAttribute(['cantidad']),
              RequiredAttribute(
                  ['precio unitario', 'preciounitario', 'precio venta']),
            ],
            needsPrimaryKey: false,
            note: 'Sin esta entidad no se puede registrar mas de un plato por '
                'pedido.',
          ),
          RequiredEntity(
              key: 'repartidor', aliases: ['Repartidor', 'Motorizado']),
        ],
        relations: [
          RequiredRelation(
            fromKey: 'restaurante',
            toKey: 'plato',
            fromCard: Cardinality.one,
            toCard: Cardinality.many,
          ),
          RequiredRelation(
            fromKey: 'cliente',
            toKey: 'pedido',
            fromCard: Cardinality.one,
            toCard: Cardinality.many,
          ),
          RequiredRelation(
            fromKey: 'restaurante',
            toKey: 'pedido',
            fromCard: Cardinality.one,
            toCard: Cardinality.many,
            description: 'Cada pedido se atiende en un unico restaurante.',
          ),
          RequiredRelation(
            fromKey: 'pedido',
            toKey: 'detalle',
            fromCard: Cardinality.one,
            toCard: Cardinality.many,
            points: 4,
          ),
          RequiredRelation(
            fromKey: 'plato',
            toKey: 'detalle',
            fromCard: Cardinality.one,
            toCard: Cardinality.many,
            points: 4,
          ),
          RequiredRelation(
            fromKey: 'repartidor',
            toKey: 'pedido',
            fromCard: Cardinality.one,
            toCard: Cardinality.many,
          ),
        ],
      ),
    ),
    NormalizationActivity(
      id: 'm6a2',
      title: 'Caso: kardex de almacen',
      summary: 'Tabla plana de movimientos con tres dependencias encadenadas.',
      competencies: const [Competency.normalization, Competency.management],
      minutes: 25,
      brief: 'Un almacen registra sus movimientos en una sola tabla. Cada '
          'fila es un producto dentro de una guia de ingreso. Descompon hasta '
          '3FN respetando las dependencias declaradas.',
      sampleRows: const [
        ['num_guia', 'fecha_guia', 'ruc_proveedor', 'razon_social',
            'ciudad_proveedor', 'cod_item', 'nombre_item', 'unidad',
            'cantidad_ingresada'],
        ['G-100', '01/03', '20100', 'Andina SAC', 'Ayacucho', 'IT-1',
            'Casco', 'unidad', '20'],
        ['G-100', '01/03', '20100', 'Andina SAC', 'Ayacucho', 'IT-2',
            'Guantes', 'par', '50'],
        ['G-101', '02/03', '20200', 'Sur EIRL', 'Lima', 'IT-1', 'Casco',
            'unidad', '15'],
      ],
      attributes: const [
        'num_guia',
        'fecha_guia',
        'ruc_proveedor',
        'razon_social',
        'ciudad_proveedor',
        'cod_item',
        'nombre_item',
        'unidad',
        'cantidad_ingresada',
      ],
      fds: const [
        Fd(['num_guia'], ['fecha_guia', 'ruc_proveedor']),
        Fd(['ruc_proveedor'], ['razon_social', 'ciudad_proveedor']),
        Fd(['cod_item'], ['nombre_item', 'unidad']),
        Fd(['num_guia', 'cod_item'], ['cantidad_ingresada']),
      ],
      expected: const [
        ExpectedTable(
          name: 'proveedor',
          primaryKey: ['ruc_proveedor'],
          attributes: ['ruc_proveedor', 'razon_social', 'ciudad_proveedor'],
        ),
        ExpectedTable(
          name: 'item',
          primaryKey: ['cod_item'],
          attributes: ['cod_item', 'nombre_item', 'unidad'],
        ),
        ExpectedTable(
          name: 'guia',
          primaryKey: ['num_guia'],
          attributes: ['num_guia', 'fecha_guia', 'ruc_proveedor'],
        ),
        ExpectedTable(
          name: 'detalle_guia',
          primaryKey: ['num_guia', 'cod_item'],
          attributes: ['num_guia', 'cod_item', 'cantidad_ingresada'],
        ),
      ],
    ),
    SqlLabActivity(
      id: 'm6a3',
      title: 'Caso: reportes de la plataforma de delivery',
      summary: 'Consultas de negocio sobre el esquema del caso anterior.',
      competencies: const [Competency.sql, Competency.management],
      minutes: 25,
      schemaName: 'delivery',
      scenario: 'El area comercial pide cuatro reportes. El esquema ya esta '
          'implementado: cliente, restaurante, plato, pedido y '
          'detalle_pedido.',
      tasks: const [
        SqlTask(
          id: 'm6a3t1',
          prompt: 'Calcula el total facturado por cada pedido entregado. '
              'Devuelve el id del pedido y el total (alias total).',
          solution: 'SELECT p.id, '
              'SUM(d.cantidad * d.precio_unitario) AS total '
              'FROM pedido p JOIN detalle_pedido d ON d.pedido_id = p.id '
              "WHERE p.estado = 'entregado' GROUP BY p.id",
          mustContain: ['sum(', 'group by', 'where'],
          hint: 'El total de una linea es cantidad por precio unitario.',
          points: 2,
        ),
        SqlTask(
          id: 'm6a3t2',
          prompt: 'Muestra el nombre del restaurante (alias restaurante) y '
              'cuantos pedidos entregados acumula (alias pedidos), ordenado '
              'de mayor a menor y luego por nombre.',
          solution: 'SELECT r.nombre AS restaurante, '
              'COUNT(p.id) AS pedidos '
              'FROM restaurante r JOIN pedido p ON p.restaurante_id = r.id '
              "WHERE p.estado = 'entregado' "
              'GROUP BY r.nombre ORDER BY pedidos DESC, restaurante',
          ordered: true,
          mustContain: ['count(', 'group by', 'order by'],
          hint: 'Puedes ordenar por el alias definido en el SELECT.',
          points: 2,
        ),
        SqlTask(
          id: 'm6a3t3',
          prompt: 'Identifica el plato mas vendido en unidades. Devuelve el '
              'nombre del plato y el total de unidades (alias unidades), '
              'en una sola fila.',
          solution: 'SELECT pl.nombre, SUM(d.cantidad) AS unidades '
              'FROM plato pl JOIN detalle_pedido d ON d.plato_id = pl.id '
              'GROUP BY pl.id, pl.nombre '
              'ORDER BY unidades DESC LIMIT 1',
          mustContain: ['sum(', 'limit'],
          hint: 'Agrupa por plato y quedate con la primera fila del orden '
              'descendente.',
          points: 2,
        ),
        SqlTask(
          id: 'm6a3t4',
          prompt: 'Lista el nombre de los clientes que no tienen ningun '
              'pedido en estado entregado.',
          solution: 'SELECT c.nombre FROM cliente c '
              'WHERE c.id NOT IN '
              "(SELECT p.cliente_id FROM pedido p WHERE p.estado = 'entregado')",
          mustContain: ['not in'],
          hint: 'Tambien puedes resolverlo con LEFT JOIN, pero aqui se pide '
              'practicar la subconsulta con NOT IN.',
          points: 2,
        ),
      ],
    ),
    ConceptActivity(
      id: 'm6a4',
      title: 'Decisiones de arquitectura de datos',
      summary: 'El criterio que se evalua en una sustentacion de proyecto.',
      competencies: const [Competency.management],
      minutes: 10,
      questions: const [
        Question(
          id: 'm6a4q1',
          prompt: 'El equipo quiere guardar el total del pedido como columna '
              'calculada en la tabla pedido. Esto es aceptable si:',
          choices: [
            Choice('Nunca: siempre debe calcularse al vuelo'),
            Choice('Se documenta como desnormalizacion y se garantiza su '
                'actualizacion junto con el detalle',
                correct: true,
                why: 'Ademas, el total historico de una boleta debe '
                    'congelarse: es un valor legal, no un calculo actual.'),
            Choice('Solo en bases NoSQL'),
            Choice('Solo si la tabla tiene menos de 1000 filas'),
          ],
          takeaway: 'Los documentos historicos guardan el valor del momento, '
              'no el precio vigente.',
        ),
        Question(
          id: 'm6a4q2',
          prompt: 'Migrar un cambio de esquema en produccion se hace:',
          choices: [
            Choice('Editando las tablas a mano en el servidor'),
            Choice('Con scripts de migracion versionados y reversibles, '
                'probados antes en un entorno de pruebas',
                correct: true,
                why: 'Las migraciones son codigo: se revisan, se versionan y '
                    'se pueden revertir.'),
            Choice('Restaurando un respaldo antiguo'),
            Choice('Creando una base nueva cada vez'),
          ],
          takeaway: 'Sin migraciones versionadas no hay despliegue repetible.',
        ),
        Question(
          id: 'm6a4q3',
          prompt: 'Un respaldo sirve solo si:',
          choices: [
            Choice('Se genera todos los dias'),
            Choice('Se ha probado la restauracion completa al menos una vez',
                correct: true,
                why: 'Un respaldo que nunca se restauro es una suposicion, no '
                    'una garantia.'),
            Choice('Se guarda en el mismo servidor'),
            Choice('Ocupa poco espacio'),
          ],
          takeaway: 'La prueba de restauracion forma parte del plan de '
              'respaldo.',
        ),
        Question(
          id: 'm6a4q4',
          prompt: 'En la sustentacion te preguntan por que no usaste NoSQL. '
              'La mejor respuesta es:',
          choices: [
            Choice('Porque SQL es mas conocido'),
            Choice('Porque el dominio exige integridad referencial, cupos y '
                'reportes agregados, y eso lo garantiza el motor relacional',
                correct: true,
                why: 'La justificacion se construye desde los requisitos del '
                    'dominio, no desde la preferencia personal.'),
            Choice('Porque NoSQL es inseguro'),
            Choice('Porque el docente lo pidio asi'),
          ],
          takeaway: 'Toda decision tecnica se defiende con el requisito que '
              'la origina.',
        ),
      ],
    ),
  ],
);
