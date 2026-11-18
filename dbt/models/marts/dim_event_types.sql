{{ config(location=var('lake_root') ~ '/gold/dim_event_types.parquet') }}

select
    hash(event_type)         as event_type_key,
    event_type,
    min(event_timestamp)     as first_seen_at,
    count(*)                 as total_events
from {{ ref('stg_events') }}
group by event_type