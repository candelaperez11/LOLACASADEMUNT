-- =============================================================================
-- slv_red_comercial__area
-- =============================================================================
-- Entidad Area: una fila por area
-- Un area tiene varias tiendas (1:N con Tienda)
-- Cada area la lleva un area manager (N:1 con Area manager)
-- Contiene area_id, area_nombre y area_manager_id (las tiendas tendran una columna area_id)
-- Nos quedamos con una fila por area, la mas reciente segun date_load
-- =============================================================================

with estructura as (
    select * from {{ ref('stg_comercial__estructura_comercial') }}
),

final as (
    select
        area_id
        , area_nombre
        , area_manager_id
    from estructura
    qualify row_number() over (partition by area_id order by date_load desc) = 1
)

select * from final