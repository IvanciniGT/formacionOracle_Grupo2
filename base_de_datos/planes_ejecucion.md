# Ejemplos de planes de ejecución

## EJEMPLO 1: Plan simple de búsqueda de un nombre específico de usuarios. SIN INDICES

### Query

```sql
EXPLAIN PLAN FOR
SELECT 
    COUNT(*) 
FROM 
    USUARIOS
WHERE 
    NOMBRE LIKE 'Aaron%';
```

### Plan de ejecución

    Plan hash value: 524510376
    
    -------------------------------------------------------------------------------
    | Id  | Operation          | Name     | Rows  | Bytes | Cost (%CPU)| Time     |
    -------------------------------------------------------------------------------
    |   0 | SELECT STATEMENT   |          |     1 |    52 |   239   (1)| 00:00:01 |
    |   1 |  SORT AGGREGATE    |          |     1 |    52 |            |          |
    |*  2 |   TABLE ACCESS FULL| USUARIOS |   430 | 22360 |   239   (1)| 00:00:01 |
    -------------------------------------------------------------------------------
    
    Predicate Information (identified by operation id):
    ---------------------------------------------------
    
    2 - filter("NOMBRE" LIKE 'Aaron%')

### Qué cuenta esto?

El plan de ejecución se calcula antes de ejecutar la consulta. Hasta que la query no se ejecuta no conocemos los datos reales... Lo que hace el motor que calcula los planes de ejecución es estimar el coste de la consulta y el número de filas que devolver, lecturas que se harán... para determinar el mejor plan de ejecución.

- ROWS? 430 filas ESTIMADAS que devolverá la query
- BYTES? 22.360 bytes ESTIMADOS que devolverá la query
- COST? 239 unidades de coste ESTIMADAS para ejecutar la query
   ESO DE unidades de coste es un valor relativo. Tiene en cuenta la cantidad de CPU, Operaciones de lectura en memoria, en disco, ... que la BBDD necesitará para ejecutar la consulta.
   Este dato por si solo no nos cuenta mucho... Nos cuenta cuando lo comparamos con otros... O nos cuenta cuando miramos el coste de cada tarea y la comparamos con el coste de otras tareas.

   TABLE ACCESS FULL = FULLSCAN de la tabla USUARIOS. Esto significa que el motor de la BBDD va a leer TODAS las filas de la tabla USUARIOS para encontrar las filas que cumplen el filtro de la consulta.

Cuando visualizamos/analizamos un plan de ejecución:
- Antes de eso, lo suyo sería ver si las estimaciones son correctas (comparando con los datos reales manejados después de ejecutar la query). Si las estimaciones se desvían mucho de los datos reales, es posible que el optimizador de consultas no hará un buen trabajo... Y deberíamos de tratar de conseguir que las estimaciones MEJORES: Esto tiene que ver con las estadísticas de la tabla.
  Esas estadísticas se van recalculando automáticamente, pero a veces no se actualizan con la frecuencia que deberían. 
  Podemos forzar que se actualicen las estadísticas de una tabla con el comando `DBMS_STATS.GATHER_TABLE_STATS` o `DBMS_STATS.GATHER_SCHEMA_STATS`.

  ```sql

  EXEC DBMS_STATS.GATHER_TABLE_STATS('curso', 'USUARIOS');
  ```

  Imaginad que tengo la tabla Usuarios, con el campo DNI... Y meto 10.000 usuarios... y de repente hago una carga de 200.000 usuarios nuevos... Necesito regenerar estadísticas? NADA DE NADA..
  Los datos cambian... SU DISTRIBUCION NO.
  Siempre tenemos un 10% de DNIS que comienzan por 1, un 10% que comienzan por 2, un 10% que comienzan por 3... y así sucesivamente.
  Da igual que tenga 1M de registros... o 10M de registros... La distribución de los DNIS no cambia.

  Muy diferente es si en esa tabla tengo el campo FECHA_ALTA... Según vaya metiendo datos, iré teniendo fechas nuevas que antes no había.
  Quizás tenía 10.000 usuarios en el 2024... Y ahora que vuelco 200.000 usuarios nuevos... Son con fechas del 2025... Me destroza las estadísticas de la tabla.
  
  Puedo solicitar la regeneración de estadísticas solo de algunas columnas de la tabla:

  ```sql
  EXEC DBMS_STATS.GATHER_COLUMN_STATS('curso', 'USUARIOS', method_opt => 'FOR COLUMN NOMBRE, FECHA_ALTA SIZE AUTO');
  ```

- Buscamos qué operaciones le están llevamos más tiempo.... para tratar de determinar si podríamos hacer algo para mejorar el rendimiento de la consulta.

  Afinadas ya las estadísticas, podemos intentar buscar estrategias para mejorar el rendimiento de la consulta.
  En este caso, un índice podría mejorar el rendimiento de la consulta, ya que el motor de la BBDD no tendría que hacer un FULLSCAN de la tabla USUARIOS.

  ```sql
  -- SELECT COUNT(*) FROM USUARIOS WHERE NOMBRE LIKE 'Aaron%';
  CREATE INDEX idx_nombre ON USUARIOS(NOMBRE);
  ```

