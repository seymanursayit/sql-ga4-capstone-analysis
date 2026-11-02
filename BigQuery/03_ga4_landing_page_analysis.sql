WITH base AS (
  SELECT
    DATE(TIMESTAMP_MICROS(event_timestamp)) AS event_date,
    user_pseudo_id,
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
    -- page_location parametresi
    (
      SELECT
        ep.value.string_value
      FROM
        UNNEST(event_params) AS ep
      WHERE
        ep.key = 'page_location'
      LIMIT 1
    ) AS page_location
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    DATE(TIMESTAMP_MICROS(event_timestamp)) BETWEEN '2020-01-01' AND '2020-12-31'
    AND event_name IN ('session_start', 'purchase')
),

-- Açılış sayfası (landing page) tablosu: sadece session_start
landing AS (
  SELECT
    event_date,
    user_pseudo_id,
    session_id,
    -- session key: user + session kombinasyonu
    CONCAT(user_pseudo_id, '-', session_id) AS session_key,
    -- page_path çıkarımı
    REGEXP_EXTRACT(page_location, r'https?://[^/]+([^?#]+)') AS page_path
  FROM
    base
  WHERE
    event_name = 'session_start'
),

-- Purchase olan oturumlar
purchase_sessions AS (
  SELECT DISTINCT
    CONCAT(user_pseudo_id, '-', session_id) AS session_key
  FROM
    base
  WHERE
    event_name = 'purchase'
)

SELECT
  l.page_path,
  -- Benzersiz kullanıcı oturum sayısı (landing bazlı)
  COUNT(DISTINCT l.session_key) AS user_sessions_count,
  -- Satın alma gerçekleşen benzersiz oturum sayısı
  COUNT(DISTINCT CASE WHEN p.session_key IS NOT NULL THEN l.session_key END) AS purchase_sessions_count,
  -- Satın alma dönüşüm oranı
  SAFE_DIVIDE(
    COUNT(DISTINCT CASE WHEN p.session_key IS NOT NULL THEN l.session_key END),
    COUNT(DISTINCT l.session_key)
  ) AS purchase_conversion_rate
FROM
  landing l
LEFT JOIN
  purchase_sessions p
ON
  l.session_key = p.session_key
GROUP BY
  l.page_path
ORDER BY
  purchase_conversion_rate DESC;

