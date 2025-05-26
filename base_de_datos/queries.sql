SELECT USER FROM DUAL;

-- EXPLAIN PLAN FOR
SELECT 
    COUNT(*) 
FROM 
    USUARIOS
WHERE 
    NOMBRE LIKE 'Aaron%';

-- SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

EXEC DBMS_STATS.GATHER_TABLE_STATS('curso', 'USUARIOS');
EXEC DBMS_STATS.GATHER_TABLE_STATS('curso', 'VISUALIZACIONES');

CREATE INDEX idx_nombre ON USUARIOS(NOMBRE);

SELECT 
    ID,
    NOMBRE
FROM 
    USUARIOS
WHERE 
    NOMBRE LIKE 'A%';

SELECT NOMBRE, COUNT(*) 
FROM USUARIOS
GROUP BY NOMBRE
ORDER BY COUNT(*) DESC;


DROP INDEX idx_nombre;
CREATE INDEX idx_nombre ON USUARIOS(NOMBRE, ID);
CREATE INDEX idx_nombre ON USUARIOS(ID, NOMBRE);
-- Esos 2 índices SON TOTALMENTE DIFERENTES. El segundo nunca se usaría haciendo una búsqueda de like por el nombre.


SELECT /*+ GATHER_PLAN_STATISTICS */
    NOMBRE, PELICULA, COUNT(PELICULA) AS Numero_Visualizaciones
FROM 
    VISUALIZACIONES INNER JOIN USUARIOS ON VISUALIZACIONES.USUARIO = USUARIOS.ID
WHERE 
    USUARIOS.NOMBRE LIKE 'Mary%'
GROUP BY
    USUARIOS.NOMBRE, VISUALIZACIONES.PELICULA
ORDER BY 
    Numero_Visualizaciones DESC;

select * from table(dbms_xplan.display_cursor(NULL,NULL, format=>'ALLSTATS LAST'));
-- Saca las estadísticas REALES de la última query en esta sesión... si es que sigue en cache

select * from table(dbms_xplan.display_cursor(sql_id=>'4ajnupnpx1xhz', format=>'ALLSTATS LAST'));



CREATE INDEX idx_visualizaciones_usuario ON VISUALIZACIONES(USUARIO);
--CREATE INDEX idx_visualizaciones_usuario ON VISUALIZACIONES(USUARIO, PELICULA);

SELECT COUNT(*) FROM USUARIOS WHERE NOMBRE LIKE 'Lance%';

--- Miraría el uso global de la cache... El hit ratio
SELECT 1- (PHYSICAL_READS / (DB_BLOCK_GETS + CONSISTENT_GETS)) * 100 AS "Buffer Cache Hit Ratio"
FROM v$buffer_pool_statistics;

-- Un ratio por debajo del 80% es preocupante
-- Entre un 80% y un 90% es aceptable
-- Lo ideal es al menos un 90%



-- Esta query me da el ratio por tabla
SELECT
  s.owner,
  s.object_name AS tabla,
  s.object_type,
  SUM(CASE WHEN s.statistic_name = 'logical reads' THEN s.value ELSE 0 END) AS logical_reads,
  SUM(CASE WHEN s.statistic_name = 'physical reads' THEN s.value ELSE 0 END) AS physical_reads,
  ROUND(
    (1 - (SUM(CASE WHEN s.statistic_name = 'physical reads' THEN s.value ELSE 0 END) /
           NULLIF(SUM(CASE WHEN s.statistic_name = 'logical reads' THEN s.value ELSE 0 END), 0))
    ) * 100, 2
  ) AS cache_hit_ratio_percent
FROM
  v$segment_statistics s
WHERE
  s.owner = 'CURSO' 
GROUP BY
  s.owner, s.object_name, s.object_type
ORDER BY
  tabla
  ;