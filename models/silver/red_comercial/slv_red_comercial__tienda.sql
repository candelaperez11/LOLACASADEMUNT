-- =============================================================================
-- slv_red_comercial__tienda
-- =============================================================================
-- CHUNGA
-- Una fila por tienda 
-- Relacion N:1 con Provincia (seed provincias), y a traves de ella con Comunidad
-- Relacion N:1 con Area (sale de la estructura comercial)
-- Relacion N:1 con Formato de tienda (seed formatos_tienda: tipo + seccion)
-- Relacion 1:N con Vendedor, Ticket, Objetivo diario y Trafico
-- tienda_id, provincia_id, area_id, formato_id, nombre, es_franquicia, ubicacion, direccion, codigo_postal
-- ciudad, telefono, m2, num_muebles, hora_apertura, hora_cierre, abre_domingo, tiene_contador
-- fecha_apertura, fecha_cierre
-- =============================================================================

with tiendas as (
    select * from {{ ref('stg_comercial__tiendas') }}
),

estructura as (
    select * from {{ ref('stg_comercial__estructura_comercial') }}
),

provincias as (
    select * from {{ ref('provincias') }}
),

formatos as (
    select * from {{ ref('formatos_tienda') }}
),

final as (
    select
        t.tienda_id
        , t.tienda_nombre
        , e.area_id
        , f.formato_id
        , p.provincia_id
        , t.es_franquicia
        , t.ubicacion
        , t.direccion
        , t.codigo_postal
        , t.ciudad
        , t.telefono
        , t.m2
        , t.num_muebles
        , t.hora_apertura
        , t.hora_cierre
        , t.abre_domingo
        , t.tiene_contador
        , t.fecha_apertura
        , t.fecha_cierre
        , t.date_load
    from tiendas t
    left join provincias p
        on t.provincia = p.provincia
    left join estructura e
        on t.tienda_id = e.tienda_id
    left join formatos f
        on  t.tipo_tienda = f.tipo_tienda
        and t.seccion     = f.seccion
    qualify row_number() over (partition by t.tienda_id order by t.date_load desc) = 1
)

select * from final