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

#6. First-Time vs Repeat Customers
#Classify customers as One-Time if they have exactly one completed order and Repeat if they have more than one. Exclude customers with no completed orders.

select customer_name, count(o.order_id) as completed_orders,
case when count(o.order_id) = 1 then 'One-Time'
	 when count(o.order_id) > 1 then 'Repeat'
End As customer_type
from customers c join orders o
on c.customer_id = o.customer_id
where status = 'completed'
group by c.customer_id, customer_name

#7. Latest Order for Each Customer
#Retrieve each customer's most recent order, including its order ID, date, amount, and status. Return only one row per customer who has placed an order.

with ranked_order as (
select customer_name,order_id, order_date, amount,status,
row_number() over (Partition by c.customer_id order by order_date desc) as customer_rank
from customers c join orders o
on c.customer_id = o.customer_id
)
select customer_name,order_id, order_date, amount,status
from ranked_order
where customer_rank = 1

#8. Days Between Customer Orders
#For every order, calculate the number of days since that customer's previous order.

with customer_previous as (
select customer_name, o.order_id, order_date, 
lag(order_date) over (Partition by c.customer_id order by order_date) as previous_order
from customers c join orders o 
on c.customer_id = o.customer_id
)
select customer_name, order_id, order_date, previous_order,
datediff(order_date, previous_order) as days_between_orders
from customer_previous

#9. Top Customer in Each City
#Find the customer with the highest completed sales in every city. Include all tied customers.

with highest_customer as (
select customer_name, city,
sum(amount) as total_sales
from customers c join orders o
on c.customer_id = o.customer_id
where status = 'completed'
group by c.customer_id, customer_name, city
),
ranked_customers as (
select customer_name, city, total_sales, 
rank () over (partition by city order by total_sales desc) as customer_rank
from highest_customer
)
select city, customer_name, total_sales
from ranked_customers
where customer_rank = 1

#10. Customer Purchase Recency
#Calculate how many days have passed between each customer's most recent order date and the fixed analysis date 2025-06-01. Include customers who have placed at least one order.

select customer_name, max(order_date) as last_order_date,
datediff ('2025-06-01', max(order_date)) as days_since_last_order
from customers c join orders o
on c.customer_id = o.customer_id
group by c.customer_id, customer_name

#11. Month-over-Month Sales Growth Percentage
#Calculate monthly completed sales, previous month's sales, and percentage growth compared with the previous available month.

with monthly_sales as (
select date_format (order_date, '%Y-%m') as month_date, sum(amount) as total_sales
from orders
where status = 'completed'
group by month_date
),
previous_sales as (
select month_date, total_sales,
lag (total_sales) over (order by month_date) as previous_month_sales
from monthly_sales
)
select month_date, total_sales, previous_month_sales,
concat(round(coalesce ((previous_month_sales / total_sales) * 100,0),2),'%') as growth_percentage
from previous_sales

#12. Cumulative Monthly Sales
#Calculate total completed sales per month and the cumulative sales from the first month through each month.

with total_sales as (
select date_format (order_date, '%Y-%m') as month_date, sum(amount) as monthly_sales
from orders
where status = 'completed'
group by month_date
)
select month_date, monthly_sales,
sum(monthly_sales) over (order by month_date) as cumulative_sales
from total_sales

#13. Highest Sales Day in Each Month
#Find the date with the highest completed sales for each month. Include all dates tied for the highest daily sales.

with total_sales as (
select date_format (order_date, '%Y-%m') as month_date, order_date, sum(amount) as daily_sales
from orders
where status = 'completed'
group by month_date, order_date
),
order_rank as (
select month_date, order_date, daily_sales,
rank() over (partition by month_date order by daily_sales desc) as sales_rank
from total_sales
)
select month_date, order_date, daily_sales
from order_rank
where sales_rank = 1
order by month_date

#14. Sales Above the Monthly Average
##Find completed orders whose amounts are greater than the average completed order amount for their respective month.

with avg_amount as (
select order_id, order_date, amount,
avg(amount) over (partition by date_format (order_date, '%Y-%m')) as monthly_average
from orders
where status = 'completed'
)
select order_id, order_date, amount, monthly_average
from avg_amount
where amount > monthly_average

#15. Best and Worst Sales Months
#Find the month with the highest completed sales and the month with the lowest completed sales, considering only months containing completed orders.

with date_sales as (
select date_format (order_date, '%Y-%m') as month_date, sum(amount) as total_sales
from orders
where status = 'completed'
group by month_date
),
customer_rank as (
select month_date, total_sales,
rank() over (order by total_sales desc) as best_rank,
rank() over (order by total_sales asc) as worst_rank
from date_sales
)
select month_date, total_sales,
Case 
	when best_rank = 1 then 'Best Sales'
    when worst_rank = 1 then 'Worst Sales'
End as sales_rank
from customer_rank
where best_rank = 1 OR worst_rank = 1

#16. Product Category Analysis
#Using the products table, calculate the number of products, average product price, minimum price, and maximum price in each category.

select category, count(product_id) as product_count,
avg(price) as average_price,
min(price) as minimum_price,
max(price) as maximum_price
from products
group by category

#17. Products Priced Above Their Category Average
#Find products whose price is greater than the average price of products in their own category.

WITH product_analysis AS (
select product_name, category, price,
avg(price) over (partition by category) as category_average_price
from products
)
select product_name, category, price, category_average_price
from product_analysis
where price > category_average_price

#18. Customer Revenue Segmentation
#Calculate each customer's completed sales and classify them into these groups:
- High Value: ₹10,000 or more
- Medium Value: ₹5,000 to below ₹10,000
- Low Value: below ₹5,000
#Include customers with zero completed sales.

select customer_name, coalesce(SUM(o.amount),0) AS total_sales,
case when coalesce(sum(amount),0) > 10000 then 'High Value'
	 when coalesce(sum(amount),0) >= 5000 then 'Medium Value'
     when coalesce(sum(amount),0) < 5000 then 'Low Value'
End as customer_segment
from customers c left join orders o
on c.customer_id = o.customer_id
AND status = 'completed'
group by c.customer_id, customer_name
