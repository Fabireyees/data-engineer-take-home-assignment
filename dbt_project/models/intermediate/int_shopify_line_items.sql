-- int_shopify_line_items.sql
-- Explodes Shopify NDJSON line_items array and pre-computes line-level amounts.
--
-- Responsibility: extraction + explosion + amount computation only.
-- Schema normalization and business logic live in stg_shopify_sales.
--
-- Why intermediate and not staging?
-- Shopify is the only source with nested data requiring unnesting + a window function
-- for proportional tax allocation. Isolating this here keeps stg_shopify_sales focused
-- on schema mapping, not data extraction.

with source as (

    select * from read_json_auto(
        '/app/data/samples/shopify_sample.json',
        format = 'newline_delimited'
    )

),

-- Unnest line_items: each element becomes its own row
exploded as (

    select
        o.id                    as order_id,
        o.created_at,
        o.customer,
        o.total_tax,
        o.total_discounts,
        o.total_price,
        o.financial_status,
        o.fulfillment_status,
        o.discount_codes,
        o.payment_gateway,
        unnest(o.line_items)    as line_item
    from source o

),

-- Pre-compute line-level amounts
-- Filter dirty data here: quantity=0 rows are invalid (SHP00000004 Baseball Cap)
line_amounts as (

    select
        order_id,
        created_at,
        customer,
        total_tax,
        total_discounts,
        total_price,
        financial_status,
        fulfillment_status,
        discount_codes,
        payment_gateway,
        line_item,

        cast(line_item->>'price' as decimal(10,2))                  as unit_price,
        cast(line_item->>'quantity' as integer)                     as quantity,
        cast(line_item->>'discount_amount' as decimal(10,2))        as discount_amount,
        cast(total_tax as decimal(10,2))                            as total_tax_cast,

        -- gross = unit_price * quantity
        cast(line_item->>'price' as decimal(10,2))
            * cast(line_item->>'quantity' as integer)               as line_gross,

        -- net before tax = gross - discount (base for tax allocation)
        cast(line_item->>'price' as decimal(10,2))
            * cast(line_item->>'quantity' as integer)
            - cast(line_item->>'discount_amount' as decimal(10,2))  as line_net_before_tax

    from exploded

    where cast(line_item->>'quantity' as integer) > 0

),

-- Compute order-level net before tax via window function
-- Stays at line-item grain — no aggregation
tax_allocation as (

    select
        *,
        sum(line_net_before_tax) over (partition by order_id)       as order_net_before_tax
    from line_amounts

)

select * from tax_allocation