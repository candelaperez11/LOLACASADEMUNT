-- =============================================================================
-- slv_ventas__linea_ticket
-- =============================================================================
-- Una fila por linea de ticket (cada producto de cada ticket)
-- Relacion N:1 con Ticket: un ticket tiene varias lineas, cada linea es de un solo ticket
-- Relacion N:1 con Producto: un producto aparece en muchas lineas, cada linea es de un producto
-- Resuelve la N:M entre Ticket y Producto (un ticket tiene muchos productos y un
-- producto esta en muchos tickets)
-- La BOLSA_PAPEL no es un producto: tipo_linea = BOLSA y referencia nula, asi no
-- apunta a un producto que no existe (pero suma al importe del ticket)
-- Las devoluciones vienen con unidades e importes en negativo
-- =============================================================================

with lineas as (
    select * from {{ ref('stg_tpv__lineas_ticket') }}
),

final as (
    select
          linea_ticket_id
        , ticket_id
        , num_linea
        , case
              when es_producto then referencia
          end                                       as referencia       --bolsa null porque no tiene ref
        , case
              when es_producto then 'PRODUCTO'
              else 'BOLSA'
          end                                       as tipo_linea     --diferenciar las bolsas
        , unidades
        , pvp
        , descuento_pct
        , precio_final
        , es_precio_recalculado                                         --precio calculado con datos de producto porque venia vacio
        , date_load
    from lineas
    qualify row_number() over (partition by linea_ticket_id order by date_load desc) = 1
)

select * from final