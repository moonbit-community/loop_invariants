// ============================================================================
// SLIDING WINDOW MAXIMUM - O(n) using Monotonic Deque
// ============================================================================
//
// Find maximum element in each window of size k as window slides across array.
//
// KEY INSIGHT: Maintain a deque of indices where values are strictly decreasing.
// The front of deque always has the maximum. Remove indices outside window
// and smaller values when adding new elements.
//
// ALGORITHM:
// 1. For each element at index i:
//    a. Remove front if outside window (i - front >= k)
//    b. Remove all back elements smaller than arr[i]
//    c. Add i to back
//    d. If i >= k-1, front is maximum for this window
//
// INVARIANTS:
// 1. Deque contains indices in increasing order
// 2. Values at deque indices are in strictly decreasing order
// 3. All indices in deque are within current window [i-k+1, i]
// 4. Front of deque is index of maximum in current window
//
// TIME COMPLEXITY: O(n) - each element added and removed at most once
// SPACE COMPLEXITY: O(k) for deque

///|
/// Compute maximum in each sliding window of size k
fn sliding_window_max(arr : Array[Int64], k : Int) -> Array[Int64] {
  let n = arr.length()
  if n == 0 || k <= 0 {
    return []
  }
  if k >= n {
    // Single window containing all elements - find max using fold
    let m = arr[1:].fold(init=arr[0], fn(acc, x) {
      if x > acc {
        x
      } else {
        acc
      }
    })
    return [m]
  }
  let result : Array[Int64] = []
  let dq : @deque.Deque[Int] = @deque.new()
  for i = 0; i < n; i = i + 1 {
    // Remove elements outside window
    while dq.front() is Some(front) {
      if front <= i - k {
        let _ = dq.pop_front()

      } else {
        break
      }
    }

    // Remove smaller elements from back
    while dq.back() is Some(back) {
      if arr[back] <= arr[i] {
        let _ = dq.pop_back()

      } else {
        break
      }
    }

    // Add current index
    dq.push_back(i)

    // Record maximum once we have a full window
    if i >= k - 1 {
      result.push(arr[dq.front().unwrap()])
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT 1 (Bounds): i iterates through [0, n], and deque stores indices
      #|from the processed prefix [0, i).
      #|MAINTENANCE:
      #|Each iteration increments i by 1; deque operations keep indices in [0, i].
      #|TERMINATION:
      #|At i = n, all positions are processed.
    ),
    invariant: dq.length() >= 0 && dq.length() <= i,
    reasoning: (
      #|INVARIANT 2 (Deque size): deque contains at most i indices from [0, i).
      #|MAINTENANCE:
      #|Pop operations remove indices; push_back appends the new index i.
      #|TERMINATION:
      #|At loop end, deque indices refer only to processed elements.
    ),
    invariant: dq.is_empty() ||
    (dq.front().unwrap() >= i - k && dq.front().unwrap() <= i - 1),
    reasoning: (
      #|INVARIANT 3 (Window membership): if deque is non-empty, its front index
      #|lies inside the current window for prefix [0, i): [i-k, i-1].
      #|MAINTENANCE:
      #|Pop_front removes indices < i-k before using the front.
      #|TERMINATION:
      #|At i = n, the front belongs to the last window.
    ),
    invariant: result.length() == (if i >= k { i - k + 1 } else { 0 }),
    reasoning: (
      #|INVARIANT 4 (Output size): after processing indices [0, i), we have
      #|exactly one maximum per full window.
      #|
      #|MAINTENANCE:
      #|- Drop indices <= i-k (out of window).
      #|- Drop back indices with value <= arr[i] so remaining values are
      #|  strictly decreasing.
      #|- Push i so deque indices increase and front stays the window maximum.
      #|- When i >= k-1, emit front as the window max.
      #|
      #|TERMINATION:
      #|After i = n, every window [j, j+k-1] has been recorded in order.
    ),
  }
  result
}

// ============================================================================
// SLIDING WINDOW MINIMUM (similar logic)
// ============================================================================

