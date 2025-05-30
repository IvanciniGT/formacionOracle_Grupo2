
En ocasiones el optimizador de consultas no genera el mejor plan posible para una consulta.
ES RARO! Si ocurre esto, habitualmente puede ser debido a falta de unas buenas estadísticas.

No todas las estadísticas que se generan son iguales.... de la misma calidad.
Puede ser que en algunas tablas tenga estadísticas de MALA CALIDAD.. al menos con respecto a los datos que tengo en la tabla. ME PUEDE PASAR MUY A MENUDO.

Imaginad que tengo la tabla personas... y tengo el campo DNI.
Cómo es la distribución de los datos en ese campo? UNIFORME

        Número de ocurrencias %
            ^
            |
            |
        10% |   X   X   X   X   X   X   X   X   X   X
            |   X   X   X   X   X   X   X   X   X   X
            |   X   X   X   X   X   X   X   X   X   X
            ---------------------------------------------------------------> dni
                0   1   2   3   4   5   6   7   8   9

        Eso es una distribución uniforme de los datos.
        En estos casos, con saber el valor mínimo, el máximo y el número de datos que tengo, es suficiente para que el optimizador de consultas pueda hacer un buen trabajo.

        MINIMO 00.000.001 X
        MAXIMO 99.999.999 X
        VALORES DISTINTOS 1.000.000
        En total tengo 1.000.000 de datos.

        Si me piden el registro con DNI 3.000.000, por donde caerá? como hago el corte

        |--^-----------------------------------------------| DNIs Ordenados
           3% <- Busco el dato: 30.000

        Cuantos datos devolverá esta query:
        SELECT COUNT(*) FROM personas WHERE dni > 30.000.000 AND dni < 70.000.000;
           40% de los datos: 400.000 registros
        
        ESTO EXACTAMENTE ES LO QUE HACE EL OPTIMIZADOR DE CONSULTAS, para estimar la cantidad de datos que va a devolver una consulta o que mueve una operación dentro de la query.

Estas sin las estadísticas BÁSICAS QUE CALCULA ORACLE!

Para campos que no siguen distribuciones uniformes, necesitamos solicitar a Oracle que haga estadísticas más completas: Histogramas.

Tenemos la tabla NOMBRE de la persona.
El mínimo sería un nombre que empiece por A: Abelardo
El valor máximo sería un nombre que empiece por Z: Zacarías

Los datos se distribuyen uniformemente entre A y Z en los nombres de las personas? NO
Tendré muchos nombre que empiecen por A, por Z pocos, o por X na... y por M montón!

Una estadística simple dará estimaciones muy malas.
Si tengo 1 millón de nombres... y le pregunto cuantos empiezan por A, si tiene solo el max y min, estimará que 1/27 * 1.000.000 = 37.037 nombres empiezan por A.
Pero quizás tendremos 100.000 nombres que empiezan por A

Por la Z estimará que hay 37.037 nombres que empiezan por Z, pero quizás solo haya 100 nombres que empiecen por Z.

En estos casos podemos generar un histograma de la columna NOMBRE.
        Número de ocurrencias %
            ^
            |   X
            |   X
            |   X       X
            |   X       X       X
            |   X   X   X   X   X   X
            |   X   X   X   X   X   X                           X                                       .           .
            +---------------------------------------------------------------------------------------------------------->
                A   B   C   D   E   F   G   H   I   J   K   L   M   N   O   P   Q   R   S   T   U   V   W   X   Y   Z

Esta estadística es más pesada de calcular, pero es más precisa. Y ORACLE NO ES LA QUE CALCULA POR DEFECTO cuando solicito las estadísticas de una tabla.

Para calcular estadísticas normales:
```sql
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => 'NOMBRE_USUARIO',
        tabname => 'NOMBRE_TABLA',
        estimate_percent => 100, -- 100% de los datos
        cascade => TRUE -- Calcula estadísticas de índices también
    );
END;-- Esta es la forma más sencilla de calcular estadísticas de una tabla: MAX, MIN, COUNT, NULLS, DISTINCTS, etc.
```

Para calcular estadísticas con histogramas:
```sql
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => 'NOMBRE_USUARIO',
        tabname => 'NOMBRE_TABLA',
        estimate_percent => 100, -- 100% de los datos
        cascade => TRUE, -- Calcula estadísticas de índices también
        granularity => 'ALL', -- Granularidad de las estadísticas
        method_opt => 'FOR ALL COLUMNS SIZE <tamaño>' -- Genera histogramas para todas las columnas
    );
END;-- ese <tamaño> puede ser un número entre 1 y 254, o AUTO para que Oracle decida el tamaño del histograma.
```

