-- Ver transacciones que bloqueanbloqueos
SELECT * FROM v$lock WHERE block = 1;

-- Ver bloqueos por fila
SELECT 
  l1.sid blocker_sid,
  l2.sid waiter_sid,
  l1.id1, l1.id2, l1.type
FROM 
  v$lock l1, 
  v$lock l2
WHERE 
  l1.block = 1 AND
  l2.request > 0 AND
  l1.id1 = l2.id1 AND
  l1.id2 = l2.id2 AND
  l1.type = l2.type;

-- Ver sesiones
SELECT * FROM v$session WHERE blocking_session IS NOT NULL;


SELECT 
  nombre,
  valor,
  ROWID,
  DBMS_ROWID.ROWID_RELATIVE_FNO(ROWID) AS file_id,
  DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID) AS block_id,
  DBMS_ROWID.ROWID_ROW_NUMBER(ROWID) AS row_number
FROM contadores
WHERE nombre = 'contador_0043';

SELECT
  o.object_name,
  lo.session_id,
  lo.oracle_username,
  lo.os_user_name,
  lo.locked_mode
FROM
  v$locked_object lo
  JOIN dba_objects o ON lo.object_id = o.object_id;

SELECT
  a.sid,
  a.serial#,
  a.username,
  o.object_name,
  a.row_wait_obj#,
  a.row_wait_file#,
  a.row_wait_block#,
  a.row_wait_row#
FROM v$session a
JOIN dba_objects o ON o.object_id = a.row_wait_obj#
WHERE a.wait_class != 'Idle'
  AND a.row_wait_obj# != -1;

SELECT
  DBMS_ROWID.ROWID_RELATIVE_FNO(ROWID) AS file_id,
  DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID) AS block_id
FROM contadores
WHERE nombre = 'contador_0042';

ALTER SYSTEM DUMP DATAFILE 12 BLOCK 196;
SELECT value 
FROM v$diag_info 
WHERE name = 'Default Trace File';


SELECT table_name, ini_trans, pct_free
FROM user_tables
WHERE table_name = 'CONTADORES';

--- itc avsp

CREATE TABLE contadores (
  nombre VARCHAR2(100) PRIMARY KEY,
  valor NUMBER
);

BEGIN
  FOR i IN 1..1000 LOOP
    INSERT INTO contadores (nombre, valor)
    VALUES ('contador_' || TO_CHAR(i, 'FM0000'), TRUNC(DBMS_RANDOM.VALUE(0, 1000)));
  END LOOP;
  COMMIT;
END;
/

SELECT * FROM CONTADORES;

SELECT valor
FROM contadores
WHERE nombre = 'contador_0042'
FOR UPDATE;

COMMIT;

SELECT COUNT(*) FROM USUARIOS;

```
SELECT valor
FROM contadores
WHERE nombre = 'contador_0043'
FOR UPDATE;
SELECT valor
FROM contadores
WHERE nombre = 'contador_0042'
FOR UPDATE;

COMMIT;
SELECT USER FROM DUAL;