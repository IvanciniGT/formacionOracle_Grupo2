DESC MOVIMIENTOS;

-- ROWNUM

SELECT ROWNUM, 
       ID, 
       CLIENTE, 
       FECHA, 
       IMPORTE, 
       TIPO_MOV
FROM (
    SELECT 
        ID, 
        CLIENTE, 
        FECHA, 
        IMPORTE, 
        TIPO_MOV 
    FROM 
        MOVIMIENTOS 
    ORDER BY 
        FECHA ASC
    )
WHERE ROWNUM <= 10;

SELECT MIN(FECHA) AS fecha_minima
FROM MOVIMIENTOS;

-- ROWNUM , que es una columna ficticia que ORACLE asigna a cada valor devuelto por una query,
-- se calcula antes de aplicar el ORDER BY, por lo que no se puede usar en la cláusula ORDER BY.

SELECT CLIENTE, SUM(IMPORTE) AS SALDO
FROM MOVIMIENTOS
WHERE CLIENTE = 'Ana García'
GROUP BY CLIENTE;

SELECT CLIENTE, FECHA, IMPORTE AS MOVIMIENTO
FROM MOVIMIENTOS
WHERE CLIENTE = 'Ana García'
ORDER BY FECHA ASC;

-- Quiero el saldo ACUMULADO en cada registro.

-- Quiero saber el importe del ultimo movimiento de una persona.

SELECT cliente,fecha,importe
from Movimientos
where fecha = (select max(fecha) from movimientos m where m.cliente=Movimientos.cliente)
order by fecha asc;

SELECT cliente,fecha,importe
FROM 
(SELECT cliente,fecha,importe
from Movimientos
where cliente='Ana García'
order by fecha desc)
WHERE ROWNUM = 1;

--- Estos escenarios son los que resuelven las funciones de ventana

