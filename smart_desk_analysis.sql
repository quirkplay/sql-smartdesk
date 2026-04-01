-- Configurando el contexto.

USE ROLE TRAINING_ROLE;
USE WAREHOUSE RACCOON_WH;
USE DATABASE UCM;
USE SCHEMA SMART_DESK;

SHOW TABLES;

-- Previsualizo para ver el contenido de cada tabla.
SELECT *
FROM UCM.SMART_DESK.SALES;

SELECT *
FROM UCM.SMART_DESK.ACCOUNTS;

SELECT *
FROM UCM.SMART_DESK.FORECASTS;



-- EJERCICIO 1: Análisis de Ventas y Beneficio por Categoría de Producto


-- Análisis detallado de Adabs Entertainment en 2020 por categoría
SELECT
    CATEGORY AS Categoria,
    SUM(MAINTENANCE) AS Mantenimiento,
    SUM(PRODUCT) AS Producto,
    SUM(PARTS) AS Partes,
    SUM(SUPPORT) AS Soporte,
    SUM(TOTAL) AS Total_Ventas,
    SUM(UNITS_SOLD) AS Unidades_Vendidas,
    SUM(PROFIT) AS Beneficio_Total
FROM UCM.SMART_DESK.SALES
WHERE ACCOUNT = 'Adabs Entertainment'
  AND YEAR = 2020
GROUP BY CATEGORY
ORDER BY Beneficio_Total DESC;



-- EJERCICIO 2: Comparación de Rendimiento por País en Regiones APAC y EMEA


-- Rendimiento promedio por país en APAC y EMEA
SELECT
    A.REGION AS Region,
    A.COUNTRY AS Pais,
    ROUND(AVG(S.TOTAL), 2) AS Ingreso_Promedio,
    ROUND(AVG(S.UNITS_SOLD), 2) AS Unidades_Vendidas_Promedio,
    ROUND(AVG(S.PROFIT), 2) AS Beneficio_Promedio
FROM UCM.SMART_DESK.SALES AS S
JOIN UCM.SMART_DESK.ACCOUNTS AS A
    ON S.ACCOUNT = A.ACCOUNT
WHERE A.REGION IN ('APAC', 'EMEA')
GROUP BY A.REGION, A.COUNTRY
ORDER BY A.REGION, Beneficio_Promedio DESC;



-- EJERCICIO 3: Análisis del Beneficio Total por Industria


-- Beneficio por industria para cuentas Commit con forecast >$500K
SELECT
    A.INDUSTRY AS Industria,
    SUM(S.PROFIT) AS Beneficio_Total,
    CASE
        WHEN SUM(S.PROFIT) > 1000000 THEN 'Alto'
        ELSE 'Normal'
    END AS Benefit_Category
FROM UCM.SMART_DESK.SALES AS S
JOIN UCM.SMART_DESK.ACCOUNTS AS A
    ON S.ACCOUNT = A.ACCOUNT
WHERE S.ACCOUNT IN (
    SELECT DISTINCT ACCOUNT
    FROM UCM.SMART_DESK.FORECASTS
    WHERE PREDICTION_CATEGORY = 'Commit'
      AND FORECAST > 500000
)
GROUP BY A.INDUSTRY
ORDER BY Beneficio_Total DESC;



-- EJERCICIO 4: Evolución del Pronóstico y Beneficio Real
-- Análisis de la Trayectoria por Categoría


-- Beneficio 2021 vs Pronóstico 2022 con antigüedad de oportunidades
SELECT
    COALESCE(S.CATEGORY, F.CATEGORY) AS Categoria,
    SUM(S.PROFIT) AS Beneficio,
    SUM(F.FORECAST) AS Prevision_Beneficio,
    MIN(F.OPPORTUNITY_AGE) AS Oportunidad_Mas_Reciente,
    MAX(F.OPPORTUNITY_AGE) AS Oportunidad_Mas_Antigua
FROM (
    SELECT CATEGORY, PROFIT
    FROM UCM.SMART_DESK.SALES
    WHERE YEAR = 2021
) AS S
FULL OUTER JOIN (
    SELECT CATEGORY, FORECAST, OPPORTUNITY_AGE
    FROM UCM.SMART_DESK.FORECASTS
    WHERE YEAR = 2022
) AS F
    ON S.CATEGORY = F.CATEGORY
