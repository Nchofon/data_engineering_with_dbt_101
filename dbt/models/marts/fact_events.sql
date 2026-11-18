{{ config(location=var('lake_root') ~ '/gold/fact_events',
          options={'partition_by': 'event_date', 'overwrite': 'true'}) }}

-- Grain: one row per event. Payload kept as JSON for audit/ad-hoc queries.
select
    event_id,
    event_type,
    user_id,
    event_timestamp,
    event_date,
    extract(hour from event_timestamp) as event_hour,
    payload
from {{ ref('stg_events') }}
order by event_date, event_type          -- physical sort ≈ clustering within a partition