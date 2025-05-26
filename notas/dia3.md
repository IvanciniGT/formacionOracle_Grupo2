

En la base de datos, guardamos datos (secuencias de bytes) en los ficheros.
Esas secuencias las tenemos asociadas a campos. Cada campo tiene un tipo de datos... y en base a ese tipo de datos, el campo se guarda ocupando más o menos bytes.

En DB2 o en Oracle puedo tener un campo que ocupe 1 byte, 2 bytes... lo que sean.
Si quiero trabajar a nivel de bytes, en Oracle tengo un tipo de datos llamado RAW, que es un tipo de datos binario.
Puedo pedir cuántos quiero guardar: RAW(1), RAW(2), RAW(200)

Una cosa es el campo que tengo en la BBDD... y otra cosa el significado que le doy a esos bytes que tengo guardados en ese campo.

 4 valores 00 01 10 11: Y asignarle conceptualmente un significado a cada uno de esos valores. POCO, ALGO, MUCHO, MUCHISIMO
 VV
0000 0000
^  ^^^^^^ <- 5 bits(2^5 = 32 valores) 00000, 00001... 11111-- y asignarle conceptualmente un significado a cada uno de esos valores.
^                          
BIT: Es un valor lógico: Si llueve o no

A nivel de la BBDD, lo que tengo es un campo que ocupa 1 byte.
A nivel de mi programa , ese byte lo descompongo, como me interese y le doy un significado a cada uno de los bits (o grupos de bits que yo creo) que tengo en ese byte. ESTO ES LO QUE EN COBOL HACEMOS CON LOS CAMPOS EMPAQUETADOS.
Eso me ayuda a optimizar el espacio que ocupan datos en la BBDD.
Guardo varios datos JUNTOS en un único campo de la BBDD. Empaqueto los datos en un campo!

Otra cosa distinta es cómo yo humano, tirando una query a la BBDD voy a ver ese campo (bytes)
Cómo veo un byte... en pantalla?
Pintarlo como un número [0;255]; [-128;127]. Podría verlo en hexadecimal

0000 0000
^^^^ ^^^^
En 4 bits puedo guardar hasta 16 valores-> HEXADECIMAL 0-f: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, F

1 byte lo vería como 2 dígitos hexadecimales.
            HEX    NUMERO INT  CARACTER ASCII
0000 0000 -> 00 -   0          ?? NO TIENE REPRESENTACION EN ASCII
1111 1111 -> FF -   255        CUADRADITO
0001 1100 -> 1C -   28         A

TO_HEX(campo_raw(2)) = '1c2f'


# Campos de tipo fecha o campos de tipo FechaHora (Tipo TIMESTAMP)

Internamente Oracle guarda estos campos como un número entero (secuencia de bytes).
Lo que pasa es que es un tipo de campo especial... aunque internamente es un número entero.
Las operaciones que admiten son diferentes a las de un número entero... Puedo restar fechas y obtener días, puedo saber en que día de la semana cae una fecha, puedo sumar días a una fecha y obtener otra fecha...

Una cosa es cómo se guarda el dato en la BBDD...
Otra cosa es cómo yo le paso el dato a la BBDD para que entienda mi formato de fecha y lo sepa traducir a su formato interno.
Y otra cosa es cómo quiero ver ese dato en pantalla... es decir, traducirlo de nuevo del formato interno de la BBDD a un formato que yo entienda.

