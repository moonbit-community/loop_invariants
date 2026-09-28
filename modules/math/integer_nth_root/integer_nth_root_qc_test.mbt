///|
fn big(x : Int64) -> @bigint.BigInt {
  @bigint.BigInt::from_int64(x)
}

///|
fn big_pow(b : Int64, e : Int) -> @bigint.BigInt {
  big_pow_n(big(b), e)
}

///|
fn big_pow_n(bb : @bigint.BigInt, e : Int) -> @bigint.BigInt {
  let mut acc = 1N
  for _ in 0..<e {
    acc = acc * bb
  }
  acc
}

///|
/// `r` is the floor `k`-th root of `x` iff `r^k <= x < (r + 1)^k`.
fn is_floor_root(r : Int64, x : Int64, k : Int) -> Bool {
  r >= 0L && big_pow(r, k) <= big(x) && big(x) < big_pow_n(big(r) + 1N, k)
}

///|
/// A radicand/exponent pair. Radicands mix arbitrary Int64 values (which
/// include negatives and extrema), exact powers `r^k` and their neighbours
/// (including those next to Int64::MAX), and small values.
priv struct RootCase {
  x : Int64
  k : Int
} derive(Debug)

///|
fn gen_exponent(rs : @quickcheck.RandomState) -> Int {
  match rs.next_uint(limit=10) {
    0 | 1 | 2 => 2
    3 | 4 => 3
    5 | 6 | 7 => 1 + rs.next_uint(limit=10).reinterpret_as_int()
    _ => 1 + rs.next_uint(limit=70).reinterpret_as_int()
  }
}

///|
/// Largest `r` with `r^k <= Int64::MAX`, by big-integer bisection.
fn max_base(k : Int) -> Int64 {
  let max = big(9223372036854775807L)
  let mut lo = 1L
  let mut hi = 3037000500L
  while hi - lo > 1L {
    let mid = lo + (hi - lo) / 2L
    if big_pow(mid, k) <= max {
      lo = mid
    } else {
      hi = mid
    }
  }
  lo
}

///|
impl @quickcheck.Arbitrary for RootCase with fn arbitrary(size, rs) {
  let k = gen_exponent(rs)
  let x = match rs.next_uint(limit=5) {
    0 => @quickcheck.Arbitrary::arbitrary(size, rs)
    1 => {
      let v : Int64 = @quickcheck.Arbitrary::arbitrary(size, rs)
      if v < 0L {
        -(v + 1L)
      } else {
        v
      }
    }
    2 => rs.next_uint(limit=5000).reinterpret_as_int().to_int64()
    3 =>
      9223372036854775807L -
      rs.next_uint(limit=3).reinterpret_as_int().to_int64()
    _ => {
      // r^k + delta, delta in {-1, 0, 1}, r uniform in [0, max_base(k)]
      // or the top base itself (so r^k is the largest k-th power).
      let top = max_base(k)
      let r = if rs.next_uint(limit=2) == 0 {
        top
      } else {
        rs
        .next_uint64(limit=(top + 1L).reinterpret_as_uint64())
        .reinterpret_as_int64()
      }
      let p = big_pow(r, k).to_int64()
      let delta = rs.next_uint(limit=3).reinterpret_as_int().to_int64() - 1L
      if delta > 0L && p == 9223372036854775807L {
        p
      } else if delta < 0L && p == 0L {
        0L
      } else {
        p + delta
      }
    }
  }
  { x, k, }
}

///|
impl @quickcheck.Shrink for RootCase with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.x, self.k)).map(p => { x: p.0, k: p.1, })
}

///|
test "qc: nth_root returns the floor root (r^k <= x < (r+1)^k)" {
  @quickcheck.check(
    (c : RootCase) => {
      is_floor_root(@integer_nth_root.nth_root(c.x, c.k), c.x, c.k)
    },
    filter=c => c.x >= 0L && c.k >= 1,
    count=1000,
    seed=31,
    observe=c => {
      let r = @integer_nth_root.nth_root(c.x, c.k)
      [
        @quickcheck.classify(big_pow(r, c.k) == big(c.x), "exact power"),
        @quickcheck.classify(c.x >= 4611686018427387904L, "x >= 2^62"),
        @quickcheck.classify(c.k == 2, "k = 2"),
        @quickcheck.classify(c.k > 10, "k > 10"),
      ]
    },
  )
}

///|
test "qc: isqrt and icbrt return floor roots for every non-negative Int64" {
  @quickcheck.check(
    (c : RootCase) => {
      is_floor_root(@integer_nth_root.isqrt(c.x), c.x, 2) &&
      is_floor_root(@integer_nth_root.icbrt(c.x), c.x, 3)
    },
    filter=c => c.x >= 0L,
    count=1000,
    seed=32,
  )
}

///|
test "qc: negative radicand or exponent < 1 gives 0 and no perfect power" {
  @quickcheck.check(
    (p : (Int64, Int)) => {
      let (x, k) = p
      if x < 0L || k < 1 {
        @integer_nth_root.nth_root(x, k) == 0L &&
        !@integer_nth_root.is_perfect_nth_power(x, k)
      } else {
        true
      }
    },
    filter=p => p.0 < 0L || p.1 < 1,
    count=300,
    seed=33,
  )
}

///|
test "qc: is_perfect_nth_power holds exactly for r^k" {
  @quickcheck.check(
    (c : RootCase) => {
      let r = @integer_nth_root.nth_root(c.x, c.k)
      @integer_nth_root.is_perfect_nth_power(c.x, c.k) ==
      (big_pow(r, c.k) == big(c.x))
    },
    filter=c => c.x >= 0L && c.k >= 1,
    count=1000,
    seed=34,
  )
}

///|
test "regression: roots of values near Int64::MAX terminate and are exact" {
  // Used to walk upward ~2 * 10^9 steps (isqrt) or forever (k = 5) because
  // a saturated power compared equal to Int64::MAX.
  let max = 9223372036854775807L
  @debug.assert_eq(@integer_nth_root.isqrt(max), 3037000499L)
  @debug.assert_eq(@integer_nth_root.isqrt(max - 1L), 3037000499L)
  @debug.assert_eq(@integer_nth_root.icbrt(max), 2097151L)
  @debug.assert_eq(@integer_nth_root.nth_root(max, 5), 6208L)
  @debug.assert_eq(@integer_nth_root.nth_root(max, 63), 1L)
  @debug.assert_eq(@integer_nth_root.is_perfect_nth_power(max, 2), false)
  @debug.assert_eq(
    @integer_nth_root.isqrt(3037000499L * 3037000499L),
    3037000499L,
  )
}
