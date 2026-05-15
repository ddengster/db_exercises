
// to run: cd <q.exe directiony>, then q server_script.q

// setup table definitions
trades:([]time:`timestamp$();sym`symbol$();price`float$();size:`int$())

// data generation + timer loop
tickers: `AAPL`GOOG`TSLA

randomTrade: {
  sym: syms ? 1;      / pick random symbol from tickers
  price: 10 + 10?1f;  / random price from 10 to 20
  size: 1 + 100?100;  / random trade size
  (`trades insert (
    .z.p;        / utc timestamp$
	sym; price; size))
}

.z.ts: { randTrade[]; show last trade; }

// set timer
interval: 1000 / 1k milliseconds
\t interval

// start server
port: 5000
system "p", string port
  
  
  
