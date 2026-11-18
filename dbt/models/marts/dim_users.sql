{{ config(location=var('lake_root') ~ '/gold/dim_users.parquet') }}

select
    user_id,
    min(event_timestamp)                                             as first_seen_at,
    max(event_timestamp)                                             as last_seen_at,
    count(*)                                                         as total_events,
    max(case when event_type = 'user_signup' then payload ->> '$.platform' end) as signup_platform,
    max(case when event_type = 'user_signup' then payload ->> '$.country'  end) as signup_country,
    arg_max(payload ->> '$.tier_to', event_timestamp)
        filter (where event_type = 'subscription_upgrade')           as current_tier
from {{ ref('stg_events') }}
group by user_id