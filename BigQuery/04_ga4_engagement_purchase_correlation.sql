-- Her event için temel tablo
WITH base AS (
  SELECT
    user_pseudo_id,

    -- session_id: event_params içinden ga_session_id
    (
      SELECT
        CAST(ep.value.int_value AS STRING)
      FROM
        UNNEST(event_params) AS ep
      WHERE
        ep.key = 'ga_session_id'
      LIMIT 1
    ) AS session_id,

    event_name,

    -- session_engaged parametresi (user_engagement event'lerinde 1 olur)
    (
      SELECT
        ep.value.int_value
      FROM
        UNNEST(event_params) AS ep
      WHERE
        ep.key = 'session_engaged'
      LIMIT 1
    ) AS session_engaged,

    -- engagement_time_msec parametresi
    (
      SELECT
        ep.value.int_value
      FROM
        UNNEST(event_params) AS ep
      WHERE
        ep.key = 'engagement_time_msec'
      LIMIT 1
    ) AS engagement_time_msec

  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  -- Bu event'ler bizim işimize yarıyor
  WHERE
    event_name IN ('user_engagement', 'purchase', 'session_start')
),

-- Oturum bazında özet (user_id + session_id)
sessions AS (
  SELECT
    user_pseudo_id,
    session_id,
    -- user + session birleşimi (benzersiz oturum anahtarı)
    CONCAT(user_pseudo_id, '-', COALESCE(session_id, 'no_session')) AS session_key,

    -- 1) session_engaged = 1 mi? (integer)
    MAX(
      COALESCE(CAST(session_engaged AS INT64), 0)
    ) AS session_engaged_int,

    -- 2) engagement_time_msec toplamı (boşları 0 yap)
    SUM(
      COALESCE(engagement_time_msec, 0)
    ) AS total_engagement_time_msec,

    -- 3) purchase oldu mu? (integer flag)
    MAX(
      CASE
        WHEN event_name = 'purchase' THEN 1
        ELSE 0
      END
    ) AS purchase_flag
  FROM
    base
  WHERE
    session_id IS NOT NULL   -- oturumu tanımlı olanlar
  GROUP BY
    user_pseudo_id,
    session_id
),

-- Korelasyon sonuçları
correlations AS (
  SELECT
    -- Etkileşim var mı (0/1) ↔ satın alma (0/1)
    CORR(session_engaged_int, purchase_flag) AS corr_engaged_vs_purchase,

    -- Etkileşim süresi ↔ satın alma (0/1)
    CORR(total_engagement_time_msec, purchase_flag) AS corr_time_vs_purchase
  FROM
    sessions
)

-- Sonuç tablo
SELECT
  corr_engaged_vs_purchase,
  corr_time_vs_purchase
FROM
  correlations;
