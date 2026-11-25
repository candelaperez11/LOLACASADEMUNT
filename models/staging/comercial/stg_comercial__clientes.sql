-- =============================================================================
-- stg_comercial__clientes
-- =============================================================================
-- Clientes del CRM. Contiene datos personales: no se exponen en Gold
-- Nombre sin espacios y con mayuscula inicial, email en minusculas
-- Telefono en formatos distintos lo pasamos a +34...
-- Fecha de nacimiento en dos formatos, probamos los dos
-- Consentimiento de marketing (SI, Si, 1, NO, 0...) a booleano;
-- si viene vacio es false: sin consentimiento explicito no se puede usar (RGPD)
-- Quitamos las fichas repetidas: una por cliente
-- =============================================================================

with source as (
    select * from {{ source('comercial', 'clientes') }}
),

renamed as (
    select
          upper(trim(cliente_id))                                        as cliente_id
        , initcap(trim(nombre))                                          as nombre
        , trim(apellidos)                                                as apellidos
        , nullif(lower(trim(email)), '')                                 as email
        , {{ normalizar_telefono('telefono') }}                          as telefono                                                          
        , coalesce(try_to_date(trim(fecha_nacimiento), 'DD/MM/YYYY'),
                   try_to_date(trim(fecha_nacimiento), 'YYYY-MM-DD'))    as fecha_nacimiento
        , try_to_date(trim(fecha_alta), 'YYYY-MM-DD')                    as fecha_alta
        , case
              when upper(trim(acepta_comunicaciones)) in ('SI', 'SÍ', '1') then true
              else false
          end                                                            as acepta_comunicaciones
        , _loaded_at                                                     as date_load
    from source
)

select * from renamed
qualify row_number() over (partition by cliente_id order by date_load desc) = 1