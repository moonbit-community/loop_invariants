// ============================================================================
// Challenge: Two Pointers / Sliding Window
// Count subarrays with sum <= k for non-negative arrays
// ============================================================================

///|
/// Count subarrays with sum <= k (requires non-negative values).
#warnings("+missing_invariant+missing_reasoning")
pub fn count_subarrays_leq(arr : ArrayView[Int], k : Int) -> Int {
  let n = arr.length()
  guard n > 0 else { return 0 }
  outer~: for right = 0, left = 0, sum = 0, count = 0 {
    guard right < n else { break count }
    let sum_with_right = sum + arr[right]
    // Shrink window from left until sum <= k
    for l = left, s = sum_with_right {
      if s <= k {
        // Found valid window: count all subarrays ending at right
        let add = right - l + 1
        continue outer~ right + 1, l, s, count + add
      }
      continue l + 1, s - arr[l]
    } where {
      invariant: l >= left && l <= right + 1,
      invariant: s >= 0,
      reasoning: (
        #|INVARIANT (Window tightening):
        #|s equals the sum of arr[l..right+1), and l only moves rightward.
        #|MAINTENANCE:
        #|If s > k, remove arr[l] and increment l, shrinking the window.
        #|TERMINATION:
        #|When s <= k, continue outer~ with the valid window.
      ),
    }
  } where {
    invariant: right >= 0 && right <= n,
    invariant: left >= 0 && left <= right,
    reasoning: (
      #|INVARIANT (Counting subarrays):
      #|count equals the number of valid subarrays ending before index right.
      #|MAINTENANCE:
      #|After finding minimal left for this right via inner loop,
      #|continue outer~ adds all subarrays ending at right.
      #|TERMINATION:
      #|At right = n, count is the total number of subarrays with sum <= k.
    ),
  }
}

///|
test "count_subarrays_leq" {
  let arr : Array[Int] = [1, 2, 1, 1]
  // Valid subarrays with sum <= 3: [1], [1,2], [2], [2,1], [1], [1,1], [1]
  assert_eq(count_subarrays_leq(arr[:], 3), 7)
  assert_eq(count_subarrays_leq([2, 2, 2][:], 3), 3) // each single element
}
