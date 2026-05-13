// ============================================================================
// Challenge: Sliding Window Minimum
// ============================================================================

///|
/// Return minimum for each window of size k.
pub fn sliding_window_min(arr : ArrayView[Int], k : Int) -> Array[Int] {
  let n = arr.length()
  guard n >= k && k > 0 else { return [] }
  let result : Array[Int] = []
  let deque : @deque.Deque[Int] = Deque([])
  for i in 0..<n {
    let _ = for front = deque.front() {
      match front {
        None => break ()
        Some(front) =>
          if front <= i - k {
            let _ = deque.pop_front()
            continue deque.front()
          } else {
            break ()
          }
      }
    }
    let _ = for back = deque.back() {
      match back {
        None => break ()
        Some(back) =>
          if arr[back] >= arr[i] {
            let _ = deque.pop_back()
            continue deque.back()
          } else {
            break ()
          }
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
  @debug.assert_eq(sliding_window_min(arr, 3), [2, 2, 3, 1])
}