```sql

CREATE TABLE FECHAS (
    FECHA DATE,
    FECHA_HORA TIMESTAMP,
);

INSERT INTO FECHAS (FECHA, FECHA_HORA) 
VALUES (
    TO_DATE('03-03-2023', 'DD-MM-YYYY'),
    TO_TIMESTAMP('2023-10-03 12:34:56', 'YYYY-MM-DD HH24:MI:SS')
);

INSERT INTO FECHAS (FECHA, FECHA_HORA) 
VALUES (
    TO_DATE('03-03-2023', 'MM-DD-YYYY'),
    TO_TIMESTAMP('2023-10-03 12:34:56', 'YYYY-MM-DD HH24:MI:SS')
);

SELECT 
    TO_CHAR(FECHA, 'DD/MM/YYYY') AS FECHA_FORMATO,
    TO_CHAR(FECHA_HORA, 'DD/MM/YYYY HH24:MI:SS') AS FECHA_HORA_FORMATO
FROM FECHAS;

-- Para evitar tener que estar continuamente pasando esos formatos en cada query, podemos establecer esos datos a nivel de la conexión que hemos abierto con la BBDD puntualmente.
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD/MM/YYYY HH24:MI:SS';


INSERT INTO FECHAS (FECHA, FECHA_HORA) 
VALUES (
    '03/03/2023',  -- Si la sesión tiene el formato establecido, no es necesario usar TO_DATE
    '03/10/2023 12:34:56'  -- Si la sesión tiene el formato establecido, no es necesario usar TO_TIMESTAMP
);

-- Esto se puede configurar a nivel de la BBDD, y con VSCode y SQL Developer podemos establecerlo... PERO... NO OS FIES DE ESO.
-- Es una solución FRAGIL!
-- En cualquier momento me pueden cambiar ese formato sin previo aviso y romper todas mis consultas.

--Esos datos, a nivel global se pueden establecer en varios sitios:
-- Para consultar los formatos que hay por defecto en BBDD:
SELECT * FROM NLS_DATABASE_PARAMETERS WHERE PARAMETER_NAME = 'NLS_DATE_FORMAT';
SELECT * FROM NLS_DATABASE_PARAMETERS WHERE PARAMETER_NAME = 'NLS_TIMESTAMP_FORMAT'; -- PERO NO ME PUEDO FIAR
ALTER SYSTEM SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY'; -- Afecta a todas las sesiones que se abran a partir de ahora
ALTER SYSTEM SESSION SET NLS_TIMESTAMP_FORMAT = 'DD/MM/YYYY HH24:MI:SS'; -- Afecta a todas las sesiones que se abran a partir de ahora

```

Hay 2 ficheros de configuración de Oracle que también me permiten definir esto:
- spfile (eso un archivo binario... que gestiona oracle)
- init.ora (es un fichero de texto plano que se lee al arrancar la BBDD y se carga en memoria)
     NLS_DATE_FORMAT = 'DD/MM/YYYY'
     NLS_TIMESTAMP_FORMAT = 'DD/MM/YYYY HH24:MI:SS'


```sql
-- Desde un cliente 1, un usuario 1:
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

INSERT INTO FECHAS (FECHA, FECHA_HORA)
VALUES (
    '03/03/2023',  -- Si la sesión tiene el formato establecido, no es necesario usar TO_DATE
    '03/10/2023 12:34:56'  -- Si la sesión tiene el formato establecido, no es necesario usar TO_TIMESTAMP
);
-- Desde un cliente 2, un usuario 2:
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD-MM-YYYY HH24:MI:SS';
INSERT INTO FECHAS (FECHA, FECHA_HORA)
VALUES (
    '03-03-2023',  -- Si la sesión tiene el formato establecido, no es necesario usar TO_DATE
    '03-10-2023 12:34:56'  -- Si la sesión tiene el formato establecido, no es necesario usar TO_TIMESTAMP
);
-- Internamente la BBDD guarda las 2 fechas igual... SIN INFORMACION DE FORMATO !
-- De hecho, esas fechas serían iguales.

-- Desde un cliente 3, un usuario 3:
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
SELECT * FROM FECHAS;
-- 2023-03-03 | 2023-10-03 12:34:56
-- 2023-03-03 | 2023-10-03 12:34:56
```

El formato es solo para entrada y salida de datos.
Pero internamente, no se guarda información de formato.


```sql

CRATE TABLE DATOS (
    ID NUMBER,
    EDAD NUMBER,
    NOMBRE VARCHAR2(100),
);
```
Imaginemos que en Oracle un number ocupa 4 bytes.
Un registro de esa tabla se guardaría en fichero:

