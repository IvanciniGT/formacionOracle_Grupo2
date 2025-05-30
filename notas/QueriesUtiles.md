##  Operaciones de mantenimiento típicas en Oracle

| Categoría       | Operación              | Ejemplo real de query SQL                                                                                              |
| --------------- | ---------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Estadísticas    | Recolectar de tabla    | `EXEC DBMS_STATS.GATHER_TABLE_STATS('CURSO', 'USUARIOS');`                                                             |
|                 | Recolectar de esquema  | `EXEC DBMS_STATS.GATHER_SCHEMA_STATS('CURSO');`                                                                        |
| Índices         | Rebuild índice         | `ALTER INDEX IDX_USUARIOS_NOMBRE REBUILD;`                                                                             |
|                 | Validar estructura     | `ANALYZE INDEX IDX_USUARIOS_NOMBRE VALIDATE STRUCTURE;`                                                                |
| Espacio         | Ver uso de bloques     | `SELECT blocks, num_rows FROM dba_tables WHERE table_name = 'USUARIOS';`                                               |
|                 | Liberar espacio        | `ALTER TABLE CURSO.USUARIOS SHRINK SPACE;`                                                                             |
| Limpieza        | Vaciar papelera        | `PURGE DBA_RECYCLEBIN;`                                                                                                |
|                 | Limpiar auditoría      | `EXEC DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED, DBMS_AUDIT_MGMT.LAST_ARCHIVE_TIMESTAMP);` |
| Seguridad       | Ver usuarios y bloqueo | `SELECT username, account_status FROM dba_users;`                                                                      |
| Rendimiento     | Consultar SQL lentas   | `SELECT sql_id, elapsed_time, sql_text FROM v$sql WHERE elapsed_time > 1000000;`                                       |
| Jobs            | Ver jobs activos       | `SELECT job_name, state FROM dba_scheduler_jobs WHERE enabled = 'TRUE';`                                               |

---

## Auditoría moderna (`Unified Auditing`) 

| Acción                | Ejemplo SQL completo                                                                                                               |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Crear política        | `CREATE AUDIT POLICY aud_usuarios_mods ACTIONS UPDATE, DELETE ON curso.usuarios;`                                                  |
| Activar política      | `AUDIT POLICY aud_usuarios_mods;`                                                                                                  |
| Activar para usuario  | `AUDIT POLICY aud_usuarios_mods WHEN 'SYS_CONTEXT(''USERENV'', ''SESSION_USER'') = ''CURSO''' EVALUATE PER SESSION;`               |
| Consultar políticas   | `SELECT * FROM audit_unified_enabled_policies;`                                                                                    |
| Ver eventos auditados | `SELECT dbusername, object_name, action_name, event_timestamp FROM unified_audit_trail WHERE object_name = 'USUARIOS';`            |
| Limpiar logs antiguos | `sql BEGIN DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED, DBMS_AUDIT_MGMT.LAST_ARCHIVE_TIMESTAMP); END; /` |

---

## Consultas de mantenimiento y diagnóstico en Oracle

| Categoría         | Qué quieres ver                         | Consulta SQL / ejemplo completo                                                                                                                                              |
| ----------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Segmentos         | Tamaño, tipo y ubicación de un objeto   | `SELECT segment_name, segment_type, tablespace_name, bytes/1024/1024 AS size_mb, blocks, extents FROM dba_segments WHERE segment_name = 'USUARIOS' AND owner = 'CURSO';` |
| Extents           | Lista de extents usados por un objeto   | `SELECT segment_name, extent_id, file_id, block_id, blocks FROM dba_extents WHERE segment_name = 'USUARIOS' AND owner = 'CURSO' ORDER BY extent_id;`                     |
| Tamaño lógico     | Filas, bloques, promedio por fila       | `SELECT table_name, num_rows, blocks, empty_blocks, avg_row_len FROM dba_tables WHERE table_name = 'USUARIOS' AND owner = 'CURSO';`                                      |
| Índices           | Estadísticas similares para un índice   | `SELECT index_name, num_rows, leaf_blocks, blevel FROM dba_indexes WHERE table_name = 'USUARIOS' AND owner = 'CURSO';`                                                   |
| Cabecera          | Bloque y archivo de cabecera del objeto | `SELECT segment_name, header_file, header_block FROM dba_segments WHERE segment_name = 'USUARIOS' AND owner = 'CURSO';`                                                  |
| Dump de bloque    | Ver contenido bajo nivel de un bloque   | `ALTER SYSTEM DUMP DATAFILE <file_id> BLOCK <block_id>;`<br>Requiere privilegios y acceso al `alert.log` o trace                                                        |

