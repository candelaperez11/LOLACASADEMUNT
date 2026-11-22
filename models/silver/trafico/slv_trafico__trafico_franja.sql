-- =============================================================================
-- slv_trafico__trafico_franja
-- =============================================================================
-- Una fila por tienda, dia y franja de 30 minutos
-- Relacion N:1 con Tienda y N:1 con Franja horaria (seed franjas_horarias)
-- Une las dos fuentes del contador de personas:
--   · historico: export mensual, venia en formato ancho (UNPIVOT en staging)
--   · tiempo real: lotes de 30 minutos que llegan durante el dia
-- En staging hay una fila por kpi; aqui ponemos entradas y trafico exterior en
-- columnas, en la misma fila
-- personas nulo = fallo del sensor ("Sin datos" o negativo), marcado en hay_incidencia
-- =============================================================================

with historico as (
    select * from {{ ref('stg_contador__trafico_franjas') }}
),

tiempo_real as (
    select * from {{ ref('stg_contador__trafico_tiempo_real') }}
),

-- 1. Juntamos las dos fuentes (tienen las mismas columnas)
unidas as (
    select tienda_id, fecha, franja_id, kpi, personas, es_incidencia, origen, date_load
    from historico

    union all

    select tienda_id, fecha, franja_id, kpi, personas, es_incidencia, origen, date_load
    from tiempo_real
),

-- 2. Si un dato llegara por las dos fuentes, nos quedamos con el mas reciente
sin_duplicados as (
    select *
    from unidas
    qualify row_number() over (
        partition by tienda_id, fecha, franja_id, kpi
        order by date_load desc
    ) = 1
),

-- 3. Una fila por tienda, dia y franja, con un kpi en cada columna
final as (
    select
          {{ dbt_utils.generate_surrogate_key(['tienda_id', 'fecha', 'franja_id']) }} as trafico_franja_id
        , tienda_id
        , fecha
        , franja_id
        , sum(case when kpi = 'ENTRADAS'         then personas end)   as entradas
        , sum(case when kpi = 'TRAFICO_EXTERIOR' then personas end)   as trafico_exterior
        , boolor_agg(es_incidencia)                                   as hay_incidencia
        , max(origen)                                                 as origen
        , max(date_load)                                              as date_load
    from sin_duplicados
    group by tienda_id, fecha, franja_id
)

select * from final