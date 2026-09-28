///|
/// Primes used as moduli: tiny ones (so n >= p inside Lucas), the usual
/// competitive-programming primes, and primes above 3037000499 where a
/// plain `a * b % p` overflows Int64.
let moduli : Array[Int64] = [
  2L, 3L, 5L, 7L, 13L, 101L, 998244353L, 1000000007L, 2147483647L, 3037000493L, 4294967311L,
  1000000000000000003L, 4611686018427387847L, 9223372036854775783L,
]

///|
/// Row `n` of Pascal's triangle on big integers.
fn pascal_row(n : Int) -> Array[@bigint.BigInt] {
  let mut row = [1N]
  for _ in 0..<n {
    let next = Array::make(row.length() + 1, 1N)
    for j in 1..<row.length() {
      next[j] = row[j - 1] + row[j]
    }
    row = next
  }
  row
}

///|
fn bmod(x : @bigint.BigInt, p : Int64) -> Int64 {
  (x % @bigint.BigInt::from_int64(p)).to_int64()
}

///|
/// A table query: modulus p, table size `size < p`, and a query (n, k)
/// that may fall outside the table or have k outside [0, n].
priv struct Query {
  p : Int64
  size : Int
  n : Int
  k : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Query with fn arbitrary(_size, rs) {
  let p = moduli[rs
    .next_uint(limit=moduli.length().reinterpret_as_uint())
    .reinterpret_as_int()]
  let cap = if p <= 200L { p.to_int() - 1 } else { 150 }
  let size = rs
    .next_uint(limit=(cap + 1).reinterpret_as_uint())
    .reinterpret_as_int()
  let n = rs
    .next_uint(limit=(size + 5).reinterpret_as_uint())
    .reinterpret_as_int() -
    2
  let k = rs
    .next_uint(limit=(size + 7).reinterpret_as_uint())
    .reinterpret_as_int() -
    3
  { p, size, n, k, }
}

///|
impl @quickcheck.Shrink for Query with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.size, self.n, self.k))
  .filter(t => t.0 >= 0 && t.0.to_int64() < self.p)
  .map(t => { p: self.p, size: t.0, n: t.1, k: t.2, })
}

///|
test "qc: BinomTable::choose equals Pascal's triangle mod p (0 outside the table)" {
  @quickcheck.check(
    (q : Query) => {
      let t = @binomial_mod.build(q.size, q.p)
      let expected = if q.n < 0 || q.n > q.size || q.k < 0 || q.k > q.n {
        0L
      } else {
        bmod(pascal_row(q.n)[q.k], q.p)
      }
      t.choose(q.n, q.k) == expected
    },
    count=400,
    seed=101,
    observe=q => {
      [
        @quickcheck.classify(q.p > 3037000499L, "p > sqrt(Int64::MAX)"),
        @quickcheck.classify(
          q.n >= 0 && q.n <= q.size && q.k >= 0 && q.k <= q.n,
          "query inside table",
        ),
      ]
    },
  )
}

///|
test "qc: BinomTable::factorial equals n! mod p" {
  @quickcheck.check(
    (q : Query) => {
      let t = @binomial_mod.build(q.size, q.p)
      let mut f = 1N
      for i in 1..<=q.n {
        f = f * @bigint.BigInt::from_int(i)
      }
      let expected = if q.n < 0 || q.n > q.size { 0L } else { bmod(f, q.p) }
      t.factorial(q.n) == expected
    },
    count=300,
    seed=102,
  )
}

///|
test "qc: lucas equals C(n, k) mod p for small n (n may exceed p)" {
  @quickcheck.check(
    (q : (Query, Int, Int)) => {
      let p = q.0.p
      let n = (q.1 % 120).abs()
      let k = q.2 % 125
      let expected = if k < 0 || k > n { 0L } else { bmod(pascal_row(n)[k], p) }
      @binomial_mod.lucas(n.to_int64(), k.to_int64(), p) == expected
    },
    filter=q => q.0.p < 1000L,
    count=300,
    seed=103,
  )
}

///|
/// Number of carries when adding `a` and `b` in base `p`.
fn carries(a : Int64, b : Int64, p : Int64) -> Int {
  let mut x = a
  let mut y = b
  let mut c = 0L
  let mut count = 0
  while x > 0L || y > 0L || c > 0L {
    let s = x % p + y % p + c
    c = if s >= p { 1L } else { 0L }
    count = count + c.to_int()
    x = x / p
    y = y / p
  }
  count
}

///|
test "qc: lucas(n, k, p) == 0 iff adding k and n - k in base p carries (Kummer)" {
  @quickcheck.check(
    (q : (Query, Int64, Int64)) => {
      let p = q.0.p
      let n = (q.1 % 1000000000000000000L).abs()
      let k = (q.2 % (n + 1L)).abs()
      (@binomial_mod.lucas(n, k, p) == 0L) == (carries(k, n - k, p) > 0)
    },
    filter=q => q.0.p < 200L,
    count=300,
    seed=104,
  )
}

///|
/// Exact C(n, k) on big integers via the multiplicative formula.
fn big_choose(n : Int64, k : Int64) -> @bigint.BigInt {
  let mut acc = 1N
  for i in 0L..<k {
    acc = acc *
      @bigint.BigInt::from_int64(n - i) /
      @bigint.BigInt::from_int64(i + 1L)
  }
  acc
}

///|
test "qc: lucas equals exact C(n, k) mod p for huge n and small k" {
  @quickcheck.check(
    (q : (Query, Int64, Int)) => {
      let p = q.0.p
      let n = if q.1 < 0L { -(q.1 + 1L) } else { q.1 }
      let k = (q.2 % 25).abs().to_int64()
      @binomial_mod.lucas(n, k, p) == bmod(big_choose(n, k), p)
    },
    count=300,
    seed=105,
    observe=q => [@quickcheck.classify(q.1.abs() >= q.0.p, "n >= p")],
  )
}

///|
test "regression: binomial tables and lucas with a modulus above 3037000499" {
  let p = 9223372036854775783L // prime
  let t = @binomial_mod.build(30, p)
  // 21! and C(30, 15) overflowed the plain `a * b % p` products.
  @debug.assert_eq(t.factorial(21), bmod(51090942171709440000N, p))
  @debug.assert_eq(t.choose(30, 15), 155117520L)
  @debug.assert_eq(t.choose(3, 3), 1L)
  // Lucas used to truncate the base-p digits to Int.
  @debug.assert_eq(
    @binomial_mod.lucas(5000000000L, 2L, 1000000000000000003L),
    499999997499999964L, // 12499999997500000000 mod (10^18 + 3)
  )
}
