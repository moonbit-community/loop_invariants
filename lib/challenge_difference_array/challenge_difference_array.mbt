// ============================================================================
// Challenge: Difference Array for Range Updates
// Apply many range increments in O(n + q)
// ============================================================================

///|
/// Apply range add updates to a base array and return the updated array.
/// Each update is (l, r, delta) with inclusive bounds.
#warnings("+missing_invariant+missing_reasoning")
fn apply_range_add(
  base : ArrayView[Int],
  updates : ArrayView[(Int, Int, Int)],
) -> Array[Int] {
  let n = base.length()
  let diff : Array[Int] = Array::make(n + 1, 0)
  // Mark range boundaries in the difference array.
  for i = 0; i < updates.length(); i = i + 1 {
    let (l, r, delta) = updates[i]
    if l < 0 || r < l || r >= n {
      continue
    }
    diff[l] = diff[l] + delta
    if r + 1 < n {
      diff[r + 1] = diff[r + 1] - delta
    }
  } where {
    invariant: i >= 0 && i <= updates.length(),
    reasoning: (
      #|INVARIANT (Diff marks):
      #|All updates in updates[0..i) have been applied to diff by adding
      #|delta at l and subtracting delta at r+1.
      #|MAINTENANCE:
      #|Processing updates[i] adds its boundary markers, preserving correctness.
      #|TERMINATION:
      #|At i = updates.length(), diff encodes all range updates.
    ),
  }
  let result : Array[Int] = Array::make(n, 0)
  // Prefix-sum the difference array to reconstruct final values.
  for i = 0, run = 0 {
    if i >= n {
      break
    } else {
      let new_run = run + diff[i]
      result[i] = base[i] + new_run
      continue i + 1, new_run
    }
  } where {
    invariant: i >= 0 && i <= n,
    invariant: i == 0 || run == result[i - 1] - base[i - 1],
    reasoning: (
      #|INVARIANT (Prefix reconstruction):
      #|run is the accumulated diff prefix for indices [0..i), so result[0..i)
      #|already reflects all updates for that prefix.
      #|MAINTENANCE:
      #|Add diff[i] into run and write result[i] = base[i] + run.
      #|TERMINATION:
      #|At i = n, all elements are updated.
    ),
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
