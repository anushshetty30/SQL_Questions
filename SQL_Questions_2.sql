#1. Customer Purchase Frequency
#Find each customer's total number of orders and total completed sales.

  SELECT c.customer_id, customer_name, COUNT(o.order_id) AS total_orders,
    SUM( CASE 
            WHEN status = 'completed' THEN o.amount
            ELSE 0
        END
    ) AS total_sales
FROM customers c 
INNER JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, customer_name;

#2. Average Spend Per Customer
#Calculate the average completed sales per customer. Consider only customers who have made at least one completed order.

select avg(total_sales) AS average_spend
from (
select customer_id, sum(amount) as total_sales
from orders
where status = 'completed'
group by customer_id
) as customer_sales


#3. Customers Above Average Spending
#Find customers whose total completed sales are greater than the average total sales across all customers.

with total_completedsales as (
select c.customer_id, customer_name, sum(amount) as total_sales from customers c
inner join orders o
on c.customer_id = o.customer_id
where status = 'completed'
group by c.customer_id, customer_name
)
select customer_name, total_sales
from total_completedsales
where total_sales > (select avg(total_sales) from total_completedsales)

#4. Highest Order for Each Customer
#Find the highest-value order placed by each customer.

select customer_name, max(amount) as highest_amount
from customers c
inner join orders o
on c.customer_id = o.customer_id
group by c.customer_id, customer_name

OR
  
with highest_sales as(
select c.customer_id, customer_name, amount, rank () over (partition by c.customer_id order by amount desc) as customer_rank
from customers c
inner join orders o
on c.customer_id = o.customer_id
)
select customer_name, amount from highest_sales
where customer_rank = 1

#5. Customers With Cancelled Orders
#Find customers who have placed at least one cancelled order.
  
select customer_name, COUNT(ORDER_ID)
from customers c
inner join orders o
on c.customer_id = o.customer_id
WHERE status = 'cancelled'
group by c.customer_id, customer_name

#5. Customers With Cancelled Orders
#Find customers who have placed at least one cancelled order.

select customer_name, COUNT(ORDER_ID)
from customers c
inner join orders o
on c.customer_id = o.customer_id
WHERE status = 'cancelled'
group by c.customer_id, customer_name

#6. Customers With Only Completed Orders
#Find customers who have orders but never had a cancelled order.
  
SELECT 
    c.customer_name,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(CASE 
				WHEN o.status = 'Cancelled' THEN 1 
                ELSE 0 
                END) = 0;

#7. Cancellation Rate by Customer
#Calculate the cancellation percentage for each customer.

SELECT c.customer_name, COUNT(o.order_id) AS total_orders,
sum(case when o.status = 'cancelled' then 1 
		else 0 
        end) as cancelled_orders,
    concat(round((sum(case when o.status = 'cancelled' then 1 
		else 0 
        end) / COUNT(o.order_id)) * 100,2),'%') as cancelled_orders_perc
FROM customers c JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name


#8. Cancellation Rate by Month
#Calculate the monthly cancellation percentage.

