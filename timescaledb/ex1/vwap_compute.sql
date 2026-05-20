

-- Minute data 

SELECT
    symbol,
    SUM(close * volume) / SUM(volume) AS vwap
FROM trading_prices
WHERE time >= '2026-01-01 09:30:00+00'
  AND time <  '2026-01-01 16:00:00+00'
GROUP BY symbol;

-- Hourly data

SELECT
    time_bucket('1 hour', time) AS bucket,
    symbol,
    SUM(close * volume) / SUM(volume) AS vwap
FROM trading_prices
GROUP BY bucket, symbol
ORDER BY bucket;

-- Hourly data from MATERIALIZED VIEW trading_prices_hourly

SELECT
    bucket,
    symbol,
    pv_sum / volume AS vwap
FROM trading_prices_hourly;