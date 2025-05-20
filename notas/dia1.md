
# Cómo los SO nos permiten acceder al contenido de un fichero.

- Acceso secuencial: Se accede a los datos de forma secuencial... Se lee/escribe el fichero desde el principio hasta el final.
  Ventajas: 
  - Simplicidad: Es más sencillo de implementar y entender. Es más eficiente para añadir cosas al final de un fichero.
- Acceso aleatorio: Se accede a los datos de forma aleatoria... Se puede leer/escribir en cualquier parte del fichero, sin necesidad de leer/escribir desde el principio hasta el final.
  Ventajas: 
  - Rendimiento cuando lo que necesito no es trabajar con todo el fichero.
  Inconveniente: 
  - Muy complejo de implementar. El principal problema es saber dónde poner la aguja del HDD para leer lo que sea que quiero leer o para escribir lo que sea que quiero escribir.


# Fichero con acceso secuencial

```json
{
  "nombre": "Menchu",
  "edad": 30,
  "ciudad": "Madrid"
}
``` 

Lo tengo guardado en un archivo. Y quiero modificar la edad. En un HDD al final lo que guardo son secuencias de bytes. En qué posición (número de byte) me pongo para escribir la nueva edad? Lo sé a priori? NO... npi

# Fichero QUE PERMITA ACCESO ALEATORIO

```txt
Menchu      33Madrid     
Federico    44Barcelona  
Felipe      55Valencia   
```
Si conociese (y es mucho suponer!) el número de fila en que está Felipe, podría calcular en que byte del fichero me tengo que poner para escribir su edad.
Nombre:    11
Edad:       2
Población: 10
Cada fila: 23

Felipe (3º fila): 2filas que salto * 23bytes por fila + me salto el nombre de Felipe (11) = 57 y ahi puedo escribir 2 bytes.

Hay un problema adicional con esta forma de trabajo: Para conseguir lo que queríamos, estamos sacrificando espacio... mucho espacio.

Debo de tratar de paliar este efecto... de pérdida de espacio... o dicho de otra forma.. des espacio usado inútilmente.Y ESTO SE COMPLICA.

Al final, las BBDD no son sino programas que me ayudan a lidiar con ficheros que tienen acceso aleatorio.

## ¿Qué guardo en esos fichero? ¿Cómo lo guardo?

Al final, en un HDD lo que guardo son bits (0,1).
En un bit puedo guardar 1 dato... que puede tomar hasta 2 valores (0 o 1).
Una cosa es lo que guardo (0,1) y otra cosa es el SIGNIFICADO que YO HUMANO le doy a aquello!
0 -> No llueve   No tiene deuda     Tiene billetes en la cuenta      Tiene tarjeta de crédito
1 -> Llueve      Tiene deuda        No tiene billetes en la cuenta   No tiene tarjeta de crédito

Habitualmente trabajamos con bytes (8 bits) y no con bits. Un byte puede tomar 256 valores diferentes.
2 bytes: 256x256 = 65.536 valores diferentes.
4 bytes: 256x256x256x256 = 4.294.967.296 valores diferentes.

    LO QUE GUARDO   SIGNIFICADO
                    Número entero     Número entero con signo   Letra   Otra Forma
    0000 0000         0                 -128                    A       a
    0000 0001         1                 -127                    B       A
    0000 0010         2                 -126                    C       b
    ...
    0000 1111        15                 -113                    P   
    ...
    1111 1111       255                  127                    ñ

Esto tiene que ver con 2 conceptos:
- Tipo de dato
- Textos.... JUEGO DE CARACTERES (Encoding)
  - ASCII           1 byte
  - ISO8859-1       1 byte
  - UTF-8           1, 2 o 4 bytes (form. de codificación variable)
  - UTF-16          2 o 4 bytes (form. de codificación variable)
  - UTF-32          4 bytes

