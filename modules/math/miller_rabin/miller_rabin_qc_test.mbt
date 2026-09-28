///|
/// Trial-division primality, the definition itself. Only used for
/// `n <= 10^12` so that `d * d` never overflows and the loop stays short.
fn trial_is_prime(n : Int64) -> Bool {
  if n < 2L {
    return false
  }
  let mut d = 2L
  while d * d <= n {
    if n % d == 0L {
      return false
    }
    d = d + 1L
  }
  true
}

///|
/// Independent reference: deterministic Miller-Rabin with bases 2..37 on
/// arbitrary-precision integers (correct for all n < 3.3 * 10^24), so no
/// modular multiplication can overflow.
fn big_is_prime(n : Int64) -> Bool {
  if n < 2L {
    return false
  }
  let bases = [2L, 3L, 5L, 7L, 11L, 13L, 17L, 19L, 23L, 29L, 31L, 37L]
  for p in bases {
    if n == p {
      return true
    }
    if n % p == 0L {
      return false
    }
  }
  let bn = @bigint.BigInt::from_int64(n)
  let n1 = bn - 1N
  let mut d = n1
  let mut s = 0
  while (d % 2N).is_zero() {
    d = d / 2N
    s = s + 1
  }
  for a in bases {
    let mut x = @bigint.BigInt::from_int64(a).pow(d, modulus=bn)
    if x == 1N || x == n1 {
      continue
    }
    let mut witness = true
    for _ in 1..<s {
      x = x * x % bn
      if x == n1 {
        witness = false
        break
      }
    }
    if witness {
      return false
    }
  }
  true
}

///|
/// A candidate integer: arbitrary 64-bit values (including extrema), odd
/// values in the top range `[2^62, 2^63)` where modular doubling can
/// overflow, primes and prime products near the Int64 limit, and small values.
priv struct Candidate {
  n : Int64
} derive(Debug)

///|
fn below(rs : @quickcheck.RandomState, hi : Int64) -> Int64 {
  rs.next_uint64(limit=hi.reinterpret_as_uint64()).reinterpret_as_int64()
}

///|
impl @quickcheck.Arbitrary for Candidate with fn arbitrary(size, rs) {
  let top = 4611686018427387904L // 2^62
  let n = match rs.next_uint(limit=7) {
    0 => @quickcheck.Arbitrary::arbitrary(size, rs)
    1 => (top + below(rs, top)) | 1L
    2 => below(rs, 100000L) - 10L
    3 =>
      // near the top: max_value - k
      9223372036854775807L - below(rs, 2000L)
    4 => {
      // product of two odd numbers of ~31 bits (often a semiprime)
      let p = (2147483648L + below(rs, 1000000000L)) | 1L
      let q = (1073741824L + below(rs, 1000000000L)) | 1L
      p * q
    }
    5 => {
      // the next prime (per the reference) at or above a random odd start
      let mut p = (below(rs, 9223372036854775000L) + 2L) | 1L
      while !big_is_prime(p) {
        p = p + 2L
      }
      p
    }
    _ =>
      [
        3215031751L,
        3825123056546413051L,
        2152302898747L,
        3474749660383L,
        341550071728321L,
        9223372036854775783L,
        9223372036854775807L,
        4611686018427387847L,
        561L,
        41041L,
        25326001L,
        1000000007L * 998244353L,
        4611686014132420609L,
        2305843009213693951L,
      ][rs.next_uint(limit=14).reinterpret_as_int()]
  }
  { n, }
}

///|
impl @quickcheck.Shrink for Candidate with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.n).map(n => { n, })
}

///|
test "qc: is_prime agrees with trial division on small inputs" {
  @quickcheck.check(
    (x : Int) => {
      let n = (x % 2000000).to_int64()
      @miller_rabin.is_prime(n) == trial_is_prime(n)
    },
    count=1000,
    seed=11,
  )
}

///|
test "qc: is_prime agrees with a big-integer Miller-Rabin on 64-bit inputs" {
  @quickcheck.check(
    (c : Candidate) => @miller_rabin.is_prime(c.n) == big_is_prime(c.n),
    count=600,
    seed=12,
    observe=c => {
      let prime = big_is_prime(c.n)
      [
        @quickcheck.classify(prime, "prime"),
        @quickcheck.classify(
          !prime && c.n >= 2L && c.n % 2L == 1L,
          "odd composite",
        ),
        @quickcheck.classify(c.n >= 4611686018427387904L, ">= 2^62"),
        @quickcheck.classify(c.n < 2L, "< 2"),
      ]
    },
  )
}

///|
test "qc: a product of two integers > 1 is never prime" {
  @quickcheck.check(
    (p : (Int64, Int64)) => {
      let a = (p.0 % 3037000499L).abs() + 2L
      let b = (p.1 % 3037000499L).abs() + 2L
      !@miller_rabin.is_prime(a * b)
    },
    count=500,
    seed=13,
  )
}

///|
test "regression: is_prime for moduli above 2^62" {
  // Largest prime below 2^63; modular doubling x + x overflows Int64 here.
  @debug.assert_eq(@miller_rabin.is_prime(9223372036854775783L), true)
  @debug.assert_eq(@miller_rabin.is_prime(9223372036854775643L), true)
  @debug.assert_eq(@miller_rabin.is_prime(9223372036854775807L), false)
  // strong pseudoprimes to many small bases
  @debug.assert_eq(@miller_rabin.is_prime(3215031751L), false)
  @debug.assert_eq(@miller_rabin.is_prime(3825123056546413051L), false)
}
