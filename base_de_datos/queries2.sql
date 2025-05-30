SELECT USER FROM DUAL;

-- USUARIOS < VISUALIZACIONES > PELICULAS > DIRECTORES

-- Queremos los directores favoritos de los usuarios. 
-- Al menos para considerar a un director como favorito, 
-- debe tener al menos 2 películas vistas por el usuario.
-- Si hay varios directores de los que un usuario ha visto el mismo número de películas:

-- MODALIDAD 1 de query: Sacamos todos
-- MODALIDAD 2 de query: Sacamos uno cualquiera

-- Resultado: NOMBRE DEL USUARIO / ID, NOMBRE DEL DIRECTOR, NUMERO DE PELIS
-- Menchu       Steven Spielberg    2
-- Federico     Martin Scorsese     14
-- Felipe             -             -

-- USUARIOS < VISUALIZACIONES > PELICULAS > DIRECTORES
--        LEFT              INNER       INNER
--                                       ||
--                                      LEFT OUTER (1)distinto RIGHT OUTER (2)
-- (1) No hay peliculas sin información de director en la tabla de directores:
    -- - El campo es Not Null
    -- - demás es una clave foránea.
    -- Consecuencia: LEFT OUTER JOIN = INNER JOIN
-- (2) Puede haber directores sin películas vistas por los usuarios:
    -- Consecuencia: El RIGHT OUTER JOIN es distinto del LEFT OUTER JOIN:
    --               Incluye directores sin películas... No es relevante para nuestra query

WITH visualizaciones_por_director AS (
    SELECT
        v.usuario,
        p.director,
        COUNT(*) AS numero_visualizaciones_de_un_usuario_para_un_director
    FROM
        VISUALIZACIONES v INNER JOIN PELICULAS p ON v.pelicula = p.id 
    GROUP BY
        v.usuario, p.director
    HAVING COUNT(*) >= 2
),
ranking_por_usuario AS (
    SELECT 
        visualizaciones_por_director.*,
        RANK() OVER (
            PARTITION BY visualizaciones_por_director.usuario 
            ORDER BY visualizaciones_por_director.numero_visualizaciones_de_un_usuario_para_un_director DESC
            ) AS puesto
    FROM 
        visualizaciones_por_director
)
SELECT 
    u.id,
    u.nombre as usuario,
    d.nombre as director,
    v.numero_visualizaciones_de_un_usuario_para_un_director as visualizaciones
FROM
    usuarios u LEFT OUTER JOIN
    (ranking_por_usuario v INNER JOIN directores d ON v.director = d.id)
    ON u.id = v.usuario
WHERE 
    v.puesto = 1 or v.puesto is null
;
---                                    PUESTO
--- Menchu     Martin Scorsese     3     1
--- Menchu     Steven Spielberg    2     2
--- Menchu     Quentin Tarantino   1     3
--- Federico   Martin Scorsese     14    1
--- Federico   Steven Spielberg    10    2


SELECT PCT_FREE FROM DBA_SEGMENTS WHERE SEGMENT_NAME = 'VISUALIZACIONES'; -- null. porque no lo hemos configurado. Se aplica el valor por defecto: 10%

CREATE INDEX idx_usuarios_nombre ON USUARIOS (nombre, id); 
DROP INDEX idx_usuarios_nombre;

CREATE INDEX idx_usuarios_nombre ON USUARIOS ( id, nombre); 

CREATE INDEX idx_visualizaciones_usuario ON VISUALIZACIONES (usuario, pelicula);
DROP INDEX idx_visualizaciones_usuario;

-- Esta query tiene sentido? Más allá del pajazo mental que nos estamos haciendo en el curso.
-- Podría tener sentido... en un datawarehouse... para preparar modelos predictivos.
-- Pero no en mi BB de producción!

-- Que query si podría tener sentido en la BBDD de producción?
-- Dame los directores favoritos de un usuario!
-- Incluso aquí, nos interesaría tener ese dato precalculado... y lo refrescamos por las noches.
-- O una vez a la semana.


---


WITH visualizaciones_por_director AS (
    SELECT  
        p.director,
        COUNT(*) AS numero_visualizaciones_de_un_usuario_para_un_director
    FROM
        VISUALIZACIONES v INNER JOIN PELICULAS p ON v.pelicula = p.id 
    WHERE 
        v.usuario = 8
    GROUP BY
        p.director
    HAVING COUNT(*) >= 2
),
ranking AS (
    SELECT 
        visualizaciones_por_director.*,
        RANK() OVER (
            ORDER BY visualizaciones_por_director.numero_visualizaciones_de_un_usuario_para_un_director DESC
            ) AS puesto
--        ,ROW_NUMBER() OVER (
--            ORDER BY visualizaciones_por_director.numero_visualizaciones_de_un_usuario_para_un_director DESC
--            ) AS puesto_2
    FROM 
        visualizaciones_por_director
)
SELECT
    d.nombre as director,
    v.numero_visualizaciones_de_un_usuario_para_un_director as visualizaciones
FROM
    ranking v INNER JOIN directores d ON v.director = d.id
WHERE 
    v.puesto = 1
;
--- director    nombre              visualizaciones PUESTO   PUESTO_2
--- menchu    Steven Spielberg    3                   1          1
--- menchu    Martin Scorsese     3                   1          2
--- menchu    Quentin Tarantino   2                   2          3
--- menchu    Ridley Scott        1                   3          4


CREATE INDEX idx_visualizaciones_usuario ON VISUALIZACIONES (usuario);
DROP INDEX idx_visualizaciones_usuario;

CREATE INDEX idx_visualizaciones_usuario_pelicula ON VISUALIZACIONES (usuario, pelicula);

CREATE INDEX idx_peliculas_director ON PELICULAS (id,director);
DROP INDEX idx_peliculas_director;

CREATE INDEX idx_directores_nombre ON DIRECTORES (id, nombre);
DROP INDEX idx_directores_nombre;



  SELECT *
  FROM dba_tables
    WHERE table_name = 'USUARIOS';


SELECT sql_id, sql_text FROM v$sql WHERE sql_text LIKE '%rank%';

SELECT * FROM dba_sql_patches;
DESC dba_sql_patches;