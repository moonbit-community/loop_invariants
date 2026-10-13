// ============================================================================
// Challenge: Unbounded Knapsack (Complete Knapsack)
// ============================================================================

///|
/// Maximum value with unlimited copies of each item.
pub fn knapsack_unbounded(
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
    for w in w_i..<=capacity {
      let cand = dp[w - w_i] + v_i
      if cand > dp[w] {
        dp[w] = cand
      }
    }
  }
  dp[capacity]
}

///|
test "knapsack_unbounded" {
  let weights : Array[Int32] = [2, 3]
  let values : Array[Int32] = [4, 5]
  @debug.assert_eq(knapsack_unbounded(weights, values, 7), 13)
  @debug.assert_eq(knapsack_unbounded(weights, values, 1), 0)
}
