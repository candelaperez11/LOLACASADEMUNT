-- =============================================================================
-- stg_tpv__lineas_ticket
-- =============================================================================
-- Cada ticket trae una lista de productos dentro la separamos con lateral flatten para tener una fila por producto del ticket
-- Partimos de stg_tpv__tickets por tickets de prueba y duplicados
-- Referencia igualamos formato de porductos 
-- Si precio_final viene vacio lo calculamos: unidades * pvp * (1 - descuento)
-- BOLSA_PAPEL no es un producto, la marcamos con es_producto = false pero no la quitamos porque si suma al importe del ticket (para que tampoco cuente en UPT)
-- Devoluciones negativo
-- =============================================================================

with tickets as (
    select * from {{ ref('stg_tpv__tickets') }}
),

flattened as (
    select
          t.ticket_id
        , l.value:linea::number                                          as num_linea
        , upper(replace(trim(l.value:referencia::varchar), '.', '_'))    as referencia
        , l.value:unidades::number                                       as unidades
        , l.value:pvp::number(10, 2)                                     as pvp
        , l.value:descuento_pct::number(6, 4)                            as descuento_pct
        , l.value:precio_final::number(10, 2)                            as precio_final_origen
        , t.date_load
    from tickets t,
        lateral flatten(input => t.lineas) l
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['ticket_id', 'num_linea']) }} as linea_ticket_id
        , ticket_id
        , num_linea
        , referencia
        , referencia not in ('BOLSA_PAPEL')                              as es_producto
        , unidades
        , pvp
        , descuento_pct
        , coalesce(precio_final_origen,
                   round(unidades * pvp * (1 - descuento_pct), 2))       as precio_final
        , precio_final_origen is null                                    as es_precio_recalculado
        , date_load
    from flattened
)

select * from final
