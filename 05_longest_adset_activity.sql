WITH all_adsets AS (
    -- FACEBOOK: adset_name'i facebook_adset tablosundan alıyoruz
    SELECT
        f.ad_date::date AS day,
        a.adset_name
    FROM public.facebook_ads_basic_daily f
    JOIN public.facebook_adset a
        ON f.adset_id = a.adset_id
    WHERE f.impressions > 0

    UNION ALL

    -- GOOGLE: adset_name zaten bu tabloda var
    SELECT
        g.ad_date::date AS day,
        g.adset_name
    FROM public.google_ads_basic_daily g
    WHERE g.impressions > 0
),
distinct_days AS (
    SELECT DISTINCT
        adset_name,
        day
    FROM all_adsets
),
marked_groups AS (
    SELECT
        adset_name,
        day,
        day - (ROW_NUMBER() OVER (
                    PARTITION BY adset_name
                    ORDER BY day
                ) * INTERVAL '1 day') AS grp
    FROM distinct_days
),
streaks AS (
    SELECT
        adset_name,
        MIN(day) AS start_date,
        MAX(day) AS end_date,
        COUNT(*) AS active_days
    FROM marked_groups
    GROUP BY adset_name, grp
)
SELECT
    adset_name,
    start_date,
    end_date,
    active_days
FROM streaks
ORDER BY active_days DESC
LIMIT 1;
