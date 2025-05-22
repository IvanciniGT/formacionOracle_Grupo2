
# Sobre la estructura de almacenamiento

## TABLESPACE

Es un entidad lógica de almacenamiento de objetos de la base de datos. 
Cada objeto que quiero persistir debe tener asociado un tablespace.

Al final los datos se deben guardar en un sitio físico:

## DATAFILE

Es un archivo físico en el sistema operativo que contiene datos los objetos del tablespace al que pertenece.

## SEGMENTO

Es un entidad lógica que representa un objeto de la base de datos que requiere espacio para almacenar datos. Básicamente un segmento es una agrupación lógica de extents.

## EXTENT

Es una secuencia de bloques de datos contiguos en un datafile. 

## BLOCK 

Es la unidad mínima de almacenamiento(lectura/escritura) en un datafile.

Dentro de un bloque se guardan por ejemplo, en el caso de una tabla, registros de la tabla.

    LOGICOS      FISICOS
    -----------------------
    TABLESPACE < DATAFILES
       ^            ^
    SEGMENTOS  < EXTENTS < BLOQUES



---

HDD

Fichero1
   |..............................................................................................|
   |bk1 | bk2 | bk3 | bk4 | bk5 | bk6 | bk7 | bk8 | bk9 | bk10| bk11| bk12| bk13| bk14| bk15| bk16|
   |ext1  (USUARIOS)      | ext2  (USUARIOS)      | ext3                  | ext4                  |

Fichero2
   |..............................................................................................|
   |bk1 | bk2 | bk3 | bk4 | bk5 | bk6 | bk7 | bk8 | bk9 | bk10| bk11| bk12| bk13| bk14| bk15| bk16|
   |ext1  (USUARIOS)      | ext2                  | ext3                  | ext4 (USUARIOS)       |

TABLESPACE_1 < Fichero1 + Fichero2

    Dentro del tablespace quiero guardar los datos de la tabla Usuarios <> Segmento_Tabla_Usuarios

    Segmento_Tabla_Usuarios < Fichero1 (ext1, ext2) + Fichero2 (ext1, ext4)

---

Instancia - Copia del programa de Oracle que se ejecuta en el servidor en un momento dado del tiempo
            Dentro de un servidor puedo tener varias instancias de Oracle arrancadas al mismo tiempo.
BBDD      - Conjunto de ficheros con datos + La definición/estructura de esos datos:
            (tablas, vistas, etc)
            
Hasta Oracle 11 incluido, solamente podía tener una BBDD montada en una instancia.
A partir de Oracle 12c, puedo tener varias BBDD montadas en una instancia.
    CDB <- BBDD que sirve de contenedor para otras BBDD
    PDB <- BBDD que puedo enchufar / montar /PLUG en una CDB

Solo tenemos una CDB, pero dentro de ella puedo tener muchas PDBs.
Esas PDBs tienen administración propia.
Podemos duplicarlas (clonarlas), montarlas, desmontarlas, arrancarlas (abrirlas), cerrarlas

---

# MEMORIA RAM

SGA - Memoria que comparte todos los procesos relativos a una instancia de Oracle:
      Procesos internos de oracle, cada conexión que se hace desde un cliente a la BBDD
      Se usa para:
      - Cache de bloques de datos
      - Cache de sentencias SQL
      - Cache del diccionario de datos
      - Buffers de escritura
      - Buffers de los redo logs
^^^ QUEREMOS UN VALOR MUY ALTO AQUÍ!

PGA - Memoria privada de cada proceso de la instancia de Oracle
      Cada proceso tiene su propia PGA, no la comparte con otros procesos.
      Se usa para:
      - Variables locales
      - Cursores abiertos
      - Ordenación
      - JOIN
      - Calculando columnas nuevas de una query
^^^ Hay que poner lo mínimo necesario para que las operaciones que se realicen en la BBDD
    se realicen en un tiempo aceptable.
    Hay que tener en cuenta que si tengo 200 conexiones a la BBDD, cada una tiene su PGA.

