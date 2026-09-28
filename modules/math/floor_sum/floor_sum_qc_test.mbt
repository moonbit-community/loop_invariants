///|
fn big(x : Int64) -> @bigint.BigInt {
  @bigint.BigInt::from_int64(x)
}

///|
/// Exact floor sum on big integers (ACL recurrence), used as an oracle for
/// parameters too large to sum term by term.
fn big_floor_sum(
  n : @bigint.BigInt,
  m : @bigint.BigInt,
  a : @bigint.BigInt,
  b : @bigint.BigInt,
) -> @bigint.BigInt {
  if n.is_zero() {
    return 0N
  }
  let mut ans = 0N
  let mut a = a
  let mut b = b
  if a >= m {
    ans = ans + n * (n - 1N) / 2N * (a / m)
    a = a % m
  }
  if b >= m {
    ans = ans + n * (b / m)
    b = b % m
  }
  let y_max = a * n + b
  if y_max < m {
    return ans
  }
  ans + big_floor_sum(y_max / m, a, m, y_max % m)
}

///|
/// Parameters with 0 <= a, b and m >= 1 and n * m <= 2^62 (the README's
/// overflow caveat is about `a * n` reaching `m * n`), possibly n <= 0.
priv struct FsCase {
  n : Int64
  m : Int64
  a : Int64
  b : Int64
} derive(Debug)

///|
fn upto(rs : @quickcheck.RandomState, hi : Int64) -> Int64 {
  rs.next_uint64(limit=(hi + 1L).reinterpret_as_uint64()).reinterpret_as_int64()
}

///|
impl @quickcheck.Arbitrary for FsCase with fn arbitrary(_size, rs) {
  let bits = rs.next_uint(limit=63).reinterpret_as_int()
  let m = 1L + upto(rs, (1L << bits) - 1L)
  let n_max = 4611686018427387904L / m
  let n = match rs.next_uint(limit=4) {
    0 => upto(rs, 3L) - 1L
    1 => upto(rs, n_max)
    _ => upto(rs, if n_max < 5000000000L { n_max } else { 5000000000L })
  }
  let pick = fn() {
    match rs.next_uint(limit=4) {
      0 => upto(rs, 3L)
      1 => upto(rs, m - 1L)
      2 => m * upto(rs, 3L) + upto(rs, m - 1L)
      _ => upto(rs, 9223372036854775806L)
    }
  }
  { n, m, a: pick(), b: pick(), }
}

///|
impl @quickcheck.Shrink for FsCase with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.n, self.m, self.a, self.b))
  .filter(t => {
    t.1 >= 1L && t.2 >= 0L && t.3 >= 0L && t.0 <= 4611686018427387904L / t.1
  })
  .map(t => { n: t.0, m: t.1, a: t.2, b: t.3, })
}

///|
test "qc: floor_sum equals the term-by-term sum on small inputs" {
  @quickcheck.check(
    (p : (Int, Int, Int, Int)) => {
      let n = (p.0 % 200).to_int64()
      let m = (p.1 % 1000).abs().to_int64() + 1L
      let a = (p.2 % 1000000).abs().to_int64()
      let b = (p.3 % 1000000).abs().to_int64()
      let mut s = 0L
      for i in 0L..<n {
        s = s + (a * i + b) / m
      }
      @floor_sum.floor_sum(n, m, a, b) == s
    },
    count=500,
    seed=151,
  )
}

///|
test "qc: floor_sum equals the exact sum whenever it fits in Int64" {
  @quickcheck.check(
    (c : FsCase) => {
      let expected = if c.n <= 0L {
        0N
      } else {
        big_floor_sum(big(c.n), big(c.m), big(c.a), big(c.b))
      }
      expected > 9223372036854775807N ||
      big(@floor_sum.floor_sum(c.n, c.m, c.a, c.b)) == expected
    },
    count=1000,
    seed=152,
    observe=c => {
      let e = if c.n <= 0L {
        0N
      } else {
        big_floor_sum(big(c.n), big(c.m), big(c.a), big(c.b))
      }
      [
        @quickcheck.classify(
          e > 9223372036854775807N,
          "sum overflows (skipped)",
        ),
        @quickcheck.classify(
          e > 1000000000000000000N && e <= 9223372036854775807N,
          "sum in (10^18, MAX]",
        ),
        @quickcheck.classify(c.n > 3037000499L, "n > 3037000499"),
      ]
    },
  )
}

///|
test "regression: floor_sum with n > 3037000499" {
  // (n - 1) * n overflowed Int64 in the slope-reduction step although the
  // sum itself fits: sum_{i < 4 * 10^9} i = 7999999998000000000.
  @debug.assert_eq(
    @floor_sum.floor_sum(4000000000L, 1L, 1L, 0L),
    7999999998000000000L,
  )
  // Found by the property: the recursion reaches n0 ~ 3.04 * 10^9 with
  // a0 >= m0.
  @debug.assert_eq(
    @bigint.BigInt::from_int64(
      @floor_sum.floor_sum(4486224862L, 9940L, 6729L, 12522L),
    ),
    big_floor_sum(4486224862N, 9940N, 6729N, 12522N),
  )
}
