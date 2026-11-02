WITH fb_monthly AS (
    SELECT
        date_trunc('month', f.ad_date::date)::date AS month_start,
        c.campaign_name,
        SUM(f.reach) AS monthly_reach
    FROM public.facebook_ads_basic_daily f
    JOIN public.facebook_campaign c
        ON f.campaign_id = c.campaign_id
    GROUP BY month_start, c.campaign_name
),
gg_monthly AS (
    SELECT
        date_trunc('month', g.ad_date::date)::date AS month_start,
        g.campaign_name,
        SUM(g.reach) AS monthly_reach
    FROM public.google_ads_basic_daily g
    GROUP BY month_start, g.campaign_name
),
all_monthly AS (
    SELECT month_start, campaign_name, monthly_reach FROM fb_monthly
    UNION ALL
    SELECT month_start, campaign_name, monthly_reach FROM gg_monthly
),
agg_monthly AS (
    SELECT
        month_start,
        campaign_name,
        SUM(monthly_reach) AS total_monthly_reach
    FROM all_monthly
    GROUP BY month_start, campaign_name
),
with_diff AS (
    SELECT
        campaign_name,
        month_start,
        total_monthly_reach,
        total_monthly_reach
          - LAG(total_monthly_reach) OVER (
                PARTITION BY campaign_name
                ORDER BY month_start
            ) AS reach_increase
    FROM agg_monthly
)
SELECT
    campaign_name,
    month_start,
    total_monthly_reach,
    reach_increase
FROM with_diff
ORDER BY reach_increase DESC NULLS LAST
LIMIT 1;