---

# Juego de caracteres y el collate

Juego de caracteres es el conjunto de caracteres que puedo almacenar en la BBDD, junto con la forma en la que se almacenan esos caracteres.

   ASCII
   ISO-8859-1
   UTF-8   \ ****** MAS HABITUAL HOY EN DIA
   UTF-16   > Mismo juego de caracteres, pero con diferente forma de almacenarlos
   UTF-32  /

Collate. Tiene que ver con la forma en la que se comparan secuencias de caracteres al hacer distintas operaciones en la BBDD: Sort, Group by

  BINARY          BINARY_CI      BINARY_AI      

  Avión           avion +        avión *
  Camión          avión *        avion *
  avion           Avión *        Avión *
  avión           camion -       camion -
  camion          Camión /       Camión -

Collate Spanish: Sigue reglas de ordenación ESPECIFICAS de español
Por ejemplo: En Español, la ñ va detrás al ordenar de la n

En otros idiomas, la ñ iría después de la z.

---

Operaciones con las que hay que tener mucho cuidado en Oracle:
- ORDER BY: SOLO CUANDO SEA ESTRICTAMENTE NECESARIO (Intentar además que haya un índice asociado a la columna)
- DISTINCT: SOLO CUANDO SEA ESTRICTAMENTE NECESARIO (Intentar además que haya un índice asociado a la columna). Hace un order by de todas las columnas que aparecen en el select
- UNION: Muchas veces lo usamos sin necesidad. Podríamos reemplazarlo por el UNION ALL.
- El UNION, hace un distinct.
- GROUP BY (implica un order by). Normalmente éste si lo usamos solo cuando es necesario.
- LIKE '%loquesea' <--- En estos casos, si se hacen estas queries con cierta frecuencia, es mejor crear un índice de texto.

---

# INSTALACION DE ORACLE 

Hay varias formas de instalar Oracle:
- Entornos de producción
  - Instalación en un servidor dedicado (físico o virtual: VMWare VCenter, Solaris/Zonas)
  - Instalación en un contenedor - Kubernetes
- Entornos de desarrollo/pruebas
  - Instalación en una máquina virtual - VirtualBox, VMWare workstation
  - Instalación en un contenedor - Docker ****
---

Hoy en día la forma estandar de instalar en general CUALQUIER PRODUCTO DE SOFTWARE de tipo empresarial es mediante CONTENEDORES (docker, podman).

# Métodos de instalación de Software empresarial (Esto no aplica al Word, ni al photoshop... a nada que tenga interfaz gráfica)

## Método tradicional

    App1 + App2 + App3          Tiene muchos problemas:
----------------------------      - Imaginad que App1 tiene un bug y pone la CPU al 100%
     Sistema Operativo                   App1 ---> OFFLINE
----------------------------             App2 ---> OFFLINE 
        HIERRO                           App3 ---> OFFLINE
                                  - Puede ser que App1 y App2 tengan dependencias/configuraciones incompatibles
                                  - Potencialmente App1 puede ESPIAR los datos de App2 y App3

## Método basado en VMs

   App1   |  App2 + App3         Pero esto tiene sus problemas también:
----------------------------         - La configuración se hace mucho más compleja
   SO 1   |   SO 2                   - El mnto es más costoso
----------------------------         - Pérdida de recursos
   MV 1   |   MV 2                   - Merma en el rendimiento
----------------------------
     Hipervisor:
     Citrix, VMWare, Hyper-V
     KVM, VirtualBox
----------------------------
     Sistema Operativo      
----------------------------
        HIERRO              
                            
Esto aplica menos a las BBDD... ya que las BBDD son programas tan pesados que suelen ejecutarse en servidores dedicados. Aunque no siempre.
Solaris po ejemplo hace esto mismo de una forma mucho más eficiente: Con el conceptop de las ZONAS.
Una ZONA de solaris es como una máquina virtual, pero que comparte el kernel del sistema operativo con el resto de zonas.

   App1   |  App2 + App3  
