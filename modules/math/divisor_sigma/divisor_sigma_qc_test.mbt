///|
/// sigma_k(n) on big integers by enumerating divisor pairs (d, n / d).
fn big_sigma(n : Int64, k : Int) -> @bigint.BigInt {
  let mut s = 0N
  let mut d = 1L
  while d * d <= n {
    if n % d == 0L {
      s = s + @bigint.BigInt::from_int64(d).pow(@bigint.BigInt::from_int(k))
      let e = n / d
      if e != d {
        s = s + @bigint.BigInt::from_int64(e).pow(@bigint.BigInt::from_int(k))
      }
    }
    d = d + 1L
  }
  s
}

///|
/// (n, k): n is either random (<= 10^10, so enumeration stays cheap) or a
/// prime power / smooth number whose sigma_k is close to Int64::MAX.
priv struct SigmaCase {
  n : Int64
  k : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for SigmaCase with fn arbitrary(_size, rs) {
  let k = match rs.next_uint(limit=4) {
    0 => 0
    1 => 1
    _ => rs.next_uint(limit=6).reinterpret_as_int()
  }
  let n = match rs.next_uint(limit=4) {
    0 => rs.next_uint64(limit=10000UL).reinterpret_as_int64() - 3L
    1 => 1L + rs.next_uint64(limit=10000000000UL).reinterpret_as_int64()
    _ => {
      // p^e with p small and e as large as fits in Int64, times a small cofactor
      let p = [2L, 3L, 5L, 7L, 11L, 13L][rs
        .next_uint(limit=6)
        .reinterpret_as_int()]
      let mut v = 1L
      let limit = 1 + rs.next_uint(limit=63).reinterpret_as_int()
      for _ in 0..<limit {
        if v > 9223372036854775807L / p {
          break
        }
        v = v * p
      }
      let c = 1L + rs.next_uint64(limit=3UL).reinterpret_as_int64()
      if v <= 9223372036854775807L / c {
        v * c
      } else {
        v
      }
    }
  }
  { n, k, }
}

///|
impl @quickcheck.Shrink for SigmaCase with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.n, self.k)).map(p => { n: p.0, k: p.1, })
}

///|
fn fits(x : @bigint.BigInt) -> Bool {
  x <= 9223372036854775807N
}

///|
fn smooth_or_small(n : Int64) -> Bool {
  // enumeration is O(sqrt n): only use it when n is small or 13-smooth
  let mut m = n
  for p in [2L, 3L, 5L, 7L, 11L, 13L] {
    while m > 0L && m % p == 0L {
      m = m / p
    }
  }
  n <= 10000000000L || m <= 3L
}

///|
/// sigma_k(n) for 13-smooth-times-small n via the prime-power formula on
/// big integers (avoids enumerating divisors of huge n).
fn big_sigma_fast(n : Int64, k : Int) -> @bigint.BigInt {
  if n <= 10000000000L {
    return big_sigma(n, k)
  }
  let mut m = n
  let mut total = 1N
  for p in [2L, 3L, 5L, 7L, 11L, 13L] {
    let mut term = 1N
    let mut pw = 1N
    let pk = @bigint.BigInt::from_int64(p).pow(@bigint.BigInt::from_int(k))
    while m % p == 0L {
      m = m / p
      pw = pw * pk
      term = term + pw
    }
    total = total * term
  }
  // remaining cofactor is 1, 2 or 3 but those primes were stripped; m == 1
  total
}

///|
test "qc: sigma_k equals the divisor-power sum whenever it fits in Int64" {
  @quickcheck.check(
    (c : SigmaCase) => {
      if c.n <= 0L {
        @divisor_sigma.sigma_k(c.n, c.k) == 0L
      } else {
        let expected = big_sigma_fast(c.n, c.k)
        !fits(expected) ||
        @bigint.BigInt::from_int64(@divisor_sigma.sigma_k(c.n, c.k)) == expected
      }
    },
    filter=c => smooth_or_small(c.n),
    count=500,
    seed=121,
    observe=c => {
      let big = c.n > 0L && fits(big_sigma_fast(c.n, c.k))
      [
        @quickcheck.classify(
          big && c.n > 1000000000000L,
          "large n, result fits",
        ),
        @quickcheck.classify(c.n > 0L && !big, "result overflows (skipped)"),
        @quickcheck.classify(c.k == 0, "k = 0"),
      ]
    },
  )
}

///|
test "qc: divisor_count and divisor_sum are sigma_0 and sigma_1" {
  @quickcheck.check(
    (c : SigmaCase) => {
      @divisor_sigma.divisor_count(c.n) == @divisor_sigma.sigma_k(c.n, 0) &&
      @divisor_sigma.divisor_sum(c.n) == @divisor_sigma.sigma_k(c.n, 1)
    },
    filter=c => smooth_or_small(c.n),
    count=300,
    seed=122,
  )
}

///|
test "qc: divisor_count agrees with enumeration" {
  @quickcheck.check(
    (x : Int) => {
      let n = (x % 100000).to_int64()
      let mut c = 0L
      for d in 1L..<=n {
        if n % d == 0L {
          c = c + 1L
        }
      }
      @divisor_sigma.divisor_count(n) == c
    },
    count=200,
    seed=123,
  )
}

///|
test "qc: divisor_count_sieve(n)[k] == divisor_count(k)" {
  @quickcheck.check(
    (x : Int) => {
      let n = x % 3000
      let t = @divisor_sigma.divisor_count_sieve(n)
      if n < 0 {
        t.length() == 0
      } else {
        let mut ok = t.length() == n + 1 && t[0] == 0L
        for k in 1..<=n {
          ok = ok && t[k] == @divisor_sigma.divisor_count(k.to_int64())
        }
        ok
      }
    },
    count=100,
    seed=124,
  )
}

///|
test "regression: sigma_k of a prime power whose closed-form numerator overflows" {
  // sigma_1(11^18) = (11^19 - 1) / 10 = 6115909044841454629 fits in Int64,
  // but 11^19 does not.
  @debug.assert_eq(
    @divisor_sigma.sigma_k(5559917313492231481L, 1),
    6115909044841454629L,
  )
  @debug.assert_eq(
    @divisor_sigma.divisor_sum(4052555153018976267L), // 3^39
    6078832729528464400L,
  )
}

///|
#skip("slow; run with: MOON_WORK=off moon test -p divisor_sigma --include-skipped")
test "regression: divisor_count / sigma_k of a prime above 3037000499^2 terminate" {
  // Skipped by default because of its runtime (the fixed loop still does
  // ~3 * 10^9 (twice) trial divisions, several seconds). Run it with
  //   MOON_WORK=off moon test -p divisor_sigma --include-skipped
  // The always-on white-box test "square guard ..." covers the guard itself.
  // `p * p <= m` overflowed once p passed 3037000499, so trial division
  // never stopped for primes in (3037000499^2, Int64::MAX].
  let p = 9223372036854775783L
  @debug.assert_eq(@divisor_sigma.divisor_count(p), 2L)
  @debug.assert_eq(@divisor_sigma.sigma_k(p, 1), p + 1L)
}
