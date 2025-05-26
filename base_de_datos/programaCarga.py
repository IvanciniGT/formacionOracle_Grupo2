
import cx_Oracle # Importar el instant client de Oracle
from faker import Faker # Librería que genera datos de prueba en BBDD
import datetime

# Configuración de la conexión
db_config = {
    'user': 'curso',
    'password': '1234',
    'dsn': '3.249.161.89:1521/ORCLPDB1',
}

# Constantes
NUM_USERS = 100 * 1000
NUM_DIRECTORS = 10 * 1000
NUM_TEMATICS = 100
NUM_MOVIES = 30 * 1000
NUM_VISUALIZATIONS = 1000*1000

# Conexión
try:
    conn = cx_Oracle.connect(**db_config)
    cur = conn.cursor()
    print("Conexión a la base de datos exitosa")
except Exception as e:
    print(f"Error al conectar: {e}")
    exit()

fake = Faker() # Arrancar la libreria de datos de prueba

# Función de ejecución
def execute_query(query, params):
    try:
        cur.execute(query, params)
    except Exception as e:
        print(f"Error al ejecutar: {e}")
        conn.rollback()
        return False
    return True

# Usuarios
def insert_users(num_users):
    emails = set()
    for _ in range(num_users):
        email = fake.email()
        while email in emails:  # Si se ha usado ya ese email, que genere otro
            email = fake.email()
        emails.add(email)
        nombre = fake.name()
        execute_query("INSERT INTO usuarios (email, nombre) VALUES (:1, :2)", [email, nombre])
    conn.commit()
    print(f"{num_users} usuarios insertados.")

# Directores
def insert_directors(num_directors):
    nombres = set()
    for _ in range(num_directors):
        nombre = fake.name()
        while nombre in nombres:
            nombre = fake.name()
        nombres.add(nombre)
        if not execute_query("INSERT INTO directores (nombre) VALUES (:1)", [nombre]):
            break
    conn.commit()
    print(f"{num_directors} directores insertados.")

# Temáticas
def insert_tematics(num_tematics):
    nombres = set()
    for _ in range(num_tematics):
        nombre = fake.word()
        while nombre in nombres:
            nombre = fake.word()
        nombres.add(nombre)
        if not execute_query("INSERT INTO tematicas (nombre) VALUES (:1)", [nombre]):
            break
    conn.commit()
    print(f"{num_tematics} temáticas insertadas.")

# Películas
def insert_movies(num_movies):
    for _ in range(num_movies):
        tematica = fake.random_int(min=1, max=NUM_TEMATICS)
        director = fake.random_int(min=1, max=NUM_DIRECTORS)
        duracion = fake.random_int(min=60, max=180)
        fecha = fake.date_between(start_date='-30y', end_date='today')
        edad_minima = fake.random_int(min=0, max=18)
        nombre = fake.sentence(nb_words=3)
        if not execute_query(
            "INSERT INTO peliculas (tematica, director, duracion, fecha, edad_minima, nombre) VALUES (:1, :2, :3, :4, :5, :6)",
            [tematica, director, duracion, fecha, edad_minima, nombre]
        ):
            break
    conn.commit()
    print(f"{num_movies} películas insertadas.")

# Visualizaciones
def insert_visualizations(num_visualizations):
    for _ in range(num_visualizations):
        usuario = fake.random_int(min=1, max=NUM_USERS)
        pelicula = fake.random_int(min=1, max=NUM_MOVIES)
        fecha = fake.date_time_this_year()
        if not execute_query(
            "INSERT INTO visualizaciones (usuario, pelicula, fecha) VALUES (:1, :2, :3)",
            [usuario, pelicula, fecha]
        ):
            break
    conn.commit()
    print(f"{num_visualizations} visualizaciones insertadas.")

# Ejecución
try:
    #insert_users(NUM_USERS)
    #insert_directors(NUM_DIRECTORS)
    #insert_tematics(NUM_TEMATICS)
    #insert_movies(NUM_MOVIES)
    insert_visualizations(NUM_VISUALIZATIONS)
finally:
    cur.close()
    conn.close()