REG 1: | 4 bytes para ID | 4 bytes para EDAD | 80 bytes para NOMBRE | HUECOS EN BLANCO |
REG 2: | 4 bytes para ID | 4 bytes para EDAD | 70 bytes para NOMBRE | HUECOS EN BLANCO |

Si hay un cambio en el nombre del REG 1, no tengo que tocar ni el ID ni la EDAD, solo el NOMBRE.
Si hay un cambio en el la EDAD del REG 1, no tengo que tocar ni el ID ni el NOMBRE, solo la EDAD.

Si en lugar de eso tuviera:

```sql
CREATE TABLE DATOS (
    ID NUMBER(10),
    NOMBRE VARCHAR2(100),
    EDAD NUMBER(3),
);
```

Y tenemos :
REG1    : | 4 bytes para ID | 80 bytes para NOMBRE | 1 byte para EDAD | HUECOS EN BLANCO |
REG2    : | 4 bytes para ID | 70 bytes para NOMBRE | 1 byte para EDAD | HUECOS EN BLANCO |
Si tocamos el campo NOMBRE de reg 1 y ahora ocupa en lugar de 80 bytes, 90 bytes, tengo que desplazar todo el registro hacia la derecha para que quepa el nuevo NOMBRE.

En ORACLE Existe el campo VARCHAR y VARCHAR2.
El que oracle recomienda es VARCHAR2.
VARCHAR se define en ANSI SQL, VARCHAR2 es un tipo especial de Oracle.

VARCHAR ahora mismo es lo mismo que VARCHAR2, pero en el futuro Oracle podría cambiar el significado de VARCHAR y dejar de ser lo mismo que VARCHAR2.

Son 4000 el máximo de caracteres que puedo guardar en un VARCHAR2. Desde oracle 12c Se puede aumentar hasta 32000 si se configura a nivel de la BBDD con MAX_STRING_SIZE.

Si queréis campos más largos: CLOB (Character Large Object)
Si fuera un campo muy grande binario: BLOB (Binary Large Object)

Esos son campos un poco puñeteros. Destrozan mucho la estructura interna de los bloques de datos de Oracle.

Si tengo campos BLOB o CLOB, la recomendación es sacarlos de la tabla principal y meterlos en una tabla aparte.

```sql

CREATE TABLE personas (
    id NUMBER,
    nombre VARCHAR2(100),
    foto BLOB, -- Foto de la persona
    cv CLOB -- Descripción de la persona
); -- ASI NO!!!!

-- LA recomendación sería:
CREATE TABLE personas (
    id NUMBER,
    nombre VARCHAR2(100)
);
CREATE TABLE personas_fotos (
    id NUMBER,
    foto BLOB, -- Foto de la persona
);
CREATE TABLE personas_cv (
    id NUMBER,
    cv CLOB -- Descripción de la persona
);
--Y definir los foraneos de las tablas para que se relacionen entre sí.
ALTER TABLE personas_fotos ADD CONSTRAINT fk_personas_fotos FOREIGN KEY (id) REFERENCES personas(id);
ALTER TABLE personas_cv ADD CONSTRAINT fk_personas_cv FOREIGN KEY (id) REFERENCES personas(id);
```

Antiguamente en Oracle n tenñiamos campos especiales para XML ni JSON...
Eso le metieron en Oracle 11.

Hoy en día tenemos: 
- XMLType: Para guardar datos XML
- JSON: Para guardar datos JSON

