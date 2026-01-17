// ============================================================================
// Challenge: Difference Array for Range Updates
// Apply many range increments in O(n + q)
// ============================================================================

///|
/// Apply range add updates to a base array and return the updated array.
/// Each update is (l, r, delta) with inclusive bounds.
pub fn apply_range_add(
  base : ArrayView[Int],
  updates : ArrayView[(Int, Int, Int)],
) -> Array[Int] {
  let n = base.length()
  let diff : Array[Int] = Array::make(n + 1, 0)
  // Mark range boundaries in the difference array.
  for update in updates {
    let (l, r, delta) = update
    if l < 0 || r < l || r >= n {
      continue
    }
    diff[l] = diff[l] + delta
    if r + 1 < n {
      diff[r + 1] = diff[r + 1] - delta
    }
  }
  let result : Array[Int] = Array::make(n, 0)
  // Prefix-sum the difference array to reconstruct final values.
  let mut run = 0
  for i in 0..<n {
    run = run + diff[i]
    result[i] = base[i] + run
  }
  result
}

///|
test "difference_array" {
  let base : Array[Int] = [1, 2, 3, 4, 5]
  let updates : Array[(Int, Int, Int)] = [(1, 3, 2), (0, 0, -1), (2, 4, 1)]
  let updated = apply_range_add(base[:], updates[:])
  // base + updates = [0, 4, 6, 7, 6]
  assert_eq(updated, [0, 4, 6, 7, 6])
}
