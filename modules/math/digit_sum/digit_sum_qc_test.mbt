///|
/// Reference digits of |n| in base b (least significant first) on big
/// integers, so |Int64::MIN| = 2^63 is handled.
fn ref_digits(n : Int64, base : Int) -> Array[Int] {
  let mut m = @bigint.BigInt::from_int64(n)
  if m < 0N {
    m = -m
  }
  if m.is_zero() {
    return [0]
  }
  let b = @bigint.BigInt::from_int(base)
  let out = []
  while !m.is_zero() {
    out.push((m % b).to_int())
    m = m / b
  }
  out
}

///|
/// (n, base): n arbitrary (the default Int64 generator hits 0, +-1 and the
/// extrema) or small; base usually 2..36, sometimes large or invalid.
priv struct DigitCase {
  n : Int64
  base : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for DigitCase with fn arbitrary(size, rs) {
  let base = match rs.next_uint(limit=10) {
    0 => rs.next_uint(limit=4).reinterpret_as_int() - 2
    1 => 37 + rs.next_uint(limit=2147483600).reinterpret_as_int()
    2 => 2
    3 => 10
    _ => 2 + rs.next_uint(limit=35).reinterpret_as_int()
  }
  let n = match rs.next_uint(limit=4) {
    0 => rs.next_uint64(limit=2000UL).reinterpret_as_int64() - 1000L
    1 =>
      [-9223372036854775808L, 9223372036854775807L, -9223372036854775807L, 0L][rs
      .next_uint(limit=4)
      .reinterpret_as_int()]
    _ => @quickcheck.Arbitrary::arbitrary(size, rs)
  }
  { n, base, }
}

///|
impl @quickcheck.Shrink for DigitCase with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.n, self.base)).map(p => {
    n: p.0,
    base: p.1,
  })
}

///|
test "qc: to_digits gives the base-b digits of |n|, least significant first" {
  @quickcheck.check(
    (c : DigitCase) => {
      let d = @digit_sum.to_digits(c.n, c.base)
      if c.base <= 1 {
        d.length() == 0
      } else {
        d == ref_digits(c.n, c.base)
      }
    },
    count=1000,
    seed=141,
    observe=c => {
      [
        @quickcheck.classify(c.base <= 1, "invalid base"),
        @quickcheck.classify(c.n < 0L, "negative n"),
        @quickcheck.classify(c.n == -9223372036854775808L, "Int64::MIN"),
      ]
    },
  )
}

///|
test "qc: from_digits inverts to_digits (for |n| representable)" {
  @quickcheck.check(
    (c : DigitCase) => {
      let abs = if c.n < 0L { -c.n } else { c.n }
      @digit_sum.from_digits(@digit_sum.to_digits(c.n, c.base), c.base) == abs
    },
    filter=c => c.base >= 2 && c.n != -9223372036854775808L,
    count=1000,
    seed=142,
  )
}

///|
test "qc: digit_sum, digit_count and digit_at agree with the digit list" {
  @quickcheck.check(
    (p : (DigitCase, Int)) => {
      let (c, pos) = p
      if c.base <= 1 {
        @digit_sum.digit_sum(c.n, c.base) == 0 &&
        @digit_sum.digit_count(c.n, c.base) == 0 &&
        @digit_sum.digit_at(c.n, pos, c.base) == 0
      } else {
        let d = ref_digits(c.n, c.base)
        let i = pos % 70
        let expected_at = if i < 0 || i >= d.length() { 0 } else { d[i] }
        @digit_sum.digit_sum(c.n, c.base) == d.fold(init=0, (a, x) => a + x) &&
        @digit_sum.digit_count(c.n, c.base) == d.length() &&
        @digit_sum.digit_at(c.n, i, c.base) == expected_at
      }
    },
    count=1000,
    seed=143,
  )
}

///|
test "qc: digital_root(n, b) == 1 + (|n| - 1) mod (b - 1) for n != 0" {
  @quickcheck.check(
    (c : DigitCase) => {
      let m = @bigint.BigInt::from_int64(c.n)
      let abs = if m < 0N { -m } else { m }
      let expected = if abs.is_zero() {
        0
      } else {
        1 + ((abs - 1N) % @bigint.BigInt::from_int(c.base - 1)).to_int()
      }
      @digit_sum.digital_root(c.n, c.base) == expected
    },
    filter=c => c.base >= 2,
    count=1000,
    seed=144,
  )
}

///|
test "qc: is_palindrome and reverse_digits agree with the digit list" {
  @quickcheck.check(
    (c : DigitCase) => {
      let d = ref_digits(c.n, c.base)
      let rev = d.rev()
      let mut r = 0N
      for x in d {
        r = r * @bigint.BigInt::from_int(c.base) + @bigint.BigInt::from_int(x)
      }
      @digit_sum.is_palindrome(c.n, c.base) == (d == rev) &&
      (
        r > 9223372036854775807N ||
        @bigint.BigInt::from_int64(@digit_sum.reverse_digits(c.n, c.base)) == r
      )
    },
    filter=c => c.base >= 2,
    count=1000,
    seed=145,
  )
}

///|
test "regression: digit functions on Int64::MIN use |n| = 2^63" {
  let min = -9223372036854775808L
  // 9223372036854775808
  @debug.assert_eq(@digit_sum.digit_sum(min, 10), 89)
  @debug.assert_eq(@digit_sum.digit_count(min, 10), 19)
  @debug.assert_eq(@digit_sum.digit_count(min, 2), 64)
  @debug.assert_eq(@digit_sum.digit_at(min, 18, 10), 9)
  @debug.assert_eq(@digit_sum.digital_root(min, 10), 8) // 2^63 mod 9 = 8
  @debug.assert_eq(@digit_sum.to_digits(min, 16), [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8,
  ])
  @debug.assert_eq(@digit_sum.reverse_digits(min, 2), 1L)
}

///|
test "regression: digital_root with a base above 2^30" {
  // The two base-1947750935 digits of 453012460437688947 sum to more than
  // Int::MAX, which overflowed the Int returned by digit_sum.
  let n = 453012460437688947L
  let b = 1947750935
  @debug.assert_eq(
    @digit_sum.digital_root(n, b),
    1 + ((n - 1L) % (b - 1).to_int64()).to_int(),
  )
}
