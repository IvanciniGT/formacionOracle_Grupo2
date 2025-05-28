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