UNICODE Es un estándar que recopila todos los caracteres de todos los idiomas del mundo... Poco más de 150.000 caracteres.

Los Sistemas Operativos, cuando trabajamos con fichero me ofrecen 2 alternativas (paralelas al hecho de que use acceso secuencial o aleatorio):
- Si se trata el fichero como texto: Cada byte, todos y cada uno de ellos, se interpreta como un carácter.
  CSV, DOCX, XLSX, JSON, XML, TXT, etc. 
- Si se trata el fichero como binario: Cada bytes es un byte... y tu sabrás como lo interpretas. Es tu problema. PARQUET, AVRO
   

PRIMER BYTES ES EL NUMERO DE FILAS QUE HAY EN EL FICHERO.
El SEGUNDO BYTE ES LA POSICIÓN DEL PRIMER CARÁCTER DE LA PRIMERA FILA.
DEL TERCERO AL 20... el nombre del creador del fichero, como texto.

SOLAMENTE QUIEN CREA EL FICHERO ES QUIEN SABE CÓMO INTERPRETARLO.
El problema es que cuando trabajamos con grandes cantidades de datos, NUNCA QUEREMOS TRABAJAR CON FICHEROS DE TEXTO... es una locura absoluta!

DNI: 12345678Z

Pregunta: Al guardarlo com texto en un fichero, cuánto ocupa? 9 caracteres (Si uso UTF-8, ISO8859-1) = 9 bytes
Y si guardo aquello de otra forma? NUMERO  + LETRA
    - El número más grande es 100.000.000... cuántos bytes necesito pa eso? 4bytes
    - Letra: 1 más
    - Total: 5 bytes
Y si guardo aquello de otra forma? NUMERO 
    - El número más grande es 100.000.000... cuántos bytes necesito pa eso? 4bytes
    - Total: 4 bytes

Las BBDD no me permiten solo trabajar con acceso aleatorio... sino también con ficheros binarios.

---

# Para que usan los programas la memoria RAM del computador?

- Ir colocando datos temporales que voy generando...
- Hacer más rápido el acceso a ciertos datos: Cache
- Empaquetar un conjunto de datos, antes de remitirlo: Buffer
- Poner el propio código del programa para que se ejecute.

Nuestra BBDD (Oracle) al fin ay al cabo, no es sino un programa más... que usará RAM:
- Cachear datos que lee de disco para que no tenga que volver a leerlos de disco e ir más rápido.
- Preparar buffers de escritura a disco!
- Guardar temporalmente los datos de columnas calculadas, query...., ordenaciones, etc.

# Cuando me conecte a la BBDD...

Si necesito mandar o consultar unos datos de mi BBDD, abriré una conexión a la BBDD.
Cuántas conexiones habrá abiertas en un momento dado? Tropecientas... tantas como clientes tenga conectados a la BBDD.

Esas operaciones que se vayan realizando, querremos que se realicen de forma SECUENCIAL o PARALELA?
PARALELAMENTE!

Para poder ejecutar tareas paralelas en una computadora, los SO nos ofrecen el concepto de HILOS (Threads).
Un hilo es el portador de mi código a un core de la CPU para su ejecución.
Los hilos van recorriendo el código de un programa, ejecutando sus instrucciones, accediendo a memoria RAM,  EN LA CPU.

Un hilo vive dentro de un PROCESO. Un proceso es una copia en ejecución de un programa, con una determinada región de memoria RAM asignada.

Pregunta... Cuando se abren ... pongamos ... 20 conexiones a una BBDD Oracle, lo que se abren son 20 hilos o 20 procesos a nivel del servidor?
- De toda la vida, lo que se han abierto han sido 20 procesos!
- En las últimas versiones de Oracle, existe la posibilidad (no por defecto) de configurar sesiones de tipo shared, que cuando llegan conexiones, son atendidas por hilos dentro de un proceso.

Lo más normal es que cada conexión a BBDD sea un proceso diferente. Lo cuál... es un tinglao gordo!

