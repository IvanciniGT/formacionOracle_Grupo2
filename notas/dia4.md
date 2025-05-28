1. Planes de ejecución 
2. Bloqueos
3. Estadísticas
4. Hints <- SQL PATCH

---
BBDD de producción... Con datos que están vivos.. que estamos manejando... que necesitamos ir haciendo algo con ellos.
 v
 ETL
 v
DATALAKE
 v
 ETL
 v
DATAWAREHOUSE

De vez en cuando quitamos datos de las BBDD de producción y los llevo a un datalake.
Un datalake es un repositorio gigantesco de datos en bruto... según vienen de otras fuentes..
Guardo ahí los datos para futuros usos... o por necesidades legales.

Un datawarehouse es un repositorio de datos donde ya he preparado los datos para que sean útiles para un menester concreto.. por ejemplo para hacer BI, para hacer modelos de machine learning, para hacer análisis de datos, etc.


---

# BLOQUEOS EN ORACLE

Los bloqueos son una de las cosas más importantes que hay que tener en cuenta a la hora de trabajar con bases de datos.

A qué nivel bloquea Oracle datos? 
- A nivel de registro              <<<<<<<<< SIEMPRE !
- A nivel de bloque de datos

Siempre que no haga algo que cambie la estructura de la tabla, si tiro una query que modifique la estructura de la tabla, entonces bloquea la tabla entera.

```sql
ALTER TABLE usuarios ADD COLUMN edad NUMBER; -- Se bloquea la tabla entera
```

En los bloqueos del tipo: 
```sql
SELECT * from usuarios where id = 1 FOR UPDATE; -- El bloqueo siempre es a nivel de registro
```

## Qué ocurre con Oracle.. que a veces nos hace cosas raras en este sentido.

La información de qué registros están bloqueados se guarda a nivel de bloque!
Se guarda en la cabecera de cada bloque... en una tabla que se denomina ITL.
Es tabla (ITL = Interested Transaction List) es una lista de transacciones que tienen asuntos pendientes con ese bloque.

En esa tabla (ITL) se guarda el número de transacción y el número de registro que está bloqueado.
Si en un bloque tengo 200 registros, y tengo 3 transacciones que cada una bloquea un registro, entonces en la ITL de ese bloque habrá 3 entradas, cada una con el número de transacción y el número de registro que está bloqueado.

CUAL ES EL PROBLEMA... el problema es que dependiendo de cómo yo haya creado la tabla, el número de entradas que puedo tener en la ITL es limitado. Y el problema es que si esa tabla en un momento dado se llena, entonces no puedo apuntar nuevas transacciones a la ITL, y se produce una CONTENCIÓN A NIVEL DEL BLOQUE... que no es un bloqueo, pero a la vista tienen unas consecuencias similares.

Cuando vaya a hacer un INSERT, UPDATE o DELETE, mi query queda en espera... no en espera de que el registro se desbloquee, ni en espera de que el bloque se desbloquee (ya que esto en Oracle no existe) ... en espera de que haya espacio en la ITL para poder apuntar mi transacción.

Cuando creamos una tabla en Oracle, hay un parámetro, que por defecto suele ser muy bajo (1,2), llamado INITRANS, que es el número de entradas que se reservan en la ITL de cada bloque.

```sql 
CREATE TABLE usuarios (
    id NUMBER PRIMARY KEY,
    nombre VARCHAR2(50),
    edad NUMBER
) INITRANS 10 PCTFREE 10;
```

Cada entrada del ITL ocupa 23 bytes, si guardo 10 entrada, entonces estoy reservando 230 bytes por bloque. 230b/8Kbs= 0.028125 bloques por cada entrada de la ITL.

Antiguamente en Oracle (versiones 11 y anteriores) había un segundo parámetro que se llamaba MAXTRANS, que era el número máximo de entradas que podía haber en la ITL de un bloque. Este parámetro ya no existe en las versiones actuales de Oracle.
Hoy en día el tamaño de la ITL es dinámico, y puede crecer hasta un máximo de 255 entradas por bloque. Si se supera este número, entonces se produce una contención a nivel de bloque.
Y crece mientras haya espacio en el bloque, el tamaño de la ITL puede crecer... Con respecto al tamaño libre que haya en el bloque, nos afecta el parámetro PCTFREE, que es el porcentaje de espacio libre que se deja en cada bloque para actualizaciones de datos.

