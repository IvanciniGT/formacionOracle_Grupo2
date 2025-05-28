# Planes de ejecución:

## Primero: DIRECTORES FAVORITOS DE TODOS LOS USUARIOS sin índices

    ------------------------------------------------------------------------------------------------------------------------
    | Id  | Operation                    | Name            | Rows  | Bytes |TempSpc| Cost (%CPU)| Time     | Pstart| Pstop |
    ------------------------------------------------------------------------------------------------------------------------
    |   0 | SELECT STATEMENT             |                 |   999K|   105M|       | 10013   (1)| 00:00:01 |       |       |
    |*  1 |  FILTER                      |                 |       |       |       |            |          |       |       |
    |*  2 |   HASH JOIN RIGHT OUTER      |                 |   999K|   105M|  5064K| 10013   (1)| 00:00:01 |       |       |
    |   3 |    VIEW                      |                 | 50342 |  4473K|       |  5777   (2)| 00:00:01 |       |       |
    |*  4 |     HASH JOIN                |                 | 50342 |  1917K|       |  5777   (2)| 00:00:01 |       |       |
    |   5 |      TABLE ACCESS FULL       | DIRECTORES      | 10000 |   175K|       |    11   (0)| 00:00:01 |       |       |
    |   6 |      VIEW                    |                 | 50342 |  1032K|       |  5766   (2)| 00:00:01 |       |       |
    |   7 |       WINDOW SORT            |                 | 50342 |   934K|    27M|  5766   (2)| 00:00:01 |       |       |
    |*  8 |        FILTER                |                 |       |       |       |            |          |       |       |
    |   9 |         HASH GROUP BY        |                 | 50342 |   934K|    27M|  5766   (2)| 00:00:01 |       |       |
    |* 10 |          HASH JOIN           |                 |  1006K|    18M|       |  1172   (1)| 00:00:01 |       |       |
    |  11 |           TABLE ACCESS FULL  | PELICULAS       | 30000 |   263K|       |    68   (0)| 00:00:01 |       |       |
    |  12 |           PARTITION RANGE ALL|                 |  1009K|  9859K|       |  1100   (1)| 00:00:01 |     1 |     2 |
    |  13 |            TABLE ACCESS FULL | VISUALIZACIONES |  1009K|  9859K|       |  1100   (1)| 00:00:01 |     1 |     2 |
    |  14 |    TABLE ACCESS FULL         | USUARIOS        |   999K|    19M|       |  2470   (1)| 00:00:01 |       |       |
    ------------------------------------------------------------------------------------------------------------------------


   1 - filter("from$_subquery$_008"."PUESTO"=1 OR "from$_subquery$_008"."PUESTO" IS NULL)
   2 - access("U"."ID"="V"."USUARIO"(+))
   4 - access("V"."DIRECTOR"="D"."ID")
   8 - filter(COUNT(*)>=2)
  10 - access("V"."PELICULA"="P"."ID")

### TRABAJO QUE HA HECHO EL ORACLE

1. Leer completa la tabla de visualizaciones
2. Leer completa la tabla de películas
3. Join de visualizaciones con películas. 
     El join no le lleva nada: 1172 - 68 - 1100    = 4
     El tiempo se va en leer la tabla de visualizaciones: 1100. Podemos mejorarlo?
     - Las visualizaciones hay que leerlas todas... Pero...
       - 1: Podría haber problema si las visualizaciones no están en memoria... y están en disco? Tendríamos que mirar el hit ratio de cache de la tabla visualizaciones. Si es bajo... podemos tener problemas.
       - 2: Dice que mueve 10M de datos (9859K). Eso está bien o podemos bajarlo? Qué me puede influir ahí?
         Esos 10M qué son? datos de visualizaciones? NO exactamente... SON LOS BLOQUES DE la tabla que lee. Qué puede pasar aquí?
         Que en esos bloques haya mucha información inútil. Qué casos serían esos... 
         - Que me esté trayendo muchos datos de visualizaciones que no son necesarios.
                En nuestro caso, nos estamos trayendo la fecha de la visualización, el usuario y la película.
                Y la fecha no la usamos para nada. SOLUCIÓN? INDICE QUE SOLO TENGA USUARIO Y PELÍCULA. Compensa?
                - La query a priori debería mejorar... pero cuidao!!! son más datos que necesito en RAM.. y espacio en cache (DEL SGA)
                  que pierdo para otras tablas/indices ==> Empeoraría el cache hit ratio de otras tablas o índices + Espacio en DISCO + Peor rendimiento en INSERTS! En nuestro caso, con 1 campo solo que es el campo FECHA que son 8 bytes, no compensa.
         - Que el PCT_FREE de la tabla visualizaciones sea muy alto.
           ```sql
           SELECT PCT_FREE FROM DBA_TABLES WHERE TABLE_NAME = 'VISUALIZACIONES'; -- 10% VACIO : 1 Mega... es lo que hay, 
                                                                                 -- si no quiero cambiar PCT_FREE
           ```
         - Que haya muchas filas marcadas como muertas (porque se hayan borrado o actualizado) y no se hayan eliminado físicamente.
           Esto ocurre en nuestro caso? Es una tabla sujeta a modificaciones? NO SOLO INSERTS:
           - No hay datos muertos <--- Seguramente con X periodicidad me llevaré datos a un DATALAKE... después debería asegurarme
             de eliminar los datos muertos de la tabla visualizaciones.
           - Qué podríamos hacer con el PCT_FREE? BAJARLO 
