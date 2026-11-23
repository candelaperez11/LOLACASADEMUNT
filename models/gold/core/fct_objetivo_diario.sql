-- =============================================================================
-- fct_objetivo_diario
-- =============================================================================
-- Hecho objetivo: una fila por tienda y dia (grano tienda + dia)
-- Medida: objetivo de venta neta en euros
-- Se relaciona con dim_tienda (tienda_id) y dim_fecha (fecha)
-- El % de objetivo (venta / objetivo) se calcula en Power BI, no aqui
-- =============================================================================

with objetivos as (
    select * from {{ ref('slv_ventas__objetivo_diario') }}
),

final as (
    select
        objetivo_id
        , tienda_id
        , fecha
        , objetivo_venta_neta
    from objetivos
)

select * from final