///|
fn sliding_window_min(arr : Array[Int64], k : Int) -> Array[Int64] {
  let n = arr.length()
  if n == 0 || k <= 0 {
    return []
  }
  if k >= n {
    // Single window containing all elements - find min using fold
    let m = arr[1:].fold(init=arr[0], fn(acc, x) {
      if x < acc {
        x
      } else {
        acc
      }
    })
    return [m]
  }
  let result : Array[Int64] = []
  let dq : @deque.Deque[Int] = @deque.new()
  for i = 0; i < n; i = i + 1 {
    while dq.front() is Some(front) {
      if front <= i - k {
        let _ = dq.pop_front()

      } else {
        break
      }
    }
    while dq.back() is Some(back) {
      if arr[back] >= arr[i] {
        let _ = dq.pop_back()

      } else {
        break
      }
    }
    dq.push_back(i)
    if i >= k - 1 {
      result.push(arr[dq.front().unwrap()])
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT 1 (Bounds): i advances through [0, n], deque stores indices
      #|from the processed prefix [0, i).
      #|MAINTENANCE:
      #|Increment i by 1; deque operations keep indices within [0, i].
      #|TERMINATION:
      #|At i = n, all positions are processed.
    ),
    invariant: dq.length() >= 0 && dq.length() <= i,
    reasoning: (
      #|INVARIANT 2 (Deque size): deque contains at most i indices from [0, i).
      #|MAINTENANCE:
      #|Pop operations remove indices; push_back appends the new index i.
      #|TERMINATION:
      #|At loop end, deque indices refer only to processed elements.
    ),
    invariant: dq.is_empty() ||
    (dq.front().unwrap() >= i - k && dq.front().unwrap() <= i - 1),
    reasoning: (
      #|INVARIANT 3 (Window membership): if deque is non-empty, its front index
      #|lies inside the current window for prefix [0, i): [i-k, i-1].
      #|MAINTENANCE:
      #|Pop_front removes indices < i-k before using the front.
      #|TERMINATION:
      #|At i = n, the front belongs to the last window.
    ),
    invariant: result.length() == (if i >= k { i - k + 1 } else { 0 }),
    reasoning: (
      #|INVARIANT 4 (Output size): after processing indices [0, i), we have
      #|exactly one minimum per full window.
      #|
      #|MAINTENANCE:
      #|- Drop indices <= i-k (out of window).
      #|- Drop back indices with value >= arr[i] so remaining values are
      #|  strictly increasing.
      #|- Push i so deque indices increase and front stays the window minimum.
      #|- When i >= k-1, emit front as the window min.
      #|
      #|TERMINATION:
      #|After i = n, every window [j, j+k-1] has been recorded in order.
    ),
  }
  result
}

// ============================================================================
// FIXED WINDOW OPERATIONS
// ============================================================================

///|
/// Sum of each window of size k
fn sliding_window_sum(arr : Array[Int64], k : Int) -> Array[Int64] {
  let n = arr.length()
  if n == 0 || k <= 0 || k > n {
    return []
  }
  // Initialize first window sum using fold
  let initial_sum = arr[:k].fold(init=0L, fn(acc, x) { acc + x })
  let result : Array[Int64] = [initial_sum]

  // Slide window - use functional for loop to track running sum
  for i = k, sum = initial_sum; i < n; {
    let new_sum = sum + arr[i] - arr[i - k]
    result.push(new_sum)
    continue i + 1, new_sum
  } else {
    result
  } where {
    invariant: i >= k && i <= n,
    reasoning: (
      #|INVARIANT (sliding sum):
      #|sum equals the sum of arr[i-k..i) at each step.
      #|MAINTENANCE:
      #|Subtract arr[i-k] and add arr[i] to slide the window.
      #|TERMINATION:
      #|At i = n, all window sums have been recorded.
    ),
  }
}

// ============================================================================
// TWO POINTER / VARIABLE WINDOW
// ============================================================================

///|
/// Find length of longest subarray with sum <= target
fn longest_subarray_with_sum_le(arr : Array[Int64], target : Int64) -> Int {
  let n = arr.length()
  if n == 0 {
    return 0
  }
  let mut left = 0
  let mut sum = 0L
  let mut max_len = 0
  for right = 0; right < n; right = right + 1 {
    sum = sum + arr[right]

    // Shrink window until sum <= target
    while sum > target && left <= right {
      sum = sum - arr[left]
      left = left + 1
    }
    if sum <= target {
      let len = right - left + 1
      if len > max_len {
        max_len = len
      }
    }
  } where {
    invariant: right >= 0 && right <= n && left >= 0 && left <= right + 1,
    reasoning: (
      #|INVARIANT 1 (Bounds): left/right stay within [0, n] with at most one-step
      #|gap when the window becomes empty.
      #|MAINTENANCE:
      #|right increments each step; left only moves forward during shrinking.
      #|TERMINATION:
      #|At right = n, all elements have been processed.
    ),
    invariant: max_len >= 0 && max_len <= right,
    reasoning: (
      #|INVARIANT 2 (Best-so-far): max_len is the longest valid window found
      #|in the processed prefix [0, right).
      #|
      #|MAINTENANCE:
      #|- Add arr[right] to the running sum.
      #|- If sum exceeds target, advance left while subtracting values.
      #|  (Assumes non-negative elements so shrinking only decreases sum.)
      #|- After shrinking, [left, right] is the longest valid window ending at right.
      #|- Update max_len if this window is longer.
      #|
      #|TERMINATION:
      #|After right = n, every window end was considered, so max_len is optimal.
    ),
  }
  max_len
}

