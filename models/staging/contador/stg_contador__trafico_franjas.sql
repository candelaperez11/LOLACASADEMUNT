-- =============================================================================
-- stg_contador__trafico_franjas
-- =============================================================================
-- Fecha a date
-- Dar nombre a KPIs:  ENT = ENTRADAS y Ext = TRAFICO_EXTERIOR
-- Si no hay datos o negativo = incidencia, 0 es válido (no entra nadie o no pasa nadie por fuera)
-- De 10:00 pasar a 1000 como id franja horaria (seed)
-- UNPIVOTED para pasar columnas tipo dato a filas y bucle jinja para no tener que escirbir los nombre de todas las filas
-- =============================================================================

with source as (
    select * from {{ source('contador', 'trafico_franjas') }}
),

unpivoted as (
    select *
    from source
        unpivot include nulls (valor for franja in (
            {%- for h in range(9, 23) %}
                {%- for m in ['00', '30'] %}
            f_{{ '%02d' % h }}{{ m }}{{ ',' if not (h == 22 and m == '30') }}
                {%- endfor %}
            {%- endfor %}
        ))
),

renamed as (
    select
          upper(trim(sfid))                                              as tienda_id
        , trim(tienda)                                                   as tienda_nombre
        , coalesce(try_to_date(trim(fecha), 'YYYY-MM-DD'),
                   try_to_date(trim(fecha), 'DD/MM/YYYY'))               as fecha
        , case
              when upper(trim(kpi)) like '(ENT)%' then 'ENTRADAS'
              when upper(trim(kpi)) like '(EXT)%' then 'TRAFICO_EXTERIOR'
          end                                                            as kpi
        , replace(upper(franja), 'F_', '')                               as franja_id
        , case
              when nullif(trim(valor), '') is null              then 0
              when try_to_number(trim(valor)) < 0               then null
              else try_to_number(trim(valor))
          end                                                            as personas
        , nullif(trim(valor), '') is not null
          and coalesce(try_to_number(trim(valor)), -1) < 0               as es_incidencia
        , 'HISTORICO'                                                    as origen
        , _source_file                                                   as source_file
        , _loaded_at                                                     as date_load
    from unpivoted
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['tienda_id', 'fecha', 'kpi', 'franja_id']) }} as trafico_id
        , *
    from renamed
)

select * from final
qualify row_number() over (partition by trafico_id order by date_load desc, source_file desc) = 1
