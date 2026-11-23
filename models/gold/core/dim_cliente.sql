-- =============================================================================
-- dim_cliente
-- =============================================================================
-- Dimension cliente: una fila por cliente
-- Sin datos personales: nombre, email y telefono se quedan en Silver.
-- Solo atributos que no identifican a la persona, para analizar las ventas por
-- rango de edad o antiguedad (minimizacion de datos, RGPD)
-- =============================================================================

with clientes as (
    select * from {{ ref('slv_ventas__cliente') }}
),

edades as (
    select
          cliente_id
        , floor(datediff('month', fecha_nacimiento, current_date) / 12)    as edad
        , floor(datediff('month', fecha_alta, current_date) / 12)          as antiguedad_anios
        , acepta_comunicaciones
    from clientes
),

final as (
    select
          cliente_id
        , case
              when edad is null then 'Sin dato'
              when edad < 30    then 'Menos de 30'
              when edad < 40    then '30 - 39'
              when edad < 50    then '40 - 49'
              when edad < 60    then '50 - 59'
              else '60 o más'
          end                                                              as rango_edad
        , antiguedad_anios
        , acepta_comunicaciones
    from edades
)

select * from final