---

## Gestión de **usuarios, roles y permisos** 

| Acción                        | Qué hace / para qué sirve                 | Comando SQL / Ejemplo real                                                   |
| ----------------------------- | ----------------------------------------- | ---------------------------------------------------------------------------- |
| Crear usuario                 | Crear un nuevo usuario                    | `CREATE USER curso IDENTIFIED BY password DEFAULT TABLESPACE users;`         |
| Dar permisos mínimos          | Permitir login y crear objetos            | `GRANT CREATE SESSION, CREATE TABLE TO curso;`                               |
| Asignar roles                 | Aplicar permisos agrupados                | `GRANT CONNECT, RESOURCE TO curso;`                                          |
| Dar permiso sobre objeto      | Permitir usar tabla/objeto específico     | `GRANT SELECT, INSERT ON empleados TO curso;`                                |
| Ver permisos por usuario      | Consultar privilegios explícitos          | `SELECT * FROM dba_sys_privs WHERE grantee = 'CURSO';`                       |
| Ver permisos sobre objetos    | Ver privilegios de objetos otorgados      | `SELECT * FROM dba_tab_privs WHERE grantee = 'CURSO';`                       |
| Ver roles de usuario         | Qué roles tiene cada usuario              | `SELECT * FROM dba_role_privs WHERE grantee = 'CURSO';`                      |
| Crear rol personalizado      | Definir conjunto de permisos reutilizable | `CREATE ROLE gestor_rrhh; GRANT SELECT, UPDATE ON empleados TO gestor_rrhh;` |
| Revocar permisos             | Quitar permisos o roles                   | `REVOKE CREATE TABLE FROM curso;` <br>`REVOKE gestor_rrhh FROM curso;`       |
| Borrar usuario               | Eliminar usuario y sus objetos            | `DROP USER curso CASCADE;`                                                   |

---

##  gestión de **PDBs (Pluggable Databases)** 

| Acción                    | Qué hace / para qué sirve                   | Comando SQL / Ejemplo real                                                                         |
| ------------------------- | ------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Ver PDBs existentes       | Lista de pluggable databases                | `SELECT pdb_name, status FROM dba_pdbs;`                                                           |
| Conectarse a una PDB      | Cambia de contenedor (CDB → PDB)            | `ALTER SESSION SET CONTAINER = mi_pdb;`                                                            |
| Crear nueva PDB           | Clonar desde plantilla                      | `CREATE PLUGGABLE DATABASE nueva_pdb ADMIN USER admin IDENTIFIED BY pass FILE_NAME_CONVERT = ...;` |
| Abrir PDB                 | Habilita el acceso                          | `ALTER PLUGGABLE DATABASE nueva_pdb OPEN;`                                                         |
| Cerrar PDB                | Cierra la base                              | `ALTER PLUGGABLE DATABASE nueva_pdb CLOSE;`                                                        |
| Ver usuarios en PDB       | Lista usuarios desde dentro de una PDB      | `SELECT username FROM dba_users;`  *(una vez conectado a la PDB)*                                  |
| Ver estado de cada PDB    | Ver cuáles están abiertas/cerradas          | `SELECT name, open_mode FROM v$pdbs;`                                                              |
| Volver a CDB              | Cambia de vuelta a la raíz                  | `ALTER SESSION SET CONTAINER = CDB$ROOT;`                                                          |
| Eliminar una PDB          | Borrar una PDB (opcionalmente, y sus datos) | `DROP PLUGGABLE DATABASE nueva_pdb INCLUDING DATAFILES;`                                           |

# Gestión de TABLESPACES en Oracle