Imaginad una tabla de ventas que hago con su fecha. Todos los días hago el mismo número de ventas? POSIBLEMENTE NO.
Si tengo datos 4 años en mi tabla. Puedo crear un histograma de 210 buckets de 1 semana cada uno.

Y controlo cuantos datos tengo en cada semana. Las semanas de principio de mes posiblemente tengan más datos que las semanas de final de mes. Y cuando haga queries filtrando por fecha, el optimizador de consultas tendrá una mejor estimación de los datos que va a devolver.

Pensad que podríamos ir más finos... y tener esa tabla particionada por años.... y con 250 buckets por año, tengo casi 1 bucket por día.

Hay muchas columnas que con las básicas me vale.
- IDs autogenerados? Con la básica me vale (MIN y MAX)
- DNI? Con la básica me vale (MIN y MAX)
- Estado de un expediente (10 posibles estados)? HISTOGRAMA de 10 buckets... y lo peta el optimizador de consultas.

Solo esto ya me evita casi por completo el uso de PISTAS (hints) para el optimizador de consultas.
Si Oracle tiene unas buenas estadísticas, el optimizador de consultas hará un buen trabajo.
Muy complejo que yo sea capaz de hacer un mejor trabajo que el optimizador de consultas de Oracle.
Porque él tiene en cuenta muchas más cosas que yo no tengo en cuenta... entre otras cosas por el tiene datos que yo no tengo:
HIT RATIO DE LA CACHE.

Las estadísticas EN GENERAL es necesario que las mantengamos actualizadas.
PERO EN GENERAL!... 
La tabla usuarios con 100.000 usuarios. Y tengo ya las estadísticas del nombre... Es necesario regenerar las estadísticas del nombre:
- cada vez que inserto un usuario? NO
- si inserto 100.000 usuarios? TAMPOCO
- si inserto 10.000.000.000 de usuarios? TAMPOCO La distribución no cambia!
- Lo unico que cambia es el total de datos que tengo... pero nada más... Seguiré teniendo más o menos el mismo porcentaje de nombres que empiezan por A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y y Z.

La columna ID, voy metiendo... voy metiendo.. voy metiendo.
La columna fecha de venta... voy metiendo... voy metiendo... voy metiendo.
IY me incrementando el maximo de la columna fecha de venta, y de la columna ID.
Y eso se tiene que enterar .. y necesitamos regenerar las estadísticas de esas columnas.

Hay veces que podemos forzar a que se regenere solo alguna columna.
```sql
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => 'NOMBRE_USUARIO',
        tabname => 'NOMBRE_TABLA',
        estimate_percent => 100, -- 100% de los datos
        cascade => TRUE, -- Calcula estadísticas de índices también
        method_opt => 'FOR COLUMNS SIZE AUTO nombre_columna' -- Genera histograma solo para la columna nombre_columna
    );
END;
```

Hay veces que puedo pedir que se actualicen solo los metadatos de una tabla, sin recalcular las estadísticas.
```sql
BEGIN
    DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO; -- Actualiza los metadatos de todas las tablas (TOTAL)
END;
```

Hay veces que le pido que solo analice los datos nuevos que se han insertado en una tabla.
```sql
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => 'NOMBRE_USUARIO',
        tabname => 'NOMBRE_TABLA',
        estimate_percent => 100, -- 100% de los datos
        cascade => TRUE, -- Calcula estadísticas de índices también
        options => 'GATHER STALE' -- Solo actualiza las estadísticas de las columnas que están desactualizadas
    );
END;
```

Nos suele traer más cuenta asegurarnos que las estadísticas de las tablas están actualizadas, que intentar jugar a dar pistas al optimizador de consultas.

---

En ocasiones, aún así (porque tenga malas estadísticas o simplemente por equivocación), el optimizador de consultas no genera el mejor plan posible para una consulta (RARO).

Ahi es donde entran los hints (pistas) para el optimizador de consultas.
Esos hints los escribimos después del SELECT , entre /*+ HINT */

