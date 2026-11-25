-- =============================================================================
-- dim_vendedor
-- =============================================================================
-- Dimension vendedor: una fila por vendedor
-- Para filtrar las ventas por vendedor en Power BI con su nombre (como en BI2GO)
-- Lleva el nombre de su tienda para saber de donde es cada vendedor
-- El filtro de vendedor solo afecta a las ventas: el objetivo y el trafico son
-- de la tienda, no del vendedor
-- =============================================================================

with vendedores as (
    select * from {{ ref('slv_red_comercial__vendedor') }}
),

tiendas as (
    select * from {{ ref('slv_red_comercial__tienda') }}
),

final as (
    select
          v.vendedor_id
        , v.nombre || ' ' || v.apellidos                                   as vendedor_nombre
        , t.tienda_nombre
        , v.puesto
        , v.horas_semanales
        , floor(datediff('month', v.fecha_alta, current_date) / 12)        as antiguedad_anios
    from vendedores v
    left join tiendas t
        on v.tienda_id = t.tienda_id
)

select * from final