-- =============================================================================
-- dim_tienda
-- =============================================================================
-- Dimension tienda: una fila por tienda (tambien las cerradas, por el historico)
-- Aplana la red comercial de Silver en una sola tabla para Power BI:
--   tienda + area + area manager + formato + provincia + comunidad
-- Asi se puede filtrar por area manager, comunidad o formato con un solo filtro
-- La geografia va en su propio CTE: si se añade la entidad Ciudad, solo cambia ese bloque
-- =============================================================================

with tiendas as (
    select * from {{ ref('slv_red_comercial__tienda') }}
),

areas as (
    select * from {{ ref('slv_red_comercial__area') }}
),

area_managers as (
    select * from {{ ref('slv_red_comercial__area_manager') }}
),

formatos as (
    select * from {{ ref('formatos_tienda') }}
),

-- Provincia con su comunidad y su pais
geografia as (
    select
          p.provincia_id
        , p.provincia
        , c.comunidad_id
        , c.comunidad_autonoma
        , c.pais
    from {{ ref('provincias') }} p
    left join {{ ref('comunidades_autonomas') }} c
        on p.comunidad_id = c.comunidad_id
),

final as (
    select
          t.tienda_id
        , t.tienda_nombre
        -- Formato
        , t.formato_id
        , f.formato
        , f.tipo_tienda
        , f.seccion
        -- Red comercial
        , t.area_id
        , a.area_nombre
        , a.area_manager_id
        , am.area_manager_nombre
        -- Geografia
        , g.pais
        , g.comunidad_id
        , g.comunidad_autonoma
        , g.provincia_id
        , g.provincia
        , t.ciudad
        , t.codigo_postal
        , t.direccion
        -- Caracteristicas de la tienda
        , t.ubicacion
        , t.es_franquicia
        , t.m2
        , t.num_muebles
        , t.telefono
        , t.hora_apertura
        , t.hora_cierre
        , t.abre_domingo
        , t.tiene_contador
        , t.fecha_apertura
        , t.fecha_cierre
        , t.fecha_cierre is null                                       as esta_abierta
    from tiendas t
    left join areas a
        on t.area_id = a.area_id
    left join area_managers am
        on a.area_manager_id = am.area_manager_id
    left join formatos f
        on t.formato_id = f.formato_id
    left join geografia g
        on t.provincia_id = g.provincia_id
)

select * from final