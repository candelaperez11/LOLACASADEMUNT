--La semana empieza en lunes = 1, martes = 2 , miercoles = 3......
{{
    config(
        pre_hook="alter session set week_start = 1", 
        post_hook="alter session unset week_start"
    )
}}

-- =============================================================================
-- dim_fecha
-- =============================================================================
-- Una fila por dia, del 01/11/2024 (inicio del TPV antiguo) al 31/12/2026
-- El pre_hook fija WEEK_START = 1 en la sesion: asi dayofweek() devuelve
-- 1 = lunes ... 7 = domingo, como en España, sea cual sea la configuracion
-- de la cuenta. El post_hook lo deshace para no afectar a otros modelos.
-- fecha_aa = mismo dia de la semana del año anterior (fecha - 364 dias),
-- que es como compara BI2GO
-- Semana ISO con su propio año (el 31/12 puede ser la semana 1 del año siguiente)
-- =============================================================================

with spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2024-11-01' as date)",
        end_date="cast('2027-01-01' as date)"
    ) }}
),

fechas as (
    select date_day::date                                         as fecha
    from spine
),

final as (
    select
          fecha
        , year(fecha) * 10000 + month(fecha) * 100 + day(fecha)    as fecha_id      --20261120, clave para Power BI
        , year(fecha)                                              as anio
        , quarter(fecha)                                           as trimestre
        , month(fecha)                                             as mes
        , case month(fecha)
              when 1 then 'Enero'      when 2 then 'Febrero'    when 3 then 'Marzo'
              when 4 then 'Abril'      when 5 then 'Mayo'       when 6 then 'Junio'
              when 7 then 'Julio'      when 8 then 'Agosto'     when 9 then 'Septiembre'
              when 10 then 'Octubre'   when 11 then 'Noviembre' when 12 then 'Diciembre'
          end                                                      as mes_nombre
        , year(fecha) * 100 + month(fecha)                         as anio_mes      --año mes para ordenar los meses
        , weekiso(fecha)                                           as semana_iso
        , yearofweekiso(fecha)                                     as anio_semana_iso
        , 's' || weekiso(fecha) || ' ' || yearofweekiso(fecha)     as semana_etiqueta  --"s47 2026", como en BI2GO
        , dayofweek(fecha)                                         as dia_semana    --1 = lunes ... 7 = domingo
        , case dayofweek(fecha)
              when 1 then 'Lunes'   when 2 then 'Martes'  when 3 then 'Miércoles'
              when 4 then 'Jueves'  when 5 then 'Viernes' when 6 then 'Sábado'
              when 7 then 'Domingo'
          end                                                      as dia_semana_nombre
        , dayofweek(fecha) in (6, 7)                               as es_fin_de_semana
        , dateadd(day, -364, fecha)                                as fecha_aa      --mismo dia de la semana del año anterior para caso 1 vs año anterior
    from fechas
)

select * from final