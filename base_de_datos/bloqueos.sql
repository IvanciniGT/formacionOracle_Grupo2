
CREATE TABLE contador (
    nombre VARCHAR2(50) NOT NULL,
    valor NUMBER NOT NULL
) INITRANS 4 PCTFREE 10;

ALTER TABLE contador ADD CONSTRAINT pk_contador PRIMARY KEY (nombre);

BEGIN
    FOR i IN 1..10000 LOOP
        INSERT INTO contador (nombre, valor) VALUES ('contador_' || i, 0);
    END LOOP;
    COMMIT;
END;
/

SELECT COUNT(*) FROM contador;
SELECT * FROM contador WHERE ROWNUM <= 10;

-- Vamos a mirar el segmento(s) de la tabla contador
SELECT segment_name, bytes, blocks, extents
FROM dba_segments
WHERE segment_name = 'CONTADOR';

--- SEGMENT_NAME: CONTADOR     BYTES: 327680       BLOCKS: 40 (Nº de extents x 8 = 5 x 8 = 40)      EXTENTS: 5
--- Cada bloque son 8Kbs * 40 bloques = 320Kbs = 327680 bytes

--- Vamos a ver cada uno de esos extents
SELECT FILE_ID, extent_id, block_id, blocks , bytes
FROM dba_extents
WHERE segment_name = 'CONTADOR';
--- Como cada extent tiene 8 bloques, y cada bloque son 8Kbs, entonces cada extent ocupa 64Kbs = 65536 bytes


--- Podemos ver en qué bloque tenemos guardado cada uno de los registros
SELECT
    nombre, 
    valor,
    ROWID,
    DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID) AS bloque,
    DBMS_ROWID.ROWID_ROW_NUMBER(ROWID) AS fila
FROM contador;

SELECT
    DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID) AS bloque,
    COUNT(*)
FROM contador
GROUP BY DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID);

-- Podemos echar algunas cuentas.
-- En nuestra tabla hemos metido 10000 registros. Cuanto ocupa cada uno? 13 + 8 = 21 bytes
-- En cada bloque tendríamos un máximo teórico de (8Kbs-10%) / 21 bytes = (8100- 810)/21 = 317 registros por bloque.
-- En principio si hemos guardado 10000 registros, y cada bloque puede guardar 317, entonces necesitamos 10000 / 317 = 31.6 bloques.
-- Nos salieron 5 extents de 8 bloques cada uno, por lo que tenemos 40 bloques. 4 extents ocupados y 1 más o menos libre.
-- 32 bloques ocupados

-- En la realidad 340 es lo que entra en un bloque. 340 filas por bloque.
-- De esas querremos hacer os BLOQUEOS.


SELECT * FROM contador WHERE nombre = 'contador_1435' FOR UPDATE;
SELECT * FROM contador WHERE nombre = 'contador_1480' FOR UPDATE;
SELECT * FROM contador WHERE nombre = 'contador_1535' FOR UPDATE;
SELECT * FROM contador WHERE nombre = 'contador_1635' FOR UPDATE;

SELECT * FROM v$lock  where block = 1;

commit;
--- 12547

SELECT * FROM dba_tables WHERE table_name= 'CONTADOR';


---

---- TODO ESTO COMO SYSDBA
-- Para hacer el dump de un bloque de datos a disco.. para debugging:
ALTER SYSTEM DUMP DATAFILE <FILE_ID> BLOCK <block_id>;

SELECT value FROM v$dial_info WHERE name = 'Default Trace File'; -- Fichero en el que se guardan los dumps de los bloques
-- Ese fichero es a nivel de sesión... hay que ejecutarlo inmediatamente antes/después de hacer el dump.




SELECT COUNT(*) FROM USUARIOS;

ANALYZE INDEX idx_visualizaciones_usuario_pelicula VALIDATE STRUCTURE;

SELECT * FROM INDEX_STATS;

EXEC DBMS_STATS.GATHER_TABLE_STATS('CURSO', 'USUARIOS');
SELECT *
FROM dba_tables
WHERE owner = 'CURSO' AND table_name = 'USUARIOS';
