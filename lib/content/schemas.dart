/// Esquemas semilla de los laboratorios SQL.
///
/// Cada laboratorio reconstruye su base desde estas sentencias antes de cada
/// intento, de forma que un DELETE mal escrito nunca arruina el ejercicio.
class LabSchemas {
  static const universidad = <String>[
    '''
CREATE TABLE facultad (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL
)''',
    '''
CREATE TABLE carrera (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  facultad_id INTEGER NOT NULL REFERENCES facultad(id)
)''',
    '''
CREATE TABLE estudiante (
  id INTEGER PRIMARY KEY,
  codigo TEXT NOT NULL UNIQUE,
  nombre TEXT NOT NULL,
  ciclo INTEGER NOT NULL,
  carrera_id INTEGER NOT NULL REFERENCES carrera(id)
)''',
    '''
CREATE TABLE curso (
  id INTEGER PRIMARY KEY,
  codigo TEXT NOT NULL UNIQUE,
  nombre TEXT NOT NULL,
  creditos INTEGER NOT NULL,
  carrera_id INTEGER NOT NULL REFERENCES carrera(id)
)''',
    '''
CREATE TABLE matricula (
  id INTEGER PRIMARY KEY,
  estudiante_id INTEGER NOT NULL REFERENCES estudiante(id),
  curso_id INTEGER NOT NULL REFERENCES curso(id),
  periodo TEXT NOT NULL,
  nota REAL
)''',
    '''
INSERT INTO facultad (id, nombre) VALUES
 (1, 'Ingenieria'),
 (2, 'Ciencias Empresariales'),
 (3, 'Ciencias de la Salud')''',
    '''
INSERT INTO carrera (id, nombre, facultad_id) VALUES
 (1, 'Ingenieria de Sistemas', 1),
 (2, 'Ingenieria de Minas', 1),
 (3, 'Administracion', 2),
 (4, 'Contabilidad', 2),
 (5, 'Psicologia', 3)''',
    '''
INSERT INTO estudiante (id, codigo, nombre, ciclo, carrera_id) VALUES
 (1, 'S001', 'Ana Quispe', 5, 1),
 (2, 'S002', 'Bruno Flores', 5, 1),
 (3, 'S003', 'Carla Mendoza', 3, 1),
 (4, 'S004', 'Diego Ramos', 7, 1),
 (5, 'S005', 'Elena Vargas', 5, 2),
 (6, 'S006', 'Fabio Ccahuana', 3, 2),
 (7, 'S007', 'Gabriela Soto', 5, 3),
 (8, 'S008', 'Hugo Pariona', 1, 3),
 (9, 'S009', 'Irma Huaman', 7, 4),
 (10, 'S010', 'Jorge Nunez', 5, 4),
 (11, 'S011', 'Marcos Aliaga', 3, 1),
 (12, 'S012', 'Maria Torres', 5, 1)''',
    '''
INSERT INTO curso (id, codigo, nombre, creditos, carrera_id) VALUES
 (1, 'BD101', 'Base de Datos I', 4, 1),
 (2, 'BD202', 'Base de Datos II', 4, 1),
 (3, 'SW110', 'Ingenieria de Software', 3, 1),
 (4, 'AL100', 'Algoritmos', 5, 1),
 (5, 'MN120', 'Mecanica de Rocas', 4, 2),
 (6, 'MN130', 'Ventilacion Minera', 3, 2),
 (7, 'AD100', 'Fundamentos de Administracion', 3, 3),
 (8, 'CT100', 'Contabilidad General', 4, 4),
 (9, 'RD100', 'Redes de Computadoras', 2, 1),
 (10, 'ET100', 'Estadistica Aplicada', 3, 3)''',
    '''
INSERT INTO matricula (id, estudiante_id, curso_id, periodo, nota) VALUES
 (1, 1, 1, '2025-I', 16.0),
 (2, 1, 3, '2025-I', 14.0),
 (3, 1, 4, '2025-I', 18.0),
 (4, 2, 1, '2025-I', 11.0),
 (5, 2, 4, '2025-I', 13.0),
 (6, 3, 4, '2025-I', 15.0),
 (7, 3, 1, '2025-II', 12.0),
 (8, 4, 2, '2025-I', 17.0),
 (9, 4, 3, '2025-I', 15.0),
 (10, 4, 9, '2025-II', 14.0),
 (11, 5, 5, '2025-I', 13.0),
 (12, 5, 6, '2025-I', 16.0),
 (13, 6, 5, '2025-I', 9.0),
 (14, 7, 7, '2025-I', 15.0),
 (15, 7, 10, '2025-I', 17.0),
 (16, 8, 7, '2025-I', 12.0),
 (17, 9, 8, '2025-I', 18.0),
 (18, 10, 8, '2025-I', 14.0),
 (19, 10, 7, '2025-II', 13.0),
 (20, 11, 1, '2025-II', 19.0),
 (21, 11, 4, '2025-II', 16.0),
 (22, 12, 1, '2025-II', 15.0),
 (23, 12, 2, '2025-II', 13.0),
 (24, 12, 3, '2025-II', 16.0),
 (25, 2, 9, '2025-II', 10.0),
 (26, 3, 3, '2025-II', 14.0),
 (27, 6, 6, '2025-II', 12.0),
 (28, 9, 10, '2025-II', 15.0),
 (29, 1, 2, '2025-II', 17.0),
 (30, 4, 4, '2025-II', 12.0)''',
  ];