SELECT 
    date_format(order_date,'%Y-%m') as month_date,
    COUNT(o.order_id) AS total_orders,
    SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
        concat(ROUND(
        SUM(CASE WHEN o.status = 'Cancelled' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(o.order_id),2),'%') AS cancellation_percentage
FROM orders o
group by month_date


#9. Highest-Selling City
#Find the city with the highest total completed sales.

SELECT c.city, SUM(o.amount) AS total_sales
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.city
ORDER BY total_sales DESC
LIMIT 1;

	OR

WITH city_sales AS (
    SELECT city, SUM(amount) AS total_sales
    FROM customers c
    INNER JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE status = 'Completed'
    GROUP BY city
),
ranked_sales AS (
    SELECT *, RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM city_sales
)
SELECT city, total_sales
FROM ranked_sales
WHERE sales_rank = 1;

#10. Average Order Value by City
#Calculate the average completed order value for each city.

select city, avg(amount) as total_sales
from customers c inner join orders o
on c.customer_id = o.customer_id
where status = 'Completed'
group by city	

#11. Rank Customers Within Their City
#Calculate each customer's total completed sales and rank customers within their city

with city_sales as (
    SELECT c.customer_id, c.customer_name, c.city, SUM(o.amount) AS total_sales
    FROM customers c
    JOIN orders o
	ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, c.customer_name, c.city
)
select customer_name, city, total_sales,
rank () over (partition by city order by  total_sales desc) as city_rank
from city_sales
order by city, city_rank


#12. Running Total of Sales
#Calculate the running total of completed sales by order date.

with date_sales as (
select order_date, sum(amount) as total_sales
from orders
where status = 'completed'
group by order_date
)
select order_date, total_sales,
sum(total_sales) over(order by order_date) as daily_sales
from date_sales

#13. Previous Order Amount
#For each order, display the previous order amount based on order date.

select order_id, order_date, amount,
lag (amount) over (order by order_date)
from orders

#14. Difference From Previous Order
#For each order, calculate the difference between the current order amount and the previous order amount.

select order_id, amount,
lag (amount) over (order by order_date) as previous_amount,
abs(amount - lag (amount) over (order by order_date)) as difference
from orders
order by order_date

#15. First and Last Order Date
#For each customer, find:
#First order date
#Last order date

select customer_name, 
min(order_date) as first_order_date , 
min(order_date) as last_order_date
FROM customers c 
JOIN orders o
    ON c.customer_id = o.customer_id
    group by c.customer_id, customer_name

OR

SELECT distinct c.customer_id, c.customer_name,
    MIN(o.order_date) OVER (PARTITION BY c.customer_id) AS first_order_date,
    MAX(o.order_date) OVER (PARTITION BY c.customer_id) AS last_order_date
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id;

#16. Customer Lifetime
#Calculate the number of days between a customer's first and last order.

select customer_name, 
min(order_date) as first_order_date , 
max(order_date) as last_order_date,
datediff(max(order_date), min(order_date)) as customer_lifetime_days
FROM customers c 
JOIN orders o
    ON c.customer_id = o.customer_id
    group by c.customer_id, customer_name

#17. Repeat Customers
#Find customers who have placed at least 2 completed orders.

select c.customer_name, count(o.order_id) as count_orders
from customers c join orders o
on c. customer_id = o.customer_id
where status = 'completed'
group by c.customer_id, c.customer_name
having count(o.order_id) >= 2

#18.Monthly Sales Growth
#Calculate total completed sales by month and compare each month with the previous month's sales.

with current_sales as (
select date_format(order_date, '%Y-%m') as month_date , sum(amount) as total_sales
from orders o
where status = 'completed'
group by month_date
),
previous_sales as (
select month_date, total_sales, lag(total_sales) over (order by month_date) as previous_month_sales
from current_sales
)
select month_date, total_sales, previous_month_sales,
coalesce(total_sales - previous_month_sales,0) as sales_growth
from previous_sales
order by month_date


#19. Top 2 Customers Per City
#Find the top 2 customers in each city based on completed sales.

with total_customer_sales as (
select c.customer_id, customer_name, city, sum(amount) as total_sales
from customers c join orders o
on c.customer_id = o.customer_id
where status = 'completed'
group by c.customer_id, customer_name, city
),
ranked_sales as (
select customer_name, city, total_sales,
rank() over (partition by city order by total_sales desc) as rank_customers
from total_customer_sales
)
select customer_name, city, total_sales, rank_customers
from ranked_sales
where rank_customers <= 2
order by city, rank_customers

#20. Customer Segmentation
#Classify customers based on their total completed sales:
#Total Sales	Segment
#>= ₹10,000	    High Value
#₹5,000–₹9,999	Medium Value
#< ₹5,000	    Low Value

select customer_name, sum(amount) as total_sales,
case
	when sum(amount) >= 10000 then 'High Value'
    when sum(amount) >= 5000 then 'Medium Value'
	else 'Low Value'
End as customer_segment
from customers c join orders o
on c.customer_id = o.customer_id
where status = 'completed'
group by c.customer_id, customer_name

