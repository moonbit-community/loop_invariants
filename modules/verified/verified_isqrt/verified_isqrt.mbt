///|
/// Compute the integer square root of a non-negative integer.
///
/// Uses binary search over a bracketing interval `[lo, hi)` maintained so that
/// `lo * lo <= n < hi * hi`. The loop runs in `O(log n)` iterations and the
/// verified version carries the precondition `nonneg(n)` and postcondition
/// `isqrt_ok(n, result)` (i.e. `result * result <= n < (result + 1)^2`).
///
/// Parameters:
/// - `n`: a non-negative integer (precondition `n >= 0`).
///
/// Returns: the largest integer `r >= 0` such that `r * r <= n`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(isqrt(0), 0)
///   @debug.assert_eq(isqrt(15), 3)
///   @debug.assert_eq(isqrt(16), 4)
/// }
/// ```
pub fn isqrt(
  n : Int,
) -> Int where {
  proof_require: nonneg(n),
  proof_ensure: result => isqrt_ok(n, result),
} {
  for lo = 0, hi = n + 1; lo < hi - 1; {
    let mid = lo + (hi - lo) / 2
    if mid * mid <= n {
      continue mid, hi
    } else {
      continue lo, mid
    }
  } nobreak {
    lo
  } where {
    proof_invariant: 0 <= lo,
    proof_invariant: lo < hi,
    proof_invariant: lo * lo <= n,
    proof_invariant: n < hi * hi,
    proof_reasoning: (
      #| The loop maintains a bracketing interval around the integer square
      #| root. `lo` is always feasible because `lo * lo <= n`, while `hi` is
      #| always too large because `n < hi * hi`.
      #|
      #| At the start, `lo = 0` and `hi = n + 1`, so the interval is valid for
      #| every nonnegative `n`.
      #|
      #| The midpoint test `mid * mid <= n` decides whether the answer is at or
      #| below `mid` or strictly above it:
      #|   - If true, `mid` is still feasible, so we move `lo` up to `mid`.
      #|   - If false, `mid` is too large, so we move `hi` down to `mid`.
      #|
      #| Under the guard `lo < hi - 1`, the midpoint lies strictly inside the
      #| window, so each iteration shrinks the gap `hi - lo`.
      #|
      #| When the loop exits, `hi == lo + 1`. The two square-bound invariants
      #| then become exactly `lo * lo <= n < (lo + 1) * (lo + 1)`, which is the
      #| standard integer square-root postcondition.
    ),
  }
}
