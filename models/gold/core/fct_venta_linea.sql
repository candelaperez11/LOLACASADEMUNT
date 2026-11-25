{{
    config(
        materialized = 'incremental',
        unique_key = 'linea_ticket_id',
        on_schema_change = 'append_new_columns'
    )
}}

-- =============================================================================
-- fct_venta_linea
-- =============================================================================
-- Hecho venta por linea: una fila por linea de ticket (grano linea de ticket)
-- Medidas: unidades e importe (precio_final)
-- Se relaciona con dim_fecha, dim_tienda, dim_producto y dim_franja
-- Lleva tambien el vendedor y el cliente, para filtrar por vendedor en Power BI
-- Incluye ventas y devoluciones (en negativo) y la linea de la bolsa
-- (tipo_linea = BOLSA): asi la suma de importes cuadra con el total de los tickets.
-- Para los mas vendidos se filtra tipo_linea = PRODUCTO
--
-- INCREMENTAL: los tickets llegan cada 30 minutos. En vez de rehacer toda la
-- tabla, cada ejecucion solo procesa las lineas cargadas recientemente:
--   · la primera vez (o con --full-refresh) carga todo
--   · despues, solo lo cargado en los ultimos 3 dias respecto a lo ultimo que
--     ya tiene la tabla (margen por si algun lote llega con retraso)
--   · unique_key: si una linea ya existe, se actualiza en vez de duplicarse
--   · on_schema_change: si aparece una columna nueva (como canal en julio de
--     2026), se añade sin romper la carga
-- =============================================================================

with lineas as (
    select * from {{ ref('slv_ventas__linea_ticket') }}

    {% if is_incremental() %}
    -- Solo lo nuevo: lo cargado desde 3 dias antes de lo ultimo que ya tenemos
    where date_load >= (select dateadd('day', -3, max(date_load)) from {{ this }})
    {% endif %}
),

tickets as (
    select * from {{ ref('slv_ventas__ticket') }}
),

final as (
    select
          l.linea_ticket_id
        , l.ticket_id
        , t.fecha
        , t.tienda_id
        , l.referencia
        , t.franja_id
        , t.vendedor_id
        , t.cliente_id
        , t.tipo_ticket
        , l.tipo_linea
        -- Medidas
        , l.unidades
        , l.precio_final                                     as importe
        -- Para la incremental
        , l.date_load
    from lineas l
    join tickets t
        on l.ticket_id = t.ticket_id
)

select * from final