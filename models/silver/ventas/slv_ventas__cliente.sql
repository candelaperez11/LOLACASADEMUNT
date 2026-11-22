--====================================================================
--slv_ventas__cliente
--====================================================================
--Relacion 1:N con Ticket (Un cliente puede aparecer en tickets diferentes, cada ticket es de un solo cliente)
--cliente_id
--==============================================================================================================

with tickets as (
    select * from {{ ref('stg_tpv__tickets') }}
),

final as (
    select
        cliente_id
        , date_load
    from tickets
    where cliente_id is not null
    qualify row_number() over (partition by cliente_id order by date_load desc) = 1
)

select * from final