Si tengo 20 conexiones de usuario... puedo:
- Abrir 1 proceso con 20 hilos dentro de él.
- Abrir 20 procesos, cada uno con un hilo dentro de él.

La diferencia es importante:
- Arrancar un proceso es algo complejo y costoso desde un punto de vista computacional.
- Arrancar un hilo es algo mucho más sencillo y rápido.
- Los hilos de un proceso comparten la misma memoria RAM -> NO ESTAN AISLADOS!
- Los hilos de diferentes procesos no comparten la misma memoria RAM.

Los Sistemas operativos nos ofrecen formas de comunicar hilos entre si, cuando están ejecutándose en diferentes procesos:
- Pipes
- Sockets
- Memoria compartida (Shared memory)
- Portapapeles

--------------------------------------------------------------------------------------------
SERVIDOR DE ORACLE

    HDD   ... fichero con los datos de facturas
--------------------------------------------------------------------------------------------

            ZONA COMPARTIDA (SGA)
   RAM         CACHE: Partes del fichero de facturas
               CACHE: Planes de ejecución
               CACHE: De compilaciones de queries
               BUFFERS: Partes del fichero de facturas que se están escribiendo
               Data Dictionary: Información sobre la estructura de los datos

                               PGA1               PGA2              PGA3         (Program Global Area)
--------------------------------------------------------------------------------------------

PROCESOS
            ProcesoBBDD       ProcesoFelipe     ProcesoMenchu    ProcesoFederico
            - Hilo1           - Hilo1            - Hilo1          - Hilo1

--------------------------------------------------------------------------------------------

# Forma en la que Oracle gestiona el almacenamiento de los datos

## Tablespace

Un tablespace es un espacio de almacenamiento LÓGICO dentro de la BBDD. 
Es un contenedor de objetos de la BBDD.

    Tablespace1 -> Tabla usuarios, facturas, 2 índices.

Una tabla es una colección lógica de datos. No es algo físico.

Ahora.. al final.. los datos habrá que guardarlos en algún sitio FISICO!

Ese sitio FISICO Es lo que llamamos un DATAFILE. Un DATAFILE es UN FICHERO que se guarda en un disco duro, y que puede contener información de tropecientas tablas, índices...

Un tablespace puede tener asociados varios datafiles.

Dentro de un datafile, los datos se organizan en EXTENTS. Un extent es una colección de bloques contiguos, que se reservan para el almacenamiento de datos de UN objeto concreto de la BBDD (Una tabla, un índice). Un bloque es la unidad mínima de almacenamiento en un datafile.

Cualquier tabla, índice... objeto que requiere persistencia en la BBDD tiene asociado un SEGMENTO. Un segmento es el conjunto de extents que conforman un objeto de la BBDD. Un segmento puede estar formado por uno o varios extents... que estén en uno varios datafiles.


    CONCEPTOS LOGICOS                                       CONCEPTOS FISICOS
      Tablespace                 >>>>>>>>>>>                     Datafile
          V                                                          V
       Tablas, Indices, etc.                                         V
          V       V                                                  V
       Segmento1  Segmento2                                        Extent1 \
        Extent1    Extent2                                          Block1  |
        Extent3                                                     Block2  |   Tabla 1
                                                                    BlockN /
                                                                   Extent2 \
                                                                    Block1  |   Indice 1
                                                                    Block2  |
                                                                    BlockN / 
                                                                   Extent3 \
                                                                    Block1  |   Tabla 1
                                                                    Block2  |
                                                                    BlockN /
                                                                   Extent4 \
                                                                    Block1  |   Tabla 2
                                                                    Block2  |
                                                                    BlockN /
                                                                    ...
                                                                   ExtentN
                                                                    Block1
                                                                    Block2
                                                                    BlockN

