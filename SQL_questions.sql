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
