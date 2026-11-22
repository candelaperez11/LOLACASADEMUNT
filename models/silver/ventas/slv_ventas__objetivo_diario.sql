--==========================================================
--slv_ventas__objetivo_diario
--==========================================================
--Relacion N:1 con tiendas (Una tienda tiene muchos objetivos, uno por cada día, y cada objetivo es de una sola tienda)
--Tienda_id, fecha, objetivo_venta_neta
--Los dias con dos objetivos ya se resolvieron en staging
--==========================================================

with objetivos as (
    select * from {{ ref('stg_comercial__objetivos_tienda_dia') }}
),

final as (
    select
          objetivo_id
        , tienda_id
        , fecha
        , objetivo_venta_neta
        , date_load
    from objetivos
    qualify row_number() over (partition by objetivo_id order by date_load desc) = 1
)

select * from final