Los blocks son la unidad mínima de almacenamiento en un datafile. Es lo mínimo que Oracle va a leer de una tabla o a escribir. Por defecto, en Oracle un block es de 8K. Eso es alterable al momento de crear la BBDD. Después ya NASTI !!!!

Si quiero traerme la edad de Felipe, Oracle va a subir a RAM el block de 8kbs donde entre otros 25 registros, esta Felipe... y en él la edad. Esto es lo que se guarda en cache... en el SGA.

Si hay un cambio, se reeescribe la página entera!

## Cómo es un bloque de datos?

Un bloque (secuencia de 8Kbs) tiene 3 partes:
- Cabecera: Información sobre el bloque. 
            Espacio libre: Espacio que queda libre en el bloque para poder añadir más filas.
            Segmento de datos al que pertenece el bloque...
- Row Directory: Información sobre las filas que hay en el bloque. 
                 Cada fila tiene un puntero a la posición de la fila dentro del bloque.
- Datos: Las filas que hay en el bloque. Cada registro, tiene antes de los datos propios, otra cabecera:
  - Cabecera: 
    - Longitud de la fila (en bytes)
    - Si el registro está activo o no (puede haber sido borrado)
    - Si el registro está repartido en varios bloques (si es muy grande)
   

   -------------------------------------------------------------
   Titulo: Soy un bloque que almacena datos de la tabla Usuarios
           Y tengo un 50% de espacio libre aún.

   Índice de Registros:
    Felipe ->  120
    Menchu ->  140
    Federico -> 158
    Juan > 198

    Datos:
    20bytes,Felipe,30,Madrid
    NO VALE 12bytes,Menchu,33,Madrid
    30bytes,Federico,~,Barcelona
    11bytes,Juan,55
    Menchu,~,Barcelona

   -------------------------------------------------------------
DEPENDIENDO DEL ORDEN DE LAS COLUMNAS, la BBDD ocupe más o menos espacio. (son cambios menores)

PCTFREE:20 Oracle deja al menos libre este porcentaje de espacio en cada bloque por si hay que hacer updates que necesiten tamaño extra. Es decir, cuando hagas INSERTS no llenes el bloque más allá del 80%.


Al final, sobre una tabla...lo que vamos a estar es haciendo operaciones de tipo CRUD!

# Create: Insertar datos en la tabla.

1. Asignar un identificador único al registro (Oracle asigna un id interno a cada registro), con independencia de la PK.
2. Elegir el bloque donde se va a guardar el registro.
3. Se guarda el registro en el bloque elegido.

# Read: Consultar datos de la tabla.

TABLE: RECETAS DE COCINA

   |    id   |   nombre                     | dificultad |  tiempo  | tipo_plato | ingredientes               |
   |---------|------------------------------|------------|----------|------------|----------------------------|
   |    1    |   tortilla de patatas        |  2         |  30      |  unico     | huevo, patata, cebolla     |
   |    2    |   Tortilla de patatas        |  3         |  55      |  unico     | huevo, patata, cebolla     |
   |    3    |   tortilla de camarones      |  1         |  20      |  primero   | huevo, camarones, cebolla  |
   |    4    |   Patatas guisadas con carne |  2         |  60      |  segundo   | patata, carne, cebolla     |
   |    5    |   Escalivada de verduras     |  1         |  45      |  primero   | berenjena, calabacín       |
   |    6    |   Cordero asado con patata panadera|  3   |  120     |  segundo   | cordero, patata, cebolla   |

SELECT nombre FROM Recetas where tipo_plato = "segundo"

A priori, cómo resolvería mi BBDD esa query? FULLSCAN: Leer fila a fila... bloque a bloque... para ir revisando si el tipo_plato es segundo o no en cada registro.

Ésto... tiene sentido? Quizás si.. quizás no...
De que depende? Factores? Volumen de datos en la tabla? Volumen de datos que vaya recuperar con esa query?
No es lo mismo que tenga 10M de datos en la tabla y la query devuelva 2... que tenga una tabla de 2000 registros y la query devuelva 1970 registros

