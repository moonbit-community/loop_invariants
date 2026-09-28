///|
fn trial_is_prime(n : Int) -> Bool {
  if n < 2 {
    return false
  }
  for d = 2; d * d <= n; d = d + 1 {
    if n % d == 0 {
      return false
    }
  }
  true
}

///|
/// Sieve bounds: small values around the special cases 2, 3, 5 and
/// perfect squares of primes (which Atkin must explicitly eliminate), plus
/// larger bounds up to 20000.
priv struct Limit {
  n : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Limit with fn arbitrary(_size, rs) {
  let n = match rs.next_uint(limit=4) {
    0 => rs.next_uint(limit=16).reinterpret_as_int() - 5
    1 => {
      let p = [5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 97, 101][rs
        .next_uint(limit=15)
        .reinterpret_as_int()]
      p * p + rs.next_uint(limit=3).reinterpret_as_int() - 1
    }
    2 => rs.next_uint(limit=500).reinterpret_as_int()
    _ => rs.next_uint(limit=20000).reinterpret_as_int()
  }
  { n, }
}

///|
impl @quickcheck.Shrink for Limit with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.n).map(n => { n, })
}

///|
test "qc: primes_up_to(n) is exactly the ascending list of primes <= n" {
  @quickcheck.check(
    (l : Limit) => {
      let expected = []
      for k in 2..<=l.n {
        if trial_is_prime(k) {
          expected.push(k)
        }
      }
      @sieve_of_atkin.primes_up_to(l.n) == expected
    },
    count=200,
    seed=61,
    observe=l => {
      [
        @quickcheck.classify(l.n < 5, "n < 5 (special-cased)"),
        @quickcheck.classify(l.n >= 1000, "n >= 1000"),
      ]
    },
  )
}

///|
test "qc: is_prime_atkin agrees with trial division" {
  @quickcheck.check(
    (l : Limit) => @sieve_of_atkin.is_prime_atkin(l.n) == trial_is_prime(l.n),
    count=300,
    seed=62,
  )
}

///|
test "qc: primes_up_to is monotone in n (prefix property)" {
  @quickcheck.check(
    (p : (Limit, Limit)) => {
      let (a, b) = if p.0.n <= p.1.n { (p.0.n, p.1.n) } else { (p.1.n, p.0.n) }
      let small = @sieve_of_atkin.primes_up_to(a)
      let large = @sieve_of_atkin.primes_up_to(b)
      small.length() <= large.length() &&
      large[:small.length()] == small[:] &&
      large[small.length():].iter().all(q => q > a)
    },
    count=100,
    seed=63,
  )
}
