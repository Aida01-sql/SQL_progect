#список клиентов с непрерывной историей за год, то есть каждый месяц на регулярной основе без пропусков за указанный годовой период, средний чек за период с 01.06.2015 по 01.06.2016, средняя сумма покупок за месяц, количество всех операций по клиенту за период

SELECT 
    c.Id_client,
    AVG(t.Sum_payment) AS avg_check,
    SUM(t.Sum_payment) / 12 AS avg_monthly_sum,
    COUNT(t.Id_check) AS total_operations
FROM customers c
JOIN transactions t ON c.Id_client = t.ID_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
  AND c.Id_client IN (
    SELECT ID_client
    FROM (
        SELECT 
            ID_client,
            COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) AS months_active
        FROM transactions
        WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
        GROUP BY ID_client
    ) AS active_months
    WHERE months_active = 12
  )
GROUP BY c.Id_client;



#средняя сумма чека в месяц;

WITH checks AS (
    SELECT 
        Id_check,
        ID_client,
        date_new,
        SUM(Sum_payment) AS check_amount
    FROM Transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY Id_check, ID_client, date_new
)
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    ROUND (AVG(check_amount),2) AS avg_check_per_month
FROM checks
GROUP BY DATE_FORMAT(date_new, '%Y-%m')
ORDER BY month;


#среднее количество операций в месяц;

WITH checks AS (
    SELECT
        Id_check,
        ID_client,
        date_new,
        SUM(Sum_payment) AS check_amount
    FROM Transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY Id_check, ID_client, date_new
)
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(Id_check) AS total_operations_per_month
FROM checks
GROUP BY DATE_FORMAT(date_new, '%Y-%m')
ORDER BY month;


#среднее количество клиентов, которые совершали операции;

WITH checks AS (
    SELECT
        Id_check,
        ID_client,
        date_new,
        SUM(Sum_payment) AS check_amount
    FROM Transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY Id_check, ID_client, date_new
)
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(DISTINCT ID_client) AS active_clients_count
FROM checks
GROUP BY DATE_FORMAT(date_new, '%Y-%m')
ORDER BY month;


#долю от общего количества операций за год и долю в месяц от общей суммы операций;

WITH checks AS (
    SELECT
        Id_check,
        ID_client,
        date_new,
        SUM(Sum_payment) AS check_amount
    FROM Transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY Id_check, ID_client, date_new
),
monthly_data AS (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        COUNT(Id_check) AS operations_count,
        SUM(check_amount) AS total_amount
    FROM checks
    GROUP BY DATE_FORMAT(date_new, '%Y-%m')
)
SELECT
    month,
    operations_count,
    ROUND(total_amount, 2) AS total_amount,
    ROUND(operations_count / SUM(operations_count) OVER () * 100, 2) AS share_of_total_operations,
    ROUND(total_amount / SUM(total_amount) OVER () * 100, 2) AS share_of_total_amount
FROM monthly_data
ORDER BY month;

#вывести % соотношение M/F/NA в каждом месяце с их долей затрат;

WITH checks AS (
    SELECT
        t.ID_client,
        t.date_new,
        t.Id_check,
        SUM(t.Sum_payment) AS check_amount,
        c.Gender
    FROM Transactions t
    LEFT JOIN Customers c ON t.ID_client = c.Id_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY t.Id_check, t.ID_client, t.date_new, c.Gender
)
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COALESCE(Gender, 'NA') AS gender,
    COUNT(DISTINCT ID_client) AS clients,
    SUM(check_amount) AS spent,
    ROUND(100 * COUNT(DISTINCT ID_client) / SUM(COUNT(DISTINCT ID_client)) OVER (PARTITION BY DATE_FORMAT(date_new, '%Y-%m')), 2) AS client_share,
    ROUND(100 * SUM(check_amount) / SUM(SUM(check_amount)) OVER (PARTITION BY DATE_FORMAT(date_new, '%Y-%m')), 2) AS spend_share
FROM checks
GROUP BY month, gender
ORDER BY month, gender;



#возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации, с параметрами сумма и количество операций за весь период, и поквартально - средние показатели и %

#за весь период 
SELECT 
    CASE 
        WHEN c.Age IS NULL THEN 'Нет данных'
        WHEN c.Age BETWEEN 0 AND 9 THEN '0-9'
        WHEN c.Age BETWEEN 10 AND 19 THEN '10-19'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN c.Age BETWEEN 50 AND 59 THEN '50-59'
        WHEN c.Age BETWEEN 60 AND 69 THEN '60-69'
        WHEN c.Age BETWEEN 70 AND 79 THEN '70-79'
        ELSE '80+'
    END AS age_group,
    SUM(t.Sum_payment) AS total_sum,
    COUNT(t.Id_check) AS total_operations
FROM transactions t
LEFT JOIN customers c ON t.ID_client = c.Id_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY age_group;

#поквартально

SELECT 
    CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) AS quarter,
    CASE 
        WHEN c.Age IS NULL THEN 'Нет данных'
        WHEN c.Age BETWEEN 0 AND 9 THEN '0-9'
        WHEN c.Age BETWEEN 10 AND 19 THEN '10-19'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN c.Age BETWEEN 50 AND 59 THEN '50-59'
        WHEN c.Age BETWEEN 60 AND 69 THEN '60-69'
        WHEN c.Age BETWEEN 70 AND 79 THEN '70-79'
        ELSE '80+'
    END AS age_group,
    SUM(t.Sum_payment) AS total_sum,
    COUNT(t.Id_check) AS total_operations,
    AVG(t.Sum_payment) AS avg_check
FROM transactions t
LEFT JOIN customers c ON t.ID_client = c.Id_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY quarter, age_group
ORDER BY quarter, age_group;