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
  let mut n0 = n
  let mut m0 = m
  let mut a0 = a
  let mut b0 = b
  let mut ans = 0L
  for {
    if a0 >= m0 {
      let q = a0 / m0
      ans = ans + (n0 - 1L) * n0 / 2L * q
      a0 = a0 % m0
    }
    if b0 >= m0 {
      let q = b0 / m0
      ans = ans + n0 * q
      b0 = b0 % m0
    }
    let y_max = a0 * n0 + b0
    if y_max < m0 {
      break
    }
    let new_n = y_max / m0
    let new_b = y_max % m0
    let new_m = a0
    a0 = m0
    m0 = new_m
    n0 = new_n
    b0 = new_b
  } where {
    invariant: n0 >= 0L && m0 > 0L && a0 >= 0L && b0 >= 0L,
    reasoning: (
      #|INVARIANT (Euclidean reduction):
      #|The current (n0, m0, a0, b0) represent the same floor sum after
      #|extracting full multiples of m0 from a0 and b0. The swap step applies
      #|the Euclidean transform that reduces m0 while preserving the total.
      #|TERMINATION:
      #|When y_max < m0, all remaining terms are < 1 and the loop ends.
    ),
  }
  ans
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "floor sum small" {
  inspect(floor_sum(4L, 5L, 3L, 2L), content="4")
  inspect(floor_sum(5L, 4L, 2L, 1L), content="4")
}

///|
test "floor sum with reductions" {
  inspect(floor_sum(5L, 4L, 6L, 7L), content="21")
}
