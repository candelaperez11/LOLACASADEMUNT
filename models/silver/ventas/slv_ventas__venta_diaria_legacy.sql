-- =============================================================================
-- slv_ventas__venta_diaria_legacy
-- =============================================================================
-- Una fila por tienda y dia, del TPV antiguo (16/11/2024 - 15/11/2025)
-- Sirve para comparar con el año anterior
-- Relacion N:1 con Tienda
-- El TPV antiguo no traia el codigo de la tienda, solo el nombre: lo cruzamos con
-- las tiendas por el nombre en mayusculas para sacar el tienda_id
-- Usamos left join: si algun nombre no cruza, su tienda_id queda nulo y el test
-- not_null nos avisa (asi no perdemos ventas sin enterarnos)
-- Quitamos el nombre porque ya esta en Tienda (3FN)
-- =============================================================================

with ventas as (
    select * from {{ ref('stg_tpv__ventas_diarias_legacy') }}
),

tiendas as (
    select * from {{ ref('slv_red_comercial__tienda') }}
),

final as (
    select
          {{ dbt_utils.generate_surrogate_key(['t.tienda_id', 'v.fecha']) }}  as venta_diaria_id
        , t.tienda_id
        , v.fecha
        , v.num_tickets
        , v.unidades
        , v.venta_bruta
        , v.num_devoluciones
        , v.importe_devoluciones
        , v.venta_neta
        , v.date_load
    from ventas v
    left join tiendas t
        on replace(v.tienda_nombre_normalizado, 'LC ', '') = replace(upper(t.tienda_nombre), 'LC ', '')  --errores con corner ECi en algunos tickets
    qualify row_number() over (partition by t.tienda_id, v.fecha order by v.date_load desc) = 1
)

select * from final