HINTS disponibles:
- USE_NL: Utiliza un bucle anidado para unir tablas, en lugar de join hash.
- USE_HASH: Utiliza un join hash para unir tablas, en lugar de un bucle anidado.
- INDEX: Utiliza un índice específico para una tabla.
- FULL: Utiliza un escaneo completo de la tabla, en lugar de un índice.
- LEADING: Especifica el orden en que se deben unir las tablas. LEADING (tabla1 tabla2 tabla3)   LEADING (tabla3, tabla1, tabla2)
- NO_INDEX: No utiliza un índice específico para una tabla.
- GATHER_PLAN_STATISTICS: Recoge estadísticas del plan de ejecución de la consulta.
- ORDERED: Respeta el orden que yo impongo en la query para los joins.

Esas pistas las podemos hacer/dar de 2 formas:
- A nivel de la query que lanzo:
```sql
SELECT /*+ USE_NL(t1 t2) */ * FROM tabla1 t1 JOIN tabla2 t2 ON t1.id = t2.id;

SELECT /*+ INDEX(t1 idx_t1) */ * FROM tabla1 t1 WHERE t1.columna = 'valor';
```

- Con SQL_PATCH.
  Oracle cada vez que ejecutamos una query, la guarda en un caché de SQL.
  Entre otras cosas, porque analizar una query y determinar el plan de ejecución es costoso.
  Cuando llega una query, la BBDD debe:
  1. Analizar sintácticamente la query, en busca de errores de sintaxis.
  2. Eliminar comentarios y espacios en blanco.
  3. Analizar semánticamente la query, en busca de errores semánticos.
     - Hay funciones que pueden requerir un determinado número de argumentos
     - O unos tipos de datos concretos.
  4. Mirar en el catalogo de la BBDD si existen las tablas, vistas, funciones, procedimientos, etc. que se mencionan en la query.
  5. Mirar las columnas que se mencionan en la query, si existen, si son del tipo correcto, etc.
  6. Y después de todo este follón, empezar a plantear distintos planes de ejecución.
     - Y para cada plan de ejecución, calcular el coste de ese plan de ejecución... haciendo previamente estimaciones de los datos que va a devolver cada operación.
     - Y elegir el plan de ejecución con menor coste.
Y el Oracle (Y cualquier bbdd) tiene una cache donde guarda las queries y sus planes de ejecución.
La próxima vez que se ejecute la misma query, no tiene que volver a analizarla, ni volver a calcular el plan de ejecución.
Esa cache evidentemente tiene un tamaño finito.. Eso va en el SGA de la BBDD.
El Oracle mantiene en esa caché las queries que más se ejecutan.

La estrategia de SQL_PATCH lop que hace es modificar una query que ya está en la caché de SQL, para que se ejecute con un plan de ejecución diferente al que original.
Y eso me evita tener que tocar directamente la query que se ejecuta en la aplicación.


A nivel de la app yo tengo la query:
```sql
SELECT * FROM tabla1 t1 JOIN tabla2 t2 ON t1.id = t2.id WHERE t1.columna = 'valor';
```

Y eso se guarda en cache... o no!
Si se guarda en caché, tendrá un ID de la consulta.

Puedo hacer un patch para ese ID de la consulta.

Para ver las queries que tengo en caché:
```sql
SELECT sql_id, sql_text FROM v$sql; ---WHERE sql_text LIKE '%tabla1%';
```

Con los ids o con el texto, podemos pedir que se un patch:

```sql
BEGIN
    DBMS_SQLTUNE.CREATE_SQL_PATCH(
        sql_id => 'mi_sql_patch', 
        sql_text => 'SELECT * FROM tabla1 t1 JOIN tabla2 t2 ON t1.id = t2.id WHERE t1.columna = ''valor''',
        fixed => TRUE, -- Si es TRUE, el patch se aplica siempre que se ejecute la query
        hints => '/*+ USE_NL(t1 t2) */', -- Aquí van los hints que quiero aplicar a la query
        name => 'mi_sql_patch_name', -- Nombre del patch
        description => 'Este es un patch para mejorar el rendimiento de la consulta que une tabla1 y tabla2'
    );
END;



DESC dba_sql_patches;
SELECT name, description, sql_text, hints, status FROM dba_sql_patches WHERE name = 'mi_sql_patch_name';

-- Hay procedimientos para borrar, activar, desactivar, etc. los patches.
-- Para borrar un patch:
BEGIN
    DBMS_SQLTUNE.DROP_SQL_PATCH(
        name => 'mi_sql_patch_name'
    );
END;
```

