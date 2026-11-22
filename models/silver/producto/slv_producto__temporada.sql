-- =============================================================================
-- slv_producto__temporada
-- =============================================================================
-- Un fila por temporada (FW25-26, SS26, FW26-27)
-- Relacion 1:N con producto (Una temporada tiene muchos productos, cada producto es de una sola temporada)
-- Relación 1:N con Capsula (Una temporada tiene varias capsulas, cada capsula es de una sola temporada)
-- Temporada_id, tipo, nombre, año inicio, fecha_inicio, fecha_fin
-- =============================================================================

with productos as (
    select * from {{ ref('stg_catalogo__productos') }}
),

temporadas as (
    select
        temporada_id
        , left(temporada_id, 2)                                    as tipo  --FW o SS
        , 2000 + to_number(substr(temporada_id, 3, 2))             as anio_inicio  --2000 + 25 = 2025
        , date_load
    from productos
    qualify row_number() over (partition by temporada_id order by date_load desc) = 1
),

final as (
    select
        temporada_id
        , tipo
        , case
              when tipo = 'FW' then 'Fall-Winter '
              when tipo = 'SS' then 'Spring-Summer '
          end || '20' || substr(temporada_id, 3)                   as temporada_nombre  --ej: Fall-Winter2026
        , anio_inicio
        , case
              when tipo = 'FW' then to_date(anio_inicio || '-09-01')
              when tipo = 'SS' then to_date(anio_inicio || '-03-01')
          end                                                      as fecha_inicio_venta  --FW siempre sept a feb y SS de marz a agos
        , case
              when tipo = 'FW' then last_day(to_date((anio_inicio + 1) || '-02-01'))
              when tipo = 'SS' then to_date(anio_inicio || '-08-31')
          end                                                      as fecha_fin_venta 
        , date_load
    from temporadas
)

select * from final