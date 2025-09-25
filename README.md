# 🍽️ Zomato Database Management System — SQL Project

## 📌 Project Overview
This project demonstrates the implementation of a **Zomato-like Food Delivery System** using **SQL**. It includes:
- Database setup with relational tables
- CRUD operations
- Advanced SQL queries for analysis
- Reporting and insights  

**Database:** `zomato`  
**Level:** Intermediate → Advanced  

---

## 🎯 Objectives
- Create and manage database schema for customers, restaurants, riders, orders, and deliveries  
- Perform CRUD operations and enforce relationships with primary/foreign keys  
- Write analytical SQL queries to answer real-world business questions  
- Showcase SQL skills for **data analysis, joins, window functions, ranking, and aggregation**  

---

## 🏗️ Database Setup

```sql
-- Create Database
CREATE DATABASE zomato;
USE zomato;

-- Create Customers Table
CREATE TABLE customers(
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(25),
    reg_date DATE
);

-- Create Restaurants Table
CREATE TABLE restaurants(
    restaurant_id INT PRIMARY KEY,
    restaurant_name VARCHAR(55),
    city VARCHAR(15),
    opening_hours VARCHAR(55)
);

-- Create Riders Table
CREATE TABLE riders(
    rider_id INT PRIMARY KEY,
    rider_name VARCHAR(55),
    signup_date DATE
);

-- Create Orders Table
CREATE TABLE orders(
    order_id INT PRIMARY KEY,
    customer_id INT,
    restaurant_id INT,
    order_item VARCHAR(55),
    order_date DATE,
    order_time TIME,
    order_status VARCHAR(55),
    total_amount FLOAT,
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_restaurants FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
);

-- Create Deliveries Table
CREATE TABLE deliveries(
    delivery_id INT PRIMARY KEY,
    order_id INT,
    delivery_status VARCHAR(35),
    delivery_time TIME,
    rider_id INT,
    CONSTRAINT fk_orders FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT ref_riders FOREIGN KEY (rider_id) REFERENCES riders(rider_id)
);
```

---

## 📊 Analytical SQL Queries

### 1️⃣ Top 2 Most Frequently Ordered Dishes by a Customer
```sql
SELECT c1.customer_name, order_item, COUNT(order_id),
       DENSE_RANK() OVER(ORDER BY COUNT(order_id) DESC) AS r1
FROM customers AS c1
JOIN orders AS o1 ON c1.customer_id=o1.customer_id
WHERE c1.customer_name='Ashley Sanders' 
  AND order_date>=DATE_SUB(CURRENT_DATE(), INTERVAL 2 YEAR)
GROUP BY c1.customer_name, order_item;
```

### 2️⃣ Popular Time Slots (2-hour intervals)
```sql
SELECT HOUR(order_time),
       COUNT(order_id) OVER(PARTITION BY FLOOR(HOUR(order_time)/2)) AS k1
FROM orders
ORDER BY k1 DESC;
```

### 3️⃣ Average Order Value per Customer (>6 Orders)
```sql
SELECT c1.customer_name, COUNT(order_id) AS c1, AVG(total_amount) AS avg_order_value
FROM customers AS c1
JOIN orders AS o1 ON c1.customer_id=o1.customer_id
GROUP BY 1
HAVING c1>6;
```

### 4️⃣ High-Value Customers (>1000 spent)
```sql
SELECT c1.customer_name, SUM(total_amount) AS sum_order_value
FROM customers AS c1
JOIN orders AS o1 ON c1.customer_id=o1.customer_id
GROUP BY 1
HAVING sum_order_value>=1000;
```

### 5️⃣ Orders Without Delivery
```sql
SELECT *
FROM orders AS o1
LEFT JOIN deliveries AS d1 ON o1.order_id=d1.order_id
WHERE delivery_status='Cancelled';
```

