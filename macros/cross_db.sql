{#- Cross-database helpers: every model runs unchanged on DuckDB (local) and Snowflake. -#}

{# Read a field from a raw JSON payload. path is dotted, e.g. 'in_view_mean.car' #}
{% macro jfield(col, path, type='varchar') -%}{{ return(adapter.dispatch('jfield')(col, path, type)) }}{%- endmacro %}
{% macro duckdb__jfield(col, path, type) -%}try_cast(json_extract_string({{ col }}, '$.{{ path }}') as {{ type }}){%- endmacro %}
{% macro snowflake__jfield(col, path, type) -%}try_cast({{ col }}:{{ path }}::varchar as {{ type }}){%- endmacro %}

{# The collector and the NWS both write UTC ISO-8601 strings; keep them as naive UTC timestamps #}
{% macro utc_ts(expr) -%}cast(replace(substr({{ expr }}, 1, 19), 'T', ' ') as timestamp){%- endmacro %}

{% macro to_pacific(ts) -%}{{ return(adapter.dispatch('to_pacific')(ts)) }}{%- endmacro %}
{% macro duckdb__to_pacific(ts) -%}cast(timezone('America/Los_Angeles', timezone('UTC', {{ ts }})) as timestamp){%- endmacro %}
{% macro snowflake__to_pacific(ts) -%}convert_timezone('UTC', 'America/Los_Angeles', {{ ts }}){%- endmacro %}

{% macro hour_of(ts) -%}hour({{ ts }}){%- endmacro %}

{# 0 = Monday ... 6 = Sunday on both engines #}
{% macro weekday_of(d) -%}{{ return(adapter.dispatch('weekday_of')(d)) }}{%- endmacro %}
{% macro duckdb__weekday_of(d) -%}((dayofweek({{ d }}) + 6) % 7){%- endmacro %}
{% macro snowflake__weekday_of(d) -%}(dayofweekiso({{ d }}) - 1){%- endmacro %}

{% macro hours_between(start_ts, end_ts) -%}{{ return(adapter.dispatch('hours_between')(start_ts, end_ts)) }}{%- endmacro %}
{% macro duckdb__hours_between(start_ts, end_ts) -%}((epoch({{ end_ts }}) - epoch({{ start_ts }})) / 3600.0){%- endmacro %}
{% macro snowflake__hours_between(start_ts, end_ts) -%}(datediff(second, {{ start_ts }}, {{ end_ts }}) / 3600.0){%- endmacro %}

{% macro ilike_any(col, words) -%}({% for w in words %}{{ col }} ilike '%{{ w }}%'{% if not loop.last %} or {% endif %}{% endfor %}){%- endmacro %}

{# continuous percentile, usable as an aggregate or a window function #}
{% macro pctl(col, p) -%}{{ return(adapter.dispatch('pctl')(col, p)) }}{%- endmacro %}
{% macro duckdb__pctl(col, p) -%}quantile_cont({{ col }}, {{ p }}){%- endmacro %}
{% macro snowflake__pctl(col, p) -%}percentile_cont({{ p }}) within group (order by {{ col }}){%- endmacro %}
