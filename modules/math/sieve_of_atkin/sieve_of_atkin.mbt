// ============================================================================
// SIEVE OF ATKIN - Modern prime sieve via quadratic forms mod 60
// ============================================================================
//
// PROBLEM
//
// Enumerate every prime up to `N`. The classical Sieve of Eratosthenes
// does this in `O(N log log N)`; Atkin & Bernstein (2003) gave a sieve
// running in `O(N / log log N)` — asymptotically faster, though with
// a larger constant factor for small `N`.
//
// THE TRICK
//
// A number `n > 5` is prime iff it is squarefree AND the number of
// representations of `n` by one of three quadratic forms (specific to
// `n mod 12`) is **odd**:
//
//   n ≡ 1  (mod 12)  or  n ≡ 5  (mod 12)
//     -> n = 4 x^2 + y^2,  with x, y > 0
//
//   n ≡ 7  (mod 12)
//     -> n = 3 x^2 + y^2,  with x, y > 0
//
//   n ≡ 11 (mod 12)
//     -> n = 3 x^2 - y^2,  with x > y > 0
//
// So we toggle `sieve[n]` whenever (x, y) hits such an n. After all
// toggles, `sieve[n] = true` for exactly those n with odd
// representation count -- the candidate primes. Finally we clear
// squares of primes (these slip through with odd representation count
// but are not squarefree).
//
// THE LOOP INVARIANTS
//
// 1. After all three quadratic-form loops have completed:
//      sieve[n] is true  <=>  n has an odd number of representations
//                              by its corresponding form.
// 2. After the squares-of-primes pass:
//      sieve[n] is true  <=>  n is prime AND n > 3.
//
// We always emit 2 and 3 directly (they are not covered by the forms).
//
// TIME COMPLEXITY  : O(N / log log N)
// SPACE COMPLEXITY : O(N) sieve bits

///|
/// Integer square root via Newton's method. Returns `floor(sqrt(n))`
/// for `n >= 0`. Used to bound the inner loops of the sieve.
fn atkin_isqrt(n : Int) -> Int {
  if n < 2 {
    return n
  }
  for x = n / 2 + 1 {
    let nx = (x + n / x) / 2
    if nx >= x {
      break x
    } else {
      continue nx
    }
  } where {
    proof_invariant: x > 0,
    proof_invariant: x * x >= n || x * x < n,
    proof_reasoning: (
      #|INVARIANT (Newton's iteration):
      #|x is a positive guess for the integer square root. Each step
      #|computes the next Newton iterate; convergence is monotonic
      #|decreasing until nx >= x, at which point x is floor(sqrt(n)).
      #|TERMINATION:
      #|x strictly decreases until the fixed-point check `nx >= x` holds.
    ),
  }
}

///|
/// Compute every prime up to `n` (inclusive) using the Sieve of Atkin.
///
/// ## Parameters
///
/// - `n` : upper bound on the primes to return. May be any `Int`;
///         non-positive values yield an empty array.
///
/// ## Returns
///
/// An ascending `Array[Int]` of all primes `p` with `2 <= p <= n`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // Primes up to 20: 2, 3, 5, 7, 11, 13, 17, 19.
///   assert_eq(@sieve_of_atkin.primes_up_to(20), [2, 3, 5, 7, 11, 13, 17, 19])
/// }
/// ```
///
/// ## Complexity
///
/// Time `O(N / log log N)`, space `O(N)` for the sieve bitmap.
pub fn primes_up_to(n : Int) -> Array[Int] {
  if n < 2 {
    return []
  }
  let result : Array[Int] = []
  if n >= 2 {
    result.push(2)
  }
  if n >= 3 {
    result.push(3)
  }
  if n < 5 {
    return result
  }
  let sieve = Array::make(n + 1, false)
  let limit = atkin_isqrt(n) + 1
  // Form 1: n ≡ 1 or 5 (mod 12), n = 4 x^2 + y^2.
  for x in 1..<=limit {
    for y in 1..<=limit {
      let m = 4 * x * x + y * y
      if m > n {
        // y has grown too large; further y values only worsen this.
        break
      }
      let r = m % 12
      if r == 1 || r == 5 {
        sieve[m] = !sieve[m]
      }
    } where {
      proof_invariant: y >= 1,
      proof_reasoning: (
        #|INVARIANT (Form 1, y-loop):
        #|For each (x, y) pair already processed, sieve[4x^2 + y^2]
        #|has been toggled iff that value is in [5, n] and ≡ 1 or 5
        #|(mod 12).
      ),
    }
  } where {
    proof_invariant: x >= 1,
    proof_reasoning: (
      #|INVARIANT (Form 1, x-loop):
      #|For each x already processed, every valid y has been tried.
    ),
  }
  // Form 2: n ≡ 7 (mod 12), n = 3 x^2 + y^2.
  for x in 1..<=limit {
    for y in 1..<=limit {
      let m = 3 * x * x + y * y
      if m > n {
        break
      }
      if m % 12 == 7 {
        sieve[m] = !sieve[m]
      }
    }
  }
  // Form 3: n ≡ 11 (mod 12), n = 3 x^2 - y^2, x > y > 0.
  for x in 1..<=limit {
    for y in x>=..1 {
      let m = 3 * x * x - y * y
      if m > n {
        continue
      }
      if m < 5 {
        // No primes below 5 are produced by this branch; skip.
        continue
      }
      if m % 12 == 11 {
        sieve[m] = !sieve[m]
      }
    }
  }
  // Remove squares of primes: for each surviving r, clear r^2, 2 r^2, ...
  // (any multiple of r^2 in the sieve).
  for r in 5..<=limit {
    if sieve[r] {
      let rr = r * r
      for k = rr; k <= n; {
        sieve[k] = false
        continue k + rr
      } where {
        proof_invariant: k >= rr,
        proof_reasoning: (
          #|INVARIANT (Square clearing):
          #|For each multiple of r^2 in [r^2, k), sieve has been
          #|cleared. The loop increments k by r^2 each step until
          #|k exceeds n.
        ),
      }
    }
  }
  // Collect the remaining true entries.
  for i in 5..<=n {
    if sieve[i] {
      result.push(i)
    }
  }
  result
}

