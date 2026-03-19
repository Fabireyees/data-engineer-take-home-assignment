-- Completed orders should never have negative net_amount
select * from {{ ref('fct_sales') }}
where order_status = 'completed'
  and net_amount < 0
