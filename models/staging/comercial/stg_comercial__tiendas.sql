-- =============================================================================
-- stg_comercial__tiendas
-- =============================================================================
-- Deduplicados, Jorge Juan aprece 2 veces por reforma, nos quedamos última
-- Comunidad_autonoma escrita de varias formas, nombre oficial del seed.
--   · m2 con texto ("95 m2") -> número; hora_cierre "21h" -> 21:00.
--   · fecha_apertura en dd/mm/aaaa -> date.
--   · Teléfono en varios formatos -> E.164 (+34...).

-- =============================================================================

with source as (
    select * from {{ source('comercial', 'tiendas') }}
),

renamed as (
    select
          upper(trim(tienda_id))                                    as tienda_id
        , trim(nombre)                                              as tienda_nombre
        , upper(trim(tipo_tienda))                                  as tipo_tienda
        , initcap(trim(seccion))                                    as seccion
        , try_to_boolean(trim(es_franquicia))                       as es_franquicia
        , trim(ubicacion)                                           as ubicacion
        , trim(direccion)                                           as direccion
        , trim(codigo_postal)                                       as codigo_postal
        , trim(ciudad)                                              as ciudad
        , trim(provincia)                                           as provincia
        , case
              when upper(trim(comunidad_autonoma)) in ('CATALUÑA', 'CATALUNYA', 'CATALUNA')
                  then 'Cataluña'
              when upper(trim(comunidad_autonoma)) in ('ANDALUCÍA', 'ANDALUCIA')
                  then 'Andalucía'
              when upper(trim(comunidad_autonoma)) in ('MADRID', 'COMUNIDAD DE MADRID')
                  then 'Comunidad de Madrid'
              when upper(trim(comunidad_autonoma)) in ('COMUNITAT VALENCIANA', 'C. VALENCIANA', 'COMUNIDAD VALENCIANA')
                  then 'Comunidad Valenciana'
              else trim(comunidad_autonoma)
          end                                                       as comunidad_autonoma
        , trim(pais)                                                as pais
        , {{ normalizar_telefono('telefono') }}                     as telefono  --solo digitos y prefijo +34 (macro)
        , try_to_number(trim(replace(lower(m2), 'm2', '')))         as m2
        , num_muebles                                               
        , try_to_time(replace(trim(hora_apertura), 'h', ':00'))      as hora_apertura
        , try_to_time(replace(trim(hora_cierre), 'h', ':00'))        as hora_cierre
        , case
              when upper(trim(abre_domingo)) in ('SÍ', 'SI', '1', 'TRUE')  then true
              else false
          end                                                       as abre_domingo
        , try_to_boolean(trim(tiene_contador))                      as tiene_contador
        , coalesce(try_to_date(trim(fecha_apertura), 'DD/MM/YYYY'),
                   try_to_date(trim(fecha_apertura), 'YYYY-MM-DD')) as fecha_apertura
        , coalesce(try_to_date(trim(fecha_cierre), 'DD/MM/YYYY'),
                   try_to_date(trim(fecha_cierre), 'YYYY-MM-DD'))   as fecha_cierre
        , _loaded_at                                                as date_load
    from source
)

select * from renamed
qualify row_number() over (partition by tienda_id order by date_load desc, m2 desc) = 1