NOTA IMPORTANTE:
A la mínima que cambia la query (que cambia el texto de la query), el patch no se aplica.

```sql
SELECT * FROM tabla1 t1 JOIN tabla2 t2 ON t1.id = t2.id WHERE t1.columna = 'valor' ;

SELECT * FROM tabla1 t1 JOIN tabla2 t2 ON t1.id = t2.id WHERE t1.columna = 'otro_valor'; -- esto se considera una query diferente y el patch no se aplica.

-- por eso solemos, y es recomendable usar parametrización de las queries.

SELECT * FROM tabla1 t1 JOIN tabla2 t2 ON t1.id = t2.id WHERE t1.columna = :valor; -- esto se considera la misma query, y el patch se aplica. -- PREPARED STATEMENT
```

NOTA 2: OJO CON ESTO... porque si uso prepared statements con parámetros, el optimizador de consultas no puede hacer estimaciones de los datos que va a devolver la consulta.
Y además, el plan de ejecución siempre será el mismo, independientemente del valor que le pase al parámetro.
Y en ocasiones esto puede ser subóptimo. Y un prepared statement puede ser peor que una query normal.

Muchas veces... pasamos un poco de todo esto... porque es muy complicado.. hay que ir caso a caso. Y toco una cosa... y puedo fácilmente joder otra.

Lo mejor: BUENAS ESTADISTICAS (cuanto mejores mejor!) y cruzar los dedos, para que el ORACLE haga un buen trabajo( que suele hacerlo si las estadísticas son buenas).

En casos muy especiales cuando no queda otra.. y el impacto de alguna query es muy grande, podemos usar hints o SQL_PATCH.
Pero si eso se convierte en una necesidad constante, posiblemente el problema lo tengo en otro sitio.


---

# Vistas Materializadas:

Característica muy potente de Oracle.

Estamos muy acostumbrados al concepto de VIEW... que es una view?
Una view es tan solo UN ALIAS que le pongo a una query.

```sql
CREATE VIEW nombre_view AS
SELECT columna1, columna2 FROM tabla1 WHERE columna3 = 'valor';

CREATE VIEW nombre_view2 AS
SELECT t1.c1, t2.c2 FROM tabla1 t1 JOIN tabla2 t2 ON t1.id = t2.id WHERE t1.columna3 = 'valor';
```
Una view es una query que se guarda en la BBDD, y que se puede consultar como si fuera una tabla.
NO EL RESULATDO DE LA QUERY... sino LA QUERY EN SÍ.

Cuando yo escribo 
```sql
SELECT * FROM nombre_view;
```
Si miro el plan de ejecución es el mismo que si escribo:
```sql
SELECT columna1, columna2 FROM tabla1 WHERE columna3 = 'valor';
```

Las vistas son muy útiles para simplificar consultas complejas.

Las vistas materializadas son algo diferente, aunque también se llaman views.

Son tablas FISICAS que existen en los ficheros de la BBDD, lo que pasa es que esas tablas se populan con el resultado de una query...
Son como si fueran tablas temporales que me genero en memoria en un procedimiento, pero que se guardan en disco y que se pueden consultar como si fueran tablas normales, yo, u otros usuarios.

Esas vistas materializadas se van refrescando con el tiempo, y se pueden refrescar de varias formas:
- Manualmente
- Automáticamente cada cierto tiempo
- Automáticamente cuando se actualizan las tablas de las que dependen.
- Cuando se accede a la vista materializada, se refresca automáticamente.

Cuando trae cuentas el trabajar con vistas materializadas?
- Cuando necesito hacer muchas subconsultas sobre un conjunto de datos que es muy costo de calcular.
- Y entonces me interesa calcularlo una vez, y guardarlo en disco, y tirar queries sobre eso.
Si tengo más actualizaciones que lecturas, no me interesa una vista materializada.
Si tengo más lecturas que actualizaciones, no me interesa una vista materializada.
Si tengo muchas lecturas y pocas actualizaciones, me interesa una vista materializada.

Solemos usarlas mucho con datos que vamos agrupando, agregando, sobre los que aplicamos operaciones en ventana...
Y usamos esa "tabla" nueva para hacerle luego subconsultas.

Hay también casos muy típicos, donde realmente me importa poco acceder a datos que esté actualizados al 100% (en tiempo real), y me interesa más que los datos estén disponibles rápidamente.