### 6️⃣ Restaurant Revenue Ranking (by City, Last Year)
```sql
SELECT city, restaurant_name, SUM(total_amount) AS total_revenue,
       DENSE_RANK() OVER(PARTITION BY city ORDER BY SUM(total_amount) DESC)
FROM restaurants AS r1
LEFT JOIN orders AS o1 ON r1.restaurant_id=o1.restaurant_id
WHERE order_date>=DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)
GROUP BY city, restaurant_name;
```

### 7️⃣ Most Popular Dishes by City
```sql
SELECT city, order_item, COUNT(order_id) AS total_order,
       DENSE_RANK() OVER(PARTITION BY city ORDER BY COUNT(order_id) DESC)
FROM restaurants AS r1
LEFT JOIN orders AS o1 ON r1.restaurant_id=o1.restaurant_id
WHERE order_date>=DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)
GROUP BY 1,2;
```

### 8️⃣ Customer Churn (Active in 2023 but Not in 2024)
```sql
SELECT DISTINCT(c1.customer_id)
FROM customers AS c1
LEFT JOIN orders AS o1 ON c1.customer_id=o1.customer_id
WHERE EXTRACT(YEAR FROM order_date)=2023 
  AND c1.customer_id NOT IN (
    SELECT DISTINCT(c1.customer_id)
    FROM customers AS c1
    LEFT JOIN orders AS o1 ON c1.customer_id=o1.customer_id
    WHERE EXTRACT(YEAR FROM order_date)=2024
);
```

### 9️⃣ Cancellation Rate Comparison (Yearly)
```sql
SELECT t1.restaurant_name, current_year_cancellation, last_year_cancellation,
       (t1.current_year_cancellation - t2.last_year_cancellation) AS difference_percent
FROM (
    SELECT restaurant_name,
           ((COUNT(CASE WHEN order_status='Cancelled' THEN 1 END)/COUNT(order_id))*100) AS current_year_cancellation
    FROM restaurants AS r1
    LEFT JOIN orders  AS o1 ON r1.restaurant_id=o1.restaurant_id
    WHERE EXTRACT(YEAR FROM order_date)=YEAR(CURDATE())
    GROUP BY restaurant_name
) AS t1
JOIN (
    SELECT restaurant_name,
           ((COUNT(CASE WHEN order_status='Cancelled' THEN 1 END)/COUNT(order_id))*100) AS last_year_cancellation
    FROM restaurants AS r1
    LEFT JOIN orders  AS o1 ON r1.restaurant_id=o1.restaurant_id
    WHERE EXTRACT(YEAR FROM order_date)=YEAR(CURDATE())-1
    GROUP BY restaurant_name
) AS t2
ON t1.restaurant_name=t2.restaurant_name;
```

### 🔟 Rider Average Delivery Time
```sql
SELECT rider_name, AVG(TIMESTAMPDIFF(MINUTE, delivery_time, order_time))
FROM riders AS r1
LEFT JOIN deliveries AS d1 ON r1.rider_id=d1.rider_id
JOIN orders AS o1 ON o1.order_id=d1.order_id
GROUP BY 1;
```

### 1️⃣1️⃣ Monthly Restaurant Growth Rate
```sql
SELECT restaurant_name, DATE_FORMAT(order_date,'%m-%Y'), COUNT(o1.order_id) AS total_orders,
       LAG(COUNT(o1.order_id)) OVER(PARTITION BY restaurant_name ORDER BY DATE_FORMAT(order_date,'%m-%Y')) AS l1,
       COUNT(o1.order_id)/LAG(COUNT(o1.order_id)) OVER(PARTITION BY restaurant_name ORDER BY DATE_FORMAT(order_date,'%m-%Y')) AS growth_ratio
FROM restaurants AS r1
LEFT JOIN orders AS o1 ON r1.restaurant_id=o1.restaurant_id
JOIN deliveries AS d1 ON d1.order_id=o1.order_id
WHERE delivery_status='Delivered'  
  AND EXTRACT(YEAR FROM order_date)=YEAR(CURDATE())
GROUP BY restaurant_name, DATE_FORMAT(order_date,'%m-%Y')
ORDER BY 1, DATE_FORMAT(order_date,'%m-%Y');
```

