#1.Customers Above Average Age
#Find customers whose age is greater than the average age of all customers.

select customer_name, age from customers
where age > (select avg(age) from customers)

#2. Second Highest Order
#Find the second-highest order amount from the orders table.

select max(amount) from orders
where amount < (select max(amount) from orders)

#3. Orders Above Average
#Find all orders where the order amount is greater than the average order amount.

select order_id, amount from orders
where amount > (select avg(amount) from orders)

#4. Customer Order Count
#Find the number of orders placed by each customer and display. Include only customers who have placed at least one order.

select c.customer_id, c.customer_name, count(o.order_id) AS order_count from customers c
inner join orders o
on c.customer_id = o.customer_id
group by c.customer_id, c.customer_name

#5. Customers With No Orders
#Find customers who have never placed an order.

select c.* from customers c
left join orders o
on c.customer_id = o.customer_id
where order_id IS NULL

#6. Total Completed Sales Per Customer
#Find each customers total completed sales.Sort from highest to lowest.

select c.customer_name, sum(amount) as total_sales from customers c
inner join orders o
on c.customer_id = o.customer_id
where status = 'completed'
group by c.customer_id, c.customer_name
order by total_sales desc
