# Lola Casademunt · Del dato de tienda a la decisión de tienda

Proyecto de Data Engineering de punta a punta para la red de tiendas de **Lola Casademunt**: ingesta de ventas, tráfico y producto en **Snowflake**, transformación con **dbt** siguiendo una arquitectura **medallion** y visualización en **Power BI**.

> Proyecto final del curso de Data Engineering de Cívica (noviembre de 2026).
> Los datos son **simulados**, calibrados con informes reales de BI2GO, y se han ensuciado a propósito para trabajar la calidad del dato.

---

## Índice

1. [El problema de negocio](#1-el-problema-de-negocio)
2. [Arquitectura](#2-arquitectura)
3. [Fuentes de datos](#3-fuentes-de-datos)
4. [Ingesta en Snowflake](#4-ingesta-en-snowflake)
5. [Ingesta en tiempo real con Python](#5-ingesta-en-tiempo-real-con-python)
6. [Transformación con dbt](#6-transformación-con-dbt)
7. [Calidad del dato](#7-calidad-del-dato)
8. [Entornos y despliegue](#8-entornos-y-despliegue)
9. [Power BI](#9-power-bi)
10. [Estructura del repositorio](#10-estructura-del-repositorio)
11. [Cómo ejecutarlo](#11-cómo-ejecutarlo)

---

## 1. El problema de negocio

En tienda, la información está repartida entre varias herramientas: **BI2GO** para la venta y el objetivo, el **contador de personas** para el tráfico y el **catálogo** para el producto. Cada una responde a una parte, pero ninguna las cruza.

El proyecto junta las tres en un solo modelo para responder a las tres preguntas que se hace una tienda cada día:

| Pregunta | Página del informe |
|---|---|
| ¿Cómo vamos frente al objetivo y al año pasado? | Ranking de tiendas |
| ¿A qué hora entra gente y no la convertimos? | Tienda hora a hora |
| ¿Qué cápsulas y productos se venden más en mi tienda y en mi zona? | Más vendidos y cápsulas |

**KPIs principales**

- **Atracción** = entradas ÷ tráfico exterior → ¿el escaparate hace entrar a la gente?
- **Conversión** = tickets ÷ entradas → ¿la convertimos en venta una vez dentro?
- **Ticket medio** = venta neta ÷ nº de tickets · **UPT** = unidades ÷ tickets
- **% objetivo** = venta neta ÷ objetivo · **Evolución** frente al año anterior (mismo día de la semana, D − 364), solo con tiendas comparables

---

## 2. Arquitectura

```
 Fuentes (CSV · JSON)          Snowflake                     dbt                            Power BI
┌──────────────────┐    ┌──────────────────────┐    ┌──────────────────────────────┐    ┌──────────────┐
│ TPV (tickets)    │    │ BRONZE               │    │ STAGING  limpia y deduplica  │    │ 3 páginas    │
│ Contador (TC)    │──► │ stage + COPY INTO    │──► │ SILVER   modelo en 3FN       │──► │ Import mode  │
│ Catálogo         │    │ Tasks cada 30 min    │    │ GOLD     modelo en estrella  │    │ REPORTING_   │
│ Tiendas, CRM...  │    │ dato tal cual llega  │    │ incremental + tests          │    │ ROLE         │
└──────────────────┘    └──────────────────────┘    └──────────────────────────────┘    └──────────────┘
        ▲
        │ simulador_envio.py (PUT cada 30 min)
```

| Capa | Base de datos | Qué contiene |
|---|---|---|
| Bronze | `DEV_BRONZE_DB` / `PRO_BRONZE_DB` | El dato tal cual llega, con el fichero de origen (`_source_file`) y la hora de carga (`_loaded_at`) |
| Silver | `DBT_SILVER_DB` | Staging (vistas) y modelo normalizado en tercera forma normal |
| Gold | `DBT_GOLD_DB` | Modelo en estrella para Power BI: 5 dimensiones y 4 tablas de hechos |

**Stack:** Snowflake · dbt Cloud (dbt_utils) · Python 3.10+ · Power BI Desktop · GitHub

---

## 3. Fuentes de datos

| Fichero | Formato | Tabla en Bronze | Contenido |
|---|---|---|---|
| `productos_lookbooks.csv` | CSV | `CATALOGO.PRODUCTOS` | ~2.060 referencias de 3 temporadas |
| `product_images_b64.csv` | CSV | `CATALOGO.IMAGENES_PRODUCTO` | Foto de cada referencia en base64 (data URI) |
| `tiendas.csv` | CSV `;` latin-1 | `COMERCIAL.TIENDAS` | 76 puntos de venta: tiendas, outlets y corners de ECI |
| `estructura_comercial.csv` | CSV | `COMERCIAL.ESTRUCTURA_COMERCIAL` | Área y área manager de cada tienda |
| `objetivos_tienda_dia.csv` | CSV | `COMERCIAL.OBJETIVOS_TIENDA_DIA` | Objetivo de venta neta por tienda y día |
| `clientes.csv` · `vendedores.csv` | CSV | `COMERCIAL.CLIENTES` · `COMERCIAL.VENDEDORES` | Maestros de CRM y RR. HH. |
| `ventas_diarias_tienda_2024-2025.csv` | CSV latin-1 | `TPV.VENTAS_DIARIAS_LEGACY` | TPV antiguo: totales tienda-día (año anterior) |
| `trafico_franjas_AAAA-MM.csv` | CSV ancho | `CONTADOR.TRAFICO_FRANJAS` | Contador histórico: una columna por franja de 30' |
| `tickets_AAAA-MM.json.gz` · `tickets_AAAA-MM-DD.json` | JSON (NDJSON) | `TPV.TICKETS` | Tickets del TPV nuevo, con sus líneas |
| Lotes de 30': `tickets_*.json` · `trafico_tr_*.csv` | JSON · CSV | `TPV.TICKETS` · `CONTADOR.TRAFICO_TIEMPO_REAL` | Ingesta en tiempo real |

### Cómo se obtuvieron los datos

No hay acceso a los sistemas reales de la empresa, así que el dataset se construyó **mezclando datos reales públicos y datos simulados**, calibrados con informes reales para que las cifras sean creíbles. Todos los scripts están en [`scripts/`](scripts/).

| Datos | Origen | Cómo | Script |
|---|---|---|---|
| **Catálogo** | Real | Extraído de los PDF de los lookbooks de tres temporadas (FW25-26, SS26, FW26-27): referencia, nombre, cápsula, precio y foto | `build_catalog.py` · `finalize_catalog.py` |
| **Tiendas** | Real | Puntos de venta de la web de la marca: tiendas, outlets y corners de ECI, con sus nombres oficiales de BI2GO | `gen_tiendas_v2.py` |
| **Estructura comercial** | Simulada | Reparto de tiendas por área y área manager | `gen_area_managers.py` |
| **Tickets y año anterior** | Simulados | Generados tienda a tienda y día a día, **calibrados con exportaciones reales de BI2GO** (octubre y noviembre de 2026): nº de ventas, objetivo, tráfico y entradas | `parse_bi2go.py` · `gen_ventas_v2.py` · `reconciliar.py` |
| **Tráfico del contador** | Simulado | Con la curva horaria real de un contador de tienda, en el mismo formato ancho que exporta el sistema | `gen_ventas_v2.py` |
| **Clientas y vendedores** | Simulados | Maestros generados para que cuadren con los IDs de los tickets | generados aparte (`clientes.csv`, `vendedores.csv`) |
| **Suciedad** | Añadida a propósito | Duplicados, tickets de prueba, formatos de fecha e importe distintos, nombres de tienda distintos… | `ensuciar_v2.py` |
| **Días extra y lotes** | Simulados | Días adicionales y corte del mes en curso en lotes de 30 minutos | `gen_dias_extra.py` · `tiempo_real/preparar_lotes.py` |

El resultado se usa también como **examen** para Gold: el número de ventas por tienda de octubre tiene que cuadrar con el informe real de BI2GO.

**Seeds de dbt** (CSV dentro del proyecto): `familias_agregadas`, `formatos_tienda`, `provincias`, `comunidades_autonomas`, `franjas_horarias`.

**Suciedad incluida a propósito:** tickets duplicados y de prueba, tickets que llegan tarde, importes con `€` y comas, fechas en varios formatos, teléfonos sin normalizar, nombres de tienda distintos entre el TPV antiguo y el nuevo, cápsulas mezcladas en la descripción…

---

## 4. Ingesta en Snowflake

Scripts en [`snowflake/`](snowflake/):

| Script | Qué hace |
|---|---|
| `01_setup_entorno.sql` | Warehouse, bases de datos DEV/PRO por capa, esquemas y roles (incluido `REPORTING_ROLE`) |
| `02_bronze_ingesta.sql` | File formats, stage interno `CARGA_BRONZE`, tablas de Bronze y `COPY INTO` del histórico |
| `03_tiempo_real.sql` | Tabla de tráfico en vivo y las dos Tasks de la ingesta en tiempo real |

### JSON: datos semiestructurados

Los tickets se guardan **enteros** en una columna `VARIANT`, sin transformar, junto con su trazabilidad:

```sql
create or replace file format DEV_BRONZE_DB.PUBLIC.FF_JSON
    type = json
    compression = auto            -- lee igual .json y .json.gz
    strip_outer_array = false;    -- un ticket por línea (NDJSON)

copy into DEV_BRONZE_DB.TPV.TICKETS (raw, _source_file, _source_row_number)
from (
    select $1, metadata$filename, metadata$file_row_number
    from @DEV_BRONZE_DB.PUBLIC.carga_bronze/ventas/
)
pattern = '.*tickets_.*[.]json([.]gz)?'
file_format = (format_name = 'DEV_BRONZE_DB.PUBLIC.FF_JSON');
```

En staging se extraen los campos con la notación `raw:campo::tipo` y las líneas de cada ticket se despliegan con `lateral flatten`.

**COPY INTO es incremental por sí mismo:** recuerda los ficheros ya cargados (64 días), así que relanzarlo solo carga los nuevos.

---

## 5. Ingesta en tiempo real con Python

El histórico entra de una vez (*backfill*). El mes en curso entra **cada 30 minutos**, como en producción: un script de Python hace de TPV y de contador de personas, y deja un lote en el stage; un grafo de **Tasks** de Snowflake lo carga.

```
 TU ORDENADOR (hace de TPV y de contador)               SNOWFLAKE
 ─────────────────────────────────────────              ─────────────────────────────────────────────
 preparar_lotes.py                                      @CARGA_BRONZE/tiempo_real/
   corta el mes en lotes de 30 minutos                           │
            │                                                    │  cada intervalo
 simulador_envio.py                                              ▼
   sube el siguiente lote cada X segundos ──── PUT ──►  T_INGESTA_TICKETS  ──► TPV.TICKETS
                                                                 └► T_INGESTA_TRAFICO ──► CONTADOR.TRAFICO_TIEMPO_REAL
```

- **Python** es el sistema de origen: solo genera ficheros y los sube con `PUT`.
- **Snowflake** es la ingesta: dos Tasks encadenadas ejecutan `COPY INTO` y cargan solo lo nuevo.
- **Reloj acelerado:** en la simulación, 1 minuto real equivale a 30 minutos de tienda. En producción, la Task se programaría cada 30 minutos.

Scripts en [`tiempo_real/`](tiempo_real/):

| Fichero | Para qué |
|---|---|
| `preparar_lotes.py` | Corta los tickets y el tráfico del mes en curso en lotes de 30 minutos |
| `lotes/` | Lotes ya preparados (un fichero de tickets y uno de tráfico por franja) |
| `simulador_envio.py` | Sube un lote al stage cada X segundos y recuerda por dónde iba (`enviados.txt`) |
| `03_tiempo_real.sql` | Tabla de tráfico en vivo y Tasks (en `snowflake/`) |

### 5.1 Preparar los lotes (opcional, ya vienen hechos)

```bash
python preparar_lotes.py --datos "RUTA/A/datos_ingesta_lola" --salida lotes
```

Reglas del corte:
- Cada ticket va al lote de su hora (10:47 → lote de las 10:30).
- Los tickets que llegaron tarde van al primer lote del día en que llegaron.
- La suciedad se mantiene: se limpia en staging.
- El tráfico pasa de formato ancho (una columna por franja) a largo (una fila por tienda, franja y KPI).

### 5.2 Crear la tabla y las Tasks en Snowflake

Ejecuta `snowflake/03_tiempo_real.sql`. Las Tasks se crean **suspendidas**. El COPY que ejecutan es el mismo del histórico, apuntando a la carpeta `tiempo_real/`:

```sql
copy into DEV_BRONZE_DB.TPV.TICKETS (raw, _source_file, _source_row_number)
from (
    select $1, metadata$filename, metadata$file_row_number
    from @DEV_BRONZE_DB.PUBLIC.carga_bronze/tiempo_real/
)
pattern = '.*tickets_.*[.]json([.]gz)?'
file_format = (format_name = 'DEV_BRONZE_DB.PUBLIC.FF_JSON');
```

Encender y apagar (en un grafo: al encender, primero la hija; al apagar, primero la raíz):

```sql
alter task DEV_BRONZE_DB.PUBLIC.T_INGESTA_TRAFICO resume;
alter task DEV_BRONZE_DB.PUBLIC.T_INGESTA_TICKETS resume;

alter task DEV_BRONZE_DB.PUBLIC.T_INGESTA_TICKETS suspend;
alter task DEV_BRONZE_DB.PUBLIC.T_INGESTA_TRAFICO suspend;

show tasks in schema DEV_BRONZE_DB.PUBLIC;    -- columna state: started / suspended
```

> ⚠️ No dejes las Tasks encendidas: cada ejecución despierta el warehouse y consume créditos.

### 5.3 Configurar el simulador

```bash
pip install snowflake-connector-python
```

En `simulador_envio.py`, rellena la sección de **CONFIGURACIÓN** (`account`, `user`…) y elige cómo autenticarte:

- **Clave privada (recomendado):** guarda la clave en `rsa_key.p8` y define la passphrase en una variable de entorno:
  - Windows (PowerShell): `$env:SNOWFLAKE_PASSPHRASE="tu_passphrase"`
  - macOS / Linux: `export SNOWFLAKE_PASSPHRASE="tu_passphrase"`
- **Contraseña + MFA:** `AUTENTICACION = "password_mfa"`. El script pide la contraseña y el código.

> 🔒 Nunca subas a GitHub `rsa_key.p8`, contraseñas ni passphrases. Están en `.gitignore`.

### 5.4 Lanzarlo

```bash
# Prueba sin conectar: enseña los PUT que haría
python simulador_envio.py --dry-run --hasta 2026-11-01 --intervalo 0

# Precarga rápida de casi todo el mes, sin esperas
python simulador_envio.py --hasta 2026-11-17 --intervalo 0

# Tiempo real: un lote por intervalo
python simulador_envio.py
```

| Opción | Significado |
|---|---|
| `--hasta AAAA-MM-DD` | Último día que se envía (incluido) |
| `--intervalo N` | Segundos entre lotes (`0` = sin esperas) |
| `--dry-run` | No conecta ni sube nada |

Para parar: `Ctrl + C` en el simulador y `suspend` de las Tasks. Al relanzarlo, sigue por el siguiente lote.

**Sin Python** (por ejemplo, en un equipo sin permisos de instalación), los lotes también se pueden subir desde Snowsight: *Stages → CARGA_BRONZE → + Files → ruta `tiempo_real`* y después `execute task DEV_BRONZE_DB.PUBLIC.T_INGESTA_TICKETS;`.

### 5.5 Comprobar que ha entrado

```sql
select _source_file, count(*) as filas, max(_loaded_at) as cargado
from DEV_BRONZE_DB.TPV.TICKETS
group by _source_file
order by cargado desc
limit 5;
```

---

## 6. Transformación con dbt

### Capas

| Capa | Materialización | Qué hace |
|---|---|---|
| `staging` | `view` | Limpia, tipa y deduplica cada fuente. Extrae el JSON y despliega las líneas con `lateral flatten` |
| `silver` | `table` / `incremental` | Modelo normalizado en 3FN. Une el TPV antiguo con el nuevo. Los datos personales se quedan aquí |
| `gold` | `table` / `incremental` | Modelo en estrella para Power BI. Permiso de lectura para `REPORTING_ROLE` |

### Modelo de Silver (3FN)

Entidades: `marca`, `temporada`, `capsula`, `producto`, `ticket`, `linea_ticket`, `cliente`, `vendedor`, `tienda`, `area`, `area_manager`, `objetivo_diario`, `venta_diaria_legacy`, `trafico_franja`, más los seeds. Todas las relaciones son de muchos a uno.

### Modelo de Gold (estrella)

| Tabla | Grano |
|---|---|
| `fct_venta_linea` | Una fila por línea de ticket (**incremental**) |
| `fct_venta_diaria_tienda` | Tienda y día (TPV nuevo + TPV antiguo) |
| `fct_trafico_franja` | Tienda, día y franja de 30 minutos |
| `fct_objetivo_diario` | Tienda y día |
| `dim_fecha` · `dim_tienda` · `dim_producto` · `dim_franja` · `dim_vendedor` | Dimensiones desnormalizadas |

### Incrementalidad

`slv_ventas__ticket`, `slv_ventas__linea_ticket` y `fct_venta_linea` son incrementales:

```sql
{{ config(
    materialized = 'incremental',
    unique_key = 'linea_ticket_id',
    on_schema_change = 'append_new_columns'
) }}
...
{% if is_incremental() %}
where date_load >= (select dateadd('day', -3, max(date_load)) from {{ this }})
{% endif %}
```

- **Ventana de 3 días:** recoge los tickets que llegan con retraso.
- **`unique_key` → MERGE:** inserta lo nuevo y actualiza lo existente, sin duplicar. El proceso es **idempotente**: relanzarlo da el mismo resultado.
- **`on_schema_change`:** si aparece una columna nueva, se añade sin romper la carga.
- Las tablas agregadas (venta diaria, tráfico) son pequeñas y se reconstruyen enteras en segundos.

### Macros, seeds y paquetes

- Macros propias: `limpiar_importe`, `normalizar_telefono`, `generate_schema_name`.
- Paquete `dbt_utils` (claves sustitutas con `generate_surrogate_key`, calendario con `date_spine`).
- Hooks en `dim_fecha` para que la semana empiece en lunes (`week_start = 1`).

---

## 7. Calidad del dato

- **Tests** de dbt en cada capa: `unique`, `not_null`, `accepted_values`, `relationships` y un test singular (`assert_vendedor_vende_en_su_tienda`).
- **Severidad pensada:** lo que debe parar el pipeline es `error`; los desfases esperables son `warn`. Por ejemplo, las líneas vendidas con referencias que no están en el catálogo son venta real: se mantienen y quedan avisadas.
- **Validación contra BI2GO:** el número de ventas por tienda de octubre de 2026 cuadra exacto con el informe real.

---

## 8. Entornos y despliegue

- **DEV y PRO** con bases de datos separadas. El Bronze de PRO se creó como **clon zero-copy** de DEV.
- **Job de CI:** en cada pull request ejecuta `dbt build --select state:modified+` en un esquema temporal.
- **Job de Deploy:** tras el merge a `main`, ejecuta `dbt build` en PRO y genera la documentación.
- **Mínimo privilegio:** Power BI se conecta con `REPORTING_ROLE`, que solo puede leer Gold.

---

## 9. Power BI

Modo **Import**, 12 relaciones muchos a uno en una sola dirección y una tabla de medidas (`_Medidas`).

| Página | Contenido |
|---|---|
| **Ranking de tiendas** | Venta neta, objetivo, evolución frente al año anterior (tiendas comparables), ticket medio, UPT y conversión. Filtros por fecha, área manager, tipo de tienda y comunidad |
| **Tienda hora a hora** | Entradas, tráfico exterior, atracción y conversión por franja de 30 minutos, con el último dato recibido |
| **Más vendidos y cápsulas** | Referencias más vendidas con foto y venta por cápsula, por tienda o comunidad |

Las fotos de producto viajan en **base64 dentro del propio dato**, así que el informe no depende de ninguna web.
<img width="1324" height="744" alt="image" src="https://github.com/user-attachments/assets/0e0a9acd-0329-4bcd-8652-577fa3bcc610" />
<img width="1327" height="727" alt="image" src="https://github.com/user-attachments/assets/76961dab-136a-4a96-9dd6-52a7cba551b6" />
<img width="1320" height="733" alt="image" src="https://github.com/user-attachments/assets/21062c25-84c3-4517-bce4-c73dbec492cc" />

---

## 10. Estructura del repositorio

```
.
├── analyses/                 # SQL de análisis (p. ej. reconciliación con BI2GO)
├── macros/                   # limpiar_importe, normalizar_telefono, generate_schema_name
├── models/
│   ├── staging/              # catalogo · comercial · tpv · contador
│   ├── silver/               # producto · red_comercial · ventas · trafico
│   └── gold/core/            # dimensiones y hechos
├── seeds/                    # familias, formatos, provincias, comunidades, franjas
├── tests/singular/           # tests propios
├── scripts/                  # generación del dataset (catálogo, tiendas, ventas, suciedad...)
├── snowflake/                # 01_setup · 02_bronze_ingesta · 03_tiempo_real
├── tiempo_real/              # preparar_lotes.py · simulador_envio.py · lotes/
├── dbt_project.yml
└── packages.yml
```

---

## 11. Cómo ejecutarlo

1. **Snowflake:** ejecuta `snowflake/01_setup_entorno.sql` y `snowflake/02_bronze_ingesta.sql`, subiendo antes los ficheros al stage `CARGA_BRONZE`.
2. **dbt:**
   ```bash
   dbt deps
   dbt seed
   dbt build
   ```
3. **Tiempo real:** ejecuta `snowflake/03_tiempo_real.sql`, enciende las Tasks y lanza `python tiempo_real/simulador_envio.py`.
4. **Después de cada lote:**
   ```bash
   dbt build --select +fct_venta_linea +fct_venta_diaria_tienda +fct_trafico_franja
   ```
5. **Power BI:** abre el `.pbix`, conecta a Snowflake con `REPORTING_ROLE` y pulsa **Actualizar**.

---

*Proyecto académico. Lola Casademunt es una marca registrada de su titular; los datos de este repositorio son simulados y no representan cifras reales de la compañía.*
