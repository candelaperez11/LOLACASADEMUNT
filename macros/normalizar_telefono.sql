{# =============================================================================
   normalizar_telefono(columna)
   =============================================================================
   Deja un telefono en formato internacional E.164 (+34...), venga como venga:
     "+34 647933390"  -> +34647933390
     "0034647933390"  -> +34647933390
     "647 93 33 90"   -> +34647933390
     "34647933390"    -> +34647933390
     vacio            -> null
   Primero quita espacios, + y guiones (solo numeros) y despues decide el prefijo.
   Un numero de 9 cifras que empieza por 6, 7, 8 o 9 es español sin prefijo.
   Uso:
     {{ normalizar_telefono('telefono') }}   as telefono
   ============================================================================= #}

{% macro normalizar_telefono(columna) %}

    {%- set numeros -%}
        nullif(replace(replace(replace(trim({{ columna }}), ' ', ''), '+', ''), '-', ''), '')
    {%- endset -%}

    case
        when {{ numeros }} is null                                        then null
        when {{ numeros }} like '00%'                                     then '+' || substr({{ numeros }}, 3)
        when length({{ numeros }}) = 9
         and left({{ numeros }}, 1) in ('6', '7', '8', '9')               then '+34' || {{ numeros }}
        else '+' || {{ numeros }}
    end

{% endmacro %}