QUE ALTERNATIVA HABRÍA A UN FULLSCAN? Crear un ÍNDICE.

## Qué es un ÍNDICE?

Copia Ordenada de ciertos datos de una tabla, junto con la ubicación de los registros asociados a cada dato en el espacio original.
      (Datos UNICOS ORDENADOS)

INDICE TIPO DE PLATO:
            UBICACION:
primero     3, 5
segundo     1, 4
unico       1, 2

Es igual que el índice de un libro.

Qué aporta el índice? Un índice me permite cambiar el algoritmo que usamos para hacer una búsqueda. En lugar de un fullscan me permite hacer una búsqueda binaria.

La busqueda binaria tiene mucha gracia.
Si tengo 1.000.000 de datos.. y quiero encontrar 1.... Si voy leyendo datos uno detrás de otro (FULLSCAN), podría tener que llegar a hacer 1.000.000 lecturas para encontrar el dato que me interesa.
Si los datos están ordenados, puedo hacer una búsqueda binaria.

1.000.000 datos ordenados. Parto a la mitad:
  500.000
  250.000
  125.000
    62.500
    31.250
    15.625
     7.812
     3.906
     1.953
       976
       488
       244
       122
        61
        30
        15
         7
         3
         1

Sobre 1 millón de datos... en el peor escenario.. en 20 lecturas he encontrado el dato que buscaba.

Si tuvieramos que ordenar los datos de la tabla para poder aplicar una búsqueda binaria, el coste sería mucho mayor que hacer el fullscan. La única opción es tener una copia preordenada de los datos.

---------------------------------- bloque

primero     3, 5,  ,  ,  ,  ,  ,  

segundo     1, 4,  ,  ,  ,  ,  ,
            
unico       1, 2,  ,  ,  ,  ,  ,

----------------------------------

Cuando creamos un índice, se configura el fill factor. lo que me permite determinar es qué cantidad de espacio libre quiero dejar en cada bloque del índice.

Esos huecos, de vez en cuando se van perdiendo... me quedo sin huecos al ir añadiendo datos. ESO VA A PASAR FIJO, 100%, antes o después, pero pasará. Y me tocará reescribir el fichero del índice, dejando nuevos huecos libres. Esa es una operación TIPICA de mnto de bbdd.

Tengo una tabla con 1 Millón de registros... de los cuales la query va a devolver 2.
    Se usa el índice? Sería mejor usar el índice que hacer un fullscan? CLARO!
Y si devuelve 10.000 registros? 
Y si devuelve 20.000 registros? 
Y si devuelve 100.000 registros? 
Tengo una tabla con 1 Millón de registros... de los cuales la query va a devolver 999.999.
    Uso el índice? RIDICULO! Leo todo... y solo descarto 1.

Cuando aplicamos una búsqueda binaria, los humanos por ejemplo al buscar en un diccionario, no abrimos por la mitad...
tendemos a optimizar los primeros 1,2... hasta el 3 corte... ya que más o menos, tenemos en la cabeza cómo se DISTRIBUYEN las palabras en el diccionario. Conocemos la DISTRIBUCION de los datos (esto es lo que nos ofrece la estadística).

    Sabemos que la A está al principio, la Z al final... y que entre medias hay un montón de letras.
    Se que por Ñ empiezan pocas palabras... y que por la S empiezan muchas.

Esto mismo lo hacen las BBDD. Van generando ESTADISTICAS, tanto de los datos, como de los índices, para saber cómo se distribuyen los datos en la tabla y en el índice y hacer estimaciones de:
- Cual es el primer corte que interesa hacer
- Si acaso interesa usar el índice o no, ya que la query va a devolver muchos registros.

