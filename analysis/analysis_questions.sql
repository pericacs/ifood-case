-- ==========================================================
-- iFood Case Técnico - Data Architect
-- Análises solicitadas no desafio
-- ==========================================================

-- Pergunta 1:
-- Qual a média de valor total (total_amount) recebido em um mês
-- considerando todos os Yellow Taxis da frota?

SELECT
    pickup_year,
    pickup_month,
    ROUND(AVG(total_amount), 2) AS avg_total_amount
FROM workspace.silver.yellow_taxi_trips
GROUP BY
    pickup_year,
    pickup_month
ORDER BY
    pickup_month;


-- Pergunta 2:
-- Qual a média de passageiros (passenger_count) por cada hora do dia
-- que pegaram táxi no mês de maio considerando todos os táxis da frota?

SELECT
    pickup_hour,
    ROUND(AVG(passenger_count), 2) AS avg_passenger_count
FROM workspace.silver.yellow_taxi_trips
WHERE pickup_year = 2023
  AND pickup_month = 5
GROUP BY
    pickup_hour
ORDER BY
    pickup_hour;