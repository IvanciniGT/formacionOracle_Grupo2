
SELECT USER FROM DUAL;

CREATE TABLE palabras_ivan (
    palabra VARCHAR2(50) NOT NULL
);

INSERT INTO palabras_ivan (palabra) VALUES ('Camión');
INSERT INTO palabras_ivan (palabra) VALUES ('Camion');
INSERT INTO palabras_ivan (palabra) VALUES ('camion');
INSERT INTO palabras_ivan (palabra) VALUES ('camión');
INSERT INTO palabras_ivan (palabra) VALUES ('CAMION');
INSERT INTO palabras_ivan (palabra) VALUES ('CAMIÓN');
INSERT INTO palabras_ivan (palabra) VALUES ('avion');
INSERT INTO palabras_ivan (palabra) VALUES ('Avion');
INSERT INTO palabras_ivan (palabra) VALUES ('Avión');
INSERT INTO palabras_ivan (palabra) VALUES ('AVION');
INSERT INTO palabras_ivan (palabra) VALUES ('Avión');
INSERT INTO palabras_ivan (palabra) VALUES ('avión');

commit;

SELECT * FROM palabras_ivan ORDER BY palabra COLLATE XSpanish_AI;
-- Con el Spanish la Ñ la pone bien después de la N
-- BINARY_AI;