PCTFREE es el espacio que se reserva de forma que si se hacen inserts, esos inserts no se guarden en el bloque... y se guarden en otro... ya que el espacio del PCTFREE se reserva para que si se hacen actualizaciones, esas actualizaciones no tengan que ir a otro bloque (doble lectura).


---

Con respecto al PCTFREE:
No afecta por igual a todas las tablas... y sus columnas.

```sql

CREATE TABLE usuarios (
    id NUMBER PRIMARY KEY,
    nombre VARCHAR2(50) NOT NULL,
    edad NUMBER
) INITRANS 10 PCTFREE 10;

CREATE TABLE contadores (
    id NUMBER PRIMARY KEY,
    NOMBRE VARCHAR2(50),
    valor NUMBER NOT NULL
) INITRANS 10 PCTFREE 5;

```

En contadores, si hago un UPDATE, de qué columna haré el UPDATE? DE LA COLUMNA valor.
Y Esa columna es de tipo NUMBER... y tiene un tamaño fijo.
Y como además tiene un NOT NULL. desde el primer insert, se reservaron los bytes necesarios para esa columna.
Si hago un UPDATE, el update modifica el valor de esa columna, pero no hace falta más espacio en el bloque... TIENE UN ANCHO FIJO... siempre ocupa lo mismo.
En la tabla contadores, el PCTFREE no influye en nada (AL MENOS con respecto a lo que son las actializaciones de datos).... aunque si me afecta al ITL... ya que el ITL puede necesitar crecer... y si no hay espacio en el bloque, entonces se produce una contención a nivel de bloque (que no un bloqueo del bloque... eso no existe...)

En la tabla usuarios, ,me pueden modificar:
- EDAD... que puede ser que antes no existiera- (ES NULLABLE)... y cuando se ponga una edad (con un UPDATE) necesito espacio espacio para guardar ese dato. (AQUÍ INFLUYE EL PCT FREE para asegurarme que tengo espacio para guardar ese dato).
- NOMBRE, aunque sea NO NULLABLE, de un insert  a un update... u otro... puede cambiar de 1 byte a 50 bytes... y si antes ocupaba 1 byte, y ahora ocupa 50 bytes, entonces necesito espacio para guardar ese dato. (AQUÍ INFLUYE EL PCT FREE para asegurarme que tengo espacio para guardar ese dato).


TABLA USUARIOS -> SEGMENTO USUARIOS
SEGMENTO USUARIOS -> 57 EXTENTS
Cada extend tiene 8 bloques de 8K
Y cada bloque tiene su ITL propio.
En la tabla de usuarios tenemos en total 57 x 8 = 456 bloques cada uno con su ITL.

TABLA USUARIOS <--- PCTFREE 10%-... INIT TRANS (2)
    bloque 1
        ITL(2)
        datos: 1,2,3,4,5,6,7,8
        FREE 10%
    bloque 2
        ITL(2)
        datos: 9,10,11,12,13,14,15,16
        FREE 10%
    bloque 3
        ITL(2) 18, 19
        datos: 17,18,19,20,21,22,23,24
        FREE 0%

Hago un update del dato 18
Hago un update del dato 19... con este segundo he llenado la ITL del bloque 3.

Si intento hacer un update del dato 2, como ese dato está en el bloque 1, y en ese bloque hay hueco en la ITL, entonces no hay problema, se actualiza el dato 2.
Si intento hacer un update del dato 20, como ese dato está en el bloque 3, y en ese bloque no hay hueco en la ITL, entonces se produce una contención a nivel de bloque.

Si se me ocurre poner un INITTRANS de 200. Tengo reservado para ITL 200 x 23 bytes = 4600 bytes.
con cabecera se me van 5000bytes.... es decir, tengo disponible 3000 bytes para datos 
    3000/8000 = 37.5% del espacio total que ocupan las cosas en disco y RAM.

Para tablas que no se actualizan mucho, un initrans de 1 o 2, 3 es suficiente.
Para tablas que se actualizan mucho, un initrans de 10 o 15.
 ^^^
 En estas tengo que tener cuidado con el PCTFREE si concibo que en algunos casos puedo superar las 15

En mi tabla, que son 8100 bytes, quitando cabecera, tengo 8000 bytes... De eso tengo un 10% de PCTFREE, que son 800 bytes.
Si cada entrada en ITL ocupa 24 bytes, entonces tengo 800/24 = 33 entradas en la ITL.
