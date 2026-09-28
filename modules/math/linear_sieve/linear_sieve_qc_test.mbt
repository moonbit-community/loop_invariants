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
fn naive_spf(k : Int) -> Int {
  for d = 2; d * d <= k; d = d + 1 {
    if k % d == 0 {
      return d
    }
  }
  k
}

///|
fn naive_gcd(a : Int, b : Int) -> Int {
  if b == 0 {
    a
  } else {
    naive_gcd(b, a % b)
  }
}

///|
/// phi(k) by counting 1 <= j <= k with gcd(j, k) == 1.
fn naive_phi(k : Int) -> Int {
  let mut c = 0
  for j in 1..<=k {
    if naive_gcd(j, k) == 1 {
      c = c + 1
    }
  }
  c
}

///|
/// mu(k) from trial-division factorisation.
fn naive_mu(k : Int) -> Int {
  let mut m = k
  let mut sign = 1
  for d = 2; d * d <= m; d = d + 1 {
    if m % d == 0 {
      m = m / d
      if m % d == 0 {
        return 0
      }
      sign = -sign
    }
  }
  if m > 1 {
    sign = -sign
  }
  sign
}

///|
/// A sieve bound: mostly small (so the naive checks stay cheap), sometimes
/// negative or zero.
priv struct Bound {
  n : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Bound with fn arbitrary(_size, rs) {
  let n = match rs.next_uint(limit=5) {
    0 => rs.next_uint(limit=8).reinterpret_as_int() - 4 // -4..3
    1 => rs.next_uint(limit=40).reinterpret_as_int()
    _ => rs.next_uint(limit=700).reinterpret_as_int()
  }
  { n, }
}

///|
impl @quickcheck.Shrink for Bound with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.n).map(n => { n, })
}

///|
test "qc: primes lists exactly the primes <= n, ascending" {
  @quickcheck.check(
    (b : Bound) => {
      let s = @linear_sieve.LinearSieve(b.n)
      let expected : Array[Int] = []
      for k in 2..<=b.n {
        if trial_is_prime(k) {
          expected.push(k)
        }
      }
      s.primes == expected
    },
    count=150,
    seed=21,
    observe=b => {
      [
        @quickcheck.classify(b.n < 2, "no primes (n < 2)"),
        @quickcheck.classify(b.n >= 100, "n >= 100"),
      ]
    },
  )
}

///|
test "qc: spf, phi and mu tables agree with naive definitions" {
  @quickcheck.check(
    (b : Bound) => {
      let s = @linear_sieve.LinearSieve(b.n)
      if b.n < 0 {
        s.spf.length() == 0 && s.phi.length() == 0 && s.mu.length() == 0
      } else {
        let mut ok = s.spf.length() == b.n + 1 &&
          s.phi.length() == b.n + 1 &&
          s.mu.length() == b.n + 1
        for k in 1..<=b.n {
          let spf = if k == 1 { 0 } else { naive_spf(k) }
          ok = ok &&
            s.spf[k] == spf &&
            s.phi[k] == naive_phi(k) &&
            s.mu[k] == naive_mu(k)
        }
        ok
      }
    },
    count=60,
    seed=22,
  )
}

///|
test "qc: is_prime matches trial division, false outside [2, n]" {
  @quickcheck.check(
    (p : (Bound, Int)) => {
      let (b, y) = p
      let s = @linear_sieve.LinearSieve(b.n)
      let x = y % (b.n + 10)
      s.is_prime(x) == (x <= b.n && trial_is_prime(x))
    },
    count=300,
    seed=23,
  )
}

///|
test "qc: factorize multiplies back, primes strictly ascending" {
  @quickcheck.check(
    (p : (Bound, Int)) => {
      let (b, y) = p
      let s = @linear_sieve.LinearSieve(b.n)
      let x = y % (b.n + 10)
      let f = s.factorize(x)
      if x <= 1 || x > b.n {
        f.length() == 0
      } else {
        let mut prod = 1
        let mut prev = 1
        let mut ok = true
        for pe in f {
          let (q, e) = pe
          ok = ok && q > prev && trial_is_prime(q) && e >= 1
          prev = q
          for _ in 0..<e {
            prod = prod * q
          }
        }
        ok && prod == x
      }
    },
    count=300,
    seed=24,
  )
}
