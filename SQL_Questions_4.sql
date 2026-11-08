#1. Customer Order Summary
#For every customer, calculate:
#- Total number of orders
#- Number of completed orders
#- Number of cancelled orders
#- Total completed sales
#Include customers who have never placed an order.

select customer_name, count(o.order_id) as total_orders,
count(case when status = 'completed' then o.order_id
	  end) as completed_orders,
 count(case when status = 'cancelled' then o.order_id
	  end) as cancelled_orders,
sum(case when status = 'completed' then amount
	else 0
    end) as total_sales
from customers c left join orders o
on c.customer_id = o.customer_id
group by c.customer_id, customer_name

#2. Customers With More Completed Than Cancelled Orders
#Find customers who have more completed orders than cancelled orders.

with customers_orders as (
select customer_name, 
count(case when status = 'completed' then o.order_id
	  end) as completed_orders,
count(case when status = 'cancelled' then o.order_id
	  end) as cancelled_orders
from customers c join orders o
on c.customer_id = o.customer_id
group by c.customer_id, customer_name
)
select customer_name, completed_orders, cancelled_orders
from customers_orders
where completed_orders > cancelled_orders

#3. Customer's Largest Completed Order
#Find the largest completed order placed by each customer.
#If a customer has multiple orders with the same highest amount, include all tied orders.

with customer_order as (
select customer_name, order_id, order_date, amount,
rank() over (partition by c.customer_id order by amount desc) as customer_rank
from customers c join orders o
on c.customer_id = o.customer_id
where status = 'completed'
)
select customer_name, order_id, order_date, amount
from customer_order
where customer_rank = 1

#4. Customers Who Increased Their Spending
#Find customers whose second completed order amount was greater than their first completed order amount.

WITH customer_spend AS (
    SELECT customer_name, amount,
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY order_date) AS customer_rank
    FROM customers c JOIN orders o 
	ON c.customer_id = o.customer_id
    WHERE status = 'completed'
)
SELECT 
    customer_name,
    MAX(CASE WHEN customer_rank = 1 THEN amount
    END) AS first_order_amount,
    MAX(CASE WHEN customer_rank = 2 THEN amount
    END) AS second_order_amount
FROM customer_spend
GROUP BY customer_name
HAVING MAX(CASE WHEN customer_rank = 2 THEN amount
           END)
     >
       MAX(CASE WHEN customer_rank = 1 THEN amount
           END);

#5. Customers With Consecutive Orders
#Find customers who placed two orders within 30 days of each other.

with customers_orders as (
select customer_name, order_id, order_date,
lag(order_date) over (partition by c.customer_id order by order_date) as previous_order_date
from customers c join orders o
on c.customer_id = o.customer_id
)
select customer_name, order_id, order_date, previous_order_date,
datediff(order_date, previous_order_date) as days_between_orders
from customers_orders
where datediff(order_date, previous_order_date) <= 30

#6. Most Recent Completed Order
#Find the most recent completed order in the entire dataset.
#Output:
#order_id | customer_name | order_date | amount

select order_id, customer_name, order_date, amount
from customers c join orders o 
on c.customer_id = o.customer_id
where order_date = (select MAX(order_date) from orders o 
					where status = 'completed')
AND status = 'completed'

#7. Top 3 Orders by Month
#Find the top 3 highest-value completed orders for each month.

with highest_sales as (
select date_format(order_date, '%Y-%m') as month_date, order_id, c.customer_name, amount,
row_number() over (partition by date_format(order_date, '%Y-%m') order by amount desc) as monthly_rank
from customers c join orders o
on c.customer_id = o.customer_id
where status = 'completed'
)
select month_date, order_id, customer_name, amount, monthly_rank
from highest_sales
where monthly_rank <= 3

#8. Customer Sales Rank
#Calculate each customer's total completed sales and assign a rank from highest to lowest.
#Include customers with zero completed sales.

with customer_sales as (
select customer_name, 
coalesce(sum(case when status = 'completed' then amount
	else 0
    end),0) as total_sales
from customers c left join orders o
on c.customer_id = o.customer_id
group by c.customer_id, customer_name
)
select customer_name, total_sales,
rank() over (order by total_sales desc) as sales_rank
from customer_sales
order by total_sales desc

#9. Customers With Sales Above Their City Average
#Find customers whose total completed sales are greater than the average completed sales of customers in their city.

with customer_sales as (
select customer_name, city, 
sum(case when status = 'completed' then amount
	else 0
    end) as total_sales
from customers c left join orders o
on c.customer_id = o.customer_id
group by c.customer_id, customer_name, city
),
city_sales as (
select customer_name, city, total_sales, 
avg(total_sales) over (Partition by city) as city_average_sales
from customer_sales
)
select customer_name, city, total_sales, city_average_sales
from city_sales
where total_sales > city_average_sales

#10. City With the Highest Average Customer Spending
#Calculate the average completed sales per customer for each city and return the city with the highest average.

with customer_sales as (
select customer_name, city, sum(case when status = 'completed' then amount
			else 0
			end) as total_sales
from customers c left join orders o
on c.customer_id = o.customer_id
group by c.customer_id, customer_name, city
)
select city, avg(total_sales) as average_customer_sales
from customer_sales
group by city
order by average_customer_sales desc
limit 1

