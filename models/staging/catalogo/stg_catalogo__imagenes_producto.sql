-- =============================================================================
-- stg_catalogo__imagenes_producto
--
-- Simplemente renombrar columnas no hace falta limpiado en esta capa para este source
-- =============================================================================

with source as (
    select * from {{ source('catalogo', 'imagenes_producto') }}
),

renamed as (
    select
        upper(replace(trim(referencia), '.', '_'))     as referencia
        , image_data_uri                               as imagen_data_uri
        , _loaded_at                                   as date_load
    from source
)

select * from renamed
qualify row_number() over (partition by referencia order by date_load desc) = 1
