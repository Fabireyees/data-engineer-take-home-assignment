-- fct_sales.sql
-- Unified sales fact table combining Costco, Amazon, and Shopify.
--
-- Design decisions:
--   - Granularity: LINE ITEM level across all sources
--   - UNION ALL: staging models already deduplicate within their source
--   - sale_id is globally unique: source_orderid_lineid format
--   - Cancelled and refunded orders RETAINED with original amounts
--     Use is_cancelled / is_refunded flags or order_status to filter downstream
--   - Monetary amounts are standardized as DECIMAL(10,2); currency is not
--     explicitly provided in the sample sources
--   - Columns explicitly listed (no SELECT *) so schema is auditable

with unified as (

    select
        sale_id,
        source_system,
        source_order_id,
        source_line_id,
        order_date,
        order_timestamp,
        customer_id,
        product_id,
        product_name,
        product_category,
        quantity,
        unit_price,
        gross_amount,
        discount_amount,
        tax_amount,
        shipping_amount,
        net_amount,
        refund_amount,
        ship_country,
        ship_region,
        ship_city,
        payment_method,
        order_status,
        is_cancelled,
        is_refunded,
        loaded_at
    from {{ ref('stg_costco_sales') }}

    union all

    select
        sale_id,
        source_system,
        source_order_id,
        source_line_id,
        order_date,
        order_timestamp,
        customer_id,
        product_id,
        product_name,
        product_category,
        quantity,
        unit_price,
        gross_amount,
        discount_amount,
        tax_amount,
        shipping_amount,
        net_amount,
        refund_amount,
        ship_country,
        ship_region,
        ship_city,
        payment_method,
        order_status,
        is_cancelled,
        is_refunded,
        loaded_at
    from {{ ref('stg_amazon_sales') }}

    union all

    select
        sale_id,
        source_system,
        source_order_id,
        source_line_id,
        order_date,
        order_timestamp,
        customer_id,
        product_id,
        product_name,
        product_category,
        quantity,
        unit_price,
        gross_amount,
        discount_amount,
        tax_amount,
        shipping_amount,
        net_amount,
        refund_amount,
        ship_country,
        ship_region,
        ship_city,
        payment_method,
        order_status,
        is_cancelled,
        is_refunded,
        loaded_at
    from {{ ref('stg_shopify_sales') }}

)

select * from unified