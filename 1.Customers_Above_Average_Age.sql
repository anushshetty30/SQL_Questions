#Find customers whose age is greater than the average age of all customers.

select customer_name, age from customers
where age > (select avg(age) from customers)
