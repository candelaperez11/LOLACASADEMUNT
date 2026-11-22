-- =============================================================================
-- stg_comercial__objetivos_tienda_dia
-- =============================================================================
-- Fecha a date.
-- Hay días con 2 objetivos, nos queddmaos con el último
-- Quitar K que equivale a miles en lgunos de los formatos de entrada del objetivo neto
-- =============================================================================

with source as (
    select * from {{ source('comercial', 'objetivos_tienda_dia') }}
),

renamed as (
    select
        upper(trim(tienda_id))                                           as tienda_id
        , try_to_date(trim(fecha), 'YYYYMMDD')                           as fecha
        , case
              when upper(trim(objetivo_venta_neta)) like '%K'
                  then try_to_number(replace(replace(upper(trim(objetivo_venta_neta)), 'K', ''), ',', '.'), 12, 2) * 1000
              else try_to_number(replace(trim(objetivo_venta_neta), ',', '.'), 12, 2)
          end                                                            as objetivo_venta_neta  --Quitar K
        , _loaded_at                                                     as date_load
    from source
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['tienda_id', 'fecha']) }}   as objetivo_id            
        , *
    from renamed
)

select * from final
qualify row_number() over (partition by objetivo_id order by objetivo_venta_neta desc) = 1
