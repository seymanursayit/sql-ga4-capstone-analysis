SELECT
  TIMESTAMP_MICROS(event_timestamp) AS event_timestamp,
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
  geo.country AS country,
  device.category AS device_category,
  traffic_source.source AS source,
  traffic_source.medium AS medium,
  traffic_source.name AS campaign
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
  DATE(TIMESTAMP_MICROS(event_timestamp)) BETWEEN '2021-01-01' AND '2021-12-31'
  AND event_name IN (
    'session_start',
    'view_item',
    'add_to_cart',
    'begin_checkout',
    'add_shipping_info',
    'add_payment_info',
    'purchase'
  );