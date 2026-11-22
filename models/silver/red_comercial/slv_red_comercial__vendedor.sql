-- =============================================================================
-- slv_red_comercial__vendedor
-- =================================================================================
-- Una fila por vendedor 
-- N:1 con Tienda (Cada vendedor trabaja en una tienda, una tienda tiene varios vendedores)
-- 1:N con Ticket (Un vendedor hace muchos tickets diferentes, cada ticket lo hace un solo vendedor)
-- ===================================================================================

with tickets as (
    select * from {{ ref('stg_tpv__tickets') }}
),

final as (
    select
        vendedor_id
        , tienda_id
        , date_load
    from tickets
    where vendedor_id is not null
    qualify row_number() over (partition by vendedor_id order by date_load desc) = 1
)

select * from final