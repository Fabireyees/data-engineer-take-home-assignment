-- stg_amazon_sales.sql
-- Cleans and normalizes Amazon marketplace order data.
--
-- Reads directly from Parquet via DuckDB read_parquet.
-- Path inside Docker container: /app/data/samples/amazon_sample.parquet
--
-- Source quirks handled here:
--   - ISO timestamp → split into order_date (DATE) + order_timestamp (TIMESTAMP)
--   - Order statuses normalized: Shipped→completed, Returned→refunded,
--     Cancelled→cancelled, Pending→pending
--   - refund_amount populated only on Returned orders → used in net_amount and is_refunded
--   - ship_state is null for non-US orders (CA, UK) → preserved as NULL
--   - fulfillment_channel describes logistics (FBA/FBM), not payment → payment_method is NULL
--   - No discount field in source → defaulted to 0.00

with source as (

    select * from read_parquet('/app/data/samples/amazon_sample.parquet')

),

cleaned as (

    select
        'amazon_' || order_id || '_' || product_asin                as sale_id,

        'amazon'                                                     as source_system,

        order_id                                                     as source_order_id,

        product_asin                                                 as source_line_id,

        cast(order_datetime as date)                                 as order_date,
        cast(order_datetime as timestamp)                            as order_timestamp,

        customer_id,

        product_asin                                                 as product_id,
        product_title                                                as product_name,
        product_category,

        -- Explicit cast — don't rely on type inference from parquet schema
        cast(quantity as integer)                                    as quantity,

        cast(item_price / nullif(quantity, 0) as decimal(10,2))     as unit_price,
        cast(item_price as decimal(10,2))                           as gross_amount,

        -- Amazon has no discount field in this dataset
        0.00::decimal(10,2)                                         as discount_amount,
        cast(tax as decimal(10,2))                                  as tax_amount,
        cast(shipping_price as decimal(10,2))                       as shipping_amount,

        -- net = gross + tax + shipping - refund
        -- coalesce guards against nulls in optional fields
        -- refund subtracted so net reflects actual revenue after returns
        cast(
            item_price
            + coalesce(tax, 0)
            + coalesce(shipping_price, 0)
            - coalesce(refund_amount, 0)
            as decimal(10,2)
        )                                                           as net_amount,

        cast(refund_amount as decimal(10,2))                        as refund_amount,

        ship_country,
        ship_state                                                   as ship_region,
        ship_city,

        -- fulfillment_channel (FBA/FBM) describes logistics, not payment method
        null::varchar                                               as payment_method,

        case order_status
            when 'Shipped'   then 'completed'
            when 'Returned'  then 'refunded'
            when 'Cancelled' then 'cancelled'
            when 'Pending'   then 'pending'
            else lower(order_status)
        end                                                         as order_status,

        order_status = 'Cancelled'                                  as is_cancelled,

        -- Defensive: flag as refunded if refund_amount is present OR status is Returned
        -- handles edge cases where refund arrives without a matching status update
        (coalesce(refund_amount, 0) > 0 or order_status = 'Returned') as is_refunded,

        current_timestamp                                           as loaded_at

    from source

    where order_id is not null
      and product_asin is not null

)

select * from cleaned