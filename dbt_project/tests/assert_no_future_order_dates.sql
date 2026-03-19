-- No order should have a date in the future
select * from {{ ref('fct_sales') }}
where order_date > current_date
