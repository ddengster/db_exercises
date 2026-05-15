
// to run: cd <q.exe directiony>, then q server_script.q

// setup table definitions
trades:([]time:`timestamp$();sym:`symbol$();price:`float$();size:`int$())

// data generation
tickers:`AAPL`GOOG`TSLA

n:30;
dt: n?1000;
t:.z.p + sums dt; / sums computes the cumulative sum (running total) of a list (in this case dt)

rows:([]
  time:t;
  sym:n?tickers;
  price:100 + 10 * n?1f;
  size:1 + n?100
  )
`trades insert rows

// define function
emaFunction:{[table;ticker;n]
  show "running EMA";
  pricelist:exec price from table where sym=ticker;
  ma: ema[n;pricelist];
  ma} / returns ma

/ output:
/ 104.1232 103.9699 108.8848 109.1767 106.3239 101.512 98.97826 115.548 102.8849 98.58471 108.2363 102.8615

// start server
port: 5000
system "p ", string port

