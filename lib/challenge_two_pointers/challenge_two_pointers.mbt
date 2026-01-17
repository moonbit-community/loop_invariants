// ============================================================================
// Challenge: Two Pointers / Sliding Window
// Count subarrays with sum <= k for non-negative arrays
// ============================================================================

///|
/// Count subarrays with sum <= k (requires non-negative values).
pub fn count_subarrays_leq(arr : ArrayView[Int], k : Int) -> Int {
  let n = arr.length()
  let mut left = 0
  let mut sum = 0
  let mut count = 0
  for right in 0..<n {
    sum = sum + arr[right]
    while left <= right && sum > k {
      sum = sum - arr[left]
      left = left + 1
    }
    if left <= right {
      count = count + (right - left + 1)
    }
  }
  count
}

///|
test "count_subarrays_leq" {
  let arr : Array[Int] = [1, 2, 1, 1]
  // Valid subarrays with sum <= 3: [1], [1,2], [2], [2,1], [1], [1,1], [1]
  assert_eq(count_subarrays_leq(arr[:], 3), 7)
  assert_eq(count_subarrays_leq([2, 2, 2][:], 3), 3) // each single element
}
