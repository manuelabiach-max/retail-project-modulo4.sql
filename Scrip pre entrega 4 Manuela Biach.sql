


----PRE-ENTREGA MÓDULO 4 - PROYECTO RETAIL
----Objetivo: analizar rentabilidad, clientes y comportamiento de compra.

-- Umbral definido en $20.000 porque permite enfocarse en las
-- categorías que superan un nivel mínimo de ingresos relevante
-- para este conjunto de datos de práctica.

create database retail_project;


-- tabla clientes
create table clientes(
idclientes serial primary key,
nombrecliente varchar(50) not null,
apellidocliente varchar(50) not null,
email varchar(50) not null unique,
fecha_registro date,
edad integer not null check (edad > 10)
)
;

-- tabla productos

create table productos(
idproductos serial primary key,
nombreproducto varchar(50),
precio decimal(50,2) check (precio > 0),
stock integer not null check (stock >0)
)
;
--tabla ventas: dos FOREIGN KEY hacia clientes y productos. Crear esta tabla última (después de las dos anteriores).

create table ventas(
idventas serial primary key,
idclientes integer not null references clientes(idclientes),
idproductos integer not null references productos(idproductos),
cantidadvendida integer check (cantidadvendida > 0))
;

--Subida de informacion a las tablas

begin;
insert into clientes(nombrecliente, apellidocliente, email, fecha_registro, edad)
values
('Juana','Perez','jp@gmail.com','2023-7-15',23),
('Rita','Gonzalez','rig@gmail.com','2020-6-21',29),
('Ricardo','Gutierrez','rickyg@gmail.com','2016-5-2',55),
('Rodrigo','Gomez','rog@gmail.com','2022-2-21',33),
('Santiago','Paz','sp@gmail.com','2024-4-28',31)
;

commit;


begin;
insert into productos(nombreproducto, precio, stock)
values 
('Coca cola ',5000,50),
('Fanta ',4900,60),
('Sprite',4900,70),
('Alfajor',2000,45),
('barra cereal',1900,49)
;
commit;


begin;
INSERT INTO ventas(idclientes, idproductos, cantidadvendida)
VALUES
(1, 1, 2),
(2, 2, 3),
(3, 3, 4),
(4, 4, 6),
(5, 5, 5);

commit;


-- UPDATE precios

SELECT *
FROM productos


UPDATE productos
SET precio = precio * 1.10
WHERE precio > 4000;


--  DELETE

INSERT INTO productos(nombreproducto, precio, stock)
VALUES ('Producto prueba', 1000, 10);

SELECT *
FROM productos
WHERE nombreproducto = 'Producto prueba';

DELETE FROM productos
WHERE nombreproducto = 'Producto prueba';



--Entrega n4

-- Ejercicio 1: Rentabilidad por categoría: unir ventas, productos y categorias; mostrar nombre de categoría,
-- unidades vendidas e ingreso total; filtrar por categorías que superen un umbral de ventas que vos definas.

--Creo tabla categorias

-- TABLA CATEGORIAS

CREATE TABLE categorias (
    idcategorias SERIAL PRIMARY KEY,
    nombrecategoria VARCHAR(20) NOT NULL UNIQUE
        CHECK (nombrecategoria IN ('bebidas', 'snacks'))
);

select * from categorias;
-- CARGAR CATEGORIAS

INSERT INTO categorias (nombrecategoria)
VALUES
    ('bebidas'),
    ('snacks');

-- AGREGAR CLAVE FORANEA A PRODUCTOS

ALTER TABLE productos
ADD COLUMN idcategorias INTEGER;

-- ASIGNAR ID DE CATEGORIA A CADA PRODUCTO

UPDATE productos
SET idcategorias = (
    SELECT idcategorias
    FROM categorias
    WHERE nombrecategoria = 'bebidas'
)
WHERE TRIM(nombreproducto) IN ('Coca cola', 'Fanta', 'Sprite');

-- Asignar la categoria snacks

UPDATE productos
SET idcategorias = (
    SELECT idcategorias
    FROM categorias
    WHERE nombrecategoria = 'snacks'
)
WHERE TRIM(nombreproducto) IN ('Alfajor', 'barra cereal');




-- CREAR LA RELACION ENTRE LAS TABLAS

ALTER TABLE productos
ADD CONSTRAINT fk_productos_categorias
FOREIGN KEY (idcategorias)
REFERENCES categorias(idcategorias);

