-- =============================================================================
-- slv_producto__producto
-- =============================================================================
-- Una fila por producto 
-- Relacion N:1 con Familia_agregada (seed familias_agregadas)
-- Relacion N:1 con Temporada 
-- Relacion N:1 con Capsula, cada producto pertenece a una capsula
-- Relacion N:1 con Marca, cada producto pertenece a una marca, muchos productos pueden pertenerce a la misma
-- Relacion 1:N con Linea de tickets (no se puede directo a tickets porque era N:M)
-- =============================================================================

with productos as (
    select * from {{ ref('stg_catalogo__productos') }}
),

familias as (
    select * from {{ ref('familias_agregadas') }}
),

imagenes as (
    select * from {{ ref('stg_catalogo__imagenes_producto') }}
),

juntarlas as (
    select
          p.*
        , f.categoria
        , i.imagen_data_uri
        ,round(median(p.pvp_es)  over (partition by p.codigo_familia), 2)    as mediana_pvp_es_familia  --FW25-26 no tiene precio, en vez de null relleno con mediana
        ,round(median(p.pvp_and) over (partition by p.codigo_familia), 2)    as mediana_pvp_and_familia
    from productos p
    left join familias f
        on p.codigo_familia = f.codigo_familia
    left join imagenes i
        on p.referencia = i.referencia
),

final as (
    select
          referencia
        , marca_id
        , temporada_id
        , codigo_familia
        , case
              when categoria = 'Accesorio' then null
              else capsula_id
          end                                                           as capsula_id  --los accesorios no pertenecen a capsulas
        , producto_nombre
        , producto_nombre_en
        , descripcion
        , subfamilia
        , subcapsula
        , color
        , rango_tallas
        , composicion
        , es_45_aniversario
        , coalesce(pvp_es,  mediana_pvp_es_familia)                     as pvp_es   --si no hay precio rellenamos con mediana
        , coalesce(pvp_and, mediana_pvp_and_familia)                    as pvp_and  --igual que arriba
        , pvp_es is null                                                as es_precio_imputado  --para reconocer donde hemos añadido mediana y donde no
        , fecha_entrada
        , imagen_data_uri                                               as imagen
    from juntarlas
    qualify row_number() over (partition by referencia order by date_load desc) = 1
)

select * from final