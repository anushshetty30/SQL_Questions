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
