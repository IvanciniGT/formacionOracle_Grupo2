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