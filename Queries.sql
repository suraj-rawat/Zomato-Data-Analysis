-- 1. Customer Insights: Top customers by order frequency and total spend
WITH CustomerSpend AS (
    SELECT 
        o.user_id, 
        COUNT(o.sales_qty) AS total_orders, 
        SUM(o.sales_amount) AS total_spent
    FROM orders o
    GROUP BY o.user_id
)
SELECT 
    cs.user_id, 
    u.u_name AS customer_name, 
    cs.total_orders, 
    cs.total_spent
FROM CustomerSpend cs
JOIN users u ON cs.user_id = u.user_id
ORDER BY cs.total_spent DESC;

-- 2. Restaurant Performance: Compare restaurants by sales and ratings
CREATE VIEW RestaurantPerformance AS
SELECT 
    r.r_id AS restaurant_id, 
    r.r_name AS restaurant_name, 
    r.rating, 
    COUNT(o.sales_qty) AS total_orders, 
    SUM(o.sales_amount) AS total_sales
FROM orders o
JOIN restaurant r ON o.r_id = r.r_id
GROUP BY r.r_id, r.r_name, r.rating;

SELECT * FROM RestaurantPerformance ORDER BY total_sales DESC;

-- 3. Food Trends: Popular food items by cuisine and sales volume
WITH FoodTrends AS (
    SELECT 
        f.item AS food_item, 
        m.cuisine, 
        SUM(o.sales_qty) AS total_quantity
    FROM orders o
    JOIN menu m ON o.r_id = m.r_id
    JOIN food f ON m.f_id = f.f_id
    GROUP BY f.item, m.cuisine
)
SELECT * FROM FoodTrends ORDER BY total_quantity DESC;

-- 4. User Retention: Identify repeat customers
WITH UserOrders AS (
    SELECT 
        user_id, 
        COUNT(order_date) AS total_orders, 
        MAX(order_date) - MIN(order_date) AS active_days
    FROM orders
    GROUP BY user_id
)
SELECT 
    uo.user_id, 
    u.u_name AS customer_name, 
    uo.total_orders, 
    uo.active_days
FROM UserOrders uo
JOIN users u ON uo.user_id = u.user_id
WHERE uo.total_orders > 1
ORDER BY uo.active_days DESC;

-- 5. Geographic Insights: Top-performing cities
SELECT 
    r.city, 
    COUNT(o.sales_qty) AS total_orders, 
    SUM(o.sales_amount) AS total_sales
FROM orders o
JOIN restaurant r ON o.r_id = r.r_id
GROUP BY r.city
ORDER BY total_sales DESC;

-- 6. Rank restaurants by performance within each city
SELECT 
    r.city, 
    r.r_name AS restaurant_name, 
    SUM(o.sales_amount) AS total_sales,
    RANK() OVER (PARTITION BY r.city ORDER BY SUM(o.sales_amount) DESC) AS city_rank
FROM orders o
JOIN restaurant r ON o.r_id = r.r_id
GROUP BY r.city, r.r_name
ORDER BY r.city, city_rank;

-- 7. Identify top cuisines by city
WITH CityCuisine AS (
    SELECT 
        r.city, 
        m.cuisine, 
        SUM(o.sales_amount) AS total_sales
    FROM orders o
    JOIN menu m ON o.r_id = m.r_id
    JOIN restaurant r ON r.r_id = o.r_id
    GROUP BY r.city, m.cuisine
),
RankedCuisines AS (
    SELECT 
        city, 
        cuisine, 
        total_sales,
        RANK() OVER (PARTITION BY city ORDER BY total_sales DESC) AS cuisine_rank
    FROM CityCuisine
)
SELECT 
    city, 
    cuisine, 
    total_sales
FROM RankedCuisines
WHERE cuisine_rank = 1;