  static const delivery = <String>[
    '''
CREATE TABLE cliente (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  distrito TEXT NOT NULL
)''',
    '''
CREATE TABLE restaurante (
  id INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  categoria TEXT NOT NULL,
  distrito TEXT NOT NULL
)''',
    '''
CREATE TABLE plato (
  id INTEGER PRIMARY KEY,
  restaurante_id INTEGER NOT NULL REFERENCES restaurante(id),
  nombre TEXT NOT NULL,
  precio REAL NOT NULL
)''',
    '''
CREATE TABLE pedido (
  id INTEGER PRIMARY KEY,
  cliente_id INTEGER NOT NULL REFERENCES cliente(id),
  restaurante_id INTEGER NOT NULL REFERENCES restaurante(id),
  fecha TEXT NOT NULL,
  estado TEXT NOT NULL
)''',
    '''
CREATE TABLE detalle_pedido (
  pedido_id INTEGER NOT NULL REFERENCES pedido(id),
  plato_id INTEGER NOT NULL REFERENCES plato(id),
  cantidad INTEGER NOT NULL,
  precio_unitario REAL NOT NULL,
  PRIMARY KEY (pedido_id, plato_id)
)''',
    '''
INSERT INTO cliente (id, nombre, distrito) VALUES
 (1, 'Rosa Ayala', 'Huamanga'),
 (2, 'Luis Prado', 'Carmen Alto'),
 (3, 'Nadia Ortiz', 'Huamanga'),
 (4, 'Kevin Rojas', 'San Juan Bautista'),
 (5, 'Sofia Lazo', 'Huamanga')''',
    '''
INSERT INTO restaurante (id, nombre, categoria, distrito) VALUES
 (1, 'Puka Picante', 'Regional', 'Huamanga'),
 (2, 'Wari Grill', 'Parrillas', 'Huamanga'),
 (3, 'Sabor Andino', 'Regional', 'Carmen Alto'),
 (4, 'Verde Vivo', 'Vegetariana', 'San Juan Bautista')''',
    '''
INSERT INTO plato (id, restaurante_id, nombre, precio) VALUES
 (1, 1, 'Puca picante', 18.0),
 (2, 1, 'Qapchi', 15.0),
 (3, 2, 'Anticucho', 22.0),
 (4, 2, 'Parrilla mixta', 45.0),
 (5, 3, 'Caldo de mondongo', 16.0),
 (6, 3, 'Chicharron', 20.0),
 (7, 4, 'Ensalada andina', 14.0),
 (8, 4, 'Wrap de quinua', 17.0)''',
    '''
INSERT INTO pedido (id, cliente_id, restaurante_id, fecha, estado) VALUES
 (1, 1, 1, '2026-03-01', 'entregado'),
 (2, 2, 2, '2026-03-01', 'entregado'),
 (3, 1, 2, '2026-03-02', 'entregado'),
 (4, 3, 1, '2026-03-02', 'cancelado'),
 (5, 4, 4, '2026-03-03', 'entregado'),
 (6, 5, 3, '2026-03-03', 'entregado'),
 (7, 1, 3, '2026-03-04', 'entregado'),
 (8, 2, 1, '2026-03-04', 'pendiente')''',
    '''
INSERT INTO detalle_pedido (pedido_id, plato_id, cantidad, precio_unitario) VALUES
 (1, 1, 2, 18.0),
 (1, 2, 1, 15.0),
 (2, 3, 3, 22.0),
 (3, 4, 1, 45.0),
 (4, 1, 1, 18.0),
 (5, 7, 2, 14.0),
 (5, 8, 1, 17.0),
 (6, 5, 2, 16.0),
 (7, 6, 1, 20.0),
 (7, 5, 1, 16.0),
 (8, 2, 4, 15.0)''',
  ];

  static List<String> byName(String name) {
    switch (name) {
      case 'delivery':
        return delivery;
      case 'universidad':
      default:
        return universidad;
    }
  }

  static String describe(String name) {
    switch (name) {
      case 'delivery':
        return 'Plataforma de delivery: cliente, restaurante, plato, pedido '
            'y detalle_pedido.';
      case 'universidad':
      default:
        return 'Sistema academico: facultad, carrera, estudiante, curso y '
            'matricula.';
    }
  }
}
