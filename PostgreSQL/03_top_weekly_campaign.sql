WITH fb_weekly AS (
    SELECT
        date_trunc('week', f.ad_date::date)::date AS week_start,
        c.campaign_name,
        SUM(f.value) AS week_value
    FROM public.facebook_ads_basic_daily f
    JOIN public.facebook_campaign c
        ON f.campaign_id = c.campaign_id
    GROUP BY week_start, c.campaign_name
),
gg_weekly AS (
    SELECT
        date_trunc('week', g.ad_date::date)::date AS week_start,
        g.campaign_name,
        SUM(g.value) AS week_value
    FROM public.google_ads_basic_daily g
    GROUP BY week_start, g.campaign_name
),
all_campaigns AS (
    SELECT week_start, campaign_name, week_value FROM fb_weekly
    UNION ALL
    SELECT week_start, campaign_name, week_value FROM gg_weekly
),
agg_campaigns AS (
    SELECT
        week_start,
        campaign_name,
        SUM(week_value) AS total_week_value
    FROM all_campaigns
    GROUP BY week_start, campaign_name
)
SELECT
    week_start,
    campaign_name,
    total_week_value
FROM agg_campaigns
ORDER BY total_week_value DESC
LIMIT 1;