| Acción                             | Qué hace / para qué sirve                       | Comando SQL / Ejemplo completo                                                                                     |
| ---------------------------------- | ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| Ver tablespaces existentes         | Lista todos los tablespaces                     | `SELECT tablespace_name, contents, status FROM dba_tablespaces;`                                                   |
| Ver espacio usado/libre            | Tamaño y uso por tablespace                     | `sql SELECT tablespace_name, ROUND(SUM(bytes)/1024/1024) AS size_mb FROM dba_data_files GROUP BY tablespace_name;` |
| Ver espacio libre                  | Espacio disponible dentro del tablespace        | `sql SELECT tablespace_name, ROUND(SUM(bytes)/1024/1024) AS free_mb FROM dba_free_space GROUP BY tablespace_name;` |
| Crear nuevo tablespace             | Crear uno para datos normales                   | `sql CREATE TABLESPACE datos_user DATAFILE '/u01/app/oracle/oradata/datos01.dbf' SIZE 100M AUTOEXTEND ON;`         |
| Crear tablespace para UNDO         | Tablespace especial para UNDO                   | `sql CREATE UNDO TABLESPACE undotbs1 DATAFILE '/u01/undo01.dbf' SIZE 200M AUTOEXTEND ON;`                          |
| Crear tablespace temporal          | Usado para ordenaciones, joins, etc.            | `sql CREATE TEMPORARY TABLESPACE temp_user TEMPFILE '/u01/temp01.dbf' SIZE 200M AUTOEXTEND ON;`                    |
| Mover objetos entre tablespaces    | Mover una tabla o índice                        | `ALTER TABLE empleados MOVE TABLESPACE datos_user;`                                                                |
| Ver objetos por tablespace         | Ver qué objetos están en cuál                   | `sql SELECT segment_name, segment_type FROM dba_segments WHERE tablespace_name = 'DATOS_USER';`                    |
| Cambiar tamaño de datafile         | Aumentar espacio de un archivo                  | `ALTER DATABASE DATAFILE '/u01/app/oracle/oradata/datos01.dbf' RESIZE 500M;`                                       |
| Autoextend de datafiles            | Habilitar crecimiento automático                | `ALTER DATABASE DATAFILE '/u01/undo01.dbf' AUTOEXTEND ON NEXT 50M MAXSIZE 1G;`                                     |
| Eliminar tablespace                | Borrar tablespace (opcionalmente datos físicos) | `DROP TABLESPACE datos_user INCLUDING CONTENTS AND DATAFILES;`                                                     |

---

## Funciones de textos en Oracle

| Función                        | Qué hace                                 | Ejemplo SQL completo                                                        |
| ------------------------------ | ---------------------------------------- | ----------------------------------------------------------------------------|
| `UPPER(texto)`                 | Convierte a mayúsculas                   | `SELECT UPPER('hola mundo') FROM DUAL;`                                     |
| `LOWER(texto)`                 | Convierte a minúsculas                   | `SELECT LOWER('HOLA MUNDO') FROM DUAL;`                                     |
| `INITCAP(texto)`               | Primera letra de cada palabra en mayúsc. | `SELECT INITCAP('hola mundo') FROM DUAL;`                                   |
| `LENGTH(texto)`                | Longitud del texto                       | `SELECT LENGTH('hola') FROM DUAL;`                                          |
| `SUBSTR(texto, inicio, largo)` | Extrae subcadena                         | `SELECT SUBSTR('abcdef', 2, 3) FROM DUAL;`                                  |
| `INSTR(texto, sub)`            | Posición de subcadena                    | `SELECT INSTR('abcdef', 'cd') FROM DUAL;`                                   |
| `REPLACE(texto, bus, rep)`     | Reemplaza texto                          | `SELECT REPLACE('abcabc', 'a', 'x') FROM DUAL;`                             |
| `TRIM(texto)`                  | Quita espacios extremos                  | `SELECT TRIM('  hola  ') FROM DUAL;`                                        |
| `CONCAT(t1, t2)`               | Concatena dos textos                     | `SELECT CONCAT('hola', ' mundo') FROM DUAL;`                                |
| `LPAD(texto, n, car)`          | Rellena a la izquierda                   | `SELECT LPAD('1', 3, '0') FROM DUAL;`                                       |
| `RPAD(texto, n, car)`          | Rellena a la derecha                     | `SELECT RPAD('1', 3, '0') FROM DUAL;`                                       |

---

## Funciones de fecha en Oracle

