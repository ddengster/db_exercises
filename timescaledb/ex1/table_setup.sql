
-- TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Create base table
DROP TABLE trading_prices CASCADE;
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
);

/*
-- Convert to hypertable function alternative (exclude the WITH(...) clause from the earlier CREATE TABLE statement ). 
-- Use for (1) migration of existing tables, (2) more granular control (e.g. space partitioning)
-- (3) compatibility with older deployments
SELECT create_hypertable(
    'trading_prices',
    'time',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);
*/

-- Optional: create index for faster symbol queries

CREATE INDEX idx_trading_prices_symbol_time ON trading_prices (symbol, time DESC);

--------------------------------------------------
-- Sample data inserts
--------------------------------------------------

INSERT INTO trading_prices (time, symbol, open, high, low, close, volume)
VALUES
('2026-01-01 09:30:00+00', 'AAPL', 190.5, 191.2, 189.8, 190.9, 1200000),
('2026-01-01 09:31:00+00', 'AAPL', 190.9, 191.5, 190.7, 191.3, 950000),
('2026-01-01 09:30:00+00', 'GOOG', 2800.0, 2812.5, 2795.0, 2805.3, 300000),
('2026-01-01 09:31:00+00', 'GOOG', 2805.3, 2810.0, 2801.2, 2808.8, 250000);

--------------------------------------------------
-- Optional: continuous aggregate (for OHLC per hour)
--------------------------------------------------

CREATE MATERIALIZED VIEW trading_prices_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS bucket,
    symbol,
    first(open, time) AS open,
    max(high) AS high,
    min(low) AS low,
    last(close, time) AS close,
    sum(volume) AS volume,
	SUM(close * volume) AS pv_sum
FROM trading_prices
GROUP BY bucket, symbol;

-- Refresh policy (optional automation)
SELECT add_continuous_aggregate_policy(
    'trading_prices_hourly',
    start_offset => INTERVAL '1 day',
    end_offset   => INTERVAL '1 minute',
    schedule_interval => INTERVAL '5 minutes'
);