Cuadro de mando, que voy a mostrar en pantalla de una app. a muchos usuarios cuando acceden a un sistema, me importa poco que refleje datos actualizados al segundo... en según qué escenario... hay veces que me valen los datos de la última media hora.. o incluso lo de ayer, para según qué operaciones de negocio. Son casos ideales para vistas materializadas. 
Para todo o que es BUSINESS INTELLIGENCE, es ideal usar vistas materializadas.

DATALAKE, DATAWAREHOUSE

BUSINESS INTELLIGENCE: Proveer datos a los usuarios de negocio para que puedan tomar decisiones informadas.
Básicamente aplicar técnicas estadísticas de nivel instituto a conjuntos de datos grandes para generar cuadros de mando:
- Tablas de frecuencias
- Tablas de contingencia /Frecuencia (2 variables)
- Tablas de correlación
- Estadísticos básicos: Media, mediana, moda, desviación típica, varianza, sumatorios.

Si en los últimos 5 años, en el mes de Julio se han vendido muchas gafas de sol, para este año, vamos a llenar los almacenes de gafas de sol en Julio.
El problema es que esto tira unas queries a las BBDD de flipar.

    ORACLE BBDD PRODUCCION -> ETL --> ORACLE BBDD DATAWAREHOUSE -> ETL -> ORACLE BBDD DATAWAREHOUSE <---- POWER BI
        datos vivos.                        historicos.                     datos agregados y preparados para BI

Una forma de llevar estoa entornos de producción más simples, es usar bases de datos en espejo.

    ORACLE INSTANCE (PRODUCCION) ---> ORACLE INSTANCIA (espejo) (SOLO LECTURA)
                                       
    ORACLE INSTANCE (PRODUCCION) ---> ORACLE INSTANCIA 
                                       Vistas MAterializadas que trabajan sobre las tablas de las bbdd de producción.

```sql

CREATE MATERIALIZED VIEW nombre_vista_materializada
<PARAMETRIZACION>
AS
SELECT columna1, columna2 FROM tabla1 WHERE columna3 = 'valor';

```
PARAMETRIZACION:
- BUILD IMMEDIATE: Se construye la vista materializada inmediatamente después de crearla.
- REFRESH ON COMMIT: Se refresca la vista materializada cada vez que se hace un commit en las tablas de las que depende.
- REFRESH ON DEMAND: Se refresca la vista materializada manualmente cuando se necesita.
        EXEC DBMS_MVIEW.REFRESH('nombre_vista_materializada'); 
- REFRESH FAST: Se refresca la vista materializada de forma rápida, utilizando los ARCHIVELOGs.
- REFRESH COMPLETE: Se refresca la vista materializada de forma completa, recalculando todos los datos.
- REFRESH ON SCHEDULE: Se refresca la vista materializada automáticamente cada cierto tiempo.
        
Una gracia adicional que tienen las vistas materializadas, es que se pueden tener sus propios índices. Las usamos igual que una tabla.

Las vistas materializadas tienen más que ver con una TABLA que con una VIEW, en cuanto a su gestión y mantenimiento.
El único tema es que nosotros no cargamos los datos en la vista materializada (CON INSERTS, o DELETES, o UPDATES), sino que Oracle se encarga de ello.

Tienen sus segmentos, sus extents, sus bloques de datos... todo igual que una tabla normal.

OJO con el ON COMMIT, porque si tengo una vista materializada que se refresca cada vez que hago un commit, me puede penalizar mucho el rendimiento de la BBDD. Si encima tengo índices en la vista materializada, me puede penalizar mucho el rendimiento de la BBDD.

---

# PARTICIONADO DE TABLAS: IMPORTANTISIMO

Si tengo tablas pequeñas.. me olvido.
Seguro que si tengo un Oracle... alguna tabla grande cae. Si no me quedo en postgres o mysql... que son gratis o muy baratas.

## Qué ventajas me da el particionado...
Depende del escenario.
- A veces mejoramos la capacidad de ingesta de datos.
- A veces mejoramos el rendimiento de las consultas.
- En general facilita operaciones de mnto.
- Si lo hago bien, puedo liberar RAM... a kilos!

