#1. Customer Revenue Contribution
#Calculate each customer's completed sales and their percentage contribution to total completed sales.

with customer_sales as (
select c.customer_id, customer_name, sum(amount) as total_sales
from customers c join orders o
on c.customer_id = o.customer_id
where status = 'completed'
group by c.customer_id, customer_name
)
select customer_name, total_sales, 
concat(round(total_sales * 100 / (select sum(total_sales) from customer_sales),2),'%') as revenue_percentage
from customer_sales
order by total_sales desc

#2. Customers With Above-Average Order Value
#Find customers whose average completed order amount is greater than the average completed order amount across all completed orders.

select customer_name, avg(amount) as average_order_value
from customers c join orders o
on c.customer_id = o.customer_id
where status = 'completed'
group by c.customer_id, customer_name
having average_order_value > (select avg(amount) from orders o
							  where status = 'completed')


#3. Sales by Order Status
#For each order status, calculate the number of orders, total order amount, and average order amount.

select status, count(order_id) as order_count, sum(amount) as total_amount, avg(amount) as average_amount
from orders
group by status

#4. City Performance Comparison
#Calculate the number of customers, completed orders, and completed sales for each city. Include only cities with completed sales greater than ₹10,000.

select city, count(distinct c.customer_id) as customer_count, count(o.order_id) as completed_orders, sum(amount) as total_sales
from customers c join orders o
on c.customer_id = o.customer_id
where status = 'completed'
group by city
having total_sales > 10000

#5. Customers With No Completed Orders
#Find customers who have never placed a completed order, even if they have cancelled orders.

SELECT 
    c.customer_id,
    c.customer_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.customer_id = c.customer_id
      AND o.status = 'Completed'
);

	OR
	
SELECT 
    c.customer_id,
    c.customer_name
FROM customers c LEFT JOIN orders o
ON c.customer_id = o.customer_id
and o.status = 'Completed'
where o.customer_id is null