4. GROUP BY USUARIO, PELICULA... ESTO ES PESADO A RABIAR: 5766 - 1172 = 4594
   Por qué cuesta tanto el group by? Porque hace un sort de 1006K
   Podemos optimizar eso? NO PODEMOS... estamos ordenando el resultado de un join... No podemos crear un índice con el resultado DINÁMICO de un join. NO HAY FORMA DE OPTIMIZAR ESTO. 
   Nuestro problema es complejo: TODOS LOS USUARIOS, TODAS LAS PELÍCULAS, TODOS LOS DIRECTORES, TODAS LAS VISUALIZACIONES.
   Y juntándolos y agrupándolos. No hay forma de optimizar eso.
5. WINDOW SORT <-- PARTITION OVER Esto no tarda nada!
   La ordenación son de 3, 4, 10 datos... ya que ordena para cada usuario. 
6. Leer completa la tabla directores . El leer esta tabla: NO TARDA NADA 11. Podríamos decir.. vamos a bajarlo
7. Join de directores con visualizaciones. NO TARDA NADA
8. Leer la tabla usuario: 2470 = 25% coste: 20 Megas de datos. (Me hacen falta?) Quizás un índice me ayude.
        NUMBER id PK    ***
        NUMBER estado
        TIMESTAMP alta
        VARCHAR2 email
        VARCHAR2 nombre ***
10. Join de visualizaciones con usuarios. Tarda un poco también: 10013 - 5777 - 2470 = 1756.. Pero no hay nada que hacer.
11. Filtro que no cuesta nada (puesto=1)

## Segundo: Indice creado en usuarios (nombre, id)

    ----------------------------------------------------------------------------------------------------------------------------
    | Id  | Operation                    | Name                | Rows  | Bytes |TempSpc| Cost (%CPU)| Time     | Pstart| Pstop |
    ----------------------------------------------------------------------------------------------------------------------------
    |   0 | SELECT STATEMENT             |                     |   999K|   105M|       |  8694   (2)| 00:00:01 |       |       |
    |*  1 |  FILTER                      |                     |       |       |       |            |          |       |       |
    |*  2 |   HASH JOIN RIGHT OUTER      |                     |   999K|   105M|  5064K|  8694   (2)| 00:00:01 |       |       |
    |   3 |    VIEW                      |                     | 50342 |  4473K|       |  5777   (2)| 00:00:01 |       |       |
    |*  4 |     HASH JOIN                |                     | 50342 |  1917K|       |  5777   (2)| 00:00:01 |       |       |
    |   5 |      TABLE ACCESS FULL       | DIRECTORES          | 10000 |   175K|       |    11   (0)| 00:00:01 |       |       |
    |   6 |      VIEW                    |                     | 50342 |  1032K|       |  5766   (2)| 00:00:01 |       |       |
    |   7 |       WINDOW SORT            |                     | 50342 |   934K|    27M|  5766   (2)| 00:00:01 |       |       |
    |*  8 |        FILTER                |                     |       |       |       |            |          |       |       |
    |   9 |         HASH GROUP BY        |                     | 50342 |   934K|    27M|  5766   (2)| 00:00:01 |       |       |
    |* 10 |          HASH JOIN           |                     |  1006K|    18M|       |  1172   (1)| 00:00:01 |       |       |
    |  11 |           TABLE ACCESS FULL  | PELICULAS           | 30000 |   263K|       |    68   (0)| 00:00:01 |       |       |
    |  12 |           PARTITION RANGE ALL|                     |  1009K|  9859K|       |  1100   (1)| 00:00:01 |     1 |     2 |
    |  13 |            TABLE ACCESS FULL | VISUALIZACIONES     |  1009K|  9859K|       |  1100   (1)| 00:00:01 |     1 |     2 |
    |  14 |    INDEX FAST FULL SCAN      | IDX_USUARIOS_NOMBRE |   999K|    19M|       |  1151   (1)| 00:00:01 |       |       |
    ----------------------------------------------------------------------------------------------------------------------------

