{{ config(location=var('lake_root') ~ '/gold/fact_api_requests',
          options={'partition_by': 'event_date'}) }}

-- Typed metrics extracted from the api_request payload.
select
    event_id, user_id, event_timestamp, event_date,
    payload ->> '$.endpoint'                        as endpoint,
    cast(payload ->> '$.status_code' as integer)    as status_code,
    cast(payload ->> '$.latency_ms'  as integer)    as latency_ms
from {{ ref('stg_events') }}
where event_type = 'api_request'