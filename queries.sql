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
