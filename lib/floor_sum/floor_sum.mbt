// ============================================================================
// FLOOR SUM - Sum of floors of an arithmetic progression
// ============================================================================
//
// Compute:
//   sum_{i=0}^{n-1} floor((a*i + b) / m)
//
// This uses the classic recursive/iterative reduction from AtCoder Library.
//
// TIME COMPLEXITY: O(log m + log a)
// SPACE COMPLEXITY: O(1)

///|
/// Sum of floors for 0 <= i < n. All parameters must be non-negative.
pub fn floor_sum(n : Int64, m : Int64, a : Int64, b : Int64) -> Int64 {
  if n <= 0L || m <= 0L {
    return 0L
  }
  for n0 = n, m0 = m, a0 = a, b0 = b, ans = 0L {
    let (a1, ans1) = if a0 >= m0 {
      let q = a0 / m0
      (a0 % m0, ans + (n0 - 1L) * n0 / 2L * q)
    } else {
      (a0, ans)
    }
    let (b1, ans2) = if b0 >= m0 {
      let q = b0 / m0
      (b0 % m0, ans1 + n0 * q)
    } else {
      (b0, ans1)
    }
    let y_max = a1 * n0 + b1
    if y_max < m0 {
      break ans2
    } else {
      continue y_max / m0, a1, m0, y_max % m0, ans2
    }
  } where {
    proof_invariant: n0 >= 0L && m0 > 0L && a0 >= 0L && b0 >= 0L,
    reasoning: (
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
  assert_eq(floor_sum(4L, 10L, 6L, 3L), 3L)
  assert_eq(floor_sum(6L, 7L, 4L, 2L), 8L)
}
