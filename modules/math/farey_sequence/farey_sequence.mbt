// ============================================================================
// FAREY SEQUENCE  -  F_n
// ============================================================================
//
// DEFINITION
//
// The Farey sequence of order `n`, written `F_n`, is the **sorted**
// sequence of every fully reduced fraction `p/q` in `[0, 1]` with
// `q <= n`. For example,
//
//   F_5 = 0/1, 1/5, 1/4, 1/3, 2/5, 1/2, 3/5, 2/3, 3/4, 4/5, 1/1
//
// |F_n| = 1 + sum_{k=1..n} phi(k), where `phi` is Euler's totient.
//
// SUCCESSOR FORMULA (Cauchy 1816)
//
// Given two consecutive fractions `a/b, c/d` in `F_n`, the *next*
// fraction `p/q` after them is
//
//   k = (n + b) / d         (integer division)
//   p = k * c - a
//   q = k * d - b
//
// This gives an `O(|F_n|)` iteration without ever computing GCDs --
// the formula automatically yields a reduced fraction.
//
// COMPLEXITY
//
//   generate(n)   : O(|F_n|) ≈ O(3 n^2 / pi^2)
//   size(n)       : O(n) given a totient sieve, O(n log log n) overall
//
// THE INVARIANT
//
//   "After yielding (a, b) and (c, d), the recursion `k = (n+b)/d`
//    produces (p, q) such that p/q is the unique fraction in F_n
//    immediately following c/d."

///|
fn gcd(a : Int64, b : Int64) -> Int64 {
  let mut x = if a < 0L { -a } else { a }
  let mut y = if b < 0L { -b } else { b }
  while y != 0L {
    let t = x % y
    x = y
    y = t
  }
  x
}

///|
/// Generate the Farey sequence of order `n` as an array of (numerator,
/// denominator) pairs. Both `0/1` and `n/n = 1/1` are included.
/// Returns an empty array for `n <= 0`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let f = @farey_sequence.generate(3)
///   // 0/1, 1/3, 1/2, 2/3, 1/1
///   @debug.assert_eq(f.length(), 5)
/// }
/// ```
pub fn generate(n : Int) -> Array[(Int64, Int64)] {
  let res : Array[(Int64, Int64)] = []
  if n <= 0 {
    return res
  }
  let nn = n.to_int64()
  res.push((0L, 1L))
  if n >= 1 {
    res.push((1L, nn))
  }
  // Walk via Cauchy's successor formula.
  let mut a = 0L
  let mut b = 1L
  let mut c = 1L
  let mut d = nn
  while c < nn || d != 1L {
    let k = (nn + b) / d
    let p = k * c - a
    let q = k * d - b
    a = c
    b = d
    c = p
    d = q
    res.push((c, d))
    if c == 1L && d == 1L {
      break
    }
  }
  res
}

///|
/// Number of terms in `F_n`. Computes it directly as
/// `1 + sum_{k=1..n} phi(k)` using a small linear-sieve totient.
pub fn size(n : Int) -> Int64 {
  if n <= 0 {
    return 0L
  }
  let phi = Array::make(n + 1, 0)
  let spf = Array::make(n + 1, 0)
  let primes : Array[Int] = []
  if n >= 1 {
    phi[1] = 1
  }
  for i in 2..<=n {
    if spf[i] == 0 {
      spf[i] = i
      primes.push(i)
      phi[i] = i - 1
    }
    for j in 0..<primes.length() {
      let p = primes[j]
      if p > spf[i] || p.to_int64() * i.to_int64() > n.to_int64() {
        break
      }
      let k = p * i
      spf[k] = p
      if i % p == 0 {
        phi[k] = phi[i] * p
      } else {
        phi[k] = phi[i] * (p - 1)
      }
    }
  }
  let mut total = 1L // for 0/1
  for k in 1..<=n {
    total = total + phi[k].to_int64()
  }
  total
}

///|
/// Mediant of two fractions `a/b` and `c/d`: `(a + c) / (b + d)`,
/// already in lowest terms when `a/b < c/d` are Farey neighbours.
pub fn mediant(a : Int64, b : Int64, c : Int64, d : Int64) -> (Int64, Int64) {
  (a + c, b + d)
}

///|
test "farey small n" {
  // F_3 = 0/1, 1/3, 1/2, 2/3, 1/1
  let f = generate(3)
  @debug.assert_eq(f, [(0L, 1L), (1L, 3L), (1L, 2L), (2L, 3L), (1L, 1L)])
}

///|
test "farey n=5" {
  let f = generate(5)
  let expected = [
    (0L, 1L),
    (1L, 5L),
    (1L, 4L),
    (1L, 3L),
    (2L, 5L),
    (1L, 2L),
    (3L, 5L),
    (2L, 3L),
    (3L, 4L),
    (4L, 5L),
    (1L, 1L),
  ]
  @debug.assert_eq(f, expected)
}

///|
test "farey n=1" {
  let f = generate(1)
  @debug.assert_eq(f, [(0L, 1L), (1L, 1L)])
}

///|
test "farey degenerate inputs" {
  @debug.assert_eq(generate(0), [])
  @debug.assert_eq(generate(-3), [])
}

///|
test "farey sorted and reduced" {
  let f = generate(20)
  for i in 0..<(f.length() - 1) {
    // Strictly increasing.
    let (a, b) = f[i]
    let (c, d) = f[i + 1]
    @debug.assert_eq(a * d < c * b, true)
    // Reduced (gcd = 1).
    @debug.assert_eq(gcd(a, b), 1L)
  }
  // Each pair of neighbours: bc - ad = 1.
  for i in 0..<(f.length() - 1) {
    let (a, b) = f[i]
    let (c, d) = f[i + 1]
    @debug.assert_eq(b * c - a * d, 1L)
  }
}

///|
test "farey size matches length" {
  for n in 1..<=15 {
    let f = generate(n)
    @debug.assert_eq(size(n).to_int(), f.length())
  }
}

///|
test "farey mediant" {
  // Mediant of consecutive Farey terms a/b, c/d gives the term inserted
  // at the next order: (a+c)/(b+d).
  @debug.assert_eq(mediant(0L, 1L, 1L, 1L), (1L, 2L)) // mediant -> 1/2
  @debug.assert_eq(mediant(1L, 2L, 1L, 1L), (2L, 3L))
  @debug.assert_eq(mediant(0L, 1L, 1L, 3L), (1L, 4L))
}
