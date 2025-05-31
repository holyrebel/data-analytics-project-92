SELECT 
	COUNT(customer_id) AS customers_count -- подсчёт количества покупателей, файл customers_count
FROM customers;

SELECT -- отчет о десятке лучших продавцов, файл top_10_total_income
    e.first_name || ' ' || e.last_name AS seller,
    COUNT(s.sales_person_id) AS operations, 
    FLOOR(SUM(s.quantity * p.price)) AS income
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

WITH total_income AS ( -- продавцы, чья средняя выручка за сделку меньше средней выручки за сделку по всем продавцам файл lowest_average_income
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
        FLOOR(AVG(income / operations)) AS average_income
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

SELECT -- выручка каждого продавца по дням недели day_of_the_week_income
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
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales s
JOIN employees e ON e.employee_id = s.sales_person_id
JOIN products p ON p.product_id = s.product_id
GROUP BY e.first_name, e.last_name, MOD(EXTRACT(DOW FROM s.sale_date)::int + 6, 7) + 1
ORDER BY MOD(EXTRACT(DOW FROM s.sale_date)::int + 6, 7) + 1;


WITH age_category_t AS ( -- подсчет клиентов разных возрастных групп
	SELECT 
		CASE
			WHEN age BETWEEN 16 AND 25 THEN '16-25'
			WHEN age BETWEEN 26 AND 40 THEN '26-40'
			WHEN age > 40 THEN '40+'
		END AS age_category,
		customer_id
	FROM customers
	)
SELECT 
	age_category, 
	COUNT(customer_id) AS age_count
FROM 
	age_category_t
GROUP BY 
	age_category
ORDER BY
	age_category;

SELECT --  количество уникальных покупателей и выручка, которую они принесли за каждый месяц
	TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
	COUNT(DISTINCT(s.customer_id)) AS total_customers,
	FLOOR(SUM(s.quantity * p.price)) AS income
FROM 
	sales AS s
INNER JOIN
	products AS p
	ON s.product_id = p.product_id
GROUP BY 
	TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY 
	selling_month;

WITH first_purchases AS ( -- покупатели, первая покупка которых была с акционным товаром, файл special_offer
    SELECT 
        s.customer_id,
        s.sale_date,
        s.sales_person_id,
        s.product_id,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.sale_date) AS rn
    FROM sales s
)
SELECT 
    c.first_name || ' ' || c.last_name AS customer,
    fp.sale_date,
    e.first_name || ' ' || e.last_name AS seller
FROM first_purchases fp
JOIN customers c ON c.customer_id = fp.customer_id
JOIN employees e ON e.employee_id = fp.sales_person_id
JOIN products p ON p.product_id = fp.product_id
WHERE fp.rn = 1
  AND p.price = 0
ORDER BY c.customer_id;
