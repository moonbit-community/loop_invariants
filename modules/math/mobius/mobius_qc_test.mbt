///|
/// mu(n) from its definition via trial-division factorisation.
fn naive_mu(n : Int64) -> Int {
  if n <= 0L {
    return 0
  }
  let mut m = n
  let mut sign = 1
  let mut d = 2L
  while d * d <= m {
    if m % d == 0L {
      m = m / d
      if m % d == 0L {
        return 0
      }
      sign = -sign
    }
    d = d + 1L
  }
  if m > 1L {
    sign = -sign
  }
  sign
}

///|
/// Positive integers up to 10^12 built from random prime-ish factors,
/// squared factors (to hit mu = 0), plain random values, and non-positive
/// values.
priv struct Arg {
  n : Int64
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Arg with fn arbitrary(size, rs) {
  let n = match rs.next_uint(limit=5) {
    0 => {
      let v : Int64 = @quickcheck.Arbitrary::arbitrary(size, rs)
      if v <= 0L {
        v
      } else {
        v % 1000000000000L
      }
    }
    1 => rs.next_uint64(limit=100000UL).reinterpret_as_int64()
    2 => {
      // product of distinct-ish small factors
      let mut acc = 1L
      for _ in 0..<(1 + rs.next_uint(limit=6).reinterpret_as_int()) {
        acc = acc * (2L + rs.next_uint64(limit=90UL).reinterpret_as_int64())
      }
      acc
    }
    3 => {
      let q = 2L + rs.next_uint64(limit=1000UL).reinterpret_as_int64()
      q * q * (1L + rs.next_uint64(limit=100000UL).reinterpret_as_int64())
    }
    _ => 1L + rs.next_uint64(limit=1000000000000UL).reinterpret_as_int64()
  }
  { n, }
}

///|
impl @quickcheck.Shrink for Arg with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.n).map(n => { n, })
}

///|
test "qc: mu agrees with the factorisation definition" {
  @quickcheck.check(
    (a : Arg) => @mobius.mu(a.n) == naive_mu(a.n),
    count=300,
    seed=111,
    observe=a => {
      let m = naive_mu(a.n)
      [
        @quickcheck.classify(m == 0, "mu = 0"),
        @quickcheck.classify(m == 1, "mu = 1"),
        @quickcheck.classify(m == -1, "mu = -1"),
        @quickcheck.classify(a.n <= 0L, "n <= 0"),
      ]
    },
  )
}

///|
test "qc: sieve(n)[k] == mu(k) for every k <= n" {
  @quickcheck.check(
    (x : Int) => {
      let n = x % 3000
      let t = @mobius.sieve(n)
      if n < 0 {
        t.length() == 0
      } else {
        let mut ok = t.length() == n + 1 && t[0] == 0
        for k in 1..<=n {
          ok = ok && t[k] == @mobius.mu(k.to_int64())
        }
        ok
      }
    },
    count=100,
    seed=112,
  )
}

///|
test "qc: sum of mu(d) over the divisors d of n is [n == 1]" {
  @quickcheck.check(
    (x : Int) => {
      let n = (x % 20000).abs().to_int64() + 1L
      let mut s = 0
      for d in 1L..<=n {
        if n % d == 0L {
          s = s + @mobius.mu(d)
        }
      }
      s == (if n == 1L { 1 } else { 0 })
    },
    count=150,
    seed=113,
  )
}

///|
test "qc: mu is multiplicative on coprime arguments" {
  @quickcheck.check(
    (p : (Int, Int)) => {
      let a = (p.0 % 1000000).abs().to_int64() + 1L
      let b = (p.1 % 1000000).abs().to_int64() + 1L
      let mut x = a
      let mut y = b
      while y != 0L {
        let t = x % y
        x = y
        y = t
      }
      x != 1L || @mobius.mu(a * b) == @mobius.mu(a) * @mobius.mu(b)
    },
    count=300,
    seed=114,
  )
}

///|
#skip("slow; run with: MOON_WORK=off moon test -p mobius --include-skipped")
test "regression: mu of a prime above 3037000499^2 terminates" {
  // Skipped by default because of its runtime (the fixed loop still does
  // ~1.5 * 10^9 trial divisions, several seconds). Run it with
  //   MOON_WORK=off moon test -p mobius --include-skipped
  // The always-on white-box test "square guard ..." covers the guard itself.
  // `p * p <= m` overflowed once p passed 3037000499, so trial division
  // never stopped for primes in (3037000499^2, Int64::MAX].
  @debug.assert_eq(@mobius.mu(9223372036854775783L), -1)
}
