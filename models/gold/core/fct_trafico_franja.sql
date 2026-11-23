-- =============================================================================
-- fct_trafico_franja
-- =============================================================================
-- Hecho trafico: una fila por tienda, dia y franja de 30 min (grano tienda + dia + franja)
-- Medidas: entradas (personas que entran) y trafico_exterior (personas que pasan por delante)
-- Se relaciona con dim_tienda, dim_fecha y dim_franja
-- Une el historico del contador y el tiempo real (ya unidos en Silver)
-- La atraccion (entradas / trafico) y la conversion (tickets / entradas) se
-- calculan en Power BI, no aqui
-- Solo tienen trafico las tiendas con contador (sin corners ECI, Andorra...)
-- =============================================================================

with trafico as (
    select * from {{ ref('slv_trafico__trafico_franja') }}
),

final as (
    select
        trafico_franja_id
        , tienda_id
        , fecha
        , franja_id
        , entradas
        , trafico_exterior
        , hay_incidencia
        , origen
    from trafico
)

select * from final