-- 8. Monthly sales trends by city and cuisine
WITH MonthlySales AS (
    SELECT 
        r.city, 
        m.cuisine, 
        o.order_date AS sales_month, 
        SUM(o.sales_amount) AS total_sales
    FROM orders o
    JOIN menu m ON o.r_id = m.r_id
    JOIN restaurant r ON o.r_id = r.r_id
    GROUP BY r.city, m.cuisine, o.order_date
),
TrendAnalysis AS (
    SELECT 
        city, 
        cuisine, 
        sales_month, 
        total_sales,
        LAG(total_sales) OVER (PARTITION BY city, cuisine ORDER BY sales_month) AS previous_month_sales
    FROM MonthlySales
)
SELECT 
    city, 
    cuisine, 
    sales_month, 
    total_sales, 
    previous_month_sales, 
    (total_sales - previous_month_sales) AS sales_growth
FROM TrendAnalysis
ORDER BY city, cuisine, sales_month;

-- 9. Average order value and quantity per user category
WITH UserCategories AS (
    SELECT 
        u.user_id, 
        u.u_name AS user_name, 
        CASE
            WHEN SUM(o.sales_amount) > 10000 THEN 'High Spender'
            WHEN SUM(o.sales_amount) BETWEEN 5000 AND 10000 THEN 'Medium Spender'
            ELSE 'Low Spender'
        END AS spending_category,
        SUM(o.sales_amount) AS total_spent,
        COUNT(o.order_date) AS total_orders
    FROM orders o
    JOIN users u ON o.user_id = u.user_id
    GROUP BY u.user_id, u.u_name
)
SELECT 
    spending_category, 
    AVG(total_spent) AS avg_spent, 
    AVG(total_orders) AS avg_orders
FROM UserCategories
GROUP BY spending_category;

