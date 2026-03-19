-- stg_shopify_sales.sql
-- Normalizes Shopify line-item data to the unified staging schema.
--
-- Reads from int_shopify_line_items which handles:
--   - NDJSON file reading
--   - line_items unnesting
--   - line-level amount computation
--   - proportional tax allocation via window function
--
-- This model is responsible for:
--   - Final column naming and schema mapping
--   - Status normalization
--   - Boolean flag derivation
--   - Filtering dirty data (quantity=0 already handled upstream)

with cleaned as (

    select
        'shopify_' || order_id || '_' || (line_item->>'sku')        as sale_id,

        'shopify'                                                    as source_system,

        order_id                                                     as source_order_id,

        line_item->>'sku'                                            as source_line_id,

        cast(created_at as date)                                     as order_date,

        -- try_cast handles ISO8601 with 'Z' timezone gracefully
        try_cast(created_at as timestamp)                           as order_timestamp,

        customer->>'id'                                              as customer_id,

        line_item->>'sku'                                            as product_id,
        line_item->>'title'                                          as product_name,
        null::varchar                                                as product_category,

        quantity,
        unit_price,
        line_gross                                                   as gross_amount,
        discount_amount,

        -- Tax allocated by line net-before-tax share of order net-before-tax
        -- More accurate than gross-based allocation when discounts vary across lines
        round(
            total_tax_cast
            * (line_net_before_tax / nullif(order_net_before_tax, 0)),
            2
        )                                                            as tax_amount,

        -- No explicit shipping in this sample
        null::decimal(10,2)                                          as shipping_amount,

        -- net = line_net_before_tax + allocated tax
        round(
            line_net_before_tax
            + round(total_tax_cast * (line_net_before_tax / nullif(order_net_before_tax, 0)), 2),
            2
        )                                                            as net_amount,

        -- No explicit per-line refund in source
        -- Refund context captured via order_status and is_refunded flag
        null::decimal(10,2)                                          as refund_amount,

        customer->'location'->>'country'                            as ship_country,
        customer->'location'->>'province'                           as ship_region,
        customer->'location'->>'city'                               as ship_city,

        payment_gateway                                              as payment_method,

        case financial_status
            when 'paid'                then 'completed'
            when 'refunded'            then 'refunded'
            when 'partially_refunded'  then 'partial_refund'
            when 'pending'             then 'pending'
            when 'cancelled'           then 'cancelled'
            else lower(financial_status)
        end                                                          as order_status,

        -- Derived defensively from financial_status (no cancelled records in sample)
        financial_status = 'cancelled'                               as is_cancelled,

        -- Covers both full and partial refunds
        financial_status in ('refunded', 'partially_refunded')       as is_refunded,

        current_timestamp                                            as loaded_at

    from {{ ref('int_shopify_line_items') }}

)

select * from cleaned