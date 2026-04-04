// ============================================================================
// LINEAR SIEVE - Primes, SPF, Phi, and Mobius
// ============================================================================
//
// The linear sieve computes primes and multiplicative functions in O(n).
// For each composite i * p, the smallest prime factor is assigned exactly once.
//
// TIME COMPLEXITY: O(n)
// SPACE COMPLEXITY: O(n)

///|
/// Result of running the linear (Euler) sieve up to `n` (inclusive).
///
/// All four arrays are indexed from `0` to `n`.  Index 0 is an unused sentinel;
/// meaningful values start at index 1.
///
/// Fields:
/// - `n`: the upper bound supplied to `LinearSieve::new`.
/// - `primes`: all primes in `2..n` in ascending order.
/// - `spf`: smallest prime factor of each number.  `spf[1]` is 0 (1 has no
///   prime factor).  For a prime `p`, `spf[p] == p`.
/// - `phi`: Euler's totient function.  `phi[k]` counts integers in `1..k`
///   that are coprime with `k`.
/// - `mu`: Mobius function.  `mu[k]` is 1, -1, or 0 depending on the
///   squarefreeness and number of prime factors of `k`.
pub struct LinearSieve {
  n : Int
  primes : Array[Int]
  spf : Array[Int]
  phi : Array[Int]
  mu : Array[Int]
}

///|
/// Build a linear sieve for all integers in `1..n` (inclusive).
///
/// After construction, `primes`, `spf`, `phi`, and `mu` are all fully
/// populated.  The sieve runs in O(n) time and O(n) space because every
/// composite number `i * p` is written exactly once — when `p` is the
/// smallest prime factor of that composite.
///
/// The inner loop breaks as soon as `p` divides `i`.  At that point,
/// `spf[i * p] = p = spf[i]`, so any further prime `q > p` would give
/// `spf[i * q] = p < q`, meaning `i * q` will be handled later (when the
/// outer loop reaches `i * q / p`).
///
/// Parameters:
/// - `n`: upper bound of the sieve (inclusive).  Values `<= 0` produce an
///   empty sieve.
///
/// Example:
/// ```
/// let s = LinearSieve::new(10)
/// // s.primes  => [2, 3, 5, 7]
/// // s.spf[6]  => 2   (smallest prime factor of 6)
/// // s.phi[6]  => 2   (phi(6) = |{1,5}|)
/// // s.mu[6]   => 1   (6 = 2*3, squarefree, even number of factors)
/// ```
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
  for i in 2..<=n {
    if spf[i] == 0 {
      spf[i] = i
      primes.push(i)
      phi[i] = i - 1
      mu[i] = -1
    }
    for j in 0..<primes.length() {
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
      proof_invariant: j >= 0 && j <= primes.length(),
      proof_reasoning: (
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
    proof_invariant: i >= 2 && i <= n + 1,
    proof_reasoning: (
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
/// Return `true` if `x` is prime according to this sieve.
///
/// A number `x` is prime if and only if its smallest prime factor equals
/// itself, i.e. `spf[x] == x`.  This check is O(1).
///
/// Returns `false` when `x < 2` or when `x > self.n` (out of sieve range).
///
/// Example:
/// ```
/// let s = LinearSieve::new(20)
/// s.is_prime(2)   // true
/// s.is_prime(17)  // true
/// s.is_prime(1)   // false  (1 is not prime by convention)
/// s.is_prime(9)   // false  (9 = 3 * 3)
/// s.is_prime(25)  // false  (25 > n=20, out of range)
/// ```
pub fn LinearSieve::is_prime(self : LinearSieve, x : Int) -> Bool {
  x >= 2 && x <= self.n && self.spf[x] == x
}

///|
/// Factorize `x` into prime factors using the precomputed smallest prime
/// factor table.
///
/// Returns an array of `(prime, exponent)` pairs in ascending order of prime,
/// e.g. `factorize(84)` returns `[(2, 2), (3, 1), (7, 1)]` because
/// `84 = 2^2 * 3 * 7`.
///
/// The algorithm repeatedly divides `x` by `spf[x]`, collecting runs of the
/// same prime.  Each division reduces `x` by at least a factor of 2, so the
/// number of steps is at most `O(log x)`.
///
/// Precondition: `x <= self.n`.  If `x > self.n`, the spf table is not
/// populated for `x`, and the function returns an empty array.  If `x <= 1`,
/// the function also returns an empty array (1 has no prime factors).
///
/// Example:
/// ```
/// let s = LinearSieve::new(100)
/// s.factorize(1)   // []
/// s.factorize(12)  // [(2, 2), (3, 1)]
/// s.factorize(60)  // [(2, 2), (3, 1), (5, 1)]
/// s.factorize(97)  // [(97, 1)]   (97 is prime)
/// ```
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
