-- =============================================================================
-- slv_producto__marca
-- =============================================================================
-- Entidad 1:N con producto (Misma marca puede estar en productos diferentes pero cada prod unica marca)
-- Tiene marca_id y nombre (podría añadir descripción)
-- =============================================================================

with productos as (
    select * from {{ ref('stg_catalogo__productos') }}
),

final as (
    select
        marca_id
        , case
            when marca_id = 'L'
                then 'Lola Casademunt'
            when marca_id = 'M' 
                then 'Maite Casademunt' 
            end                        as marca_nombre 
        , date_load
    from productos
    qualify row_number() over (partition by marca_id order by date_load desc) = 1
)

select * from final