GROUP BY COALESCE(S.CATEGORY, F.CATEGORY)
ORDER BY Prevision_Beneficio DESC;



-- CASO PRÁCTICO: ANÁLISIS DE VALOR DE CUENTAS Y DISTRIBUCIÓN DE RIESGO



-- ANÁLISIS EXPLORATORIO


-- Consulta Exploratoria 1: Vista general de la cartera 2019-2021
SELECT 
    S.ACCOUNT,
    A.ACCOUNT_EXECUTIVE,
    A.INDUSTRY,
    A.REGION,
    COUNT(DISTINCT S.CATEGORY) AS Num_Categorias,
    SUM(S.PROFIT) AS Beneficio_Total,
    SUM(S.MAINTENANCE + S.PARTS + S.SUPPORT) AS Ingresos_Servicios,
    SUM(S.TOTAL) AS Ingresos_Totales,
    ROUND(SUM(S.MAINTENANCE + S.PARTS + S.SUPPORT) * 100.0 / 
          NULLIF(SUM(S.TOTAL), 0), 2) AS Pct_Servicios
FROM UCM.SMART_DESK.SALES AS S
JOIN UCM.SMART_DESK.ACCOUNTS AS A
    ON S.ACCOUNT = A.ACCOUNT
WHERE S.YEAR IN (2019, 2020, 2021)
GROUP BY S.ACCOUNT, A.ACCOUNT_EXECUTIVE, A.INDUSTRY, A.REGION
ORDER BY Beneficio_Total DESC;


-- Consulta Exploratoria 2: Resumen general de la cartera
SELECT 
    COUNT(DISTINCT S.ACCOUNT) AS Total_Cuentas,
    ROUND(SUM(S.PROFIT), 2) AS Beneficio_Total,
    ROUND(AVG(beneficio_por_cuenta.Beneficio_Cuenta), 2) AS Beneficio_Promedio_Cuenta,
    ROUND(MIN(beneficio_por_cuenta.Beneficio_Cuenta), 2) AS Beneficio_Minimo,
    ROUND(MAX(beneficio_por_cuenta.Beneficio_Cuenta), 2) AS Beneficio_Maximo
FROM UCM.SMART_DESK.SALES AS S
JOIN (
    SELECT ACCOUNT, SUM(PROFIT) AS Beneficio_Cuenta
    FROM UCM.SMART_DESK.SALES
    WHERE YEAR IN (2019, 2020, 2021)
    GROUP BY ACCOUNT
) AS beneficio_por_cuenta ON S.ACCOUNT = beneficio_por_cuenta.ACCOUNT
WHERE S.YEAR IN (2019, 2020, 2021);


-- Consulta Exploratoria 3: Distribución por número de categorías
SELECT 
    Num_Categorias,
    COUNT(*) AS Num_Cuentas,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS Pct_Cuentas
FROM (
    SELECT 
        S.ACCOUNT,
        COUNT(DISTINCT S.CATEGORY) AS Num_Categorias
    FROM UCM.SMART_DESK.SALES AS S
    WHERE S.YEAR IN (2019, 2020, 2021)
    GROUP BY S.ACCOUNT
) AS categorias_por_cuenta
GROUP BY Num_Categorias
ORDER BY Num_Categorias;



-- RESPUESTA A LA PREGUNTA DE NEGOCIO


-- Consulta 1
-- Análisis de concentración: Top 10 cuentas por beneficio


