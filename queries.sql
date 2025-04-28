SELECT 
	COUNT(customer_id) AS customers_count -- подсчёт количества покупателей, файл customers_count
FROM customers;

SELECT -- отчет о десятке лучших продавцов, файл top_10_total_income
    e.first_name || ' ' || e.last_name AS seller,
    COUNT(s.sales_person_id) AS operations, 
    SUM(s.quantity * p.price) AS income
FROM 
    sales AS s
INNER JOIN 
	employees AS e ON e.employee_id = s.sales_person_id
INNER JOIN
    products AS p ON s.product_id = p.product_id
GROUP BY 
    s.sales_person_id, e.first_name, e.last_name
ORDER by
	income desc
limit 10;

WITH total_income AS ( -- продавцы, чья средняя выручка за сделку меньше средней выручки за сделку по всем продавцам, файл lowest_average_income
    SELECT 
        s.sales_person_id,
        e.first_name || ' ' || e.last_name AS seller,
        COUNT(s.sales_person_id) AS operations, 
        SUM(s.quantity * p.price) AS income
    FROM 
        sales AS s
    INNER JOIN 
        employees AS e ON e.employee_id = s.sales_person_id
    INNER JOIN
        products AS p ON s.product_id = p.product_id
    GROUP BY 
        s.sales_person_id, e.first_name, e.last_name
),
average_tab AS (
    SELECT 
        sales_person_id,
        seller,
        ROUND(AVG(income / operations), 0) AS average_income
    FROM 
        total_income
    GROUP BY 
        sales_person_id, seller
)
SELECT 
    seller, 
    average_income
FROM 
    average_tab
WHERE 
    average_income < (
        SELECT 
            SUM(income) / SUM(operations)
        FROM 
            total_income
    )
ORDER BY 
    average_income;

SELECT -- выручка каждого продавца по дням недели, файл day_of_the_week_income
    e.first_name || ' ' || e.last_name AS seller,
    case MOD(EXTRACT(DOW FROM s.sale_date)::int + 6, 7) + 1
        WHEN 7 THEN 'sunday'
        WHEN 1 THEN 'monday'
        WHEN 2 THEN 'tuesday'
        WHEN 3 THEN 'wednesday'
        WHEN 4 THEN 'thursday'
        WHEN 5 THEN 'friday'
        WHEN 6 THEN 'saturday'
    END AS day_of_week,
    ROUND(SUM(p.price * s.quantity), 0) AS income
FROM sales s
JOIN employees e ON e.employee_id = s.sales_person_id
JOIN products p ON p.product_id = s.product_id
GROUP BY e.first_name, e.last_name, MOD(EXTRACT(DOW FROM s.sale_date)::int + 6, 7) + 1
ORDER BY MOD(EXTRACT(DOW FROM s.sale_date)::int + 6, 7) + 1;