| Función                      | Qué hace                           | Ejemplo SQL completo                                                             |
| ---------------------------- | ---------------------------------- | -------------------------------------------------------------------------------- |
| `SYSDATE`                    | Fecha/hora actual (servidor)       | `SELECT SYSDATE FROM DUAL;`                                                      |
| `CURRENT_DATE`               | Fecha/hora con zona de sesión      | `SELECT CURRENT_DATE FROM DUAL;`                                                 |
| `SYSTIMESTAMP`               | Fecha con fracción y TZ (servidor) | `SELECT SYSTIMESTAMP FROM DUAL;`                                                 |
| `TRUNC(fecha)`               | Quita hora                         | `SELECT TRUNC(SYSDATE) FROM DUAL;`                                               |
| `ADD_MONTHS(fecha, n)`       | Suma o resta meses                 | `SELECT ADD_MONTHS(SYSDATE, -1) FROM DUAL;`                                      |
| `LAST_DAY(fecha)`            | Último día del mes                 | `SELECT LAST_DAY(SYSDATE) FROM DUAL;`                                            |
| `NEXT_DAY(fecha, 'VIERNES')` | Próximo viernes                    | `SELECT NEXT_DAY(SYSDATE, 'VIERNES') FROM DUAL;`                                 |
| `MONTHS_BETWEEN(f1, f2)`     | Diferencia en meses                | `SELECT MONTHS_BETWEEN(SYSDATE, TO_DATE('2024-01-01', 'YYYY-MM-DD')) FROM DUAL;` |
| `EXTRACT(YEAR FROM fecha)`   | Extraer año                        | `SELECT EXTRACT(YEAR FROM SYSDATE) FROM DUAL;`                                   |
| `TO_CHAR(fecha, 'YYYY-MM')`  | Convertir a texto                  | `SELECT TO_CHAR(SYSDATE, 'YYYY-MM') FROM DUAL;` |

---

## Funciones de ventana en Oracle

| Función / Sintaxis                        | Qué hace / uso típico                                 | Ejemplo SQL completo                                                                                 |
| ------------------------------------------ | ----------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `ROW_NUMBER() OVER (ORDER BY col)`         | Número de fila según orden                            | `SELECT nombre, ROW_NUMBER() OVER (ORDER BY nombre) AS rn FROM empleados;`                          |
| `RANK() OVER (ORDER BY col)`               | Ranking con saltos en empates                         | `SELECT salario, RANK() OVER (ORDER BY salario DESC) AS rnk FROM empleados;`                        |
| `DENSE_RANK() OVER (ORDER BY col)`         | Ranking sin saltos en empates                         | `SELECT salario, DENSE_RANK() OVER (ORDER BY salario DESC) AS drnk FROM empleados;`                 |
| `SUM(col) OVER (PARTITION BY ... ORDER BY ...)` | Suma acumulada o por grupo                        | `SELECT depto, salario, SUM(salario) OVER (PARTITION BY depto ORDER BY salario) FROM empleados;`    |
| `AVG(col) OVER (ORDER BY col)`             | Promedio móvil/acumulado                              | `SELECT fecha, AVG(ventas) OVER (ORDER BY fecha) FROM ventas_diarias;`                              |
| `LAG(col, n, def) OVER (ORDER BY col)`     | Valor anterior (n filas antes)                        | `SELECT fecha, ventas, LAG(ventas, 1, 0) OVER (ORDER BY fecha) AS ventas_ayer FROM ventas_diarias;` |
| `LEAD(col, n, def) OVER (ORDER BY col)`    | Valor siguiente (n filas después)                     | `SELECT fecha, ventas, LEAD(ventas, 1, 0) OVER (ORDER BY fecha) AS ventas_manana FROM ventas_diarias;` |
| `FIRST_VALUE(col) OVER (ORDER BY col)`     | Primer valor de la ventana                            | `SELECT depto, salario, FIRST_VALUE(salario) OVER (PARTITION BY depto ORDER BY salario DESC) FROM empleados;` |
| `LAST_VALUE(col) OVER (ORDER BY col)`      | Último valor de la ventana                            | `SELECT depto, salario, LAST_VALUE(salario) OVER (PARTITION BY depto ORDER BY salario DESC RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) FROM empleados;` |

---

## Consultas sobre JSON y XML en Oracle

