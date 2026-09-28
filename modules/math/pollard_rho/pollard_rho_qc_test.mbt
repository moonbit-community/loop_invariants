///|
/// Independent reference: deterministic Miller-Rabin with bases 2..37 on
/// big integers (valid for all n < 3.3 * 10^24).
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
fn below(rs : @quickcheck.RandomState, hi : Int64) -> Int64 {
  rs.next_uint64(limit=hi.reinterpret_as_uint64()).reinterpret_as_int64()
}

///|
fn next_prime(from : Int64) -> Int64 {
  let mut p = from
  while !big_is_prime(p) {
    p = p + 1L
  }
  p
}

///|
/// Integers to factor: products of random primes of chosen sizes (hard
/// semiprimes with two ~31-bit factors, prime squares, three-factor
/// products), numbers just below Int64::MAX, arbitrary 64-bit values
/// (including extrema and negatives), and small values.
priv struct Composite {
  n : Int64
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Composite with fn arbitrary(size, rs) {
  let n = match rs.next_uint(limit=7) {
    0 => @quickcheck.Arbitrary::arbitrary(size, rs)
    1 => below(rs, 100000L) - 5L
    2 => {
      // semiprime: a 20..28-bit factor times a 20..31-bit factor (rho cost
      // grows with the square root of the smaller factor)
      let p = next_prime(1048576L + below(rs, 267386880L))
      let q = next_prime(1048576L + below(rs, 2146435072L))
      p * q
    }
    3 => {
      // square of a prime (rho with a repeated factor)
      let p = next_prime(2L + below(rs, 1073741824L))
      p * p
    }
    4 => {
      let p = next_prime(2L + below(rs, 2000000L))
      let q = next_prime(2L + below(rs, 2000000L))
      let r = next_prime(2L + below(rs, 2000000L))
      p * q * r
    }
    5 => 9223372036854775807L - below(rs, 64L)
    _ => {
      // a large prime, or a prime times a small cofactor
      let p = next_prime(2L + below(rs, 1000000000000000L))
      if rs.next_uint(limit=2) == 0 {
        p
      } else {
        p * (below(rs, 9000L) + 1L)
      }
    }
  }
  { n, }
}

///|
impl @quickcheck.Shrink for Composite with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.n).map(n => { n, })
}

///|
test "qc: pollard_rho.is_prime agrees with a big-integer Miller-Rabin" {
  @quickcheck.check(
    (c : Composite) => @pollard_rho.is_prime(c.n) == big_is_prime(c.n),
    count=500,
    seed=71,
  )
}

///|
test "qc: factorize returns sorted primes whose product is n" {
  @quickcheck.check(
    (c : Composite) => {
      let f = @pollard_rho.factorize(c.n)
      if c.n <= 1L {
        f.length() == 0
      } else {
        let mut prod = 1N
        let mut ok = true
        for i, p in f {
          ok = ok && big_is_prime(p) && (i == 0 || f[i - 1] <= p)
          prod = prod * @bigint.BigInt::from_int64(p)
        }
        ok && prod == @bigint.BigInt::from_int64(c.n)
      }
    },
    count=120,
    seed=72,
    observe=c => {
      [
        @quickcheck.classify(c.n <= 1L, "n <= 1"),
        @quickcheck.classify(big_is_prime(c.n), "prime"),
        @quickcheck.classify(
          c.n % 2L != 0L && !big_is_prime(c.n),
          "odd composite",
        ),
        @quickcheck.classify(c.n > 4611686018427387904L, "n > 2^62"),
      ]
    },
  )
}

///|
test "qc: factorize_with_counts is the run-length encoding of factorize" {
  @quickcheck.check(
    (c : Composite) => {
      let flat = @pollard_rho.factorize(c.n)
      let counted = @pollard_rho.factorize_with_counts(c.n)
      let expanded = []
      let mut distinct_ascending = true
      for i, pe in counted {
        let (p, e) = pe
        distinct_ascending = distinct_ascending &&
          e >= 1 &&
          (i == 0 || counted[i - 1].0 < p)
        for _ in 0..<e {
          expanded.push(p)
        }
      }
      distinct_ascending && expanded == flat
    },
    count=40,
    seed=73,
  )
}
