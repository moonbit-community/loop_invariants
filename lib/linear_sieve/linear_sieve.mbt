// ============================================================================
// LINEAR SIEVE - Primes, SPF, Phi, and Möbius
// ============================================================================
//
// The linear sieve computes primes and multiplicative functions in O(n).
// For each composite i * p, the smallest prime factor is assigned exactly once.
//
// TIME COMPLEXITY: O(n)
// SPACE COMPLEXITY: O(n)

///|
/// Linear sieve result up to n (inclusive).
pub struct LinearSieve {
  n : Int
  primes : Array[Int]
  spf : Array[Int]
  phi : Array[Int]
  mu : Array[Int]
}

///|
/// Build a linear sieve up to n (inclusive).
pub fn LinearSieve::new(n : Int) -> LinearSieve {
  if n < 0 {
    return { n: 0, primes: [], spf: [], phi: [], mu: [] }
  }
  let size = n + 1
  let spf = Array::make(size, 0)
  let phi = Array::make(size, 0)
  let mu = Array::make(size, 0)
  let primes : Array[Int] = []
  if n >= 1 {
    phi[1] = 1
    mu[1] = 1
  }
  for i = 2; i <= n; i = i + 1 {
    if spf[i] == 0 {
      spf[i] = i
      primes.push(i)
      phi[i] = i - 1
      mu[i] = -1
    }
    for j = 0; j < primes.length(); j = j + 1 {
      let p = primes[j]
      let ip = i * p
      if ip > n {
        break
      }
      spf[ip] = p
      if i % p == 0 {
        phi[ip] = phi[i] * p
        mu[ip] = 0
        break
      } else {
        phi[ip] = phi[i] * (p - 1)
        mu[ip] = -mu[i]
      }
    } where {
      invariant: j >= 0 && j <= primes.length(),
      reasoning: (
        #|INVARIANT (linear sieve inner):
        #|primes[0..j) have been processed for i, and spf/phi/mu are set for
        #|their corresponding composites i * primes[k] (when within range).
        #|MAINTENANCE:
        #|Assign spf for i * p and update phi/mu based on whether p divides i.
        #|TERMINATION:
        #|Stop when i * p exceeds n or when p divides i (linear-time property).
      ),
    }
  } where {
    invariant: i >= 2 && i <= n + 1,
    reasoning: (
      #|INVARIANT (linear sieve outer):
      #|For all integers < i, spf/phi/mu are fully computed and primes contains
      #|all primes up to i-1.
      #|MAINTENANCE:
      #|Process i by marking it prime if needed and updating composites.
      #|TERMINATION:
      #|At i = n+1, all values up to n are computed.
    ),
  }
  { n, primes, spf, phi, mu }
}

///|
/// Check if x is prime (within sieve range).
pub fn LinearSieve::is_prime(self : LinearSieve, x : Int) -> Bool {
  x >= 2 && x <= self.n && self.spf[x] == x
}

///|
/// Factorize x using smallest prime factors.
pub fn LinearSieve::factorize(self : LinearSieve, x : Int) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = []
  let _ = for v = x {
    if v <= 1 {
      break ()
    }
    if v > self.n {
      break ()
    }
    let p = self.spf[v]
    if p == 0 {
      break ()
    }
    let (next_v, cnt) = for curr = v, cnt = 0 {
      if curr % p == 0 {
        continue curr / p, cnt + 1
      } else {
        break (curr, cnt)
      }
    }
    result.push((p, cnt))
    continue next_v
  }
  result
}