## Ejemplo 2: Plan de ejecución con índice

### Resultado del EXPLAIN PLAN

    Plan hash value: 1425028490
    
    --------------------------------------------------------------------------------
    | Id  | Operation         | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
    --------------------------------------------------------------------------------
    |   0 | SELECT STATEMENT  |            |     1 |    15 |     3   (0)| 00:00:01 |
    |   1 |  SORT AGGREGATE   |            |     1 |    15 |            |          |
    |*  2 |   INDEX RANGE SCAN| IDX_NOMBRE |   415 |  6225 |     3   (0)| 00:00:01 |
    --------------------------------------------------------------------------------
    
    Predicate Information (identified by operation id):
    ---------------------------------------------------
    
    2 - access("NOMBRE" LIKE 'Aaron%')
        filter("NOMBRE" LIKE 'Aaron%')

    INDEX RANGE SCAN: Está aplicando el índice para hacer la búsqueda binaria en el índice IDX_NOMBRE.

## Ejemplo 3: Saco los nombres de los usuarios que comienzan por Aaron...

Y vemos que sigue usando el índice.

### Resultado del EXPLAIN PLAN

    Plan hash value: 56183079
    
    -------------------------------------------------------------------------------
    | Id  | Operation        | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
    -------------------------------------------------------------------------------
    |   0 | SELECT STATEMENT |            |   415 |  6225 |     3   (0)| 00:00:01 |
    |*  1 |  INDEX RANGE SCAN| IDX_NOMBRE |   415 |  6225 |     3   (0)| 00:00:01 |
    -------------------------------------------------------------------------------

## Ejemplo 4: Saco los nombres y los Ids

### Resultado del EXPLAIN PLAN
    Plan hash value: 3093099277
    
    --------------------------------------------------------------------------------------------------
    | Id  | Operation                           | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
    --------------------------------------------------------------------------------------------------
    |   0 | SELECT STATEMENT                    |            |    18 |   360 |    20   (0)| 00:00:01 |
    |   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| USUARIOS   |    18 |   360 |    20   (0)| 00:00:01 |
    |*  2 |   INDEX RANGE SCAN                  | IDX_NOMBRE |    18 |       |     2   (0)| 00:00:01 |
    --------------------------------------------------------------------------------------------------
    
    Predicate Information (identified by operation id):
    ---------------------------------------------------
    
    2 - access("NOMBRE" LIKE 'Aaron%')
        filter("NOMBRE" LIKE 'Aaron%')

### Qué me cuenta?

1º Buscar los nombres mediante una búsqueda binaria en el índice.
2º Va a la tabla de usuarios? A qué leches va a esa tabla? a por el ID
   Y en esa tabla entra por los ROW_ID

   Qué es el ROW_ID? Es un identificador único de cada fila de la tabla.... NO ES EL PRIMARY KEY.
   Yo a la tabla, la definiré el primary key que me interese.. quizás un secuencial, quizás un hash, otra cosa es el ID interno que usa la ORACLE para identificar cada fila de la tabla.
   Ese ID interno es lo que se guarda en el INDICE... En nuestro caso, para cada NOMBRE DIFERENTE en la tabla, se guardan los ROW_IDS de los registros que tienen ese NOMBRE.

   Puede paras que esta operación sea tan costosa que el motor de la BBDD decida que no merece la pena usar el índice y hacer un FULLSCAN de la tabla USUARIOS.

   Si por ejemplo, un 5% de los usuarios comenzan por Aaron, el motor de la BBDD decidiría que es mejor hacer un FULLSCAN de la tabla USUARIOS, ya que el coste de acceder a los datos en la tabla usuarios por el ROW_ID es mayor que el coste de hacer un FULLSCAN de la tabla USUARIOS.

## Ejemplo 5. El caso que os contaba antes:

    Plan hash value: 1383329024
    
    -------------------------------------------------------------------------------------------
    | Id  | Operation              | Name             | Rows  | Bytes | Cost (%CPU)| Time     |
    -------------------------------------------------------------------------------------------
    |   0 | SELECT STATEMENT       |                  |  9329 |   182K|   223   (1)| 00:00:01 |
    |*  1 |  VIEW                  | index$_join$_001 |  9329 |   182K|   223   (1)| 00:00:01 |
    |*  2 |   HASH JOIN            |                  |       |       |            |          |
    |*  3 |    INDEX RANGE SCAN    | IDX_NOMBRE       |  9329 |   182K|    34   (0)| 00:00:01 |
    |   4 |    INDEX FAST FULL SCAN| SYS_C007797      |  9329 |   182K|   236   (1)| 00:00:01 |
    -------------------------------------------------------------------------------------------

