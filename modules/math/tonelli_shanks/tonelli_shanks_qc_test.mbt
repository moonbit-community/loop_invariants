///|
fn big(x : Int64) -> @bigint.BigInt {
  @bigint.BigInt::from_int64(x)
}

///|
/// Deterministic Miller-Rabin on big integers (valid below 3.3 * 10^24).
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
  let bn = big(n)
  let n1 = bn - 1N
  let mut d = n1
  let mut s = 0
  while (d % 2N).is_zero() {
    d = d / 2N
    s = s + 1
  }
  for a in bases {
    let mut x = big(a).pow(d, modulus=bn)
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
fn bmod(x : @bigint.BigInt, p : Int64) -> @bigint.BigInt {
  let r = x % big(p)
  if r < 0N {
    r + big(p)
  } else {
    r
  }
}

///|
/// A prime p (2, small primes, primes with a large power of two in p - 1
/// such as 998244353 = 119 * 2^23 + 1, or random primes up to Int64::MAX)
/// and a value n that is either arbitrary or a square mod p.
priv struct SqrtCase {
  n : Int64
  p : Int64
} derive(Debug)

///|
fn below(rs : @quickcheck.RandomState, hi : Int64) -> Int64 {
  rs.next_uint64(limit=hi.reinterpret_as_uint64()).reinterpret_as_int64()
}

///|
impl @quickcheck.Arbitrary for SqrtCase with fn arbitrary(size, rs) {
  let p = match rs.next_uint(limit=4) {
    0 =>
      [
        2L, 3L, 5L, 13L, 17L, 97L, 257L, 65537L, 998244353L, 469762049L, 167772161L,
        4611686018427387847L, 9223372036854775783L, 2305843009213693951L,
      ][rs.next_uint(limit=14).reinterpret_as_int()]
    1 => {
      // p = k * 2^s + 1 with s large
      let s = 10 + rs.next_uint(limit=40).reinterpret_as_int()
      let mut k = 1L + below(rs, 1000L)
      while !big_is_prime(k * (1L << s) + 1L) {
        k = k + 1L
      }
      k * (1L << s) + 1L
    }
    _ => {
      let mut q = 3L + below(rs, 9223372036854775000L)
      while !big_is_prime(q) {
        q = q + 1L
      }
      q
    }
  }
  let n = if rs.next_uint(limit=2) == 0 {
    @quickcheck.Arbitrary::arbitrary(size, rs)
  } else {
    let r = below(rs, p)
    bmod(big(r) * big(r), p).to_int64() - p * below(rs, 3L)
  }
  { n, p, }
}

///|
impl @quickcheck.Shrink for SqrtCase with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.n).map(n => { n, p: self.p, })
}

///|
test "qc: tonelli_shanks returns a square root exactly for quadratic residues" {
  @quickcheck.check(
    (c : SqrtCase) => {
      let a = bmod(big(c.n), c.p)
      let residue = a.is_zero() ||
        c.p == 2L ||
        big(a.to_int64()).pow(big((c.p - 1L) / 2L), modulus=big(c.p)) == 1N
      match @tonelli_shanks.tonelli_shanks(c.n, c.p) {
        Some(r) =>
          residue && r >= 0L && r < c.p && bmod(big(r) * big(r), c.p) == a
        None => !residue
      }
    },
    count=400,
    seed=181,
    observe=c => {
      let a = bmod(big(c.n), c.p)
      [
        @quickcheck.classify(
          c.p > 2L &&
          !a.is_zero() &&
          big(a.to_int64()).pow(big((c.p - 1L) / 2L), modulus=big(c.p)) == 1N,
          "non-zero residue",
        ),
        @quickcheck.classify(c.p % 4L == 1L, "p = 1 mod 4 (general case)"),
        @quickcheck.classify(c.p > 4611686018427387904L, "p > 2^62"),
      ]
    },
  )
}