### 1️⃣2️⃣ Customer Segmentation (Gold/Silver by AOV)
```sql
SELECT customer_name, SUM(total_amount) AS total_spending,
CASE 
    WHEN SUM(total_amount)>(SELECT AVG(total_amount) FROM orders) THEN 'Gold'
    ELSE 'Silver'
END AS status_customer
FROM customers AS c1
LEFT JOIN orders AS o1 ON c1.customer_id=o1.customer_id
GROUP BY customer_name;
```

### 1️⃣3️⃣ Rider Monthly Earnings (8% of Total Orders)
```sql
SELECT r1.rider_id, rider_name, (SUM(total_amount)/100)*8 AS eight_percent
FROM riders AS r1
LEFT JOIN deliveries AS d1 ON r1.rider_id=d1.rider_id
JOIN orders AS o1 ON o1.order_id=d1.order_id
GROUP BY r1.rider_id,rider_name;
```

### 1️⃣4️⃣ Rider Rating Analysis
```sql
SELECT rider_name, TIMESTAMPDIFF(MINUTE, delivery_time, order_time) AS total_time,
CASE 
    WHEN TIMESTAMPDIFF(MINUTE,delivery_time,order_time)<20 THEN '5-star'
    WHEN TIMESTAMPDIFF(MINUTE,delivery_time,order_time) BETWEEN 20 AND 30 THEN '4-star'
    ELSE '3-star'
END AS rating
FROM riders AS r1
LEFT JOIN deliveries AS d1 ON r1.rider_id=d1.rider_id
JOIN orders AS o1 ON o1.order_id=d1.order_id
WHERE d1.delivery_status = 'Delivered'
ORDER BY rating DESC;
```

### 1️⃣5️⃣ Order Frequency by Day
```sql
SELECT restaurant_name, DAYNAME(order_date), COUNT(order_id)
FROM restaurants AS r1
LEFT JOIN orders AS o1 ON r1.restaurant_id=o1.restaurant_id
GROUP BY restaurant_name,2;
```

### 1️⃣6️⃣ Customer Lifetime Value (CLV)
```sql
SELECT customer_name, SUM(total_amount) AS total_amount_sum
FROM customers AS c1
LEFT JOIN orders AS o1 ON c1.customer_id=o1.customer_id
GROUP BY customer_name;
```

### 1️⃣7️⃣ Order Popularity by Season
```sql
SELECT order_item,
CASE
    WHEN EXTRACT(MONTH FROM order_date) BETWEEN 3 AND 5 THEN 'Spring'
    WHEN EXTRACT(MONTH FROM order_date)=6 THEN 'Summer'
    WHEN EXTRACT(MONTH FROM order_date) BETWEEN 7 AND 9 THEN 'Monsoon'
    ELSE 'Winter'
END AS seasons,
COUNT(order_id) AS k
FROM orders
GROUP BY 1,2
ORDER BY 1,2,k DESC;
```

---

## 📑 Reports & Insights
- **Top Customers**: Identified based on lifetime spend & segmentation  
- **Restaurant Performance**: Revenue ranking, growth trends, and cancellation rates  
- **Riders**: Average delivery times, earnings, and service quality ratings  
- **Seasonal Trends**: Dish popularity by seasons and order frequency by weekdays  

---

## 🚀 How to Use
1. Clone Repository  
   ```bash
   git clone nmirzasaiman-jpg/Zomato_sql_project
   ```
2. Execute SQL scripts in your MySQL/PostgreSQL environment  
3. Run queries for analysis  
4. Extend/modify queries for further insights  

---
 
✨ Thank you for exploring this project!  