En el índice IDX_NOMBRE: Nombre + ROW_ID
En el índice SYS_C007797: Id + ROW_ID

Usa el IDX_NOMBRE para hacer la búsqueda binaria de los ROW_IDs que tienen el nombre como interesa.
Acto seguido, hace un JOIN de los ROW_IDs obtenidos con el índice SYS_C007797, que es el índice del ID de los usuarios.

Esto es un desmadre...


```sql
  -- SELECT COUNT(*) FROM USUARIOS WHERE NOMBRE LIKE 'Aaron%';
  CREATE INDEX idx_nombre ON USUARIOS(NOMBRE, ID);
```

### Ejemplo 6: Indioce que tiene el nombre y el ID

    Plan hash value: 56183079
    
    -------------------------------------------------------------------------------
    | Id  | Operation        | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
    -------------------------------------------------------------------------------
    |   0 | SELECT STATEMENT |            |  9329 |   182K|    42   (0)| 00:00:01 |
    |*  1 |  INDEX RANGE SCAN| IDX_NOMBRE |  9329 |   182K|    42   (0)| 00:00:01 |
    -------------------------------------------------------------------------------
    
    Predicate Information (identified by operation id):
    ---------------------------------------------------
    
    1 - access("NOMBRE" LIKE 'A%')
        filter("NOMBRE" LIKE 'A%')

En este caso, del índice se usa el nombre para hacer la búsqueda... pero asociado a cada nombre, en el fichero del índice tiene el ID del usuario.... y ya no hace falta entrar a la tabla USUARIOS para obtener el ID del usuario.


## Ejemplo 7: JOIN con la tabla visualizaciones: Con indice en usuarios mejorado (guardando el ID)

 
    ---------------------------------------------------------------------------------------------------------
    | Id  | Operation             | Name            | Rows  | Bytes | Cost (%CPU)| Time     | Pstart| Pstop |
    ---------------------------------------------------------------------------------------------------------
    |   0 | SELECT STATEMENT      |                 |  6635 |   213K|  1148   (2)| 00:00:01 |       |       |
    |   1 |  HASH GROUP BY        |                 |  6635 |   213K|  1148   (2)| 00:00:01 |       |       |
    |*  2 |   HASH JOIN           |                 | 98348 |  3169K|  1144   (1)| 00:00:01 |       |       |
    |*  3 |    INDEX RANGE SCAN   | IDX_NOMBRE      |  9329 |   182K|    42   (0)| 00:00:01 |       |       |
    |   4 |    PARTITION RANGE ALL|                 |   961K|    11M|  1099   (1)| 00:00:01 |     1 |     2 |
    |   5 |     TABLE ACCESS FULL | VISUALIZACIONES |   961K|    11M|  1099   (1)| 00:00:01 |     1 |     2 |
    ---------------------------------------------------------------------------------------------------------

El problema ahora es que hace un full scan de la tabla VISUALIZACIONES, que tiene 1M de registros... y eso es un problema.
No haría falta.. si tuviera un índice para la columna usuario en esa tabla.
Tenemos declarado un Foreign Key, pero no un índice. Y en Oracle un Foreign Key no crea un índice automáticamente. Hay otros motores de BBDD que si ocurre. Solo es una restricción...de forma que al hacer un insert o un update, se compruebe que el dato que pongo existe en la tabla USUARIOS. Para eos no hace falta un índice en la tabla visualizaciones.

### Ejemplo 8: Con indice creado en la tabla VISUALIZACIONES


    ------------------------------------------------------------------------------------------------------
    | Id  | Operation              | Name                        | Rows  | Bytes | Cost (%CPU)| Time     |
    ------------------------------------------------------------------------------------------------------
    |   0 | SELECT STATEMENT       |                             |  6635 |   213K|   823   (2)| 00:00:01 |
    |   1 |  HASH GROUP BY         |                             |  6635 |   213K|   823   (2)| 00:00:01 |
    |*  2 |   HASH JOIN            |                             | 98348 |  3169K|   819   (1)| 00:00:01 |
    |*  3 |    INDEX RANGE SCAN    | IDX_NOMBRE                  |  9329 |   182K|    42   (0)| 00:00:01 |
    |   4 |    INDEX FAST FULL SCAN| IDX_VISUALIZACIONES_USUARIO |   961K|    11M|   774   (1)| 00:00:01 |
    ------------------------------------------------------------------------------------------------------

En este caso, no está usando el índice para búsqueda binaria. Le hace un FULL SCAN al índice... aún así tarda mucho menos.

---

SELECT CURRENT FROM CONTADORES WHERE ID = 'el de una sucursal' FOR UPDATE;

Te puede bloquear el bloque de datos donde tienes el registro de esa sucursal... no la tabla entera.


---