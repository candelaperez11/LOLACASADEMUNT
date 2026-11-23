-- =============================================================================
-- dim_tienda
-- =============================================================================
-- Dimension tienda: una fila por tienda (HISTORICO TAMB)
-- Red comercial de Silver en una sola tabla para Power BI:
--  tienda + area + area manager + formato + provincia + comunidad
-- Asi se puede filtrar por area manager, comunidad o formato con un solo filtro
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

provincias as (
    select * from {{ ref('provincias') }}
),

comunidades as (
    select * from {{ ref('comunidades_autonomas') }}
),

--Para poder filtrar en powerbi por provincia, comunidad (caso uso 3)
geografia as (
    select
          p.provincia_id
        , p.provincia
        , c.comunidad_id
        , c.comunidad_autonoma
        , c.pais
    from provincias p
    left join comunidades c
        on p.comunidad_id = c.comunidad_id
),

final as (
    select
          t.tienda_id
        , t.tienda_nombre
        , f.formato
        , a.area_nombre
        , am.area_manager_nombre
        , g.pais 
        , g.comunidad_autonoma
        , g.provincia
        , t.ciudad
        --ubicacion?? 
        , t.es_franquicia  
        , t.num_muebles
        , t.tiene_contador
        , t.fecha_apertura
        , t.fecha_cierre
        , t.fecha_cierre is null                                       as esta_abierta
        , t.fecha_apertura <= '2025-11-16'
          and t.fecha_cierre is null                                   as es_comparable  --abierta todo el año anterior y sigue abierta
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