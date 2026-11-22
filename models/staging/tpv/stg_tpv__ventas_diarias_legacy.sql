-- =============================================================================
-- stg_tpv__ventas_diarias_legacy
-- =============================================================================
-- Formato antiguo trae errores en nombre de tienda por lo que ponemos en mayusculas todo y con LC (limpieza)
-- Ventas 129,00€ = 129.00 
-- Generamos id para cada venta_diaria 
-- =============================================================================

with source as (
    select * from {{ source('tpv', 'ventas_diarias_legacy') }}
),

renamed as (
    select
        case
            when upper(trim(tienda)) like 'LC %' then upper(trim(tienda))
            else 'LC ' || upper(trim(tienda))
        end                                                              as tienda_nombre_normalizado
        , try_to_date(trim(fecha), 'DD/MM/YYYY')                         as fecha
        , num_tickets
        , unidades
        , {{ limpiar_importe('venta_bruta') }}                           as venta_bruta
        , num_devoluciones
        , {{ limpiar_importe('importe_devoluciones') }}                  as importe_devoluciones
        , _loaded_at                                                     as date_load
    from source
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['tienda_nombre_normalizado', 'fecha']) }} as venta_diaria_id
        , *
        , venta_bruta - importe_devoluciones                             as venta_neta
    from renamed
)

select * from final
qualify row_number() over (partition by venta_diaria_id order by date_load desc) = 1
