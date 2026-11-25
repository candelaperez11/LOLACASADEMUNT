-- =============================================================================
-- stg_comercial__vendedores
-- =============================================================================
-- Vendedores de las tiendas (maestro de personal). Contiene datos personales
-- Nombre y puesto a veces en MAYUSCULAS: mayuscula inicial
-- Horas semanales de texto a numero
-- Una fila por vendedor
-- =============================================================================

with source as (
    select * from {{ source('comercial', 'vendedores') }}
),

renamed as (
    select
          upper(trim(vendedor_id))                                       as vendedor_id
        , upper(trim(tienda_id))                                         as tienda_id
        , initcap(trim(nombre))                                          as nombre
        , trim(apellidos)                                                as apellidos
        , try_to_date(trim(fecha_alta), 'YYYY-MM-DD')                    as fecha_alta
        , initcap(trim(puesto))                                          as puesto
        , try_to_number(trim(horas_semanales))                           as horas_semanales
        , _loaded_at                                                     as date_load
    from source
)

select * from renamed
qualify row_number() over (partition by vendedor_id order by date_load desc) = 1