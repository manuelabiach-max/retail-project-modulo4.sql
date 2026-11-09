
-- =====================================================
-- PRE-ENTREGA - ANALISIS AVANZADO
-- Proyecto Retail
-- Objetivo: analizar ventas mensuales, rankings,
-- ventas acumuladas y rendimiento por categoria.
-- =====================================================


-- PRIMERA CTE: VENTAS MENSUALES
-- Calculamos el total vendido por mes y por categoria.
-- El importe se obtiene multiplicando cantidad vendida
-- por el precio del producto.

WITH ventas_mensuales AS (

    SELECT
        EXTRACT(YEAR FROM v.fecha_venta) AS anio,
        EXTRACT(MONTH FROM v.fecha_venta) AS mes,
        DATE_TRUNC('month', v.fecha_venta)::DATE AS periodo,
        c.nombrecategoria,
        SUM(v.cantidadvendida * p.precio) AS total_ventas

    FROM ventas v

    INNER JOIN productos p
        ON v.idproductos = p.idproductos

    INNER JOIN categorias c
        ON p.idcategorias = c.idcategorias

    GROUP BY
        EXTRACT(YEAR FROM v.fecha_venta),
        EXTRACT(MONTH FROM v.fecha_venta),
        DATE_TRUNC('month', v.fecha_venta),
        c.nombrecategoria
),

-- SEGUNDA CTE: METRICAS DE VENTANA
-- Calculamos el ranking de ventas por categoria dentro
-- de cada mes, el acumulado de ventas por categoria
-- y el promedio mensual de cada categoria.

metricas_ventana AS (

    SELECT
        anio,
        mes,
        periodo,
        nombrecategoria,
        total_ventas,

        -- Ranking de categorias mas vendidas por mes
        RANK() OVER (
            PARTITION BY anio, mes
            ORDER BY total_ventas DESC
        ) AS ranking_mensual,

        -- Total acumulado de ventas por categoria
        -- a traves de los meses
        SUM(total_ventas) OVER (
            PARTITION BY nombrecategoria
            ORDER BY periodo
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS ventas_acumuladas,

        -- Promedio de ventas mensuales por categoria
        AVG(total_ventas) OVER (
            PARTITION BY nombrecategoria
        ) AS promedio_categoria

    FROM ventas_mensuales
)

-- CONSULTA FINAL
-- Comparamos las ventas mensuales con el promedio
-- de su categoria para identificar su rendimiento.

SELECT
    anio,
    mes,
    nombrecategoria,
    total_ventas,
    ranking_mensual,
    ventas_acumuladas,
    promedio_categoria,

    CASE
        WHEN total_ventas >= promedio_categoria
            THEN 'Exitoso'
        ELSE 'Bajo el promedio'
    END AS resultado_mensual

FROM metricas_ventana

ORDER BY
    periodo,
    ranking_mensual;