----------------------------
   Zona 1 |   Zona 2        
----------------------------
     SO: Solaris
----------------------------
        HIERRO              


## Método basado en Contenedores

   App1   |  App2 + App3  
----------------------------
   C 1    |   C 2        
----------------------------
 Gestor de contenedores:
 docker, podman (redhat),
 crio, containerd
----------------------------
 SO Linux (con kernel Linux)
----------------------------
        HIERRO              

ESTA ES LA FORMA EN LA QUE HOY EN DIA INSTALAMOS SOFTWARE.
Los contenedores se crean desde IMÁGENES DE CONTENEDOR.
Una imagen de contenedor es un fichero comprimido (.tar) que contiene un programa YA INSTALADO DE ANTEMANO POR ALGUIEN (Normalmente el fabricante) que sabe de instalar ese programa 500 veces más que yo. TODAS LAS EMPRESAS DE SOFTWARE HOY EN DIA DISTRIBUYEN SU SOFTWARE MEDIANTE IMÁGENES DE CONTENEDOR.
TODAS SIN EXCEPCIÓN!!!!!

Esas imágenes de contenedor las encontramos en REGISTROS DE REPOSITORIOS DE IMÁGENES DE CONTENEDORES.
El más famoso Docker Hub. Hay muchos otros.
- Microsoft tiene su propio registro de imágenes de contenedor: Microsoft Artifact Registry
- Oracle tiene su propio registro de imágenes de contenedor: Oracle Container Registry
- Red Hat tiene su propio registro de imágenes de contenedor: quay.io

# Cliente de Oracle

- SQL Developer         (Esto es de Oracle = GRATUITO)
- Visual Studio Code    (Es de Microsoft = GRATUITO)
  Básicamente es un bloc de notas ultra-enriquecido (se enriquece con plugins) 
  CUIDADO, es distinto del Visual Studio.
  Visual Studio es un Entorno de Desarrollo de Software. De pago.. y es muy pesado.
     Oracle tiene un plugin para el Visual Studio Code, que se llama SQL Developer.
     Y es la NUEVA GENERACIÓN de cliente de Oracle.

---
# Qué era UNIX?

UNIX ERA UN SISTEMA OPERATIVO, que fabricaba la gente de los lab. Bell de la americana de telecomunicaciones AT&T. Eso dejo de fabricarse a principios de los 2000.
Antiguamente los SO se licenciaban de forma diferente a como se hace hoy en día.
Hoy en día tenemos los EULA (End User License Agreement) que son contratos de licencia de uso.
Windows tiene su EULA, Oracle tiene su EULA, etc.

UNIX se licenciaba a Grandes corporaciones, universidades, y fabricantes de hardware.
Esas organizaciones generaban su propia versión de SO modificando el código fuente de UNIX.

Llegó a haber más de 200 versiones de UNIX.... y empezaron a mostrar incompatibilidades entre ellas.

Se hicieron 2 estandares para controlar cómo debía evolucionar esos sistemas operativos que se basaban en UNIX: SUS (Single UNIX Specification) y POSIX (Portable Operating System Interface).

# Qué es UNIX?

NO ES UN SISTEMA OPERATIVO.
Hoy en día son esos 2 estándares que rigen o dictan una forma de crear sistemas operativos compatibles con esos estándares.

Muchos fabricantes de HW crean sus propios sistemas operativos, pero que son compatibles con esos estándares.

- IBM: AIX (certificado UNIX®)
- HP: HP-UX (certificado UNIX®)
- ORACLE: Solaris (certificado UNIX®)
- Apple: Mac OS X (certificado UNIX®)

Hace 20 años, arrancó el proyecto Linux. Y Linus Torvalds se inspiró en los estándares de UNIX para crear su propio sistema operativo... aunque hoy en día sigue una evolución diferente a la de UNIX.

# Qué es Linux?

NO ES UN SISTEMA OPERATIVO. Es un kernel de sistema Operativo.

