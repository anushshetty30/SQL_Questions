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
