// ============================================================================
// Challenge: Ternary Search on Unimodal Array
// ============================================================================

///|
/// Find index of minimum value in a unimodal array (decreasing then increasing).
#warnings("+missing_invariant+missing_reasoning")
pub fn find_min_unimodal(arr : ArrayView[Int]) -> Int {
  let n = arr.length()
  guard n > 0 else { return -1 }
  let (l, h) = for lo = 0, hi = n - 1 {
    if hi - lo <= 3 {
      break (lo, hi)
    } else {
      let m1 = lo + (hi - lo) / 3
      let m2 = hi - (hi - lo) / 3
      if arr[m1] <= arr[m2] {
        continue lo, m2 - 1
      } else {
        continue m1 + 1, hi
      }
    }
  } where {
    invariant: lo >= 0 && hi < n && lo <= hi,
    reasoning: (
      #|INVARIANT (Unimodal bracket):
      #|The minimum lies within [lo, hi].
      #|MAINTENANCE:
      #|Compare arr[m1] and arr[m2]; discard the side that cannot contain
      #|the minimum for a unimodal sequence.
      #|TERMINATION:
      #|When hi - lo <= 3, the minimum is within a small window.
    ),
  }
  // Linear scan for minimum in small window using functional for loop
  for i = l, best_idx = l; i <= h; {
    continue i + 1, if arr[i] < arr[best_idx] { i } else { best_idx }
  } else {
    best_idx
  } where {
    invariant: i >= l && i <= h + 1,
    reasoning: (
      #|INVARIANT (Final scan):
      #|best_idx is the index of the smallest value in arr[l..i).
      #|MAINTENANCE:
      #|Update best_idx when a smaller value is found.
      #|TERMINATION:
      #|At i = h + 1, best_idx is the minimum index in [l, h].
    ),
  }
}

///|
test "find_min_unimodal" {
  let arr : Array[Int] = [9, 7, 5, 3, 4, 6, 8]
  assert_eq(find_min_unimodal(arr[:]), 3)
  let arr2 : Array[Int] = [5, 4, 3, 2, 1]
  assert_eq(find_min_unimodal(arr2[:]), 4)
}