///|
/// Find minimum length subarray with sum >= target (all positive elements)
fn min_subarray_with_sum_ge(arr : Array[Int64], target : Int64) -> Int {
  let n = arr.length()
  if n == 0 {
    return 0
  }
  let mut left = 0
  let mut sum = 0L
  let mut min_len = n + 1 // Impossible value
  for right = 0; right < n; right = right + 1 {
    sum = sum + arr[right]

    // Shrink window while sum >= target
    while sum >= target && left <= right {
      let len = right - left + 1
      if len < min_len {
        min_len = len
      }
      sum = sum - arr[left]
      left = left + 1
    }
  } where {
    invariant: right >= 0 && right <= n && left >= 0 && left <= right + 1,
    reasoning: (
      #|INVARIANT 1 (Bounds): left/right stay within [0, n] with at most one-step
      #|gap when the window becomes empty.
      #|MAINTENANCE:
      #|right increments each step; left only moves forward during shrinking.
      #|TERMINATION:
      #|At right = n, all elements have been processed.
    ),
    invariant: min_len >= 1 && min_len <= n + 1,
    reasoning: (
      #|INVARIANT 2 (Best-so-far): min_len is the shortest window with sum >= target
      #|seen in the processed prefix, or n+1 if none exists yet.
      #|
      #|MAINTENANCE:
      #|- Add arr[right] to the running sum.
      #|- While sum >= target, record the current length and shrink from left.
      #|  (Assumes non-negative elements so shrinking only decreases sum.)
      #|- This enumerates all minimal windows ending at right.
      #|
      #|TERMINATION:
      #|After right = n, min_len is the minimal length over all valid windows.
    ),
  }
  if min_len > n {
    0
  } else {
    min_len
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "sliding window max basic" {
  let arr : Array[Int64] = [1L, 3L, -1L, -3L, 5L, 3L, 6L, 7L]
  let result = sliding_window_max(arr, 3)
  // Windows: [1,3,-1], [3,-1,-3], [-1,-3,5], [-3,5,3], [5,3,6], [3,6,7]
  // Max:     3, 3, 5, 5, 6, 7
  inspect(result.length(), content="6")
  inspect(result[0], content="3")
  inspect(result[1], content="3")
  inspect(result[2], content="5")
  inspect(result[3], content="5")
  inspect(result[4], content="6")
  inspect(result[5], content="7")
}

///|
test "sliding window min basic" {
  let arr : Array[Int64] = [1L, 3L, -1L, -3L, 5L, 3L, 6L, 7L]
  let result = sliding_window_min(arr, 3)
  // Min: -1, -3, -3, -3, 3, 3
  inspect(result[0], content="-1")
  inspect(result[1], content="-3")
  inspect(result[2], content="-3")
}

///|
test "sliding window sum" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let result = sliding_window_sum(arr, 3)
  // Sums: 6, 9, 12
  inspect(result.length(), content="3")
  inspect(result[0], content="6")
  inspect(result[1], content="9")
  inspect(result[2], content="12")
}

///|
test "sliding window k=1" {
  let arr : Array[Int64] = [5L, 2L, 8L, 1L]
  let result = sliding_window_max(arr, 1)
  inspect(result.length(), content="4")
  inspect(result[0], content="5")
  inspect(result[1], content="2")
  inspect(result[2], content="8")
  inspect(result[3], content="1")
}

///|
test "sliding window k=n" {
  let arr : Array[Int64] = [1L, 5L, 3L, 2L]
  let result = sliding_window_max(arr, 4)
  inspect(result.length(), content="1")
  inspect(result[0], content="5")
}

///|
test "longest subarray" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  inspect(longest_subarray_with_sum_le(arr, 6L), content="3") // [1,2,3]
  inspect(longest_subarray_with_sum_le(arr, 15L), content="5") // entire array
  inspect(longest_subarray_with_sum_le(arr, 0L), content="0") // none
}

///|
test "min subarray sum ge" {
  let arr : Array[Int64] = [2L, 3L, 1L, 2L, 4L, 3L]
  inspect(min_subarray_with_sum_ge(arr, 7L), content="2") // [4,3]
  inspect(min_subarray_with_sum_ge(arr, 100L), content="0") // impossible
}
