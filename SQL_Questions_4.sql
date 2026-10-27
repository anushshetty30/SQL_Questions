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

