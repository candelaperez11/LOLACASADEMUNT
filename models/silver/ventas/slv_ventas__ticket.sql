-- =============================================================================
-- slv_ventas__ticket
-- =============================================================================
-- Una fila por ticket, puede contener varios productos
-- Un unico comprador/cliente identificado o no(N:1), un vendedor (N:1), una tienda que realiza el ticket(N:1) 
-- y varias lineas de ticket(1:N)
-- Las devoluciones apuntan al ticket de venta original con ticket_origen_id
-- Los productos del ticket estan en slv_ventas__linea_ticket (entidad creada entre tickets y productos por N:M)
-- =============================================================================

with tickets as (
    select * from {{ ref('stg_tpv__tickets') }}
),

final as (
    select
          ticket_id
        , tienda_id
        , vendedor_id
        , cliente_id          --puede ser null (cliente no identificado)
        , ticket_origen_id    --solo en devoluciones
        , tipo_ticket
        , fecha
        , hora
        , franja_id           --franja de 30 min, para el analisis hora a hora
        , forma_pago
        , canal
        , importe_total
        , date_load
    from tickets
    qualify row_number() over (partition by ticket_id order by date_load desc) = 1
)

select * from final