Todo sistema operativo tiene un kernel.
Un sistema operativo no es un programa... son cientos o miles de programas.
Una parte de esos programas es el kernel. Esos programas son los que hacen el trabajo sucio (el complejo: controlar el hardware, controla procesos, controla usuarios, gestión de archivos y carpetas).

Hay muchos SO que usan el kernel de Linux. De hecho es el kernel de SO más usado en el mundo. CON MUCHISIMA DIFERENCIA.
- ANDROID: Lleva dentro el kernel de Linux y luego programas adicionales creados por la gente de GOOGLE

Hay un sistema operativo que se usa mucho en computadoras y servidores, que lleva el kernel de Linux. Ese sistema oeprativo se llama GNU/Linux.
- GNU(70%)/Linux(30%): Lleva dentro el kernel de Linux y luego programas adicionales creados por la gente de GNU (Richard Stallman y su gente). MALAMENTE solemos llamar a este sistema operativo Linux, pero no es correcto.

Ese sistema operativo se distribuye habitualmente mediante distribuciones (compendios de software).
Hay organizaciones que encima del software de GNU y de Linux ponen más programas aún.
- Red Hat Enterprise Linux (RHEL): GNU/Linux + programas de Red Hat
- Debian: GNU/Linux + programas de Debian
- Ubuntu: Debian + añadidos de la gente de Canonical
- Fedora: GNU/Linux + añadidos de la gente de Red Hat
- Suse: GNU/Linux + añadidos de la gente de SUSE

Windows tampoco es un sistema operativo... Es una familia de sistemas operativos.
Windows 3, Windows 10, Windows XP, Windows server 2019

Microsoft ha creado en su historia 2 kernels de SO:
- DOS -> MSDOS, Windows 3, Windows 95, Windows 98, Millenium, Windows Vista
- NT  -> Windows NT, Windows 2000, Windows XP, Windows 7, Windows 8, Windows 10, Windows 11, Windows Server 2003/2008/2012/2016/2019

Desde Windows 10, Microsoft ha incluido de serie en windows la capacidad de ejecutar un kernel de Linux dentro de Windows.
Esto no es nada que haya que instalar > Características de Windows > Subsistema de Windows para Linux
WLS


---

# ArchiveLog

## Backups & Recovery

Toda BBDD nos permite hacer algún tipo de backups y recovery en la BBDD.
Los backups me ofrecen recuperación ante desastres.

Dependiendo de la BBDD podrá hacer más o menos operaciones de backup y recovery.
En Oracle, el backup y recovery se hace mediante la herramienta RMAN (Recovery Manager).

Hay 2 formas de hacer backups en cuanto a cómo guardamos/leemos los datos del backup:
- FISICO: Copiar los ficheros de la BBDD (LO MEJOR)
- LOGICO: Extraer los datos de la BBDD (habitualmente los guardo en un archivo de texto con instrucciones de tipo INSERT INTO en mis tablas)

Además, tenemos 3 formas de hacer backups en cuanto a la forma en la que vamos sacando los datos de la BBDD:
- FULL: Copio toda la BBDD. Tardan un huevo!
- INCREMENTAL: Copio solo los datos que han cambiado desde el último backup
- ArchiveLog: Copio solo los datos que han cambiado desde el último backup, pero en tiempo real.

   BBDD     1        2     3 4 5        6        7         8       9 10     11      12
   ---------O---------o-----------o--------X-o----------O---------o--------o-------o-----> Tiempo
            ^         ^           ^          ^            ^
            |     Incremental1    Incr.2     Incr.3       |
        Full Backup 1                                  Full Backup 2

FullBackup lo hago los sábados a las 2 de la mañana
Incremental1 lo hago todos los días a las 2 de la mañana

Imagina que hay un desastre en el momento X.
Quiero recuperar la BBDD (Recovery desde los backups).
1. Recupero el Full Backup 1
2. Aplico todos los Incrementales hasta el momento X
   Aplicar el incremental 1
   Aplicar el incremental 2  
   Pero si hago esto, qué pasa con el dato 6? Lo tengo? NO... lo he perdido.
