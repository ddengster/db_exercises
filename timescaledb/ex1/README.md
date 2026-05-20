
# timescaledb

Timescaledb is a drop in extension for postgresql! Can use base postgresql and drop in the optimization extension (with a few instructions for your tables)

Installation (self hosted): https://www.tigerdata.com/docs/get-started/choose-your-path/install-timescaledb#tab=linux

Guides: 

- https://www.youtube.com/watch?v=69Tzh_0lHJ8

- https://www.youtube.com/watch?v=ERtcMDuPVnU

- https://www.youtube.com/watch?v=c8_iHabi-nc

Docs: https://www.tigerdata.com/docs/reference/timescaledb

# Exercise: Trading data generation, switching timeframes capability & analysis (using postgresql + timescaledb extension)

Use postgresql/timescaledb to:

1) Populate a table with ticker price data every minute. Use hypertables for optimization.

2) Make views that build upon this data so we can enable timeframe switching.

3) Compute vwap on both minute and hourly timeframes


## Populate a table with ticker price data every minute. Use hypertables for optimization

There are 2 ways to create hypertables:

1) The recommended way (since TimescaleDB 2.11+), append table creation statements with the `WITH (tsdb.xxx)` clause : 

```
CREATE TABLE trading_prices (
    time        TIMESTAMPTZ       NOT NULL,
    symbol      TEXT              NOT NULL,
    open        DOUBLE PRECISION,
    high        DOUBLE PRECISION,
    low         DOUBLE PRECISION,
    close       DOUBLE PRECISION,
    volume      BIGINT,
    PRIMARY KEY (time, symbol)
)
WITH (
    tsdb.hypertable,
    tsdb.partition_column = 'time',
    tsdb.chunk_interval = '1 day'
)
```

2) Use the `create_hypertable` function. Good for migration of older tables, or . Note that (1) uses `create_hypertable` internally

```
SELECT create_hypertable(
    'trading_prices',
    'time',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);
```

Populating data as per usual via sql:

```
INSERT INTO trading_prices (time, symbol, open, high, low, close, volume)
VALUES
('2026-01-01 09:30:00+00', 'AAPL', 190.5, 191.2, 189.8, 190.9, 1200000),
('2026-01-01 09:31:00+00', 'AAPL', 190.9, 191.5, 190.7, 191.3, 950000),
('2026-01-01 09:30:00+00', 'GOOG', 2800.0, 2812.5, 2795.0, 2805.3, 300000),
('2026-01-01 09:31:00+00', 'GOOG', 2805.3, 2810.0, 2801.2, 2808.8, 250000);
```

## Make views that build upon this data so we can enable timeframe switching.

We can build upon this per-minute ticker price in `trading_prices` via creating a materialed view, bucketing timestamp data into an hour each.

Documentation: https://www.tigerdata.com/docs/reference/timescaledb/continuous-aggregates

```
CREATE MATERIALIZED VIEW trading_prices_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS bucket,
    symbol,
    first(open, time) AS open,
    max(high) AS high,
    min(low) AS low,
    last(close, time) AS close,
    sum(volume) AS volume
FROM trading_prices
GROUP BY bucket, symbol;

-- Refresh policy (optional automation)
SELECT add_continuous_aggregate_policy(
    'trading_prices_hourly',
    start_offset => INTERVAL '1 day',
    end_offset   => INTERVAL '1 minute',
    schedule_interval => INTERVAL '5 minutes'
);
```

We then use `add_continuous_aggregate_policy` to keep it up to date.

Also take a look at hyperfunctions: https://www.tigerdata.com/docs/reference/timescaledb/hyperfunctions - we use some of them for time-series related stuff eg. `time_bucket`, `first()`, `last()`


### Compute vwap on both minute and hourly timeframes

Check vwap_compute.sql

```

-- Minute data 

SELECT
    symbol,
    SUM(close * volume) / SUM(volume) AS vwap
FROM trading_prices
WHERE time >= '2026-01-01 09:30:00+00'
  AND time <  '2026-01-01 16:00:00+00'
GROUP BY symbol;
```

```
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
```

#### Executing

`psql -d "postgres://postgres:postgres@127.0.0.1:5432/" -f table_setup.sql`

where `postgres:postgres` is username:password

### Other references

- https://github.com/timescale/examples