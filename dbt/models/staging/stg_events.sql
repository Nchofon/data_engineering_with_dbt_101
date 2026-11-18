-- Silver: one row per event_id, fully typed. Latest ingestion wins on duplicates.
with valid as (
    select *, cast(event_timestamp as date) as event_date
    from {{ ref('stg_events_typed') }}
    where event_timestamp is not null
)
select * from valid
qualify row_number() over (
    partition by event_id
    order by _ingested_at desc, _batch_id desc
) = 1