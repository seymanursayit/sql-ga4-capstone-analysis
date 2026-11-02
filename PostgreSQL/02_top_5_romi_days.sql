WITH union_ads AS (
    SELECT
        ad_date::date AS day,
        spend,
        value
    FROM public.facebook_ads_basic_daily

    UNION ALL

    SELECT
        ad_date::date AS day,
        spend,
        value
    FROM public.google_ads_basic_daily
),
daily_agg AS (
    SELECT
        day,
        SUM(spend) AS total_spend,
        SUM(value) AS total_value
    FROM union_ads
    GROUP BY day
)
SELECT
    day AS ad_date,
    total_spend,
    total_value,
    (total_value - total_spend) / NULLIF(total_spend, 0) AS romi
FROM daily_agg
WHERE total_spend > 0        
ORDER BY romi DESC
LIMIT 5;
