// ============================================================================
// CHINESE REMAINDER THEOREM  (Garner's algorithm)
// ============================================================================
//
// PROBLEM
//
// Given `k` congruences
//
//   x ≡ r_0 (mod m_0)
//   x ≡ r_1 (mod m_1)
//   ...
//   x ≡ r_{k-1} (mod m_{k-1})
//
// find the unique `x` in `[0, M)` where `M = m_0 * m_1 * ... * m_{k-1}`,
// assuming the moduli are **pairwise coprime**. The classical Chinese
// Remainder Theorem (Sun Tzu, ~3rd century CE) guarantees that such an
// `x` exists and is unique mod `M`.
//
// THE GENERAL FORM (non-coprime moduli)
//
// For arbitrary moduli, two congruences `x ≡ r_1 (mod m_1)` and
// `x ≡ r_2 (mod m_2)` have a common solution iff
// `gcd(m_1, m_2)` divides `r_1 - r_2`, in which case the solution is
// unique mod `lcm(m_1, m_2)`. Iterating this pairwise merge gives a
// solution -- or proves inconsistency -- for any list.
//
// GARNER'S ALGORITHM (used here for coprime case)
//
// Maintain a running solution `(x, M)` where `M` is the LCM of the
// moduli merged so far. When adding `(r_i, m_i)`:
//
//   1. Compute `t = (r_i - x) * inverse(M, m_i)  mod m_i`.
//   2. Update `x <- x + t * M`.
//   3. Update `M <- M * m_i`.
//
// After step `i`, `x` is the unique solution mod `M` to all the
// congruences seen so far.
//
// COMPLEXITY
//
//   Time : O(k log M) -- each merge is one extended-gcd call
//   Space: O(1) over the inputs
//
// THE INVARIANT
//
//   "After merging the first j congruences, `(x, M)` satisfies
//    0 <= x < M  and  x ≡ r_i (mod m_i)  for every i < j."

///|
fn safe_mod(a : Int64, m : Int64) -> Int64 {
  let r = a % m
  if r < 0L {
    r + m
  } else {
    r
  }
}

///|
/// Extended GCD: returns `(g, x, y)` with `a * x + b * y == g`.
fn ext_gcd(a : Int64, b : Int64) -> (Int64, Int64, Int64) {
  if b == 0L {
    return (a, 1L, 0L)
  }
  let (g, x1, y1) = ext_gcd(b, a % b)
  (g, y1, x1 - a / b * y1)
}

///|
/// Merge two congruences `x ≡ r_1 (mod m_1)` and `x ≡ r_2 (mod m_2)`.
///
/// Returns `Some((r, m))` where `r` is the unique residue mod
/// `m = lcm(m_1, m_2)` satisfying both. Returns `None` if the
/// congruences are inconsistent (i.e. `gcd(m_1, m_2) ∤ r_1 - r_2`).
///
/// Works for arbitrary positive moduli -- they need not be coprime.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // x ≡ 2 (mod 3) and x ≡ 3 (mod 5)
///   //   3, 8, 13, 18, 23, ... so smallest is 8, period 15.
///   @debug.assert_eq(@crt.merge(2L, 3L, 3L, 5L), Some((8L, 15L)))
/// }
/// ```
pub fn merge(r1 : Int64, m1 : Int64, r2 : Int64, m2 : Int64) -> (Int64, Int64)? {
  let (g, p, _) = ext_gcd(m1, m2)
  let diff = r2 - r1
  if diff % g != 0L {
    return None
  }
  let lcm = m1 / g * m2
  // x = r1 + m1 * ((diff / g) * p mod (m2 / g))
  let m2g = m2 / g
  let k = safe_mod(diff / g * p, m2g)
  let r = safe_mod(r1 + m1 * k, lcm)
  Some((r, lcm))
}

///|
/// CRT on a vector of congruences. `residues[i]` is the desired remainder
/// and `moduli[i]` is the corresponding modulus. The moduli must each be
/// positive.
///
/// Returns `Some((x, M))` where `M = lcm(moduli)` and `0 <= x < M` is the
/// unique solution mod `M`. Returns `None` if the system is inconsistent
/// or if the arrays differ in length / are empty / contain a non-positive
/// modulus.
///
/// Handles arbitrary moduli; for coprime moduli this is **Garner's**
/// algorithm.
pub fn solve(residues : Array[Int64], moduli : Array[Int64]) -> (Int64, Int64)? {
  if residues.length() != moduli.length() || residues.length() == 0 {
    return None
  }
  for m in moduli {
    if m <= 0L {
      return None
    }
  }
  let mut x = safe_mod(residues[0], moduli[0])
  let mut m = moduli[0]
  for i in 1..<residues.length() {
    match merge(x, m, residues[i], moduli[i]) {
      Some((r, lcm)) => {
        x = r
        m = lcm
      }
      None => return None
    }
  }
  Some((x, m))
}