```sql
CREATE TABLE datos (
    id NUMBER,
    datos XMLTYPE
);
-- Por defecto tenía un tamaño máximo de pocos gigas
-- Se puede forzar a que el campo XML Se guarde dentro de un clob:
CREATE TABLE datos (
    id NUMBER,
    datos XMLTYPE STORE AS CLOB
);
-- REVISAR
CREATE TABLE datos (
    id NUMBER,
    datos XMLTYPE 
) XMLTYPE datos STORE AS CLOB;

INSERT INTO datos (id, datos)
VALUES (
    1,
    XMLTYPE('<persona><nombre>Juan</nombre><edad>30</edad></persona>')
);


--- Syntaxis XPATH (estandar del W3C)
SELECT
    EXTRACTVALUE(datos, '/persona/nombre') AS nombre, --XPATH
    EXTRACTVALUE(datos, '/persona/edad') AS edad
FROM datos;

-- Sintaxis XQUERY (estandar del W3C)
SELECT
    XMLQUERY('/persona/nombre/text()').getStringVal() AS nombre, --XQUERY
    XMLQUERY('/persona/edad/text()').getStringVal() AS edad
WHERE 
    EXTRACTVALUE(datos, '/persona/nombre') = 'Juan';

CREATE INDEX idx_datos_nombre ON datos INDEXTYPE is xml_index PARAMETERS ( PATH TABLE '/persona/nombre' );

Podemos crear campos que se basen en un esquema XSD (otro estandar del W3C) o no.
Si los creamos basados en un esquema XSD, se optimizan mucho las consultas.

---

Un mal ratio de uso de cache, implica que cuando vamos a por un dato, la BBDD necesita leerlo del disco... y eso afecta gravemente al rendimiento de la BBDD.
Problemas / SOLUCIONES?
- Si veo que el problema es a nivel global? Tendríamos un problema claro de falta de SGA.
  Otra cosa es que haya un problema en TODAS LAS TABLAS... pero esto sería un segundo análisis.
- Si veo que el problema lo tengo solo en algunas tablas?
  - PCT_FREE: Espacio libre en cada bloque... quizás lo puedo bajar.. y como consecuencia, tendré menos bloques, más compactos... que ocuparán menos.
  - Si la tabla necesita compactado
  (Hay muchos datos que he ido borrando y siguen ocupando espacio en los bloques). Me traigo 500 bloques... pero solo el 50% de los datos que traen sirven para algo. Es momento claro de hacer un compactado de la tabla.. y librerar ese espacio:
    ```sql
    ALTER TABLE mi_tabla MOVE; -- Esto implica regerar indices luego!
    ```
    Si el problema no es en una tabla, sino en un índice:
    ```sql
    ALTER INDEX mi_indice REBUILD;
    ```

---

--- Esta es la sintaxis recomendada en Oracle para hacer un JOIN:
SELECT 
    DISTINCT NOMBRE, PELICULA
FROM 
    VISUALIZACIONES INNER JOIN USUARIOS ON VISUALIZACIONES.USUARIO = USUARIOS.ID
--    VISUALIZACIONES LEFT OUTER JOIN USUARIOS ON VISUALIZACIONES.USUARIO = USUARIOS.ID
--    VISUALIZACIONES RIGHT OUTER JOIN USUARIOS ON VISUALIZACIONES.USUARIO = USUARIOS.ID
--    VISUALIZACIONES FULL OUTER JOIN USUARIOS ON VISUALIZACIONES.USUARIO = USUARIOS.ID

-- Esta cuela sin problemas... pero la de arriba es ANSI SQL
SELECT 
    DISTINCT NOMBRE, PELICULA
FROM 
    VISUALIZACIONES,USUARIOS 
WHERE 
    VISUALIZACIONES.USUARIO = USUARIOS.ID -- Inner JOIN
    --VISUALIZACIONES.USUARIO (+) = USUARIOS.ID -- Left Outer Join
    --VISUALIZACIONES.USUARIO = USUARIOS.ID (+) -- Right Outer Join  
    --VISUALIZACIONES.USUARIO (+) = USUARIOS.ID (+) -- Full Outer Join
    
ESA SINTAXIS ES MUY ESPECIAL DE ORACLE... heredada de versiones ANTIGUAS DE ORACLE... y que se mantiene...
Pero que se desaconseja.