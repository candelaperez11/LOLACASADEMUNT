-- =============================================================================
-- slv_red_comercial__vendedor
-- =================================================================================
-- Una fila por vendedor 
-- N:1 con Tienda (Cada vendedor trabaja en una tienda, una tienda tiene varios vendedores)
-- 1:N con Ticket (Un vendedor hace muchos tickets diferentes, cada ticket lo hace un solo vendedor)
-- ===================================================================================

with vendedores as (
    select * from {{ ref('stg_comercial__vendedores') }}
),

final as (
    select
          vendedor_id
        , tienda_id
        , nombre
        , apellidos
        , fecha_alta
        , puesto
        , horas_semanales
    from vendedores
    qualify row_number() over (partition by vendedor_id order by date_load desc) = 1
)

select * from final