3. Aplicar el archivelog 1

Claro.. esto siempre me va a pasar. O hago backup incremental después de cada insert, delete y update o siempre pierdo datos desde el último backup incremental.

Necesito una forma de poder hacer backups en TIEMPO REAL... o lo más cercano a tiempo real.
Para eso tengo el ArchiveLog.

Cuando lo activo (que puedo no activarlo, si mi bbdd no requiere de ese tipo de backups),
cualquier operación que se ejecuta sobre la BBDD (SQL) se guarda en un log de transacciones, antes de procesar la operación. Ese log se guarda a fichero.
Lo que pasa es que en ese fichero escribo siempre al final (acceso secuencial) = MUY RAPIDO... al menos mucho más rápido que en ficheros aleatorios donde tengo que calcular posiciones.

Esto penaliza la BBDD (el rendimiento). 


NOTA: Realmente no se escribe a fichero cada operación, sino que se agrupan varias operaciones y se escriben juntas (BUFFER)... pero de ese buffer se hace un flush (ESCRITURA REAL A DISCO) cada muy poco tiempo (incluso inferior a 1 segundo).

---
Estos archivos Oracle los usa por ejemplo en caso que haya un apagón. Un reinicio inesperado del sistema. Lo primero que hace al arrancar es mirar si tiene operaciones en el log de transacciones que no se han aplicado a la BBDD. Si las tiene, las aplica a la BBDD.


---

Una vez que tengamos la Instancia de oracle en funcionamiento y nuestras bbdd podemos conectarnos y empezar a trabajar:

```sql

-- Me permite saber con qué usuario estoy conectado en un momento dado
SELECT USER FROM DUAL;

-- Me permite saber a que BBDD estoy conectado
SHOW con_name;

-- Quizás quiero saber las BBDD (PDBs) que tengo en la CDB - Lo debo ejecutar en el CDB
SELECT name FROM v$pdbs;
-- Esa vista no tiene solo el nombre de las PDBs, sino más información:
SELECT name, open_mode, restricted FROM v$pdbs;
-- De cualquier vista/tabla, puedo hacer un DESC 
DESC v$pdbs;

-- Cambiar a un PDB
ALTER SESSION SET CONTAINER = ORCLPDB1;
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- Los PDBs son bases de datos Pluggables, que puedo enchufar/desenchufar de la CDB
-- Para enchufar un PDB, lo tengo que hacer desde la CDB
ALTER PLUGGABLE DATABASE ORCLPDB1 OPEN;
-- Para desenchufar un PDB, lo tengo que hacer desde la CDB
ALTER PLUGGABLE DATABASE ORCLPDB1 CLOSE;
-- Cierre forzado
ALTER PLUGGABLE DATABASE ORCLPDB1 CLOSE IMMEDIATE;
-- Abra todas las PDBs
ALTER PLUGGABLE DATABASE ALL OPEN;

--- Usuarios que hay en la BBDD (a nivel de pdb, o a nivel de cdb)
SELECT USERNAME FROM dba_users;

-- Cambiar de usuario incluso de a dónde estoy conectado

CONNECT USUARIO/CONTRASEÑA@SID;
CONNECT USUARIO/CONTRASEÑA@//HOST:PUERTO/SID;

-- Cambiar la contraseña de un usuario
ALTER USER USUARIO IDENTIFIED BY NUEVA_CONTRASEÑA;

-- Creación de usuario: Hay que hacerlo en la CDB o en las PDBs a las que quiero que tenga acceso
-- CREATE USER USUARIO IDENTIFIED BY CONTRASEÑA;
CREATE USER curso IDENTIFIED BY "1234";
-- Hay que darle permisos al usuario para que pueda hacer algo en la BBDD.. incluso para que pueda conectarse

-- Que se pueda conectar a la BBDD
GRANT CREATE SESSION TO curso;
-- Que pueda crear tablas
GRANT CREATE TABLE TO curso;
-- Y con el resto de objetos de bbdd igual
GRANT CREATE VIEW TO curso;
GRANT CREATE PROCEDURE TO curso;
GRANT CREATE TRIGGER TO curso;
GRANT CREATE SEQUENCE TO curso;

-- Hay un permiso que lo solemos asignar a usuarios que son usados por una APP.
-- Permite crear cualquier objeto
GRANT CREATE RESOURCE TO curso;

-- Asignar al usuario: 
-- Un tablespace por defecto para que guarde los objetos que cree
ALTER USER curso DEFAULT TABLESPACE USERS;
-- Limitar el uso que pueden hacer del tablespace (QUOTA)
ALTER USER curso QUOTA 10G ON USERS;
-- O que pueda usar lo que necesite
ALTER USER curso QUOTA UNLIMITED ON USERS;
-- Para eliminar un usuario
DROP USER curso CASCADE;

-- Creación de tablespace
CREATE TABLESPACE nombre_tablespace
DATAFILE 'nombre_fichero.dbf' SIZE 10G AUTOEXTEND ON NEXT 1G MAXSIZE 50G;

-- Añadir datafile a un tablespace
ALTER TABLESPACE nombre_tablespace
ADD DATAFILE 'nombre_fichero2.dbf' SIZE 10G AUTOEXTEND ON NEXT 1G MAXSIZE UNLIMITED;
```

