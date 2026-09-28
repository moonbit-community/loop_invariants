///|
fn big(x : Int64) -> @bigint.BigInt {
  @bigint.BigInt::from_int64(x)
}

///|
fn big_pow(b : Int64, e : Int) -> @bigint.BigInt {
  let mut acc = 1N
  for _ in 0..<e {
    acc = acc * big(b)
  }
  acc
}

///|
/// `true` iff `x == r^k` for some integers `r >= 2`, `k >= 2` (reference:
/// bisection for the k-th root on big integers, for each k up to 62).
fn ref_perfect_power(x : Int64) -> Bool {
  if x < 4L {
    return false
  }
  let bx = big(x)
  for k in 2..<=62 {
    let mut lo = 1L
    let mut hi = 3037000500L
    while hi - lo > 1L {
      let mid = lo + (hi - lo) / 2L
      if big_pow(mid, k) <= bx {
        lo = mid
      } else {
        hi = mid
      }
    }
    if lo >= 2L && big_pow(lo, k) == bx {
      return true
    }
    if lo < 2L {
      break
    }
  }
  false
}

///|
/// (x, b): x is arbitrary (incl. negatives, 0, extrema), a power b^k or
/// r^k with neighbours (including next to Int64::MAX), or small; b is
/// usually 2..16, sometimes huge or invalid (<= 1).
priv struct LogCase {
  x : Int64
  b : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for LogCase with fn arbitrary(size, rs) {
  let b = match rs.next_uint(limit=10) {
    0 => rs.next_uint(limit=4).reinterpret_as_int() - 2 // -2..1
    1 => @quickcheck.Arbitrary::arbitrary(size, rs)
    2 => 1000000 + rs.next_uint(limit=3000000000).reinterpret_as_int().abs()
    _ => 2 + rs.next_uint(limit=15).reinterpret_as_int()
  }
  let x = match rs.next_uint(limit=5) {
    0 => @quickcheck.Arbitrary::arbitrary(size, rs)
    1 => rs.next_uint64(limit=1000UL).reinterpret_as_int64()
    2 => 9223372036854775807L - rs.next_uint64(limit=3UL).reinterpret_as_int64()
    _ => {
      // r^k + delta with r in 2..20 (or the base itself) and k maximal-ish
      let r = if b >= 2 && rs.next_uint(limit=2) == 0 {
        b.to_int64()
      } else {
        2L + rs.next_uint64(limit=19UL).reinterpret_as_int64()
      }
      let mut v = 1L
      let k = rs.next_uint(limit=64).reinterpret_as_int()
      for _ in 0..<k {
        if v > 9223372036854775807L / r {
          break
        }
        v = v * r
      }
      let delta = rs.next_uint64(limit=3UL).reinterpret_as_int64() - 1L
      if delta > 0L && v == 9223372036854775807L {
        v
      } else {
        v + delta
      }
    }
  }
  { x, b, }
}

///|
impl @quickcheck.Shrink for LogCase with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.x, self.b)).map(p => { x: p.0, b: p.1, })
}

///|
test "qc: floor_log(x, b) is the k with b^k <= x < b^(k+1)" {
  @quickcheck.check(
    (c : LogCase) => {
      let k = @integer_log.floor_log(c.x, c.b)
      if c.x <= 0L || c.b <= 1 {
        k == -1
      } else {
        let b = c.b.to_int64()
        k >= 0 && big_pow(b, k) <= big(c.x) && big(c.x) < big_pow(b, k + 1)
      }
    },
    count=1000,
    seed=131,
    observe=c => {
      [
        @quickcheck.classify(c.x <= 0L || c.b <= 1, "invalid input"),
        @quickcheck.classify(
          c.b >= 2 && c.x > 0L && @integer_log.is_power_of(c.x, c.b),
          "exact power of b",
        ),
        @quickcheck.classify(c.x >= 4611686018427387904L, "x >= 2^62"),
      ]
    },
  )
}

///|
test "qc: ceil_log(x, b) is the k with b^(k-1) < x <= b^k" {
  @quickcheck.check(
    (c : LogCase) => {
      let k = @integer_log.ceil_log(c.x, c.b)
      if c.x <= 0L || c.b <= 1 {
        k == -1
      } else {
        let b = c.b.to_int64()
        k >= 0 &&
        big(c.x) <= big_pow(b, k) &&
        (k == 0 || big_pow(b, k - 1) < big(c.x))
      }
    },
    count=1000,
    seed=132,
  )
}

///|
test "qc: is_power_of(x, b) iff x == b^k for some k >= 0" {
  @quickcheck.check(
    (c : LogCase) => {
      let expected = if c.x <= 0L || c.b <= 1 {
        false
      } else {
        let k = @integer_log.floor_log(c.x, c.b)
        big_pow(c.b.to_int64(), k) == big(c.x)
      }
      @integer_log.is_power_of(c.x, c.b) == expected
    },
    count=1000,
    seed=133,
  )
}

///|
test "qc: log2_floor / log2_ceil agree with the bit length" {
  @quickcheck.check(
    (x : Int64) => {
      if x <= 0L {
        @integer_log.log2_floor(x) == -1 && @integer_log.log2_ceil(x) == -1
      } else {
        let f = 63 - x.clz()
        let c = if x.popcnt() == 1 { f } else { f + 1 }
        @integer_log.log2_floor(x) == f && @integer_log.log2_ceil(x) == c
      }
    },
    count=1000,
    seed=134,
  )
}

///|
test "qc: is_perfect_power agrees with a big-integer root search" {
  @quickcheck.check(
    (c : LogCase) => {
      @integer_log.is_perfect_power(c.x) == ref_perfect_power(c.x)
    },
    count=300,
    seed=135,
    observe=c => [@quickcheck.classify(ref_perfect_power(c.x), "perfect power")],
  )
}

///|
test "regression: is_perfect_power near Int64::MAX terminates" {
  // The internal k-th root compared a saturated power against x ==
  // Int64::MAX and walked upward forever.
  @debug.assert_eq(@integer_log.is_perfect_power(9223372036854775807L), false)
  @debug.assert_eq(@integer_log.is_perfect_power(9223372030926249001L), true) // 3037000499^2
  @debug.assert_eq(@integer_log.is_perfect_power(9223372036854775806L), false)
  @debug.assert_eq(@integer_log.is_perfect_power(4611686018427387904L), true) // 2^62
}
