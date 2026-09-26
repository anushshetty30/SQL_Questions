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