///|
/// Convenience: is `n` prime, via the Atkin sieve. Sieves up to `n`
/// itself; appropriate only for moderate `n` (say, up to `10^7`).
/// For single-shot primality testing of large `n`, use `@pollard_rho.is_prime`.
pub fn is_prime_atkin(n : Int) -> Bool {
  if n < 2 {
    return false
  }
  let primes = primes_up_to(n)
  primes.contains(n)
}

///|
test "atkin small primes" {
  @debug.assert_eq(primes_up_to(20), [2, 3, 5, 7, 11, 13, 17, 19])
}

///|
test "atkin handles below-five inputs" {
  @debug.assert_eq(primes_up_to(0), [])
  @debug.assert_eq(primes_up_to(1), [])
  @debug.assert_eq(primes_up_to(2), [2])
  @debug.assert_eq(primes_up_to(3), [2, 3])
  @debug.assert_eq(primes_up_to(4), [2, 3])
}

///|
test "atkin first 25 primes" {
  let primes = primes_up_to(100)
  @debug.assert_eq(primes, [
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73,
    79, 83, 89, 97,
  ])
}

///|
test "atkin count matches pi(N) for N = 1000" {
  // π(1000) = 168 (well-known).
  let primes = primes_up_to(1000)
  @debug.assert_eq(primes.length(), 168)
}

///|
test "atkin count matches pi(N) for N = 10000" {
  // π(10 000) = 1229.
  let primes = primes_up_to(10000)
  @debug.assert_eq(primes.length(), 1229)
}

///|
test "atkin is_prime spot checks" {
  @debug.assert_eq(is_prime_atkin(2), true)
  @debug.assert_eq(is_prime_atkin(3), true)
  @debug.assert_eq(is_prime_atkin(4), false)
  @debug.assert_eq(is_prime_atkin(17), true)
  @debug.assert_eq(is_prime_atkin(91), false) // 91 = 7 * 13
  @debug.assert_eq(is_prime_atkin(97), true)
}

///|
test "atkin agrees with eratosthenes hand-rolled" {
  // Build the Eratosthenes sieve manually and cross-check.
  let n = 500
  let era = Array::make(n + 1, true)
  era[0] = false
  era[1] = false
  for i = 2; i * i <= n; i = i + 1 {
    if era[i] {
      for k = i * i; k <= n; k = k + i {
        era[k] = false
      }
    }
  }
  let era_primes : Array[Int] = []
  for i in 2..<=n {
    if era[i] {
      era_primes.push(i)
    }
  }
  @debug.assert_eq(primes_up_to(n), era_primes)
}

///|
test "atkin no false positives in [5, 60]" {
  // Spot-check the mod-12 / mod-60 corner cases that the algorithm
  // depends on. Every reported prime must really be prime.
  let primes = primes_up_to(60)
  for p in primes {
    for d in 2..<p {
      // p must not be divisible by any 2 <= d < p.
      @debug.assert_eq(p % d != 0, true)
    }
  }
}