NOTA: Si creamos el índice con (id, nombre) no cambia nada... ya que está haciendo un FULL SCAN del índice... y le igual el orden de los campos.

## Tercero: Solo los directores de un usuario:

    ----------------------------------------------------------------------------------------------------------------------
    | Id  | Operation                          | Name            | Rows  | Bytes | Cost (%CPU)| Time     | Pstart| Pstop |
    ----------------------------------------------------------------------------------------------------------------------
    |   0 | SELECT STATEMENT                   |                 |     1 |    57 |  1114   (1)| 00:00:01 |       |       |
    |   1 |  NESTED LOOPS                      |                 |     1 |    57 |  1114   (1)| 00:00:01 |       |       |
    |   2 |   NESTED LOOPS                     |                 |     1 |    57 |  1114   (1)| 00:00:01 |       |       |
    |*  3 |    VIEW                            |                 |     1 |    39 |  1113   (1)| 00:00:01 |       |       |
    |*  4 |     WINDOW SORT PUSHED RANK        |                 |     1 |    19 |  1113   (1)| 00:00:01 |       |       |
    |*  5 |      FILTER                        |                 |       |       |            |          |       |       |
    |   6 |       HASH GROUP BY                |                 |     1 |    19 |  1113   (1)| 00:00:01 |       |       |
    |   7 |        NESTED LOOPS                |                 |    10 |   190 |  1111   (1)| 00:00:01 |       |       |
    |   8 |         NESTED LOOPS               |                 |    10 |   190 |  1111   (1)| 00:00:01 |       |       |
    |   9 |          PARTITION RANGE ALL       |                 |    10 |   100 |  1101   (1)| 00:00:01 |     1 |     2 |
    |* 10 |           TABLE ACCESS FULL        | VISUALIZACIONES |    10 |   100 |  1101   (1)| 00:00:01 |     1 |     2 |
    |* 11 |          INDEX UNIQUE SCAN         | SYS_C007816     |     1 |       |     0   (0)| 00:00:01 |       |       |
    |  12 |         TABLE ACCESS BY INDEX ROWID| PELICULAS       |     1 |     9 |     1   (0)| 00:00:01 |       |       |
    |* 13 |    INDEX UNIQUE SCAN               | SYS_C007801     |     1 |       |     0   (0)| 00:00:01 |       |       |
    |  14 |   TABLE ACCESS BY INDEX ROWID      | DIRECTORES      |     1 |    18 |     1   (0)| 00:00:01 |       |       |
    ----------------------------------------------------------------------------------------------------------------------
    
### TRABAJO QUE HA HECHO EL ORACLE

1. LEERSE LA TABLA COMPLETA DE VISUALIZACIONES... igual que cuando le pedía las visualizaciones de todos los usuarios.
   CUANTO CUESTA? 1101... que representa el 1101/1114 = 99% del coste de la consulta.
   Esto tiene sentido? NINGUNO = RUINA !!!!!!!
   A la que lee la tabla, se queda solo con las visualizaciones del usuario 8 ---->  ID DE LA PELICULA
        ```sql
        SELECT PELICULA FROM VISUALIZACIONES WHERE USUARIO = 8; --- esta query da pocos resultados: Estima que 10
        ```
2. Lee un índice SYS_C007816, la pk de la tabla películas... pa qué? ID_PELICULA ---> ROWID
    Búsqueda binaria para sacar el ROWID de la película  
3. Accede a la tabla película por su ROWID, para sacar el id del director de la película.
   Y... Cuantas veces hace eso? Estima que 10... para cada visualización que hay de ese usuario
   En lugar de hacer joins, se hace un lookup por cada visualización.            ESTO EN PROGRAMACIÓN Es un BUCLE: LOOP (FOR)
4. Group by por director. No le cuesta nada
5. RANK. No le cuesta nada
6. Entra en el índice SYS_C007801, que tengo : DIRECTORES.ID -> ROWID
7. Accede a la tabla directores por su ROWID, para sacar el nombre del director.


    Predicate Information (identified by operation id):
    ---------------------------------------------------
    
    3 - filter("V"."PUESTO"=1)
    4 - filter(RANK() OVER ( ORDER BY COUNT(*) DESC )<=1)
    5 - filter(COUNT(*)>=2)
    10 - filter("V"."USUARIO"=8)
    11 - access("V"."PELICULA"="P"."ID")
    13 - access("V"."DIRECTOR"="D"."ID")


