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
    traffic_source.source AS source,
    traffic_source.medium AS medium,
    traffic_source.name AS campaign
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    event_name IN (
      'session_start',
      'add_to_cart',
      'begin_checkout',
      'purchase'
    )
)

SELECT
  event_date,
  source,
  medium,
  campaign,

  -- 1) Toplam oturum sayısı (session_start olanlar)
  COUNT(DISTINCT IF(
    event_name = 'session_start',
    CONCAT(user_pseudo_id, '-', session_id),
    NULL
  )) AS user_sessions_count,

  -- 2) Sepete gitme oranı (add_to_cart / session_start)
  SAFE_DIVIDE(
    COUNT(DISTINCT IF(
      event_name = 'add_to_cart',
      CONCAT(user_pseudo_id, '-', session_id),
      NULL
    )),
    COUNT(DISTINCT IF(
      event_name = 'session_start',
      CONCAT(user_pseudo_id, '-', session_id),
      NULL
    ))
  ) AS visit_to_cart,

  -- 3) Checkout oranı (begin_checkout / session_start)
  SAFE_DIVIDE(
    COUNT(DISTINCT IF(
      event_name = 'begin_checkout',
      CONCAT(user_pseudo_id, '-', session_id),
      NULL
    )),
    COUNT(DISTINCT IF(
      event_name = 'session_start',
      CONCAT(user_pseudo_id, '-', session_id),
      NULL
    ))
  ) AS visit_to_checkout,

  -- 4) Purchase oranı (purchase / session_start)
  SAFE_DIVIDE(
    COUNT(DISTINCT IF(
      event_name = 'purchase',
      CONCAT(user_pseudo_id, '-', session_id),
      NULL
    )),
    COUNT(DISTINCT IF(
      event_name = 'session_start',
      CONCAT(user_pseudo_id, '-', session_id),
      NULL
    ))
  ) AS visit_to_purchase

FROM
  base
GROUP BY
  event_date,
  source,
  medium,
  campaign
ORDER BY
  event_date,
  source,
  medium,
  campaign;