#11. Monthly Order Count Comparison
#For each month, calculate the number of completed orders and the previous month's completed order count.

select date_format(order_date, '%Y-%m') as month_date, count(order_id) as completed_orders,
lag(count(order_id)) over(order by date_format(order_date, '%Y-%m')) as previous_month_orders
from orders
where status = 'completed'
group by date_format(order_date, '%Y-%m')

#12. Monthly Order Growth Percentage
#Calculate the month-over-month percentage change in the number of completed orders.
#Output:
#month_date | completed_orders | previous_month_orders | growth_percentage

with month_orders as (
select date_format(order_date, '%Y-%m') as month_date, count(order_id) as completed_orders,
lag(count(order_id)) over(order by date_format(order_date, '%Y-%m')) as previous_month_orders
from orders
where status = 'completed'
group by date_format(order_date, '%Y-%m')
)
select month_date, completed_orders, previous_month_orders,
round((completed_orders - previous_month_orders) * 100 / nullif(previous_month_orders,0),2) as growth_percentage
from month_orders

#13. Revenue Contribution by Month
#Calculate each month's completed sales and its percentage contribution to total completed sales.
#Output:
#month_date | monthly_sales | revenue_percentage

with month_orders as (
select date_format(order_date, '%Y-%m') as month_date, sum(amount) as monthly_sales
from orders
where status = 'completed'
group by date_format(order_date, '%Y-%m')
),
total_completed_sales as (
select month_date, monthly_sales, sum(monthly_sales) over () as total_sales
from month_orders
)
select month_date, monthly_sales, 
concat(round((monthly_sales * 100 / total_sales),2),'%') as revenue_percentage
from total_completed_sales

#14. Best Customer by Month
#Find the customer who generated the highest completed sales in each month.
#Include all customers tied for the highest sales.

with customer_sales as (
select date_format(order_date, '%Y-%m') as month_date, customer_name, sum(amount) as monthly_sales
from customers c join orders o
on c.customer_id = o.customer_id
where status = 'completed'
group by date_format(order_date, '%Y-%m'), c.customer_id, customer_name
),
customer_rank as (
select month_date, customer_name, monthly_sales,
rank() over (partition by month_date order by monthly_sales desc) as ranking
from customer_sales
)
select month_date, customer_name, monthly_sales
from customer_rank
where ranking = 1
order by month_date

#15. Customer's First Completed Order
#Find the first completed order for every customer.
#Include only customers who have at least one completed order.

with customer_rank as (
select customer_name, order_id , order_date, amount,
row_number() over (partition by c.customer_id order by order_date) as ranking
from customers c join orders o
on c.customer_id = o.customer_id
where status = 'completed'
)
select customer_name, order_id , order_date, amount
from customer_rank
where ranking = 1

#16. Customers Who Never Cancelled an Order
#Find customers who have placed at least one order but have never cancelled any order.

select customer_name, count(o.order_id) as total_orders,
count(case when status = 'completed' then o.order_id
	  end) as completed_orders
from customers c join orders o
on c.customer_id= o.customer_id
group by c.customer_id, customer_name
having count(case when status = 'cancelled' then o.order_id
	  end) = 0

#17. Cancellation Rate by City
#Calculate the cancellation rate for each city.

with city_orders as (
select city, count(o.order_id) as total_orders,
count(case when status = 'cancelled' then o.order_id
	end) as cancelled_orders
from customers c join orders o
on c.customer_id = o.customer_id
group by city
)
select city, total_orders, cancelled_orders,
round((cancelled_orders * 100 / total_orders),2) as cancellation_percentage
from city_orders

#18. Orders Above Customer's Average
#Find completed orders where the order amount is greater than that customer's average completed order amount.

WITH order_analysis AS (
    SELECT c.customer_name, o.order_id, o.amount,
    AVG(o.amount) OVER (PARTITION BY o.customer_id) AS customer_average_order
    FROM customers c JOIN orders o
    ON c.customer_id = o.customer_id
    WHERE o.status = 'Completed'
)
SELECT
    customer_name, order_id, amount, customer_average_order
FROM order_analysis
WHERE amount > customer_average_order;

#19. Customer Revenue Segmentation With Customer Count
#Using these categories:
#- High Value: ₹10,000 or more
#- Medium Value: ₹5,000 to below ₹10,000
#- Low Value: below ₹5,000
#First classify every customer based on their total completed sales.
#Then calculate how many customers belong to each segment.

WITH customer_sales AS (
    SELECT c.customer_id, c.customer_name,
        SUM(CASE
                    WHEN o.status = 'Completed'
                    THEN o.amount
                    ELSE 0
                END) AS total_sales
    FROM customers c LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name
),
customer_segments AS (
    SELECT customer_id, customer_name, total_sales,
        CASE
            WHEN total_sales >= 10000 THEN 'High Value'
            WHEN total_sales >= 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM customer_sales
)
SELECT
    customer_segment,
    COUNT(customer_id) AS customer_count,
    SUM(total_sales) AS total_segment_sales
FROM customer_segments
GROUP BY customer_segment
ORDER BY total_segment_sales DESC;