## Cuarto: Creamos un índice en visualizaciones (usuario)

    --------------------------------------------------------------------------------------------------------------------------------------------------
    | Id  | Operation                                          | Name                        | Rows  | Bytes | Cost (%CPU)| Time     | Pstart| Pstop |
    --------------------------------------------------------------------------------------------------------------------------------------------------
    |   0 | SELECT STATEMENT                                   |                             |     1 |    57 |    27   (8)| 00:00:01 |       |       |
    |   1 |  NESTED LOOPS                                      |                             |     1 |    57 |    27   (8)| 00:00:01 |       |       |
    |   2 |   NESTED LOOPS                                     |                             |     1 |    57 |    27   (8)| 00:00:01 |       |       |
    |*  3 |    VIEW                                            |                             |     1 |    39 |    26   (8)| 00:00:01 |       |       |
    |*  4 |     WINDOW SORT PUSHED RANK                        |                             |     1 |    19 |    26   (8)| 00:00:01 |       |       |
    |*  5 |      FILTER                                        |                             |       |       |            |          |       |       |
    |   6 |       HASH GROUP BY                                |                             |     1 |    19 |    26   (8)| 00:00:01 |       |       |
    |   7 |        NESTED LOOPS                                |                             |    10 |   190 |    24   (0)| 00:00:01 |       |       |
    |   8 |         NESTED LOOPS                               |                             |    10 |   190 |    24   (0)| 00:00:01 |       |       |
    |   9 |          TABLE ACCESS BY GLOBAL INDEX ROWID BATCHED| VISUALIZACIONES             |    10 |   100 |    14   (0)| 00:00:01 | ROWID | ROWID |
    |* 10 |           INDEX RANGE SCAN                         | IDX_VISUALIZACIONES_USUARIO |    10 |       |     3   (0)| 00:00:01 |       |       |
    |* 11 |          INDEX UNIQUE SCAN                         | SYS_C007816                 |     1 |       |     0   (0)| 00:00:01 |       |       |
    |  12 |         TABLE ACCESS BY INDEX ROWID                | PELICULAS                   |     1 |     9 |     1   (0)| 00:00:01 |       |       |
    |* 13 |    INDEX UNIQUE SCAN                               | SYS_C007801                 |     1 |       |     0   (0)| 00:00:01 |       |       |
    |  14 |   TABLE ACCESS BY INDEX ROWID                      | DIRECTORES                  |     1 |    18 |     1   (0)| 00:00:01 |       |       |
    --------------------------------------------------------------------------------------------------------------------------------------------------
 
1. Entra en el índice de visualizaciones por usuario (que hemos creado) para sacar 
    En el índice tenemos: IDX_VISUALIZACIONES_USUARIO  (usuario) -> ROWID de la tabla visualizaciones
2. Entra en bucle en la tabla de visualizaciones por ROWID, para sacar el id de la película.
3. Para cada id de película, entra en el índice SYS_C007816 (películas.id -> ROWID) para sacar el ROWID de la película.
4. Entra en la tabla películas por ROWID, para sacar el id del director de la película.
5. Entra en el índice SYS_C007801 (directores.id -> ROWID) para sacar el ROWID del director.
6. Entra en la tabla directores por ROWID, para sacar el nombre del director.

SE PUEDE MEJORAR ESTO AHORA? YA VES !!!!!! 
Está dando paseos a kilos a la BBDD y a los indices.

    Predicate Information (identified by operation id):
    ---------------------------------------------------
    
    3 - filter("V"."PUESTO"=1)
    4 - filter(RANK() OVER ( ORDER BY COUNT(*) DESC )<=1)
    5 - filter(COUNT(*)>=2)
    10 - access("V"."USUARIO"=8)
    11 - access("V"."PELICULA"="P"."ID")
    13 - access("V"."DIRECTOR"="D"."ID")