SELECT cliente, fecha, importe,
       RANK() OVER(PARTITION BY cliente ORDER BY ABS(importe) DESC) AS ranking,
       LAG(importe) OVER (PARTITION BY cliente ORDER BY fecha ASC) AS importe_anterior,
       LEAD(importe) OVER (PARTITION BY cliente ORDER BY fecha ASC) AS importe_siguiente,
       SUM(importe) OVER (PARTITION BY cliente ORDER BY fecha ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS saldo_acumulado,
       FIRST_VALUE(importe) OVER (PARTITION BY cliente ORDER BY fecha ASC) AS primer_importe,
       LAST_VALUE(importe) OVER (PARTITION BY cliente ORDER BY fecha ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS ultimo_importe,
       AVG(importe) OVER (PARTITION BY cliente ORDER BY fecha ASC ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS media_movil
FROM Movimientos
ORDER BY cliente, fecha;

DESC Importancia;
SELECT * FROM IMPORTANCIA
ORDER BY NOMBRE, CANTIDAD DESC;

SELECT
 NOMBRE, 
 CANTIDAD,
 RANK() OVER (PARTITION BY NOMBRE ORDER BY CANTIDAD DESC) AS RANKING,
 DENSE_RANK() OVER (PARTITION BY NOMBRE ORDER BY CANTIDAD DESC) AS RANKING_DENSO,
 ROW_NUMBER() OVER (PARTITION BY NOMBRE ORDER BY CANTIDAD DESC) AS NUMERO_FILA
FROM IMPORTANCIA;

--- Otras peculiaridades del SQL en ORACLE
-- ROWNUM
-- Funciones de ventana
-- DUAL: tabla ficticia. En muchas BBDD se permiten queries del tipo SELECT 1, que no operan sobre ninguna tabla.
-- Cuando tengo una query que no opera sobre ninguna tabla: SELECT 1 FROM DUAL;

-- Fecha/HORA actual?
SELECT SYSDATE FROM DUAL; -- Fecha y hora del servidor de BBDD
-- Los datos de tipo fecha, recordad que cuando los saco de la BBDD en una query que convierto a texto, se les aplica un formato.

-- Lo puedo cambiar a nivel de query:
SELECT TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') FROM DUAL;
-- Lo puedo cambiar a nivel de sesión:
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY HH24:MI:SS';
SELECT SYSDATE FROM DUAL; -- Fecha y hora del servidor de BBDD

-- Hay otras 3 variables para la fecha/hora actual:
SELECT SYSTIMESTAMP FROM DUAL; -- Fecha y hora del servidor de BBDD con mayor precisión
SELECT CURRENT_DATE FROM DUAL; -- Fecha y hora del servidor del cliente que se está conectando
SELECT CURRENT_TIMESTAMP FROM DUAL; -- Fecha y hora del servidor del cliente que se está conectando con mayor precisión
-- Igual que para los campos de tipo DATE puedo establecer el formato de trabajo por defecto a nivel de sesión,
-- Para los campos de tipo TIMESTAMP puedo establecer el formato de trabajo por defecto a nivel de sesión:
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD/MM/YYYY HH24:MI:SS.FF';
-- Si tiene información horaria:
ALTER SESSION SET NLS_TIMESTAMP_TZ_FORMAT = 'DD/MM/YYYY';

SELECT * FROM v$nls_parameters WHERE parameter IN ('NLS_DATE_FORMAT', 'NLS_TIMESTAMP_FORMAT', 'NLS_TIMESTAMP_TZ_FORMAT');

SELECT CURRENT_TIMESTAMP FROM DUAL; -- REVISAR

-- FUNCIONES DE FECHA EN ORACLE

-- Quiero los movimientos de ANA GARCÍA DEL MES ANTERIOR SEGUN CALENDARIO: Mayo 2025.. Queremos los movimientos de Abril 2025.
SELECT cliente, fecha, importe
FROM Movimientos
WHERE cliente = 'Ana García'
  AND fecha >= TO_DATE('01/04/2025', 'DD/MM/YYYY')
  AND fecha < TO_DATE('01/05/2025', 'DD/MM/YYYY');

-- Para campos de tipo fecha tenemos:
-- CAMPO + numero      Lo que suma son días a ese fecha

SELECT SYSDATE + 1 FROM DUAL; -- Fecha y hora del servidor de BBDD + 1 día
SELECT SYSDATE + 1.5 FROM DUAL; -- Fecha y hora del servidor de BBDD + 1 día + 12 horas
-- Sumar 3 horas
SELECT SYSDATE + (3/24) FROM DUAL; -- Fecha y hora del servidor de BBDD + 3 horas
-- Esto me sirve para sumar días, horas, minutos y segundos a un campo de tipo fecha.
-- Lo que no sirve es para sumar meses o años. Para esto hay otra función:
SELECT ADD_MONTHS(SYSDATE, 1) FROM DUAL; -- Fecha y hora del servidor de BBDD + 1 mes
SELECT ADD_MONTHS(SYSDATE, -1) FROM DUAL; -- Fecha y hora del servidor de BBDD - 1 mes
-- Sumar y restar años... multiplicando por 12 el número de años:
SELECT ADD_MONTHS(SYSDATE, 24) FROM DUAL; -- Fecha y hora del servidor de BBDD + 2 años
-- Otra operación INTERESANTISIMA E IMPORTANTE: trunc... esa función tiene 2 formas de llamarse:
SELECT TRUNC(SYSDATE) FROM DUAL; -- Trunca la hora del campo de tipo date que yo pase.
-- En Oracle recordad que cualquier campo de tipo DATE lleva información horaria
-- Luego está el campo de tipo TIMESTAMP, que lleva información horaria con mayor precisión.
-- Es como aplicar una mascara que pone la hora a CERO.
-- Esa función admite otra forma de trabajo... pasándole un segundo parámetro que es el tipo de truncamiento que quiero hacer:
SELECT TRUNC(SYSDATE, 'MM') FROM DUAL; -- Trunca al primer día del mes
SELECT TRUNC(SYSDATE, 'YYYY') FROM DUAL; -- Trunca al primer día del año
SELECT TRUNC(SYSDATE, 'HH') FROM DUAL; -- Trunca a la hora
SELECT TRUNC(SYSDATE, 'IW') FROM DUAL; -- Truncar al inicio de la semana ISO (lunes)

SELECT 
    * 
FROM 
    MOVIMIENTOS 
WHERE 
    CLIENTE = 'Ana García' 
    AND FECHA BETWEEN 
        TRUNC(ADD_MONTHS(SYSDATE, -1), 'MM') 
        AND TRUNC(SYSDATE, 'MM') - 1; -- Tiene un problemilla. BETWEEN incluye ambos límites. Se ha resuelto con el -1 al final.
        -- Pero hay que estar fino.. a la mínima la regamos.

SELECT 
    * 
FROM 
    MOVIMIENTOS 
WHERE 
    CLIENTE = 'Ana García' 
    AND FECHA >= TRUNC(ADD_MONTHS(SYSDATE, -1), 'MM') 
    AND FECHA < TRUNC(SYSDATE, 'MM'); 

SELECT 
    * 
FROM 
    MOVIMIENTOS 
WHERE 
    CLIENTE = 'Ana García' 
    AND TRUNC(ADD_MONTHS(SYSDATE, -1), 'MM') = TRUNC(FECHA, 'MM'); -- Esta query tiene un problemón!

-- En las 3 de arriba, las funciones las estoy aplicando sobre SYSDATE.. que a efectos de la query es una CONSTANTE.
-- Se evalúa SYSDATE cuando empieza la query y ya no cambia... Esos TRUNC se calculan solo una vez.
-- En la última el trunc se está calculando sobre el campo fecha, para cada fila que se evalúa.

-- Si tuviéramos un índice creado para el campo fecha, la última query no podría usarlo.

-- Función EXTRACT
SELECT 
    EXTRACT(YEAR FROM SYSTIMESTAMP) AS año_actual, 
    EXTRACT(MONTH FROM SYSTIMESTAMP) AS mes_actual, 
    EXTRACT(DAY FROM SYSTIMESTAMP) AS dia_actual,
    EXTRACT(HOUR FROM SYSTIMESTAMP) AS hora_actual,
    EXTRACT(MINUTE FROM SYSTIMESTAMP) AS minuto_actual,
    EXTRACT(SECOND FROM SYSTIMESTAMP) AS segundo_actual
FROM
    DUAL;

-- CAMPO_DE_TIPO_FECHA - numero (dias)
SELECT 
    SYSDATE - 1 AS fecha_ayer, 
    SYSDATE - 7 AS fecha_hace_una_semana, 
    SYSDATE - 30 AS fecha_hace_un_mes
FROM
    DUAL;
-- Si quiero restar minutos
SELECT 
    SYSDATE - (30 / 1440) AS fecha_hace_30_minutos, -- 1440 minutos en un día
    SYSDATE - (60 / 1440) AS fecha_hace_1_hora -- 60 minutos en una hora
FROM
    DUAL;

-- Saber cuantos meses hay de diferencia entre dos fechas
SELECT 
    MONTHS_BETWEEN(SYSDATE, TO_DATE('01/01/2020', 'DD/MM/YYYY')) AS meses_diferencia
FROM
    DUAL;

-- En las queries en ORACLE:
-- '' = NULL Sería True
-- SELECT * FROM MOVIMIENTOS WHERE CLIENTE = '' -- Si el campo CLIENTE es NULL, se considera true
-- NULL = NULL Sería False
-- SELECT * FROM MOVIMIENTOS WHERE CLIENTE = NULL -- Si el campo CLIENTE es NULL, se considera false
-- Hay que escribirlo así:
SELECT * FROM MOVIMIENTOS WHERE CLIENTE IS NULL; -- Si el campo CLIENTE es NULL, se considera true

-- Clausula IN() está limitada a 1000 valores en ORACLE. Si necesitamos más, hay que hacer una subquery.

--SELECT * FROM MOVIMIENTOS WHERE CLIENTE IN ('Ana García', 'Juan Pérez', 'María López',...); -- Si necesito más de 1000 valores, tengo que hacer una subquery: