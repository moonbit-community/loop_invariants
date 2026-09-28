///|
/// An odd modulus in (1, 2^31) -- the documented domain of `new` -- biased
/// towards the top of the range where Montgomery reduction is tightest --
/// with operands in [0, n) and an exponent.
priv struct MontCase {
  n : Int64
  a : Int64
  b : Int64
  e : Int64
} derive(Debug)

///|
fn below(rs : @quickcheck.RandomState, hi : Int64) -> Int64 {
  rs.next_uint64(limit=hi.reinterpret_as_uint64()).reinterpret_as_int64()
}

///|
impl @quickcheck.Arbitrary for MontCase with fn arbitrary(size, rs) {
  let n = match rs.next_uint(limit=4) {
    0 => 2147483647L - 2L * below(rs, 1000L)
    1 => 3L + 2L * below(rs, 50L)
    2 =>
      [998244353L, 1000000007L, 2147483647L, 3L, 2147483645L][rs
      .next_uint(limit=5)
      .reinterpret_as_int()]
    _ => 3L + 2L * below(rs, 1073741822L)
  }
  let operand = fn() {
    match rs.next_uint(limit=4) {
      0 => n - 1L - below(rs, 3L)
      1 => below(rs, 3L)
      _ => below(rs, n)
    }
  }
  let e = match rs.next_uint(limit=3) {
    0 => below(rs, 70L)
    _ => {
      let v : Int64 = @quickcheck.Arbitrary::arbitrary(size, rs)
      if v < 0L {
        -(v + 1L)
      } else {
        v
      }
    }
  }
  { n, a: operand(), b: operand(), e, }
}

///|
impl @quickcheck.Shrink for MontCase with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.a, self.b, self.e))
  .filter(t => {
    t.0 >= 0L && t.0 < self.n && t.1 >= 0L && t.1 < self.n && t.2 >= 0L
  })
  .map(t => { n: self.n, a: t.0, b: t.1, e: t.2, })
}

///|
fn ctx(n : Int64) -> @montgomery.MontgomeryCtx {
  @montgomery.new(n).unwrap()
}

///|
test "qc: new(n) is Some exactly for odd 1 < n < 2^31" {
  @quickcheck.check(
    (n : Int64) => {
      (@montgomery.new(n) is Some(_)) ==
      (n > 1L && n % 2L != 0L && n < 2147483648L)
    },
    count=1000,
    seed=171,
  )
}

///|
test "qc: mul_mod(a, b) == a * b mod n" {
  @quickcheck.check(
    (c : MontCase) => ctx(c.n).mul_mod(c.a, c.b) == c.a * c.b % c.n,
    count=1000,
    seed=172,
    observe=c => {
      [
        @quickcheck.classify(c.n > 2000000000L, "n > 2 * 10^9"),
        @quickcheck.classify(
          c.a >= c.n - 3L || c.b >= c.n - 3L,
          "operand near n",
        ),
      ]
    },
  )
}

///|
test "qc: from_mont(to_mont(a)) == a and mul_mont stays in [0, n)" {
  @quickcheck.check(
    (c : MontCase) => {
      let m = ctx(c.n)
      let am = m.to_mont(c.a)
      let bm = m.to_mont(c.b)
      let pm = m.mul_mont(am, bm)
      m.from_mont(am) == c.a && am >= 0L && am < c.n && pm >= 0L && pm < c.n
    },
    count=1000,
    seed=173,
  )
}

///|
test "qc: pow_mod(a, e) agrees with big-integer modular exponentiation" {
  @quickcheck.check(
    (c : MontCase) => {
      let expected = @bigint.BigInt::from_int64(c.a).pow(
        @bigint.BigInt::from_int64(c.e),
        modulus=@bigint.BigInt::from_int64(c.n),
      )
      @bigint.BigInt::from_int64(ctx(c.n).pow_mod(c.a, c.e)) == expected
    },
    count=500,
    seed=174,
  )
}

///|
test "regression: Montgomery reduction for moduli close to 2^31" {
  // x + m * n in redc exceeded Int64::MAX and the arithmetic shift of the
  // wrapped (negative) sum produced garbage.
  let n = 1895440521L
  @debug.assert_eq(
    ctx(n).mul_mod(280211609L, 1895440520L),
    280211609L * 1895440520L % n,
  )
  let p = 2147483647L
  @debug.assert_eq(
    @bigint.BigInt::from_int64(ctx(p).pow_mod(9L, 52L)),
    9N.pow(52N, modulus=2147483647N),
  )
  @debug.assert_eq(
    ctx(2147482995L).from_mont(ctx(2147482995L).to_mont(657801L)),
    657801L,
  )
}