///|
test "crt sun zi example" {
  // Classical example from Sun Zi:
  // x ≡ 2 (mod 3), x ≡ 3 (mod 5), x ≡ 2 (mod 7) -> x = 23 mod 105.
  let r = solve([2L, 3L, 2L], [3L, 5L, 7L])
  @debug.assert_eq(r, Some((23L, 105L)))
}

///|
test "crt single congruence" {
  let r = solve([7L], [12L])
  @debug.assert_eq(r, Some((7L, 12L)))
}

///|
test "crt merge two coprime" {
  // x ≡ 2 mod 3 and x ≡ 3 mod 5 -> 8 mod 15.
  @debug.assert_eq(merge(2L, 3L, 3L, 5L), Some((8L, 15L)))
}

///|
test "crt non-coprime consistent" {
  // x ≡ 1 mod 4, x ≡ 5 mod 6 -> gcd(4,6)=2 divides 5-1=4 so consistent.
  // lcm = 12. Solutions: 5, 17, 29, ... -> 5 mod 12.
  @debug.assert_eq(merge(1L, 4L, 5L, 6L), Some((5L, 12L)))
}

///|
test "crt non-coprime inconsistent" {
  // x ≡ 1 mod 4, x ≡ 2 mod 6 -> gcd=2 does not divide 2-1=1 -> None.
  @debug.assert_eq(merge(1L, 4L, 2L, 6L), None)
}

///|
test "crt arrays inconsistent" {
  let r = solve([1L, 2L], [4L, 6L])
  @debug.assert_eq(r, None)
}

///|
test "crt rejects empty / mismatched / non-positive" {
  @debug.assert_eq(solve([], []), None)
  @debug.assert_eq(solve([1L, 2L], [3L]), None)
  @debug.assert_eq(solve([1L], [0L]), None)
  @debug.assert_eq(solve([1L], [-3L]), None)
}

///|
test "crt residue larger than modulus" {
  // r >= m or r < 0 should be normalised first.
  // x ≡ 100 (mod 3) ≡ 1 (mod 3); x ≡ -1 (mod 5) ≡ 4 (mod 5)
  //   -> x ≡ 4 (mod 15)? Check: 4 mod 3 = 1, 4 mod 5 = 4. Yes.
  let r = solve([100L, -1L], [3L, 5L])
  @debug.assert_eq(r, Some((4L, 15L)))
}

///|
test "crt agrees with brute force" {
  // For each candidate x in [0, M), check that it matches the residues
  // iff x equals the CRT answer.
  let moduli = [3L, 4L, 5L, 7L]
  let residues = [1L, 2L, 3L, 4L]
  let result = solve(residues, moduli)
  match result {
    None => @debug.assert_eq(true, false) // pairwise coprime -> must exist
    Some((x, m)) => {
      // M = 3*4*5*7 = 420
      @debug.assert_eq(m, 420L)
      // Verify each congruence.
      for i in 0..<moduli.length() {
        @debug.assert_eq(x % moduli[i], residues[i])
      }
      // Verify uniqueness by linear search up to M.
      let mut found = false
      for cand in 0L..<m {
        let mut ok = true
        for i in 0..<moduli.length() {
          if cand % moduli[i] != residues[i] {
            ok = false
            break
          }
        }
        if ok {
          @debug.assert_eq(cand, x)
          found = true
          break
        }
      }
      @debug.assert_eq(found, true)
    }
  }
}

///|
test "crt large coprime moduli" {
  // 10^9 + 7 and 10^9 + 9: two competitive-programming primes.
  let r = solve([12345L, 67890L], [1000000007L, 1000000009L])
  match r {
    Some((x, _)) => {
      @debug.assert_eq(x % 1000000007L, 12345L)
      @debug.assert_eq(x % 1000000009L, 67890L)
    }
    None => @debug.assert_eq(true, false)
  }
}
