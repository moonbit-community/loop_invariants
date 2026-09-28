///|
/// A pair of `Int64` operands drawn from a mix of distributions: arbitrary
/// 64-bit values (which include the extrema), small values, and pairs that
/// share a common factor so that non-trivial gcds are frequent.
priv struct Pair {
  a : Int64
  b : Int64
} derive(Debug)

///|
fn small(rs : @quickcheck.RandomState, bound : Int64) -> Int64 {
  rs
  .next_uint64(limit=(2L * bound + 1L).reinterpret_as_uint64())
  .reinterpret_as_int64() -
  bound
}

///|
fn operand(size : Int, rs : @quickcheck.RandomState) -> Int64 {
  match rs.next_uint(limit=4) {
    0 | 1 => @quickcheck.Arbitrary::arbitrary(size, rs)
    2 => small(rs, 1000L)
    _ =>
      [
        0L, 1L, -1L, 2L, 9223372036854775807L, -9223372036854775807L, -9223372036854775808L,
        4611686018427387904L, 4294967296L, 2147483648L,
      ][rs.next_uint(limit=10).reinterpret_as_int()]
  }
}

///|
impl @quickcheck.Arbitrary for Pair with fn arbitrary(size, rs) {
  if rs.next_uint(limit=3) == 0 {
    // shared factor g: a = g * x, b = g * y with small cofactors
    let g = small(rs, 1000000000L)
    { a: g * small(rs, 1000L), b: g * small(rs, 1000L), }
  } else {
    { a: operand(size, rs), b: operand(size, rs), }
  }
}

///|
impl @quickcheck.Shrink for Pair with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.a, self.b)).map(p => { a: p.0, b: p.1, })
}

///|
fn big(x : Int64) -> @bigint.BigInt {
  @bigint.BigInt::from_int64(x)
}

///|
fn babs(x : @bigint.BigInt) -> @bigint.BigInt {
  if x < 0N {
    -x
  } else {
    x
  }
}

///|
/// Mathematical gcd of `|a|` and `|b|` computed on big integers.
fn big_gcd(a : @bigint.BigInt, b : @bigint.BigInt) -> @bigint.BigInt {
  let mut x = babs(a)
  let mut y = babs(b)
  while !y.is_zero() {
    let t = x % y
    x = y
    y = t
  }
  x
}

///|
/// `gcd(|a|, |b|)` is representable unless both operands are in `{0, MIN}`
/// and at least one of them is `MIN` (then it equals `2^63`).
fn representable(p : Pair) -> Bool {
  let min = -9223372036854775808L
  !((p.a == min || p.a == 0L) &&
  (p.b == min || p.b == 0L) &&
  (p.a == min || p.b == min))
}

///|
test "qc: gcd agrees with naive divisor search on small inputs" {
  @quickcheck.check(
    (p : (Int, Int)) => {
      let a = (p.0 % 600).to_int64()
      let b = (p.1 % 600).to_int64()
      let abs_a = if a < 0L { -a } else { a }
      let abs_b = if b < 0L { -b } else { b }
      let expected = if abs_a == 0L && abs_b == 0L {
        0L
      } else {
        let mut best = 1L
        let hi = if abs_a > abs_b { abs_a } else { abs_b }
        for d in 1L..<=hi {
          if abs_a % d == 0L && abs_b % d == 0L {
            best = d
          }
        }
        best
      }
      @extended_gcd.gcd(a, b) == expected
    },
    count=300,
    seed=1,
  )
}

///|
test "qc: gcd equals the big-integer gcd for all representable inputs" {
  @quickcheck.check(
    (p : Pair) => {
      big(@extended_gcd.gcd(p.a, p.b)) == big_gcd(big(p.a), big(p.b))
    },
    filter=representable,
    count=1000,
    seed=2,
    observe=p => {
      let g = big_gcd(big(p.a), big(p.b))
      [
        @quickcheck.classify(g == 1N, "coprime"),
        @quickcheck.classify(g > 1N, "g > 1"),
        @quickcheck.classify(
          p.a == -9223372036854775808L || p.b == -9223372036854775808L,
          "Int64 MIN operand",
        ),
      ]
    },
  )
}

