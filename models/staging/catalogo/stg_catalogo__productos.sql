-- =============================================================================
-- stg_catalogo__productos
-- =============================================================================
-- Añadir nuevas columnas,  marca (L = Lola y M = Maite) y código familia (digitos 5-6), a partir de la referencia del artículo.
-- Pasar precios a número en vez de varchar
-- Añadir un booleano para localizar las referencias del 45 aniversario, estas contienen 45a al final del nombre
-- Hay unas caapsulas Resort de transicion sin codigo, por ello usamos el nombre como codigo
-- Generar capsula_id con temporada_id y capsula_codigo (no puede ser unico este porque se repiten en temporadas diferente)
-- =============================================================================

with source as (
    select * from {{ source('catalogo', 'productos') }}
),

renamed as (
    select
        upper(replace(trim(referencia), '.', '_'))                       as referencia
        , left(upper(trim(referencia)), 1)                               as marca_id          --M O L
        , substr(trim(referencia), 5, 2)                                 as codigo_familia    --SEED familias_agregadas
        , upper(trim(temporada))                                         as temporada_id
        , coalesce(nullif(upper(trim(capsula_codigo)), ''),
           nullif(upper(trim(capsula_nombre)), ''))                      as capsula_codigo   -- código, o el nombre si no hay código
        , nullif(trim(capsula_nombre), '')                               as capsula_nombre   
        , nullif(trim(subcapsula), '')                                   as subcapsula
        , case
              when upper(trim(nombre)) like '%45A'
                  then trim(left(trim(nombre), length(trim(nombre)) - 3))
              else trim(nombre)
          end                                                            as producto_nombre
        , upper(trim(nombre)) like '%45A'                                as es_45_aniversario  --nuevo para saber si pertenece o no al 45 aniversario
        , case
           when upper(trim(nombre_en)) like '%45A'
                then trim(left(trim(nombre_en), length(trim(nombre_en)) - 3))
            else trim(nombre_en)
            end                                                            as producto_nombre_en
        , trim(subfamilia)                                                 as subfamilia
        , coalesce(try_to_date(trim(fecha_entrada), 'YYYY-MM-DD'),
                   try_to_date(trim(fecha_entrada), 'DD/MM/YYYY'))       as fecha_entrada   --texto a fecha
        , trim(rango_tallas)                                             as rango_tallas
        , try_to_number(replace(replace(replace(trim(pvp_es),  '€', ''), ' ', ''), ',', '.'), 10, 2) as pvp_es 
        , try_to_number(replace(replace(replace(trim(pvp_and), '€', ''), ' ', ''), ',', '.'), 10, 2) as pvp_and
        , trim(color)                                                    as color
        , trim(descripcion)                                              as descripcion
        , trim(composicion)                                              as composicion
        , trim(catalogo)                                                 as catalogo
        , _loaded_at                                                     as date_load
    from source
), 
final as (
    select
        *
        , case
            when capsula_codigo is not null
                then {{ dbt_utils.generate_surrogate_key(['temporada_id', 'capsula_codigo']) }}
          end                                                            as capsula_id
    from renamed
)

select *
    from final
qualify row_number() over (partition by referencia order by date_load desc) = 1