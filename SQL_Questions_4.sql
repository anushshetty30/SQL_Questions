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
