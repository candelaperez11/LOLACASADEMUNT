-- =============================================================================
-- dim_producto
-- =============================================================================
-- Dimension producto: una fila por referencia
-- Aplana el catalogo de Silver en una sola tabla para Power BI:
--   producto + marca + temporada + capsula + familia (seed familias_agregadas)
-- Los productos sin capsula (accesorios) salen como "Sin capsula", para que
-- aparezcan como un grupo mas en los graficos por capsula
-- =============================================================================

with productos as (
    select * from {{ ref('slv_producto__producto') }}
),

marcas as (
    select * from {{ ref('slv_producto__marca') }}
),

temporadas as (
    select * from {{ ref('slv_producto__temporada') }}
),

capsulas as (
    select * from {{ ref('slv_producto__capsula') }}
),

familias as (
    select * from {{ ref('familias_agregadas') }}
),

final as (
    select
          p.referencia
        , p.producto_nombre
        , p.producto_nombre_en
        , p.marca_id 
        , m.marca_nombre  --para lector externo entenderlo mejor
        , p.temporada_id 
        , coalesce(c.capsula_nombre, c.capsula_codigo, 'Sin cápsula')         as capsula
        , f.familia_agregada                                                  as familia
        , f.categoria
        , p.es_45_aniversario
        , p.pvp_es
        , p.pvp_and
        , p.es_precio_imputado
        , p.imagen
    from productos p
    left join marcas m
        on p.marca_id = m.marca_id
    left join temporadas t
        on p.temporada_id = t.temporada_id
    left join capsulas c
        on p.capsula_id = c.capsula_id
    left join familias f
        on p.codigo_familia = f.codigo_familia
)

select * from final