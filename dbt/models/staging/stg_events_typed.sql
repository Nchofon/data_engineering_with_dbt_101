{{ config(materialized='ephemeral') }}

-- Casts raw strings to proper types. Failed casts become NULL (try_cast),
-- so this model never errors; downstream models decide what to do with NULLs.
select
    event_id,
    try_cast(timestamp as timestamptz)        as event_timestamp,
    lower(trim(event_type))                   as event_type,
    coalesce(nullif(trim(user_id), ''), 'unknown') as user_id,
    payload,
    _batch_id,
    _ingested_at
from {{ source('bronze', 'events') }}