-- =============================================================================
-- stg_tpv__tickets
-- =============================================================================
-- Cada ticket viene en un JSON, sacamos cada campo a su columna con raw:campo::varchar
-- tienda_id mal escrito (4f011l o 4F011L) los pasamos todos a 4-F011L
-- Fechas a formato date
-- Importe 106,50 = 106.50
-- 4 unicos valores para forma de pago (no relevante para los casos de uso)
-- Cliente vacío, 0 o SIN CLIENTE lo dejamos en null
-- Canal no existe antes de julio 2026, ponemos TIENDA
-- Calculamos la franja de 30 min del ticket (10:47 = 1030) para cruzar con el seed
-- Quitamos tickets de prueba TEST- y tienda 4-F999L (no eciste) y los duplicados por reenvío
-- Las lineas se quedan en la columna lineas y las separamos en stg_tpv__lineas_ticket
-- =============================================================================

with source as (
    select * from {{ source('tpv', 'tickets') }}
),

renamed as (
    select
          trim(raw:id_ticket::varchar)                                   as ticket_id
        , upper(trim(raw:tipo::varchar))                                 as tipo_ticket
        , nullif(trim(raw:id_ticket_origen::varchar), '')                as ticket_origen_id  --solo lo tienen las devoluciones
        , regexp_replace(upper(trim(raw:tienda_id::varchar)), '^4-?', '4-') as tienda_id
        , coalesce(try_to_date(raw:fecha::varchar, 'YYYY-MM-DD'),
                   try_to_date(raw:fecha::varchar, 'DD/MM/YYYY'))        as fecha
        , try_to_time(raw:hora::varchar)                                 as hora
        , upper(trim(raw:vendedor_id::varchar))                          as vendedor_id
        , case
              when upper(trim(raw:cliente_id::varchar)) in ('', '0', 'SIN CLIENTE') then null
              else upper(trim(raw:cliente_id::varchar))
          end                                                            as cliente_id
        , case
              when upper(trim(raw:forma_pago::varchar)) in ('TARJETA', 'CARD', 'VISA') then 'TARJETA'
              when upper(trim(raw:forma_pago::varchar)) in ('EFECTIVO', 'CASH')        then 'EFECTIVO'
              when upper(trim(raw:forma_pago::varchar)) in ('TARJETA REGALO', 'TARJETA_REGALO')
                                                                                       then 'TARJETA_REGALO'
              else upper(trim(raw:forma_pago::varchar))
          end                                                            as forma_pago
        , try_to_number(replace(raw:importe_total::varchar, ',', '.'), 12, 2) as importe_total
        , coalesce(upper(trim(raw:canal::varchar)), 'TIENDA')            as canal
        , raw:lineas                                                     as lineas
        , array_size(raw:lineas)                                         as num_lineas
        , _source_file                                                   as source_file
        , _source_row_number                                             as source_row_number
        , _loaded_at                                                     as date_load
    from source
),

final as (
    select
          *
        , to_varchar(hora, 'HH24') || iff(minute(hora) < 30, '00', '30') as franja_id  --necesitamos para las franjas de seed (redondeo)
    from renamed
    where ticket_id not like 'TEST-%'
      and tienda_id <> '4-F999L'
)

select * from final
qualify row_number() over (
    partition by ticket_id
    order by date_load desc, source_file desc, source_row_number desc
) = 1
