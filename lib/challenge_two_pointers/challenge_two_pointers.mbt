// ============================================================================
// Challenge: Two Pointers / Sliding Window
// Count subarrays with sum <= k for non-negative arrays
// ============================================================================

///|
/// Count subarrays with sum <= k (requires non-negative values).
pub fn count_subarrays_leq(arr : ArrayView[Int], k : Int) -> Int {
  let n = arr.length()
  for right in 0..<n; left = 0, sum = 0, count = 0 {
    let (new_left, new_sum) = for left1 = left, sum1 = sum + arr[right] {
      if left1 <= right && sum1 > k {
        continue left1 + 1, sum1 - arr[left1]
      } else {
        break (left1, sum1)
      }
    }
    let new_count = if new_left <= right {
      count + (right - new_left + 1)
    } else {
      count
    }
    continue new_left, new_sum, new_count
  } nobreak {
    count
  }
}

///|
test "count_subarrays_leq" {
  let arr : Array[Int] = [1, 2, 1, 1]
  // Valid subarrays with sum <= 3: [1], [1,2], [2], [2,1], [1], [1,1], [1]
  assert_eq(count_subarrays_leq(arr, 3), 7)
  assert_eq(count_subarrays_leq([2, 2, 2], 3), 3) // each single element
}