-- 10. Sales trends by cuisine and order day over months
WITH SalesTrend AS (
    SELECT 
        m.cuisine, 
        o.order_date AS order_day, 
        SUM(o.sales_amount) AS daily_sales
    FROM orders o
    JOIN menu m ON o.r_id = m.r_id
    GROUP BY m.cuisine, o.order_date
)
SELECT 
    cuisine, 
    order_day, 
    daily_sales,
    AVG(daily_sales) OVER (PARTITION BY cuisine ORDER BY order_day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_avg
FROM SalesTrend
ORDER BY cuisine, order_day;

-- 11. Tracking customer retention by first purchase month
WITH FirstPurchase AS (
    SELECT 
        user_id, 
        DATE_TRUNC('month', MIN(order_date)) AS first_purchase_month
    FROM orders
    GROUP BY user_id
),
CohortSales AS (
    SELECT 
        fp.first_purchase_month, 
        DATE_TRUNC('month', o.order_date) AS sales_month, 
        COUNT(DISTINCT o.user_id) AS active_customers
    FROM orders o
    JOIN FirstPurchase fp ON o.user_id = fp.user_id
    GROUP BY fp.first_purchase_month, DATE_TRUNC('month', o.order_date)
)
SELECT 
    first_purchase_month, 
    sales_month, 
    active_customers
FROM CohortSales
ORDER BY first_purchase_month, sales_month;



-- 12. Advanced Ranking: Identify top-selling items per cuisine category
WITH ItemSales AS (
    SELECT 
        m.cuisine, 
        f.item, 
        SUM(o.sales_qty) AS total_sold
    FROM orders o
    JOIN menu m ON o.r_id = m.r_id
    JOIN food f ON m.f_id = f.f_id
    GROUP BY m.cuisine, f.item
),
RankedItems AS (
    SELECT 
        cuisine, 
        item, 
        total_sold,
        RANK() OVER (PARTITION BY cuisine ORDER BY total_sold DESC) AS item_rank
    FROM ItemSales
)
SELECT 
    cuisine, 
    item, 
    total_sold
FROM RankedItems
WHERE item_rank = 1;

-- 13. Sales trends by day of the week
SELECT 
    r.city,
    CASE 
        WHEN EXTRACT(DOW FROM o.order_date) = 1 THEN 'Monday'
        WHEN EXTRACT(DOW FROM o.order_date) = 2 THEN 'Tuesday'
        WHEN EXTRACT(DOW FROM o.order_date) = 3 THEN 'Wednesday'
        WHEN EXTRACT(DOW FROM o.order_date) = 4 THEN 'Thursday'
        WHEN EXTRACT(DOW FROM o.order_date) = 5 THEN 'Friday'
        WHEN EXTRACT(DOW FROM o.order_date) = 6 THEN 'Saturday'
        ELSE 'Sunday'
    END AS day_of_week,
    SUM(o.sales_amount) AS total_sales
FROM orders o
JOIN restaurant r ON o.r_id = r.r_id
GROUP BY r.city, EXTRACT(DOW FROM o.order_date)
ORDER BY r.city, total_sales DESC;

-- 14. Customer Segmentation: Spending categories across multiple orders
WITH CustomerSpending AS (
    SELECT 
        u.user_id,
        u.u_name AS customer_name,
        SUM(o.sales_amount) AS total_spent
    FROM orders o
    JOIN users u ON o.user_id = u.user_id
    GROUP BY u.user_id, u.u_name
)
SELECT 
    user_id, 
    customer_name, 
    total_spent,
    CASE
        WHEN total_spent > 10000 THEN 'Premium'
        WHEN total_spent BETWEEN 5000 AND 10000 THEN 'Gold'
        ELSE 'Standard'
    END AS customer_segment
FROM CustomerSpending
ORDER BY total_spent DESC;

-- 15. Identify best restaurant-food combinations
SELECT 
    r.r_name AS restaurant_name,
    f.item AS food_item,
    SUM(o.sales_qty) AS total_orders,
    AVG(o.sales_amount) AS avg_order_value
FROM orders o
JOIN menu m ON o.r_id = m.r_id
JOIN food f ON m.f_id = f.f_id
JOIN restaurant r ON m.r_id = r.r_id
GROUP BY r.r_name, f.item
ORDER BY total_orders DESC;

-- 16. Time-Series Analysis: Yearly growth in restaurant performance
WITH YearlyPerformance AS (
    SELECT 
        r.r_id AS restaurant_id,
        r.r_name AS restaurant_name,
        EXTRACT(YEAR FROM o.order_date) AS order_year,
        SUM(o.sales_amount) AS total_sales
    FROM orders o
    JOIN restaurant r ON o.r_id = r.r_id
    GROUP BY r.r_id, r.r_name, EXTRACT(YEAR FROM o.order_date)
),
GrowthAnalysis AS (
    SELECT 
        restaurant_id,
        restaurant_name,
        order_year,
        total_sales,
        LAG(total_sales) OVER (PARTITION BY restaurant_id ORDER BY order_year) AS prev_year_sales
    FROM YearlyPerformance
)
SELECT 
    restaurant_name,
    order_year,
    total_sales,
    prev_year_sales,
    (total_sales - prev_year_sales) / NULLIF(prev_year_sales, 0) * 100 AS growth_percentage
FROM GrowthAnalysis
ORDER BY order_year, growth_percentage DESC;


-- 17. Churn Prediction: Identify customers at risk of churn
WITH LastOrder AS (
    SELECT 
        user_id,
        MAX(order_date) AS last_order_date
    FROM orders
    GROUP BY user_id
),
ChurnRisk AS (
    SELECT 
        u.user_id, 
        u.u_name AS customer_name,
        (CURRENT_DATE - lo.last_order_date) AS days_since_last_order
    FROM users u
    JOIN LastOrder lo ON u.user_id = lo.user_id
)
SELECT 
    user_id,
    customer_name,
    days_since_last_order,
    CASE
        WHEN days_since_last_order > 180 THEN 'High Risk'
        WHEN days_since_last_order BETWEEN 90 AND 180 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS churn_risk
FROM ChurnRisk
ORDER BY days_since_last_order DESC;