-- Paso 1: Calcular beneficio total por cuenta
WITH Ranking_Cuentas AS (
    SELECT 
        S.ACCOUNT,
        A.ACCOUNT_EXECUTIVE,
        A.INDUSTRY,
        SUM(S.PROFIT) AS Beneficio_Total
    FROM UCM.SMART_DESK.SALES AS S
    JOIN UCM.SMART_DESK.ACCOUNTS AS A ON S.ACCOUNT = A.ACCOUNT
    WHERE S.YEAR IN (2019, 2020, 2021)
    GROUP BY S.ACCOUNT, A.ACCOUNT_EXECUTIVE, A.INDUSTRY
    ORDER BY Beneficio_Total DESC
    LIMIT 10
)
-- Paso 2: Calcular porcentajes de representación
SELECT 
    ACCOUNT,
    ACCOUNT_EXECUTIVE,
    INDUSTRY,
    Beneficio_Total,
    -- Porcentaje dentro del top 10
    ROUND(Beneficio_Total * 100.0 / SUM(Beneficio_Total) OVER (), 2) 
        AS Pct_Del_Total_Top10,
    -- Porcentaje del beneficio total de la empresa
    ROUND(Beneficio_Total * 100.0 / 
        (SELECT SUM(PROFIT) FROM UCM.SMART_DESK.SALES 
         WHERE YEAR IN (2019, 2020, 2021)), 2) 
    AS Pct_Del_Total_General
FROM Ranking_Cuentas;


-- Consulta 2
-- Análisis de concentración: Beneficio por ejecutivo de cuentas

WITH Beneficio_Por_Cuenta AS (
    -- Calcular beneficio total de cada cuenta
    SELECT 
        ACCOUNT,
        SUM(PROFIT) AS Beneficio
    FROM UCM.SMART_DESK.SALES
    WHERE YEAR IN (2019, 2020, 2021)
    GROUP BY ACCOUNT
)
SELECT 
    A.ACCOUNT_EXECUTIVE,
    COUNT(DISTINCT A.ACCOUNT) AS Num_Cuentas,         -- Cuentas que maneja
    SUM(B.Beneficio) AS Beneficio_Total,              -- Beneficio total generado
    -- Porcentaje del beneficio total de la empresa
    ROUND(SUM(B.Beneficio) * 100.0 / 
        (SELECT SUM(Beneficio) FROM Beneficio_Por_Cuenta), 2) 
    AS Pct_Del_Total,
    ROUND(AVG(B.Beneficio), 2) AS Beneficio_Promedio_Cuenta  -- Promedio por cuenta
FROM UCM.SMART_DESK.ACCOUNTS AS A
JOIN Beneficio_Por_Cuenta AS B ON A.ACCOUNT = B.ACCOUNT
GROUP BY A.ACCOUNT_EXECUTIVE
ORDER BY Beneficio_Total DESC;


-- Consulta 3
--Segmentación por Valor Estratégico
WITH Metricas_Cuenta AS (
    -- Calcular métricas de cada cuenta
    SELECT 
        S.ACCOUNT,
        A.ACCOUNT_EXECUTIVE,
        A.INDUSTRY,
        A.REGION,
        COUNT(DISTINCT S.CATEGORY) AS Num_Categorias,  -- Diversificación
        SUM(S.PROFIT) AS Beneficio_Total,
        -- Porcentaje de ingresos por servicios
        ROUND(SUM(S.MAINTENANCE + S.PARTS + S.SUPPORT) * 100.0 / 
            NULLIF(SUM(S.TOTAL), 0), 2) AS Pct_Servicios
    FROM UCM.SMART_DESK.SALES AS S
    JOIN UCM.SMART_DESK.ACCOUNTS AS A ON S.ACCOUNT = A.ACCOUNT
    WHERE S.YEAR IN (2019, 2020, 2021)
    GROUP BY S.ACCOUNT, A.ACCOUNT_EXECUTIVE, A.INDUSTRY, A.REGION
)
-- Clasificar cuentas en tres categorías de valor
SELECT 
    CASE 
        WHEN Pct_Servicios > 30 AND Num_Categorias >= 2 THEN 'Alto Valor'
        WHEN Pct_Servicios > 15 OR Num_Categorias >= 2 THEN 'Valor Medio'
        ELSE 'Valor Bajo'
    END AS Categoria_Valor,
    COUNT(*) AS Num_Cuentas,
    SUM(Beneficio_Total) AS Beneficio_Total,
    ROUND(AVG(Beneficio_Total), 2) AS Beneficio_Promedio,
    ROUND(AVG(Pct_Servicios), 2) AS Pct_Servicios_Promedio
FROM Metricas_Cuenta
GROUP BY Categoria_Valor
ORDER BY Beneficio_Total DESC;
