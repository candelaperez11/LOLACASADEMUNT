--====================================================================
--slv_ventas__cliente
--====================================================================
--Relacion 1:N con Ticket (Un cliente puede aparecer en tickets diferentes, cada ticket es de un solo cliente)
--cliente_id
--==============================================================================================================

with clientes as (
    select * from {{ ref('stg_comercial__clientes') }}
),

final as (
    select
          cliente_id
        , nombre
        , apellidos
        , email
        , telefono
        , fecha_nacimiento
        , fecha_alta
        , acepta_comunicaciones
    from clientes
    qualify row_number() over (partition by cliente_id order by date_load desc) = 1
)

select * from final