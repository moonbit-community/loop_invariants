// ============================================================================
// Challenge: Ternary Search on Unimodal Array
// ============================================================================

///|
/// Find index of minimum value in a unimodal array (decreasing then increasing).
pub fn find_min_unimodal(arr : ArrayView[Int]) -> Int {
  let n = arr.length()
  guard n > 0 else { return -1 }
  let mut lo = 0
  let mut hi = n - 1
  for _ in 0..<n {
    if hi - lo <= 3 {
      break
    }
    let m1 = lo + (hi - lo) / 3
    let m2 = hi - (hi - lo) / 3
    if arr[m1] <= arr[m2] {
      hi = m2 - 1
    } else {
      lo = m1 + 1
    }
  }
  // Linear scan for minimum in the small window
  let mut best_idx = lo
  for i in lo..<(hi + 1) {
    if arr[i] < arr[best_idx] {
      best_idx = i
    }
  }
  best_idx
}

///|
test "find_min_unimodal" {
  let arr : Array[Int] = [9, 7, 5, 3, 4, 6, 8]
  assert_eq(find_min_unimodal(arr[:]), 3)
  let arr2 : Array[Int] = [5, 4, 3, 2, 1]
  assert_eq(find_min_unimodal(arr2[:]), 4)
}
