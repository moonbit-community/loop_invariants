///|
/// Formalized version of the repeated-subtraction division example.
pub fn div_nonneg(
  n : Int,
  d : Int,
) -> Int where {
  proof_require: valid_division_args(n, d),
  proof_ensure: result => div_ok(n, d, result),
} {
  for q = 0, r = n; q < n + 1; {
    if r < d {
      break q
    } else {
      continue q + 1, r - d
    }
  } nobreak {
    q
  } where {
    proof_invariant: 0 <= q,
    proof_invariant: q <= n,
    proof_invariant: 0 <= r,
    proof_invariant: n == q * d + r,
    proof_yield: res => div_ok(n, d, res),
    proof_reasoning: (
      #| This loop mirrors repeated subtraction exactly: `q` counts how many
      #| full copies of `d` have been removed from `n`, while `r` is the
      #| remaining amount.
      #|
      #| The core arithmetic invariant is `n == q * d + r`. It starts true at
      #| `(q, r) = (0, n)` and is preserved because each iteration changes the
      #| state to `(q + 1, r - d)`.
      #|
      #| The guard `r < d` identifies the first point at which another full
      #| subtraction is impossible. Together with `0 <= r`, that means
      #| `q * d <= n < (q + 1) * d`, so yielding `q` is correct.
      #|
      #| The auxiliary bound `q <= n` keeps the synthetic loop guard
      #| `q < n + 1` proof-friendly without changing the mathematical argument:
      #| when `d > 0`, every successful subtraction increases `q` by one and
      #| removes at least one unit from `r`.
    ),
  }
}

///|
/// Compute `n mod d` for non-negative `n` and positive `d`.
///
/// Derived from `div_nonneg`: first computes the quotient `q = div_nonneg(n, d)`
/// and returns `n - q * d`. The verified version carries the precondition
/// `valid_division_args(n, d)` (i.e. `n >= 0 && d > 0`) and postcondition
/// `mod_ok(n, d, result)` (i.e. `0 <= result < d` and `result = n - q*d` for
/// the matching quotient).
///
/// Parameters:
/// - `n`: dividend (precondition `n >= 0`).
/// - `d`: divisor (precondition `d > 0`).
///
/// Returns: the remainder `r` with `0 <= r < d`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(mod_nonneg(10, 3), 1)
///   @debug.assert_eq(mod_nonneg(0, 7), 0)
/// }
/// ```
pub fn mod_nonneg(
  n : Int,
  d : Int,
) -> Int where {
  proof_require: valid_division_args(n, d),
  proof_ensure: result => mod_ok(n, d, result),
} {
  let q = div_nonneg(n, d)
  let r = n - q * d
  proof_assert mod_ok(n, d, r)
  r
}

///|
/// Compute the pair `(n / d, n mod d)` for non-negative `n` and positive `d`.
///
/// Wraps `div_nonneg` and `mod_nonneg` to return both results in one call.
/// Shares the precondition `valid_division_args(n, d)` (i.e. `n >= 0 && d > 0`).
///
/// Parameters:
/// - `n`: dividend (precondition `n >= 0`).
/// - `d`: divisor (precondition `d > 0`).
///
/// Returns: the tuple `(q, r)` with `n = q * d + r` and `0 <= r < d`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(div_mod_nonneg(25, 5), (5, 0))
///   @debug.assert_eq(div_mod_nonneg(10, 3), (3, 1))
/// }
/// ```
pub fn div_mod_nonneg(
  n : Int,
  d : Int,
) -> (Int, Int) where {
  proof_require: valid_division_args(n, d),
} {
  let q = div_nonneg(n, d)
  let r = mod_nonneg(n, d)
  (q, r)
}

///|
test "verified_division_examples" {
  @debug.assert_eq(div_nonneg(10, 3), 3)
  @debug.assert_eq(mod_nonneg(10, 3), 1)
  @debug.assert_eq(div_mod_nonneg(25, 5), (5, 0))
  @debug.assert_eq(div_mod_nonneg(0, 7), (0, 0))
}
