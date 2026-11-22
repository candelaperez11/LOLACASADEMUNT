-- =============================================================================
-- stg_comercial__estructura_comercial
-- =============================================================================
-- Códigos en mayúsculas y nombre de area manager con INITCAP. 
-- =============================================================================

with source as (
    select * from {{ source('comercial', 'estructura_comercial') }}
),

renamed as (
    select
          upper(trim(tienda_id))                     as tienda_id
        , upper(trim(area_id))                       as area_id
        , trim(area)                                 as area_nombre
        , upper(trim(area_manager_id))               as area_manager_id
        , initcap(trim(area_manager))                as area_manager_nombre
        , _loaded_at                                 as date_load
    from source
)

select * from renamed
qualify row_number() over (partition by tienda_id order by date_load desc) = 1