| Acción / Función                | Qué hace / uso típico                        | Ejemplo SQL completo                                                                                 |
| ------------------------------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `JSON_VALUE`                    | Extrae valor de un campo JSON                | `SELECT JSON_VALUE(datos, '$.nombre') FROM empleados_json;`                                          |
| `JSON_TABLE`                    | Convierte JSON a filas/columnas relacionales | `SELECT * FROM JSON_TABLE(json_col, '$.empleados[*]' COLUMNS(nombre PATH '$.nombre')) FROM tabla;`   |
| `XMLTYPE`                       | Convierte texto a tipo XML                   | `SELECT XMLTYPE('<a>1</a>') FROM DUAL;`                                                             |
| `EXTRACTVALUE(xml, xpath)`      | Extrae valor de XML                          | `SELECT EXTRACTVALUE(XMLTYPE('<a>1</a>'), '/a') FROM DUAL;`                                          |

---

## Consultas sobre vistas materializadas

| Acción / Consulta                  | Qué hace / uso típico                        | Ejemplo SQL completo                                                                                 |
| ---------------------------------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Crear vista materializada          | Almacena resultado de consulta               | `CREATE MATERIALIZED VIEW ventas_mv AS SELECT * FROM ventas;`                                        |
| Refrescar vista materializada      | Actualiza datos almacenados                  | `EXEC DBMS_MVIEW.REFRESH('VENTAS_MV');`                                                             |
| Consultar vistas materializadas    | Ver vistas existentes                        | `SELECT mview_name, last_refresh_type, last_refresh_date FROM user_mviews;`                         |

---

## Consultas sobre particionamiento

| Acción / Consulta                  | Qué hace / uso típico                        | Ejemplo SQL completo                                                                                 |
| ---------------------------------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Crear tabla particionada           | Divide datos en particiones                  | `CREATE TABLE ventas (id NUMBER, fecha DATE) PARTITION BY RANGE (fecha) (PARTITION p2024 VALUES LESS THAN (TO_DATE('2025-01-01','YYYY-MM-DD')));` |
| Consultar particiones de tabla     | Ver particiones de una tabla                 | `SELECT table_name, partition_name, high_value FROM user_tab_partitions WHERE table_name = 'VENTAS';` |
| Consultar filas por partición      | Ver distribución de datos                    | `SELECT partition_name, num_rows FROM user_tab_partitions WHERE table_name = 'VENTAS';`              |

---

## Consultas sobre jobs y scheduler

| Acción / Consulta                  | Qué hace / uso típico                        | Ejemplo SQL completo                                                                                 |
| ---------------------------------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Ver jobs programados               | Lista jobs en el scheduler                   | `SELECT job_name, enabled, state FROM dba_scheduler_jobs;`                                           |
| Ver historial de jobs              | Ver ejecuciones pasadas                      | `SELECT job_name, status, run_duration FROM dba_scheduler_job_run_details;`                          |
| Crear job sencillo                 | Crear un job programado                      | `BEGIN DBMS_SCHEDULER.CREATE_JOB(job_name => 'JOB1', job_type => 'PLSQL_BLOCK', job_action => 'BEGIN NULL; END;', start_date => SYSTIMESTAMP, enabled => TRUE); END; /` |

---

## Consultas de performance y tuning

| Acción / Consulta                  | Qué hace / uso típico                        | Ejemplo SQL completo                                                                                 |
| ---------------------------------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Ver plan de ejecución              | Analiza cómo Oracle ejecuta una consulta      | `EXPLAIN PLAN FOR SELECT * FROM empleados WHERE depto = 10;`                                         |
| Ver plan de ejecución (visualizar) | Muestra el plan generado                     | `SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);`                                                           |
| Consultar sesiones activas         | Ver sesiones y recursos                      | `SELECT sid, serial#, username, status FROM v$session WHERE status = 'ACTIVE';`                      |
| Consultar locks                    | Ver bloqueos actuales                        | `SELECT * FROM v$lock WHERE block = 1;`                                                              |

---

## Funciones numéricas en Oracle