Este indice que hemos definido es un BTREE (B-Tree Index). Es un índice que se va reordenando a medida que se van añadiendo datos.
Hay índices muy parecidos a éste, pero que solo crecen en una dirección (FECHAS DE ALTA DE EXPEDIENTES), IDs (PK), etc.

Reverse B-Tree Index: Se invierte el orden de los bytes de los datos que se almacenan en el índice. Esto hace que la distribución de los datos en el índice sea más uniforme, y por tanto, las búsquedas sean más rápidas.

Bitmap Index... Son máscaras de bits (SI | NO). Se crean para una condición concreta... y van como un tiro!



TABLE: RECETAS DE COCINA

   |    id   |   nombre                     | dificultad |  tiempo  | tipo_plato | ingredientes               |
   |---------|------------------------------|------------|----------|------------|----------------------------|
   |    1    |   tortilla de patatas        |  2         |  30      |  unico     | huevo, patata, cebolla     |
   |    2    |   Tortilla de patatas        |  3         |  55      |  unico     | huevo, patata, cebolla     |
   |    2    |   TORTILLA de patatitas      |  3         |  55      |  unico     | huevo, patata, cebolla     |
   |    3    |   tortilla de camarones      |  1         |  20      |  primero   | huevo, camarones, cebolla  |
   |    4    |   Patatas guisadas con carne |  2         |  60      |  segundo   | patata, carne, cebolla     |
   |    5    |   Escalivada de verduras     |  1         |  45      |  primero   | berenjena, calabacín       |
   |    6    |   Cordero asado con patata panadera|  3   |  120     |  segundo   | cordero, patata, cebolla   |

    
    Select * from recetas where nombre like 'tortilla%';
    Select * from recetas where nombre = 'tortilla de patatas';

Si tuviera un índice en el campo nombre, se usaría en esa query? Potencialmente si!

    Select * from recetas where upper(nombre) like upper('tortilla%');

Si tuviera un índice en el campo nombre, se usaría en esa query? no!
Otra cosa... es que hubiera creado un índice no sobre el campo nombre... sino sobre el resultado de la función upper(nombre). En ese caso, si se usaría el índice. FUNCTION INDEX

    Select * from recetas where nombre like '%tortilla%';

Se usaría el índice? En cuanto delante tengo el %... ya no se podría usar el índice al menos para hacer una búsqueda binaria. 
    Quizás podría usarlo pero para hacer un fullscan del índice... ya que potencialmente tendrá menos datos que la tabla original (por eso de que se guardan valores UNICOS) INDEXSCAN

    Select * from recetas where nombre like 'tortilla%' and dificultad = 2;

ESTO Está prohibido! O tengo una tabla de 2000 datos.. y esa query la hago una vez al día... o prohibido!

ORACLE tiene un tipo de índices adhoc para estas situaciones: De hecho tiene un módulo entero dedicado a ello: Oracle Text.
Eso no se paga aparte... es parte de la licencia de Oracle.
Solo que hay que activarlo en el arranque o no.

Ese módulo trabaja con los denominados INDICES INVERTIDOS/INVERSOS.

NOMBRES:
    tortilla de patatas
    tortilla de patatas
    TORTILLA de patatitas
    tortilla de camarones
    Patatas guisadas con carne
    Escalivada de verduras
    Cordero asado con patata panadera

Al trabajar con índices invertidos, lo primero se hace un preprocesado de los datos:
1. Se realiza un tokenization de los datos. Se separan los datos en tokens (palabras). (Espacio, coma, punto, guión, etc.)
   tortilla-de-patatas
    tortilla-de-patatas
    TORTILLA-de-patatitas
    tortilla-de-camarones
    Patatas-guisadas-con-carne
    Escalivada-de-verduras
    Cordero-asado-con-patata-panadera
2. Se eliminan los stop words (palabras que no aportan nada al significado de la frase). En inglés: a, an, the, etc.
    tortilla-*-patatas  
    tortilla-*-patatas
    TORTILLA-*-patatitas
    tortilla-*-camarones
    Patatas-guisadas-*-carne
    Escalivada-*-verduras
    Cordero-asado-*-patata-panadera
