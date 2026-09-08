# Database Architect Lab

Laboratorio movil para aprender **modelamiento y diseno de bases de datos**
haciendo, no leyendo. Forma parte de Educational Mobile Apps Factory.

El problema que ataca: los estudiantes de Ingenieria de Sistemas aprenden SQL
de forma aislada y llegan a los cursos de proyectos sin poder disenar una
estructura correcta ni justificar por que una tabla se separa en dos.

## Que hace distinto a esta app

| Enfoque tipico | Database Architect Lab |
|---|---|
| Cuestionarios de opcion multiple sobre teoria | Diagramador ER con analisis estructural del modelo del estudiante |
| SQL "corregido" comparando texto | Motor SQLite embebido que ejecuta la consulta de verdad |
| Respuesta correcta o incorrecta | Explicacion del error concreto y el siguiente paso |
| Normalizacion en papel | Descomposicion interactiva verificada contra las dependencias funcionales |

Los tres motores de evaluacion no comparan cadenas de texto:

- **`DesignAdvisor`** recorre la estructura del diagrama y aplica reglas de
  diseno (entidad sin clave, atributo multivaluado, entidad debil sin relacion
  identificadora, entidad aislada, clave inestable...).
- **`NormalizationEvaluator`** verifica cada dependencia funcional declarada
  contra la clave que el estudiante definio, y determina la forma normal
  realmente alcanzada.
- **`SqlEngine` + `ResultComparer`** ejecutan la consulta del estudiante y la
  solucion de referencia en dos bases identicas y comparan los conjuntos de
  resultados, con tolerancia numerica y verificacion de estado para DDL/DML.

## Contenido

Seis modulos, 21 actividades:

1. **Modelo entidad-relacion** — criterio, biblioteca universitaria, clinica
   veterinaria (entidad debil), cardinalidades.
2. **Normalizacion** — dependencias funcionales, boletas de venta, matriculas,
   anomalias y desnormalizacion.
3. **SQL** — consultas basicas, uniones y agrupamiento, subconsultas, DDL/DML.
4. **PostgreSQL** — tipos y restricciones, indices y rendimiento,
   transacciones e integridad.
5. **Firebase y NoSQL** — modelado documental, consultas, costos y reglas.
6. **Casos reales** — plataforma de delivery, kardex de almacen, reportes de
   negocio, decisiones de arquitectura.

## Estructura

```
lib/
  core/       tema visual y persistencia de progreso
  models/     modelo ER y modelo de actividades
  engine/     motor SQL, comparador, analizador ER, evaluador de normalizacion
  content/    curriculo completo y esquemas semilla
  ui/         pantallas y lienzo del diagramador
test/         pruebas de logica y de integridad del contenido
```
