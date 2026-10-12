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