## Quinto: Montones de índices: peliculas (id, director), directores(id, nombre)

    ------------------------------------------------------------------------------------------------------------------
    | Id  | Operation                 | Name                                 | Rows  | Bytes | Cost (%CPU)| Time     |
    ------------------------------------------------------------------------------------------------------------------
    |   0 | SELECT STATEMENT          |                                      |     1 |    57 |    16  (13)| 00:00:01 |
    |   1 |  NESTED LOOPS             |                                      |     1 |    57 |    16  (13)| 00:00:01 |
    |*  2 |   VIEW                    |                                      |     1 |    39 |    15  (14)| 00:00:01 |
    |*  3 |    WINDOW SORT PUSHED RANK|                                      |     1 |    19 |    15  (14)| 00:00:01 |
    |*  4 |     FILTER                |                                      |       |       |            |          |
    |   5 |      HASH GROUP BY        |                                      |     1 |    19 |    15  (14)| 00:00:01 |
    |   6 |       NESTED LOOPS        |                                      |    10 |   190 |    13   (0)| 00:00:01 |
    |*  7 |        INDEX RANGE SCAN   | IDX_VISUALIZACIONES_USUARIO_PELICULA |    10 |   100 |     3   (0)| 00:00:01 |
    |*  8 |        INDEX RANGE SCAN   | IDX_PELICULAS_DIRECTOR               |     1 |     9 |     1   (0)| 00:00:01 |
    |*  9 |   INDEX RANGE SCAN        | IDX_DIRECTORES_NOMBRE                |     1 |    18 |     1   (0)| 00:00:01 |
    ------------------------------------------------------------------------------------------------------------------

Qué cambia?

    |   6 |       NESTED LOOPS        |                                      |    10 |   190 |    13   (0)| 00:00:01 |
    |*  7 |        INDEX RANGE SCAN   | IDX_VISUALIZACIONES_USUARIO_PELICULA |    10 |   100 |     3   (0)| 00:00:01 |
    |*  8 |        INDEX RANGE SCAN   | IDX_PELICULAS_DIRECTOR               |     1 |     9 |     1   (0)| 00:00:01 |
    |*  9 |   INDEX RANGE SCAN        | IDX_DIRECTORES_NOMBRE                |     1 |    18 |     1   (0)| 00:00:01 |

                                            vvvvv

    |   8 |         NESTED LOOPS                               |                             |    10 |   190 |    24   (0)| 00:00:01 |       |       |
    |   9 |          TABLE ACCESS BY GLOBAL INDEX ROWID BATCHED| VISUALIZACIONES             |    10 |   100 |    14   (0)| 00:00:01 | ROWID | ROWID |
    |* 10 |           INDEX RANGE SCAN                         | IDX_VISUALIZACIONES_USUARIO |    10 |       |     3   (0)| 00:00:01 |       |       |
    |* 11 |          INDEX UNIQUE SCAN                         | SYS_C007816                 |     1 |       |     0   (0)| 00:00:01 |       |       |
    |  12 |         TABLE ACCESS BY INDEX ROWID                | PELICULAS                   |     1 |     9 |     1   (0)| 00:00:01 |       |       |
    |* 13 |    INDEX UNIQUE SCAN                               | SYS_C007801                 |     1 |       |     0   (0)| 00:00:01 |       |       |
    |  14 |   TABLE ACCESS BY INDEX ROWID                      | DIRECTORES                  |     1 |    18 |     1   (0)| 00:00:01 |       |       |

Oracle estima que esos índices no le aportan nada , para tener un mejor rendimiento.
Y decide ni usarlos algunos (se los hemos tenido que forzar)
Otro gallo cantaría, si tuvieramos más datos... Ahí .. si tiene que hacer más bucles, quizás le compense.
Está haciendo respectivamente 9 y 18 bucles... Eso no es nada... Si tuviera que hacer 500 o 1000 bucles, quizás le compense. Y esos índices serían útiles.
---

Los algoritmos, dependiendo el que sea tienen un determinado coste computacional... es decir el número de operaciones que necesitan hacer para resolver un problema. (En ciencias de la computación se habla de orden de complejidad de un algoritmo)

    FULL SCAN: O(n) - Para n datos, necesita hacer n operaciones.  Si tengo que leer 1 millón de datos, necesito hacer 1 millón de operaciones.
    BÚSQUEDA BINARIA: O(log n) - Para n datos, necesita hacer log(n) operaciones. Si tengo que leer 1 millón de datos, necesito hacer 20 operaciones.
    SORT... con un buen algoritmo: O(n log n) - Para n datos, necesita hacer n log(n) operaciones. Si tengo que leer 1 millón de datos, necesito hacer 1M * log2(1M) = 20M operaciones.

    Si tuviera 50 datos: 
    - FULL SCAN: 50
    - BÚSQUEDA BINARIA: 6
    - SORT: 50 * log2(50) = 50 * 6 = 300

    Si tuviera 100 millones de datos:
    - FULL SCAN: 100M
    - BÚSQUEDA BINARIA: 26
    - SORT: 100M * log2(100M) = 100M * 26 = 2.600 M
  