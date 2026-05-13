// ============================================================================
// FLOOR SUM - Sum of floors of an arithmetic progression
// ============================================================================
//
// Computes the closed-form sum:
//
//   S(n, m, a, b) = sum_{i=0}^{n-1} floor((a*i + b) / m)
//
// All parameters must be non-negative integers; n=0 or m=0 returns 0.
//
// TIME COMPLEXITY : O(log min(a, m))  -- same recurrence depth as Euclid GCD
// SPACE COMPLEXITY: O(1)              -- tail-recursive loop, no stack growth
//
// The algorithm is the iterative form of the recursive reduction described in:
//   "ACL (AtCoder Library) floor_sum"
//   https://atcoder.github.io/ac-library/document_en/math.html

///|
/// Compute `S = sum_{i=0}^{n-1} floor((a*i + b) / m)`.
///
/// The sum counts the integer lattice points `(i, j)` satisfying
///
/// ```
///   0 <= i < n    and    1 <= j <= floor((a*i + b) / m)
/// ```
///
/// which is geometrically the number of lattice points strictly below the
/// line `y = (a*x + b) / m` in the strip `0 <= x < n`.
///
/// ## Parameters
///
/// - `n` : number of terms (i ranges over `0 .. n-1`); returns 0 when n <= 0.
/// - `m` : denominator; must be positive (returns 0 when m <= 0).
/// - `a` : numerator slope coefficient; must be non-negative.
/// - `b` : numerator constant offset; must be non-negative.
///
/// ## Examples
///
/// ```mbt nocheck
/// // floor((2*0+1)/3) + floor((2*1+1)/3) + ... + floor((2*4+1)/3)
/// // = 0 + 1 + 1 + 2 + 3 = 7
/// assert_eq!(@floor_sum.floor_sum(5L, 3L, 2L, 1L), 7L)
/// ```
///
/// ## Complexity
///
/// O(log min(a, m)) time, O(1) space.
pub fn floor_sum(n : Int64, m : Int64, a : Int64, b : Int64) -> Int64 {
  if n <= 0L || m <= 0L {
    return 0L
  }
  for n0 = n, m0 = m, a0 = a, b0 = b, ans = 0L {
    // Reduction 1: strip full multiples of m0 from the slope a0.
    //   floor((a0*i + b0) / m0)
    //     = floor(a0/m0)*i  +  floor((a0%m0 * i + b0) / m0)
    // The first part sums to floor(a0/m0) * n0*(n0-1)/2 over i=0..n0-1.
    let (a1, ans1) = if a0 >= m0 {
      let q = a0 / m0
      (a0 % m0, ans + (n0 - 1L) * n0 / 2L * q)
    } else {
      (a0, ans)
    }
    // Reduction 2: strip full multiples of m0 from the constant b0.
    //   floor((a1*i + b0) / m0)
    //     = floor(b0/m0)  +  floor((a1*i + b0%m0) / m0)
    // The first part adds floor(b0/m0) to each of the n0 terms.
    let (b1, ans2) = if b0 >= m0 {
      let q = b0 / m0
      (b0 % m0, ans1 + n0 * q)
    } else {
      (b0, ans1)
    }
    // After both reductions: 0 <= a1 < m0,  0 <= b1 < m0.
    // y_max is the numerator value at i = n0, which is the maximum numerator.
    let y_max = a1 * n0 + b1
    // Base case: if even the maximum numerator is below m0, every floor is 0.
    if y_max < m0 {
      break ans2
    } else {
      // Coordinate-swap (Euclidean step): count the same lattice points from
      // the perspective of the j-axis instead of the i-axis.
      //
      //   sum_{i=0}^{n0-1} floor((a1*i + b1) / m0)
      //     = (n0 * floor(y_max/m0))
      //       - sum_{j=0}^{floor(y_max/m0)-1} floor((m0*j + (m0 - b1 - 1)) / a1)
      //
      // After the swap the new parameters are:
      //   new_n = y_max / m0       (number of j-steps)
      //   new_a = m0               (old denominator becomes new slope)
      //   new_m = a1               (old slope becomes new denominator, now < old m0)
      //   new_b = y_max % m0       (remainder)
      //
      // Because new_m = a1 < m0, each step strictly reduces the denominator,
      // giving O(log min(a, m)) total iterations by the same argument as GCD.
      continue y_max / m0, a1, m0, y_max % m0, ans2
    }
  } where {
    proof_invariant: n0 >= 0L && m0 > 0L && a0 >= 0L && b0 >= 0L,
    proof_reasoning: (
      #|INVARIANT (Euclidean reduction):
      #|The current (n0, m0, a0, b0) represent the same floor sum after
      #|extracting full multiples of m0 from a0 and b0. The swap step applies
      #|the Euclidean transform that reduces m0 while preserving the total.
      #|TERMINATION:
      #|When y_max < m0, all remaining terms are < 1 and the loop ends.
    ),
  }
}

///|
test "floor_sum" {
  @debug.assert_eq(floor_sum(4L, 10L, 6L, 3L), 3L)
  @debug.assert_eq(floor_sum(6L, 7L, 4L, 2L), 8L)
}
