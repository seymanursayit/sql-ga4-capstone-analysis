SELECT
    'facebook' AS platform,
    AVG(spend) AS avg_daily_spend,
    MAX(spend) AS max_daily_spend,
    MIN(spend) AS min_daily_spend
FROM public.facebook_ads_basic_daily

union ALL

SELECT
    'google' AS platform,
    AVG(spend) AS avg_daily_spend,
    MAX(spend) AS max_daily_spend,
    MIN(spend) AS min_daily_spend
FROM public.google_ads_basic_daily;