-- OBLIGAR A QUE CADA PRODUCTO TENGA UNA CATEGORIA

ALTER TABLE productos
ALTER COLUMN idcategorias SET NOT NULL;

-- Resolucion ejercicio 1

SELECT
    c.nombrecategoria,
    SUM(v.cantidadvendida) AS unidades_vendidas,
    SUM(v.cantidadvendida * p.precio) AS ingreso_total
FROM ventas v
INNER JOIN productos p
    ON v.idproductos = p.idproductos
INNER JOIN categorias c
    ON p.idcategorias = c.idcategorias
GROUP BY c.nombrecategoria
HAVING SUM(v.cantidadvendida * p.precio) > 20000
ORDER BY ingreso_total DESC;

-- Ejercicio 2 / entrega 4

-- Clientes que todavía no realizaron compras

SELECT
    c.idclientes,
    c.nombrecliente,
    c.apellidocliente,
    c.email,
    COALESCE(COUNT(v.idventas), 0) AS cantidad_compras
FROM clientes c
LEFT JOIN ventas v
    ON c.idclientes = v.idclientes
GROUP BY
    c.idclientes,
    c.nombrecliente,
    c.apellidocliente,
    c.email
HAVING COUNT(v.idventas) = 0;

--Todos mis clientes realizaron una compra

--Agrego clientes

INSERT INTO clientes
    (nombrecliente, apellidocliente, email, fecha_registro, edad)
VALUES
    ('Laura', 'Martinez', 'laura@gmail.com', '2025-10-01', 28);

select * from clientes;

-- Ejercico 3 / entrega 4

--Se agregan fechas a la tabla ventas

ALTER TABLE ventas
ADD COLUMN fecha_venta DATE;

UPDATE ventas
SET fecha_venta = CASE idventas
    WHEN 1 THEN '2025-01-15'::DATE
    WHEN 2 THEN '2025-02-20'::DATE
    WHEN 3 THEN '2025-03-10'::DATE
    WHEN 4 THEN '2025-04-05'::DATE
    WHEN 5 THEN '2025-05-12'::DATE
END
WHERE idventas BETWEEN 1 AND 5;

-- AGREGAR MAS VENTAS

INSERT INTO ventas
    (idclientes, idproductos, cantidadvendida, fecha_venta)
VALUES
    (1, 1, 3, '2025-06-10'),
    (1, 4, 2, '2025-07-15'),
    (1, 1, 4, '2025-08-20'),
    (2, 2, 2, '2025-06-05'),
    (2, 5, 3, '2025-07-12'),
    (2, 2, 5, '2025-09-18'),
    (3, 3, 2, '2025-06-22'),
    (3, 3, 6, '2025-08-14'),
    (4, 4, 3, '2025-07-08'),
    (5, 5, 4, '2025-06-30');




-- Solucion ej 3 / entrega 4

-- Identificar el producto más comprado por cada cliente
-- y conocer la fecha de su última transacción.

WITH compras_por_producto AS (
    SELECT
        c.idclientes,
        c.nombrecliente,
        c.apellidocliente,
        p.idproductos,
        p.nombreproducto,
        SUM(v.cantidadvendida) AS unidades_compradas
    FROM clientes c
    INNER JOIN ventas v
        ON c.idclientes = v.idclientes
    INNER JOIN productos p
        ON v.idproductos = p.idproductos
    GROUP BY
        c.idclientes,
        c.nombrecliente,
        c.apellidocliente,
        p.idproductos,
        p.nombreproducto
),
ultima_transaccion AS (
    SELECT
        v.idclientes,
        MAX(v.fecha_venta) AS ultima_compra
    FROM ventas v
    GROUP BY v.idclientes
),
ranking AS (
    SELECT
        cp.*,
        ROW_NUMBER() OVER (
            PARTITION BY cp.idclientes
            ORDER BY cp.unidades_compradas DESC, cp.idproductos
        ) AS puesto
    FROM compras_por_producto cp
)
SELECT
    r.nombrecliente,
    r.apellidocliente,
    r.nombreproducto AS producto_mas_comprado,
    r.unidades_compradas,
    u.ultima_compra
FROM ranking r
INNER JOIN ultima_transaccion u
    ON r.idclientes = u.idclientes
WHERE r.puesto = 1
ORDER BY r.nombrecliente;