3. Normalización (mayúsculas, minúsculas, acentos, etc.)
    tortilla-*-patatas  
    tortilla-*-patatas
    tortilla-*-patatitas
    tortilla-*-camarones
    patatas-guisadas-*-carne
    escalivada-*-verduras
    cordero-asado-*-patata-panadera
4. Stemming (se eliminan los sufijos de las palabras). Se busca la raíz ETIMOLOGICA de la palabra.

    tort-*-patat  
    tort-*-patat
    tort-*-camar  
    patat-guis-*-carn
    escaliv-*-verdur
    corder-asa-*-patat-pan
5. Eso es lo que se indexa:

    tort          1(1), 2(1), 3(1)
    patat         1(3), 2(3), 3(3), 4(1), 5(4) 
    camar         1(4)
    guis          1(5)

Cuando llega una búsqueda, sobre el término de búsqueda se aplica exactamente el mismo proceso de preprocesado. 
    PATATAS -> patat

Todo esto son las búsquedas a textos completo.


Además antes de Oracle 12, se declaraba a nivel de BBDD o de sesión (conexión).
Desde Oracle 12 se declara a nivel de tabla y/o columna

    NOMBRE
    -------------------------------
    tortilla de patatas
    tortilla de patatas
    TORTILLA de patatitas
    tortilla de camarones
    Patatas guisadas con carne
    Escalivada de verduras
    Cordero asado con patata panadera


SELECT NOMBRE FROM RECETAS order by NOMBRE;

    NOMBRE
    -------------------------------
    Cordero asado con patata panadera
    Escalivada de verduras
    Patatas guisadas con carne
    TORTILLA de patatitas
    corderito a la brasa
    tortilla de camarones
    tortilla de patatas
    tortilla de patatas

Y esto mismo puede pasar igual con acentos:

    Iván
    Ivan
    IVÁN
    ivan
    iván

Esos datos, quiero que se consideren iguales desde el punto de vista de una ordenación?
Eso es lo que se llama un COLLATION. Un collation es una forma de ordenar los datos de una tabla, según un criterio determinado.
Si quiero que se ignoren acentos, mayusculas, minúsculas, etc. tengo que crear un collation específico para ello.

OJO... esto aplica exactamente igual a los GROUP BY

En Oracle lo cierto es que no es tan potente como en otros SGBD. En POSTGRESQL, por ejemplo, es una locura. En SQL Server también.

# Update: Modificar datos de la tabla.
1. Se busca el bloque donde está el registro.
2. Dependiendo de si entran los datos modificados en el bloque, se hace un UPDATE o un DELETE + INSERT.

# Delete: Borrar datos de la tabla.
1. Se busca el bloque donde está el registro.
2. Se marca el registro como borrado (no se borra físicamente).


### Qué tal se le da a los ordenadores, ordenar datos?

FATAL !!!!! Es de las peores operaciones (Desde un punto de vista computacional) que se puede pedir a una computadora.
















# Oracle Database

Una BBDD relacional. 


---

NOTA: El almacenamiento hoy en día es barato o caro?

En un entorno de producción el almacenamiento sigue siendo con mucha diferencia lo más caro que hay!

En casa, si quiero comprar un HDD para guardar pelis.. o fotos, me voy al mediamark! me compro un wester blue de 2Tbs. 64€
En un entorno profesional, me voy a discos de otra calidad.. que van desde x3 hasta x20 el precio.

En un entorno de producción , de cada dato al menos voy a hacer cuántas copias? 3 copias <- Redundancia para HA. Si se jode un HDD seguir pudiendo acceder a los datos.
ESTO NO SON BACKUPS. Recuperación ante desastres. Desde 2 semanas atrás a 2 años.

En la empresa, un TB me sale fácil por 8.000€