///|
test "qc: gcd is symmetric and invariant under sign changes" {
  @quickcheck.check(
    (p : Pair) => {
      let min = -9223372036854775808L
      let g = @extended_gcd.gcd(p.a, p.b)
      g == @extended_gcd.gcd(p.b, p.a) &&
      (p.a == min || g == @extended_gcd.gcd(-p.a, p.b)) &&
      (p.b == min || g == @extended_gcd.gcd(p.a, -p.b))
    },
    filter=representable,
    count=500,
    seed=3,
  )
}

///|
test "qc: bezout returns (gcd, x, y) with a*x + b*y == g" {
  @quickcheck.check(
    (p : Pair) => {
      let (g, x, y) = @extended_gcd.bezout(p.a, p.b)
      big(g) == big_gcd(big(p.a), big(p.b)) &&
      big(p.a) * big(x) + big(p.b) * big(y) == big(g)
    },
    filter=representable,
    count=1000,
    seed=4,
  )
}

///|
test "qc: bezout coefficients are small (|x| <= |b|/g, |y| <= |a|/g)" {
  @quickcheck.check(
    (p : Pair) => {
      let (g, x, y) = @extended_gcd.bezout(p.a, p.b)
      if g == 0L {
        x == 0L && y == 0L
      } else {
        let bg = big(g)
        babs(big(x)) <= bmax(babs(big(p.b)) / bg, 1N) &&
        babs(big(y)) <= bmax(babs(big(p.a)) / bg, 1N)
      }
    },
    filter=representable,
    count=1000,
    seed=5,
  )
}

///|
test "qc: mod_inverse is Some(inverse in [0, m)) exactly when gcd(a, m) == 1" {
  @quickcheck.check(
    (p : Pair) => {
      let (a, m) = (p.a, p.b)
      match @extended_gcd.mod_inverse(a, m) {
        None => m <= 0L || big_gcd(big(a), big(m)) != 1N
        Some(x) => {
          let bm = big(m)
          m > 0L && x >= 0L && x < m && ((big(a) * big(x) - 1N) % bm).is_zero()
        }
      }
    },
    count=1000,
    seed=6,
  )
}

///|
fn bmax(x : @bigint.BigInt, y : @bigint.BigInt) -> @bigint.BigInt {
  if x > y {
    x
  } else {
    y
  }
}

///|
test "regression: gcd with Int64::MIN operand is non-negative" {
  let min = -9223372036854775808L
  @debug.assert_eq(@extended_gcd.gcd(min, 6L), 2L)
  @debug.assert_eq(@extended_gcd.gcd(min, 145L), 1L)
  @debug.assert_eq(@extended_gcd.gcd(6L, min), 2L)
  @debug.assert_eq(
    @extended_gcd.gcd(min, 4611686018427387904L),
    4611686018427387904L,
  )
}

///|
test "regression: bezout with Int64::MIN operand" {
  let min = -9223372036854775808L
  let (g, x, y) = @extended_gcd.bezout(min, -1601378383065578544L)
  @debug.assert_eq(g, 16L)
  @debug.assert_eq(big(min) * big(x) + big(-1601378383065578544L) * big(y), 16N)
  @debug.assert_eq(@extended_gcd.bezout(min, -1L), (1L, 0L, -1L))
  @debug.assert_eq(@extended_gcd.mod_inverse(min, 3L), Some(1L))
}

///|
test "regression: bezout y coefficient when b*y overflows Int64" {
  // True answer: 5 * (-1846490246253618291) + 4616225615634045728 * 2 = 1,
  // but b * y = 9232451231268091456 does not fit in Int64.
  @debug.assert_eq(
    @extended_gcd.bezout(5L, 4616225615634045728L),
    (1L, -1846490246253618291L, 2L),
  )
}
