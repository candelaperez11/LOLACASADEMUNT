-- =============================================================================
-- dim_franja
-- =============================================================================
-- Dimension franja: una fila por franja de 30 minutos (09:00 a 23:00)
-- Sale del seed franjas_horarias. La comparten las ventas y el trafico,
-- asi se pueden poner en el mismo grafico por franja (pagina hora a hora)
-- =============================================================================

with franjas as (
    select * from {{ ref('franjas_horarias') }}
),

final as (
    select
          franja_id
        , hora_inicio
        , hora_fin
        , to_varchar(hora_inicio, 'HH24:MI') || ' – '
          || to_varchar(hora_fin, 'HH24:MI')                     as franja_etiqueta   --"10:00 – 10:30"
        , to_varchar(hora_inicio, 'HH24:MI')                     as hora_etiqueta     --"10:00", para el eje del grafico
        , periodo
        , orden                                                  --para ordenar en Power BI
    from franjas
)

select * from final