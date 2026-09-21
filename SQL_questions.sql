#1.Customers Above Average Age
#Find customers whose age is greater than the average age of all customers.

select customer_name, age from customers
where age > (select avg(age) from customers)

#2. Second Highest Order
#Find the second-highest order amount from the orders table.

select max(amount) from orders
where amount < (select max(amount) from orders)

#3. Orders Above Average
#Find all orders where the order amount is greater than the average order amount.

select order_id, amount from orders
where amount > (select avg(amount) from orders)

#4. Customer Order Count
#Find the number of orders placed by each customer and display. Include only customers who have placed at least one order.

select c.customer_id, c.customer_name, count(o.order_id) AS order_count from customers c
inner join orders o
on c.customer_id = o.customer_id
group by c.customer_id, c.customer_name

#5. Customers With No Orders
#Find customers who have never placed an order.

select c.* from customers c
left join orders o
on c.customer_id = o.customer_id
where order_id IS NULL

#6. Total Completed Sales Per Customer
#Find each customers total completed sales.Sort from highest to lowest.

select c.customer_name, sum(amount) as total_sales from customers c
inner join orders o
on c.customer_id = o.customer_id
where status = 'completed'
group by c.customer_id, c.customer_name
order by total_sales desc

#7. Customers With Sales Above ₹8,000
#Find customers whose total completed sales exceed ₹8,000.

select c.customer_name, sum(amount) as total_sales from customers c
inner join orders o
on c.customer_id = o.customer_id
where status = 'completed'
group by c.customer_id, c.customer_name
having total_sales > 8000

#8. City-wise Customer Count
#Find the number of customers in each city.Sort by customer count from highest to lowest.

SELECT city, COUNT(*) AS customer_count
FROM customers
GROUP BY city
ORDER BY customer_count DESC;

#9. City-wise Sales
#Calculate the total completed sales for each customer city.

SELECT c.city, SUM(o.amount) AS total_sales
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.city
ORDER BY total_sales DESC;

#10. Average Order Value by Status
#Find the average order amount for each order status.

SELECT status, AVG(amount) AS average_order_value
FROM orders
GROUP BY status;

#Date & Business Analysis
  
#11. Year-Month Sales
#Calculate total completed sales for each year-month.

SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month_date,
    SUM(amount) AS total_sales
FROM orders
WHERE status = 'Completed'
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month_date;

#12. Monthly Order Count
#Find the number of completed orders for each month.

select date_format(order_date,'%Y-%m'), count(order_id) as total_orders from orders
where status = 'completed'
group by date_format(order_date,'%Y-%m')

#13. Highest Sales Month
#Find the month with the highest total completed sales.

select date_format(order_date,'%Y-%m') as month_date, sum(amount) as total_sales from orders
where status = 'completed'
group by date_format(order_date,'%Y-%m')
order by total_sales desc
limit 1

#14. Customers With Multiple Orders
#Find customers who have placed more than one order.

SELECT
    c.customer_name,
    COUNT(o.order_id) AS order_count
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.customer_name
HAVING COUNT(o.order_id) > 1;

#15. Cancelled Order Percentage
#Calculate the percentage of orders that were cancelled.

SELECT 
    concat(round(SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) * 100 / COUNT(*),2),'%') AS cancelled_percentage
FROM orders;

#16. Rank Customers by Sales
#Calculate each customer's total completed sales and assign a rank based on sales.

With total_customersales AS (
select c.customer_id, c.customer_name, sum(amount) as total_sales from customers c
inner join orders o
on c.customer_id = o.customer_id
where status = 'completed'
group by c.customer_id, c.customer_name
order by total_sales desc
)

select customer_name, total_sales,
rank() over (order by total_sales desc) as rank_sales
from total_customersales

#17. Top 3 Customers Using Ranking
#Find customers whose sales rank is within the top 3.

WITH customer_sales AS (
    SELECT c.customer_id, c.customer_name,
        SUM(o.amount) AS total_sales
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
    GROUP BY
        c.customer_id,
        c.customer_name
),
ranked_customers AS (
    SELECT customer_name, total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM customer_sales
)
SELECT customer_name, total_sales, sales_rank
FROM ranked_customers
WHERE sales_rank <= 3
ORDER BY sales_rank;

#18. Customer Order Ranking
#For each customer, assign a sequential number to their orders based on order_date, with the earliest order getting 1.

select customer_id, order_id, order_date, 
row_number () over (partition by customer_id order by order_date) as order_number
from orders

#19. First Order of Each Customer
#Find the first order placed by each customer.
    
with customer_order as (
select customer_id, order_id, order_date, 
row_number () over (partition by customer_id order by order_date) as order_number
from orders
)
select customer_id, order_id, order_date
from customer_order
where order_number = 1
