///|
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
    reasoning: (
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
