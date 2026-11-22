-- =============================================================================
-- fct_venta_diaria_tienda
-- =============================================================================
-- Hecho venta diaria: una fila por tienda y dia (grano tienda + dia)
-- Une las dos fuentes de venta con las mismas columnas y definiciones:
--   · TPV nuevo (desde 16/11/2025): sumamos los tickets por tienda y dia
--   · TPV antiguo / legacy (hasta 15/11/2025): ya viene por tienda y dia
-- Asi se puede comparar con el año anterior desde una sola tabla
-- Definiciones (iguales en las dos fuentes):
--   venta_bruta          = lo vendido (tickets de VENTA)
--   importe_devoluciones = lo devuelto (en positivo)
--   venta_neta           = venta_bruta - importe_devoluciones
--   num_tickets          = tickets de venta (las devoluciones no cuentan)
--   unidades             = unidades de producto vendidas (sin la bolsa)
-- Los ratios (ticket medio, UPT...) se calculan en Power BI
-- =============================================================================

with tickets as (
    select * from {{ ref('slv_ventas__ticket') }}
),

lineas as (
    select * from {{ ref('slv_ventas__linea_ticket') }}
),

legacy as (
    select * from {{ ref('slv_ventas__venta_diaria_legacy') }}
),

-- 1. TPV nuevo: importes y tickets por tienda y dia
tpv_nuevo_importes as (
    select
          tienda_id
        , fecha
        , sum(case when tipo_ticket = 'VENTA'      then importe_total else 0 end)  as venta_bruta
        , -sum(case when tipo_ticket = 'DEVOLUCION' then importe_total else 0 end) as importe_devoluciones
        , count_if(tipo_ticket = 'VENTA')                                          as num_tickets
        , count_if(tipo_ticket = 'DEVOLUCION')                                     as num_devoluciones
    from tickets
    group by tienda_id, fecha
),

-- 2. TPV nuevo: unidades de producto vendidas por tienda y dia
tpv_nuevo_unidades as (
    select
          t.tienda_id
        , t.fecha
        , sum(l.unidades)                                                          as unidades
    from tickets t
    join lineas l
        on l.ticket_id = t.ticket_id
    where t.tipo_ticket = 'VENTA'
      and l.tipo_linea  = 'PRODUCTO'
    group by t.tienda_id, t.fecha
),

-- 3. TPV nuevo completo
tpv_nuevo as (
    select
          i.tienda_id
        , i.fecha
        , i.num_tickets
        , coalesce(u.unidades, 0)                                                  as unidades
        , i.venta_bruta
        , i.num_devoluciones
        , i.importe_devoluciones
        , i.venta_bruta - i.importe_devoluciones                                   as venta_neta
        , 'TPV_NUEVO'                                                              as origen
    from tpv_nuevo_importes i
    left join tpv_nuevo_unidades u
        on  i.tienda_id = u.tienda_id
        and i.fecha     = u.fecha
),

-- 4. TPV antiguo, con las mismas columnas en el mismo orden
tpv_antiguo as (
    select
          tienda_id
        , fecha
        , num_tickets
        , unidades
        , venta_bruta
        , num_devoluciones
        , importe_devoluciones
        , venta_neta
        , 'LEGACY'                                                                 as origen
    from legacy
),

-- 5. Las dos fuentes juntas
unidas as (
    select * from tpv_nuevo
    union all
    select * from tpv_antiguo
),

final as (
    select
          {{ dbt_utils.generate_surrogate_key(['tienda_id', 'fecha']) }}           as venta_diaria_id
        , tienda_id
        , fecha
        , num_tickets
        , unidades
        , venta_bruta
        , num_devoluciones
        , importe_devoluciones
        , venta_neta
        , origen
    from unidas
)

select * from final