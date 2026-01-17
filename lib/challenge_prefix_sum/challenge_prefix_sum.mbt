// ============================================================================
// Challenge: Prefix Sum Array
// Build prefix sums with precise loop invariants
// ============================================================================

///|
/// Build prefix sums where prefix[i] = sum(arr[0..i)).
pub fn build_prefix_sum(arr : ArrayView[Int]) -> Array[Int] {
  let n = arr.length()
  let prefix : Array[Int] = Array::make(n + 1, 0)
  let mut sum = 0
  for i, val in arr {
    sum = sum + val
    prefix[i + 1] = sum
  }
  prefix
}

///|
/// Range sum for inclusive bounds [l, r] using prefix sums.
pub fn range_sum(prefix : ArrayView[Int], l : Int, r : Int) -> Int {
  if l < 0 || r < l || r + 1 >= prefix.length() {
    return 0
  }
  prefix[r + 1] - prefix[l]
}

///|
test "prefix_sum" {
  let arr : Array[Int] = [3, -1, 4, 2]
  let prefix = build_prefix_sum(arr[:])
  assert_eq(prefix, [0, 3, 2, 6, 8])
  assert_eq(range_sum(prefix[:], 0, 0), 3)
  assert_eq(range_sum(prefix[:], 1, 2), 3) // -1 + 4
  assert_eq(range_sum(prefix[:], 0, 3), 8)
}
