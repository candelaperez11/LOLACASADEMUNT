-- =============================================================================
-- slv_red_comercial__area_manager
-- =============================================================================
-- Entidad 1:N con Area
-- Contiene el id y nombre (podría incluir correo si tuvieramos mas datos pero no es el caso) 
-- =============================================================================

with estructura as (
    select * from {{ ref('stg_comercial__estructura_comercial') }}
),

final as (
    select
        area_manager_id
        , area_manager_nombre
        , date_load
    from estructura
    qualify row_number() over (partition by area_manager_id order by date_load desc) = 1
)

select * from final