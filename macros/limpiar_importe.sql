{# =============================================================================
   limpiar_importe(columna)
   =============================================================================
   Convierte un importe que llega como texto en numero con 2 decimales.
   Quita el simbolo del euro y los espacios, y cambia la coma decimal por punto:
     "129,00 €" -> 129.00   ·   "106,50" -> 106.50   ·   "79.95" -> 79.95
   Si el texto no es un numero, devuelve null en vez de dar error (try_to_number).
   Uso:
     {{ limpiar_importe('venta_bruta') }}                    as venta_bruta
     {{ limpiar_importe('raw:importe_total::varchar') }}     as importe_total
   ============================================================================= #}

{% macro limpiar_importe(columna) %}
    try_to_number(replace(replace(replace(trim({{ columna }}), '€', ''), ' ', ''), ',', '.'), 12, 2)
{% endmacro %}