## Formas de crear tablas particionadas:
- RANGE: Particiono por rangos de valores. Por ejemplo, por fecha.
  ```sql
    CREATE TABLE nombre_tabla (
        id NUMBER,
        fecha DATE,
        valor NUMBER 
    )
    PARTITION BY RANGE (fecha) (
        PARTITION p1 VALUES LESS THAN (TO_DATE('2023-01-01', 'YYYY-MM-DD')),
        PARTITION p2 VALUES LESS THAN (TO_DATE('2024-01-01', 'YYYY-MM-DD')),
        PARTITION p3 VALUES LESS THAN (MAXVALUE)
    );

    -- Luego podemos ir añadiendo particiones nuevas:
    ALTER TABLE nombre_tabla ADD PARTITION p4 VALUES LESS THAN (TO_DATE('2025-01-01', 'YYYY-MM-DD'));
    ```
    Este caso me interesa si cuando hago queries filtrando por fecha, voy a devolver pocos datos.
    Cada partición puede tener su propio índice, y eso me permite hacer consultas más rápidas (menos uso de RAM)
    Posiblemente trabaje mucho más con datos del año en curso, que con datos de años anteriores.
    Y lo que quiero que esté en cache es el índice de la partición del año en curso, y los datos de esa partición.
    Y los del año pasado, que se usarán de higos a brevas, no me interesa que estén en cache.... y Oracle los tomará del HDD cuando los necesite.
- LIST: Particiono por listas de valores. Por ejemplo, por estado.
    ```sql
        CREATE TABLE nombre_tabla (
            id NUMBER,
            estado VARCHAR2(20), -- provincias
            valor NUMBER 
        )
        PARTITION BY LIST (estado) (
            PARTITION p1 VALUES ('activo', 'pendiente'),
            PARTITION p2 VALUES ('inactivo', 'cancelado'),
            PARTITION p3 VALUES ('borrador')
        );
    
        -- Luego podemos ir añadiendo particiones nuevas:
        ALTER TABLE nombre_tabla ADD PARTITION p4 VALUES ('nuevo_estado');
        ```
        Si tengo expedientes en distintos estados.. seguramente trabaje más con los que están vivos (abiertos) que con los que están cerrados.

        Si tuviera provincias... simplemente lo que hago es balanceo de datos.
        - En parte para queries... pero otra parte importante sería balancear los datos en el disco.
        - Podría tener cada partición en un HDD diferente, y así balancear el uso de los discos.
- HASH: Particiono por hash de un campo. Por ejemplo, por id. PROPORCIONA BALANCEO
  Reparto aleatoriamente los datos entre las particiones.
    ```sql
        CREATE TABLE nombre_tabla (
            id NUMBER,
            valor NUMBER 
        )
        PARTITION BY HASH (id) (
            PARTITION p1,
            PARTITION p2,
            PARTITION p3,
            PARTITION p4
        );
    ```
    Si tengo una tabla de usuarios, y quiero balancear los datos entre las particiones, puedo usar hash.
    Si tengo una tabla de ventas, y quiero balancear los datos entre las particiones, puedo usar hash.

    Puedo hacer la regeneración de estadísticas de cada partición de forma independiente, y eso me permite tener estadísticas más precisas para cada partición.

Cada partición que se genera, tiene su propio SEGMENTO.

El otro día os dije que una tabla tiene asociado un segmento, que es el espacio en disco donde se guardan los datos de la tabla.
Pero realmente una tabla puede tener varios segmentos, si está particionada. (Hay más casos donde una tabla puede tener varios segmentos, si en el futuro genero un fichero nuevo físico en el tablespace, pero eso es otro tema).

Los índex podemos elegir en una partición si queremos que se generen por partición o no. (LOCAL INDEXES)

```sql

CREATE TABLE nombre_tabla (
    id NUMBER,
    fecha DATE,
    valor NUMBER 
)
PARTITION BY RANGE (fecha) (
    PARTITION p1 VALUES LESS THAN (TO_DATE('2023-01-01', 'YYYY-MM-DD')),
    PARTITION p2 VALUES LESS THAN (TO_DATE('2024-01-01', 'YYYY-MM-DD')),
    PARTITION p3 VALUES LESS THAN (MAXVALUE)
)

CREATE INDEX idx_nombre_tabla_fecha ON nombre_tabla(fecha) LOCAL; -- Índice local, se genera por partición
CREATE INDEX idx_nombre_tabla_id ON nombre_tabla(id) GLOBAL; -- Índice global, se genera para toda la tabla
```

Otra cosa que podemos hacer con las particiones es al hacer queries decir en la query que partición quiero que use.
```sql
SELECT * FROM nombre_tabla PARTITION (p1) WHERE fecha = TO_DATE('2023-01-01', 'YYYY-MM-DD');
```