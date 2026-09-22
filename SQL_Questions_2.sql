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
