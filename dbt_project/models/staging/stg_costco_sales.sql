-- stg_costco_sales.sql
-- Cleans and normalizes Costco warehouse sales data.
--
-- Source quirks handled here:
--   - Amounts stored as strings with dollar prefix, stripped and cast to DECIMAL
--   - Dates inferred by DuckDB as DATE from CSV
--   - Multi-row transactions kept at line-item grain
--   - Missing member_id on guest transactions preserved as NULL
--   - No status, discount, tax, shipping, or refund fields, defaulted to null/0.00
--   - TXN00000002 excluded: malformed CSV row causes purchase_date to parse as NULL

with raw as (
    select * from read_csv_auto(
        '/app/data/samples/costco_sample.csv',
        header = true,
        strict_mode = false,
        ignore_errors = true
    )
),

source as (
    select * from raw
    where transaction_id is not null
      and product_sku is not null
      and purchase_date is not null
),

cleaned as (
    select
        'costco_' || transaction_id || '_' || product_sku            as sale_id,
        'costco'                                                      as source_system,
        transaction_id                                                as source_order_id,
        product_sku                                                   as source_line_id,
        cast(purchase_date as date)                                   as order_date,
        null::timestamp                                               as order_timestamp,
        nullif(trim(member_id), '')                                   as customer_id,
        product_sku                                                   as product_id,
        product_description                                           as product_name,
        null::varchar                                                 as product_category,
        cast(case_quantity as integer)                                as quantity,
        cast(replace(unit_price_per_case, '$', '') as decimal(10,2)) as unit_price,
        cast(replace(total_amount, '$', '') as decimal(10,2))         as gross_amount,
        0.00::decimal(10,2)                                           as discount_amount,
        null::decimal(10,2)                                           as tax_amount,
        null::decimal(10,2)                                           as shipping_amount,
        null::decimal(10,2)                                           as refund_amount,
        cast(replace(total_amount, '$', '') as decimal(10,2))         as net_amount,
        'US'                                                          as ship_country,
        null::varchar                                                  as ship_region,
        trim(split_part(store_location, '- ', 2))                    as ship_city,
        payment_method,
        'completed'                                                   as order_status,
        false                                                         as is_cancelled,
        false                                                         as is_refunded,
        current_timestamp                                             as loaded_at
    from source
)

select * from cleaned
