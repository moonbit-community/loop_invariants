///|
fn naive_gcd(a : Int64, b : Int64) -> Int64 {
  if b == 0L {
    a
  } else {
    naive_gcd(b, a % b)
  }
}

///|
/// phi(n) by definition: the number of 1 <= j <= n with gcd(j, n) == 1.
fn naive_phi(n : Int64) -> Int64 {
  let mut c = 0L
  for j in 1L..<=n {
    if naive_gcd(j, n) == 1L {
      c = c + 1L
    }
  }
  c
}

///|
/// A pair of moderately sized positive integers whose product stays below
/// 10^12, so `phi` (O(sqrt n)) of the product remains cheap. Often both
/// share a prime so the non-coprime branch is also exercised.
priv struct Factors {
  a : Int64
  b : Int64
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Factors with fn arbitrary(_size, rs) {
  let pick = fn() {
    match rs.next_uint(limit=3) {
      0 => rs.next_uint64(limit=100UL).reinterpret_as_int64() + 1L
      1 =>
        [2L, 4L, 8L, 1024L, 3L, 9L, 81L, 999983L, 65537L, 6L, 30L, 210L][rs
        .next_uint(limit=12)
        .reinterpret_as_int()]
      _ => rs.next_uint64(limit=1000000UL).reinterpret_as_int64() + 1L
    }
  }
  { a: pick(), b: pick(), }
}

///|
impl @quickcheck.Shrink for Factors with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.a, self.b))
  .filter(p => p.0 >= 1L && p.1 >= 1L)
  .map(p => { a: p.0, b: p.1, })
}

///|
test "qc: phi agrees with counting coprimes" {
  @quickcheck.check(
    (x : Int) => {
      let n = (x % 3000).to_int64()
      if n <= 0L {
        @euler_totient.phi(n) == 0L
      } else {
        @euler_totient.phi(n) == naive_phi(n)
      }
    },
    count=300,
    seed=41,
  )
}

///|
test "qc: sieve(n)[k] == phi(k) for every k <= n" {
  @quickcheck.check(
    (x : Int) => {
      let n = x % 2500
      let t = @euler_totient.sieve(n)
      if n < 0 {
        t.length() == 0
      } else {
        let mut ok = t.length() == n + 1 && t[0] == 0L
        for k in 1..<=n {
          ok = ok && t[k] == @euler_totient.phi(k.to_int64())
        }
        ok
      }
    },
    count=100,
    seed=42,
  )
}

///|
test "qc: phi is multiplicative on coprime pairs" {
  @quickcheck.check(
    (f : Factors) => {
      @euler_totient.phi(f.a * f.b) ==
      @euler_totient.phi(f.a) * @euler_totient.phi(f.b)
    },
    filter=f => naive_gcd(f.a, f.b) == 1L,
    count=300,
    seed=43,
  )
}

///|
test "qc: phi(a * b) * phi(g) == phi(a) * phi(b) * g for g = gcd(a, b)" {
  @quickcheck.check(
    (f : Factors) => {
      let g = naive_gcd(f.a, f.b)
      @euler_totient.phi(f.a * f.b) * @euler_totient.phi(g) ==
      @euler_totient.phi(f.a) * @euler_totient.phi(f.b) * g
    },
    count=300,
    seed=44,
    observe=f => {
      [
        @quickcheck.classify(naive_gcd(f.a, f.b) == 1L, "coprime"),
        @quickcheck.classify(f.a * f.b > 1000000000L, "product > 10^9"),
      ]
    },
  )
}

///|
test "qc: phi(n) is in [1, n], even for n > 2, and n - 1 exactly for primes" {
  @quickcheck.check(
    (x : Int64) => {
      let n = (if x < 0L { -(x + 1L) } else { x }) % 1000000000000L + 1L
      let v = @euler_totient.phi(n)
      let mut prime = n >= 2L
      for d = 2L; d * d <= n; d = d + 1L {
        if n % d == 0L {
          prime = false
          break
        }
      }
      v >= 1L && v <= n && (n <= 2L || v % 2L == 0L) && prime == (v == n - 1L)
    },
    count=200,
    seed=45,
  )
}

///|
#skip("slow; run with: MOON_WORK=off moon test -p euler_totient --include-skipped")
test "regression: phi of a prime above 3037000499^2 terminates" {
  // Skipped by default because of its runtime (the fixed loop still does
  // ~1.5 * 10^9 trial divisions, several seconds). Run it with
  //   MOON_WORK=off moon test -p euler_totient --include-skipped
  // The always-on white-box test "square guard ..." covers the guard itself.
  // `p * p > m` overflowed once p passed 3037000499, so trial division
  // never stopped for primes in (3037000499^2, Int64::MAX].
  @debug.assert_eq(
    @euler_totient.phi(9223372036854775783L),
    9223372036854775782L,
  )
}
