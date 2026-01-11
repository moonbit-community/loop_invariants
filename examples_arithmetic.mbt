// ============================================================================
// Example C: Division with Remainder (repeated subtraction)
// ============================================================================

///|
/// Compute (q, r) for non-negative n and positive d.
#warnings("+missing_invariant+missing_reasoning")
fn div_mod_nonneg(n : Int, d : Int) -> (Int, Int) {
  guard n >= 0 && d > 0 else { return (0, 0) }
  for q = 0, r = n {
    if r < d {
      break (q, r)
    } else {
      continue q + 1, r - d
    }
  } where {
    invariant: n == q * d + r,
    reasoning: (
      #|INVARIANT (division identity):
      #|n == q * d + r holds with r as the remaining remainder.
      #|MAINTENANCE:
      #|Increment q and subtract d from r, preserving the identity.
      #|TERMINATION:
      #|When r < d, (q, r) is the quotient-remainder pair.
    ),
    invariant: r >= 0,
    reasoning: (
      #|INVARIANT (non-negative remainder):
      #|r starts at n and decreases by d; we stop before r would go negative.
      #|MAINTENANCE:
      #|The loop condition ensures r >= d before subtracting.
      #|TERMINATION:
      #|At exit, r is the non-negative remainder.
    ),
  }
}

///|
test "div_mod_nonneg" {
  assert_eq(div_mod_nonneg(10, 3), (3, 1))
  assert_eq(div_mod_nonneg(25, 5), (5, 0))
  assert_eq(div_mod_nonneg(0, 7), (0, 0))
}

// ============================================================================
// Example D: Horner's Method for Polynomial Evaluation
// ============================================================================

///|
/// Evaluate polynomial prefix of length end with Horner's scheme.
fn poly_prefix(coeffs : ArrayView[Int], end : Int, x : Int) -> Int {
  if end <= 0 {
    0
  } else if end == 1 {
    coeffs[0]
  } else {
    let prev = poly_prefix(coeffs, end - 1, x)
    prev * x + coeffs[end - 1]
  }
}

///|
/// Evaluate polynomial with coefficients in descending powers.
#warnings("+missing_invariant+missing_reasoning")
fn horner_eval(coeffs : ArrayView[Int], x : Int) -> Int {
  guard coeffs.length() > 0 else { return 0 }
  for i = 1, acc = coeffs[0] {
    if i >= coeffs.length() {
      break acc
    } else {
      let next = acc * x + coeffs[i]
      continue i + 1, next
    }
  } where {
    invariant: 1 <= i && i <= coeffs.length(),
    reasoning: (
      #|INVARIANT (progress):
      #|i is the number of coefficients folded into acc, within [1..len].
      #|MAINTENANCE:
      #|Each step consumes coeffs[i] and increments i by 1.
      #|TERMINATION:
      #|At i = coeffs.length(), all coefficients are processed.
    ),
    invariant: acc == poly_prefix(coeffs, i, x),
    reasoning: (
      #|Horner step: if acc = P_prefix(i), then
      #|acc * x + coeffs[i] = P_prefix(i + 1).
      #|So acc always equals the polynomial value for the processed prefix.
    ),
  }
}

///|
test "horner_eval" {
  // 2x^2 - 3x + 5 at x=4 -> 25
  assert_eq(horner_eval([2, -3, 5][:], 4), 25)
  assert_eq(horner_eval([1][:], 10), 1)
  assert_eq(horner_eval([3, 0, 0][:], 2), 12) // 3x^2
}
