// ============================================================================
// Challenge: Sliding Window Minimum
// ============================================================================

///|
/// Return minimum for each window of size k.
pub fn sliding_window_min(arr : ArrayView[Int], k : Int) -> Array[Int] {
  let n = arr.length()
  guard n >= k && k > 0 else { return [] }
  let result : Array[Int] = []
  let deque : @deque.Deque[Int] = @deque.new()
  for i in 0..<n {
    while deque.front() is Some(front) {
      if front <= i - k {
        let _ = deque.pop_front()
      } else {
        break
      }
    }
    while deque.back() is Some(back) {
      if arr[back] >= arr[i] {
        let _ = deque.pop_back()
      } else {
        break
      }
    }
    deque.push_back(i)
    if i >= k - 1 && deque.front() is Some(front) {
      result.push(arr[front])
    }
  }
  result
}

///|
test "sliding_window_min" {
  let arr : Array[Int] = [4, 2, 12, 3, 5, 1]
  assert_eq(sliding_window_min(arr[:], 3), [2, 2, 3, 1])
}
