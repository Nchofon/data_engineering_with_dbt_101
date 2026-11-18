{{ config(materialized='external',
          location=var('lake_root') ~ '/dead_letter/reason=schema_error/dlq_schema_errors.parquet') }}

-- Rows that passed the identifier check but failed type casting.
select *, 'invalid_timestamp' as _dl_reason
from {{ ref('stg_events_typed') }}
where event_timestamp is null