NOTA: Oracle internamente maneja muchas tablas que contienen información sobre la BBDD, los usuarios, los objetos, etc.
Me permite el acceso a algunas de esas tablas... pero no a todas.
Lo que si me ofrece son muchas VISTAS (VIEWS) que trabajan o exponen la información de esas tablas.
Todas las vistas de sistema que me ofrece Oracle empiezan por V$.

---
Tablespaces y datafiles

Determinar la distribución idonea de los datafiles en los tablespaces y de tablespaces no es una tarea sencilla.
Lo primero que necesitamos es tener claro las capacidades de almacenamiento de los discos que tenemos en el servidor.
- Si tengo 1 disco
- Si tengo 2 discos
- Si tengo 3 discos
- Tipos de discos (si son nvme, ssd, hdd)

## SEQUENCE en Oracle

Es un objeto que se encarga de generar secuencias de número UNICOS.
Lo usamos habitualmente para generar claves primarias de tablas.

```sql

CREATE SEQUENCE nombre_sequence
START WITH 1
INCREMENT BY 1;

--- Lo usamos en inserts:

CREATE TABLE USUARIOS (
    id NUMBER(10),
    nombre VARCHAR2(50),
    apellidos VARCHAR2(50)
);

CREATE TABLE USUARIOS_SETTINGS (
    user_id NUMBER(10),
    setting VARCHAR2(50),
    value VARCHAR2(50)
);

ALTER TABLE USUARIOS ADD CONSTRAINT USUARIOS_PK PRIMARY KEY (id);

INSERT INTO USUARIOS (id, nombre, apellidos) VALUES (nombre_sequence.NEXTVAL, 'Juan', 'Pérez');
-- Si en la misma sesión necesito conocer el id que se ha generado para este insert, ya que lo necesito para otro insert

INSERT INTO USUARIOS_SETTINGS (user_id, setting, value) VALUES (nombre_sequence.CURRVAL, 'idioma', 'es');
INSERT INTO USUARIOS_SETTINGS (user_id, setting, value) VALUES (nombre_sequence.CURRVAL, 'pais', 'ES');

-- Otra forma de hacer esto sería automatizarlo mediante un TRIGGER
CREATE OR REPLACE TRIGGER USUARIOS_BEFORE_INSERT
BEFORE INSERT ON USUARIOS
FOR EACH ROW
BEGIN
    :NEW.id := nombre_sequence.NEXTVAL;
END;

INSERT INTO USUARIOS (nombre, apellidos) VALUES ('Juan', 'Pérez');
```
