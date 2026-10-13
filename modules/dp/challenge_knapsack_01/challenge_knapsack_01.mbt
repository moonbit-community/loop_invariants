// ============================================================================
// Challenge: 0/1 Knapsack (One-Dimensional DP)
// ============================================================================

///|
/// Maximum value with weight limit using each item at most once.
pub fn knapsack_01(
  weights : ArrayView[Int32],
  values : ArrayView[Int32],
  capacity : Int32,
) -> Int32 {
  let n = if weights.length() < values.length() {
    weights.length()
  } else {
    values.length()
  }
  let dp : Array[Int32] = Array::make(capacity + 1, 0)
  for i in 0..<n {
    let w_i = weights[i]
    let v_i = values[i]
    for w in capacity>=..w_i {
      let cand = dp[w - w_i] + v_i
      if cand > dp[w] {
        dp[w] = cand
      }
    }
  }
  dp[capacity]
}

///|
test "knapsack_01" {
  let weights : Array[Int32] = [2, 3, 4]
  let values : Array[Int32] = [4, 5, 6]
  @debug.assert_eq(knapsack_01(weights, values, 5), 9)
  @debug.assert_eq(knapsack_01(weights, values, 3), 5)
}
