--===================================================================================================
--slv_producto__capsula 
--===================================================================================================
-- Relacion 1:N con producto (Una capsula tiene muchos productos, un producto una sola capsula)
-- Relacion N:1 con temporada (Una capsula tiene una sola temporada, una temporada tiene muchas capsulas)
-- Id_capsula, nombre, id_temporada, código 
--====================================================================================================
with productos as (
    select * from {{ ref('stg_catalogo__productos') }}
),

capsulas as (
    select
        capsula_id
        ,capsula_nombre
        ,capsula_codigo
        ,temporada_id
        , date_load
    from productos
    where capsula_id is not null
    qualify row_number() over (partition by capsula_id order by date_load desc) = 1
)

select * from capsulas