| Función                        | Qué hace                                 | Ejemplo SQL completo                                                        |
| ------------------------------ | ---------------------------------------- | ----------------------------------------------------------------------------|
| `ROUND(n, d)`                  | Redondea a d decimales                   | `SELECT ROUND(123.456, 2) FROM DUAL;`                                       |
| `TRUNC(n, d)`                  | Trunca a d decimales                     | `SELECT TRUNC(123.456, 2) FROM DUAL;`                                       |
| `CEIL(n)`                      | Siguiente entero mayor                   | `SELECT CEIL(3.14) FROM DUAL;`                                              |
| `FLOOR(n)`                     | Entero menor                             | `SELECT FLOOR(3.14) FROM DUAL;`                                             |
| `MOD(a, b)`                    | Resto de la división                     | `SELECT MOD(10, 3) FROM DUAL;`                                              |
| `POWER(a, b)`                  | Potencia                                 | `SELECT POWER(2, 3) FROM DUAL;`                                             |
| `ABS(n)`                       | Valor absoluto                           | `SELECT ABS(-5) FROM DUAL;`                                                 |

---

## Uso de SQL Patch en Oracle

| Acción / Consulta                  | Qué hace / uso típico                        | Ejemplo SQL completo                                                                                 |
| ---------------------------------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Crear SQL Patch                    | Aplica hint o ajuste a una sentencia         | `BEGIN DBMS_SQLDIAG.CREATE_SQL_PATCH(sql_id => 'abcd1234', hint_text => 'INDEX(emp emp_idx)', name => 'patch_emp'); END; /` |
| Ver SQL Patch aplicados            | Lista los SQL Patch existentes               | `SELECT name, status, created, description FROM dba_sql_patches;`                                    |
| Eliminar SQL Patch                 | Borra un SQL Patch                           | `BEGIN DBMS_SQLDIAG.DROP_SQL_PATCH(name => 'patch_emp'); END; /`                                    |

---

## Tipos de Hints en Oracle

| Hint principal         | Qué hace / uso típico                                 | Ejemplo de uso en SQL                                                                 |
| ---------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `INDEX(tabla idx)`     | Fuerza uso de un índice                              | `SELECT /*+ INDEX(emp emp_idx) */ * FROM emp WHERE deptno = 10;`                      |
| `FULL(tabla)`          | Fuerza un full scan de tabla                         | `SELECT /*+ FULL(emp) */ * FROM emp;`                                                 |
| `NO_INDEX(tabla idx)`  | Evita el uso de un índice                            | `SELECT /*+ NO_INDEX(emp emp_idx) */ * FROM emp WHERE deptno = 10;`                   |
| `LEADING(tabla)`       | Fuerza el orden de join                              | `SELECT /*+ LEADING(e d) */ * FROM emp e JOIN dept d ON e.deptno = d.deptno;`         |
| `USE_NL(tabla)`        | Fuerza join nested loops                             | `SELECT /*+ USE_NL(dept) */ * FROM emp JOIN dept ON emp.deptno = dept.deptno;`        |
| `USE_HASH(tabla)`      | Fuerza join hash                                     | `SELECT /*+ USE_HASH(dept) */ * FROM emp JOIN dept ON emp.deptno = dept.deptno;`      |
| `MERGE(tabla)`         | Fuerza join merge                                    | `SELECT /*+ MERGE(dept) */ * FROM emp JOIN dept ON emp.deptno = dept.deptno;`         |
| `PARALLEL(tabla, n)`   | Fuerza ejecución en paralelo                         | `SELECT /*+ PARALLEL(emp, 4) */ * FROM emp;`                                          |
| `ORDERED`              | Fuerza el orden de las tablas en el FROM             | `SELECT /*+ ORDERED */ * FROM emp, dept WHERE emp.deptno = dept.deptno;`              |
| `FIRST_ROWS(n)`        | Optimiza para devolver las primeras n filas rápido   | `SELECT /*+ FIRST_ROWS(10) */ * FROM emp WHERE deptno = 10;`                          |
| `ALL_ROWS`             | Optimiza para throughput total                       | `SELECT /*+ ALL_ROWS */ * FROM emp;`                                                  |
| `APPEND`               | Inserción directa (mejor para cargas masivas)        | `INSERT /*+ APPEND */ INTO emp SELECT * FROM emp_temp;`                               |
| `NO_MERGE`             | Evita la fusión de subconsultas                      | `SELECT /*+ NO_MERGE */ * FROM (SELECT * FROM emp WHERE deptno = 10);`                |

