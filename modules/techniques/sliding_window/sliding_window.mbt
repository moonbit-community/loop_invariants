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
/// Compute the maximum value in each contiguous window of size `k` as the
/// window slides from left to right across `arr`.
///
/// A **monotonic deque** of indices is maintained such that:
/// - indices are stored in strictly increasing order,
/// - the values at those indices are in strictly decreasing order,
/// - every stored index lies within the current window `[i-k+1, i]`.
///
/// The front of the deque therefore always holds the index of the window
/// maximum, giving O(1) per window after an amortized O(n) total deque work.
///
/// Parameters:
/// - `arr` -- input array of `Int64` values.
/// - `k`   -- window size (must be positive; if >= `arr.length()` a single
///            window spanning the whole array is returned).
///
/// Returns an array of length `max(0, n - k + 1)` where element `j` is the
/// maximum of `arr[j..j+k]`.
///
/// Time: O(n). Space: O(k).
///
/// Example:
/// ```
/// sliding_window_max([1, 3, -1, -3, 5, 3, 6, 7], 3)
/// // => [3, 3, 5, 5, 6, 7]
/// ```
pub fn sliding_window_max(arr : Array[Int64], k : Int) -> Array[Int64] {
  let n = arr.length()
  if n == 0 || k <= 0 {
    return []
  }
  if k >= n {
    // Single window containing all elements - find max using fold
    let m = arr[1:].fold(init=arr[0], (acc, x) => if x > acc { x } else { acc })
    return [m]
  }
  let result : Array[Int64] = []
  let dq : @deque.Deque[Int] = @deque.new()
  for i in 0..<n {
    // Remove elements outside window
    let _ = for front = dq.front() {
      match front {
        None => break ()
        Some(front) =>
          if front <= i - k {
            let _ = dq.pop_front()
            continue dq.front()
          } else {
            break ()
          }
      }
    }

    // Remove smaller elements from back
    let _ = for back = dq.back() {
      match back {
        None => break ()
        Some(back) =>
          if arr[back] <= arr[i] {
            let _ = dq.pop_back()
            continue dq.back()
          } else {
            break ()
          }
      }
    }

    // Add current index
    dq.push_back(i)

    // Record maximum once we have a full window
    if i >= k - 1 && dq.front() is Some(front) {
      result.push(arr[front])
    }
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT 1 (Bounds): i iterates through [0, n], and deque stores indices
      #|from the processed prefix [0, i).
      #|MAINTENANCE:
      #|Each iteration increments i by 1; deque operations keep indices in [0, i].
      #|TERMINATION:
      #|At i = n, all positions are processed.
    ),
    proof_invariant: dq.length() >= 0 && dq.length() <= i,
    proof_reasoning: (
      #|INVARIANT 2 (Deque size): deque contains at most i indices from [0, i).
      #|MAINTENANCE:
      #|Pop operations remove indices; push_back appends the new index i.
      #|TERMINATION:
      #|At loop end, deque indices refer only to processed elements.
    ),
    proof_invariant: match dq.front() {
      None => true
      Some(f) => f >= i - k && f <= i - 1
    },
    proof_reasoning: (
      #|INVARIANT 3 (Window membership): if deque is non-empty, its front index
      #|lies inside the current window for prefix [0, i): [i-k, i-1].
      #|MAINTENANCE:
      #|Pop_front removes indices < i-k before using the front.
      #|TERMINATION:
      #|At i = n, the front belongs to the last window.
    ),
    proof_invariant: result.length() == (if i >= k { i - k + 1 } else { 0 }),
    proof_reasoning: (
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
/// Compute the minimum value in each contiguous window of size `k` as the
/// window slides from left to right across `arr`.
///
/// Mirrors `sliding_window_max` but keeps the deque in **strictly increasing**
/// value order so the front always holds the window minimum index.
///
/// Insertion rule: before pushing index `i`, pop every back element whose
/// value is `>= arr[i]` (elements that can never be the minimum while `i`
/// is present).
///
/// Parameters:
/// - `arr` -- input array of `Int64` values.
/// - `k`   -- window size (must be positive; if >= `arr.length()` a single
///            window spanning the whole array is returned).
///
/// Returns an array of length `max(0, n - k + 1)` where element `j` is the
/// minimum of `arr[j..j+k]`.
///
/// Time: O(n). Space: O(k).
///
/// Example:
/// ```
/// sliding_window_min([1, 3, -1, -3, 5, 3, 6, 7], 3)
/// // => [-1, -3, -3, -3, 3, 3]
/// ```
pub fn sliding_window_min(arr : Array[Int64], k : Int) -> Array[Int64] {
  let n = arr.length()
  if n == 0 || k <= 0 {
    return []
  }
  if k >= n {
    // Single window containing all elements - find min using fold
    let m = arr[1:].fold(init=arr[0], (acc, x) => if x < acc { x } else { acc })
    return [m]
  }
  let result : Array[Int64] = []
  let dq : @deque.Deque[Int] = @deque.new()
  for i in 0..<n {
    let _ = for front = dq.front() {
      match front {
        None => break ()
        Some(front) =>
          if front <= i - k {
            let _ = dq.pop_front()
            continue dq.front()
          } else {
            break ()
          }
      }
    }
    let _ = for back = dq.back() {
      match back {
        None => break ()
        Some(back) =>
          if arr[back] >= arr[i] {
            let _ = dq.pop_back()
            continue dq.back()
          } else {
            break ()
          }
      }
    }
    dq.push_back(i)
    if i >= k - 1 && dq.front() is Some(front) {
      result.push(arr[front])
    }
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT 1 (Bounds): i advances through [0, n], deque stores indices
      #|from the processed prefix [0, i).
      #|MAINTENANCE:
      #|Increment i by 1; deque operations keep indices within [0, i].
      #|TERMINATION:
      #|At i = n, all positions are processed.
    ),
    proof_invariant: dq.length() >= 0 && dq.length() <= i,
    proof_reasoning: (
      #|INVARIANT 2 (Deque size): deque contains at most i indices from [0, i).
      #|MAINTENANCE:
      #|Pop operations remove indices; push_back appends the new index i.
      #|TERMINATION:
      #|At loop end, deque indices refer only to processed elements.
    ),
    proof_invariant: match dq.front() {
      None => true
      Some(f) => f >= i - k && f <= i - 1
    },
    proof_reasoning: (
      #|INVARIANT 3 (Window membership): if deque is non-empty, its front index
      #|lies inside the current window for prefix [0, i): [i-k, i-1].
      #|MAINTENANCE:
      #|Pop_front removes indices < i-k before using the front.
      #|TERMINATION:
      #|At i = n, the front belongs to the last window.
    ),
    proof_invariant: result.length() == (if i >= k { i - k + 1 } else { 0 }),
    proof_reasoning: (
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
/// Compute the sum of every contiguous window of size `k` across `arr`.
///
/// Uses the O(1) sliding update rule:
/// ```
/// new_sum = old_sum - arr[i - k] + arr[i]
/// ```
/// so each step takes constant time regardless of window size.
///
/// Parameters:
/// - `arr` -- input array of `Int64` values.
/// - `k`   -- window size (must satisfy `1 <= k <= arr.length()`; returns
///            an empty array otherwise).
///
/// Returns an array of length `n - k + 1` where element `j` is the sum of
/// `arr[j..j+k]`.
///
/// Time: O(n). Space: O(1) auxiliary (output array excluded).
///
/// Example:
/// ```
/// sliding_window_sum([1, 2, 3, 4, 5], 3)
/// // => [6, 9, 12]
/// ```
pub fn sliding_window_sum(arr : Array[Int64], k : Int) -> Array[Int64] {
  let n = arr.length()
  if n == 0 || k <= 0 || k > n {
    return []
  }
  // Initialize first window sum using fold
  let initial_sum = arr[:k].fold(init=0L, (acc, x) => acc + x)
  let result : Array[Int64] = [initial_sum]

  // Slide window - use functional for loop to track running sum
  for i = k, sum = initial_sum; i < n; {
    let new_sum = sum + arr[i] - arr[i - k]
    result.push(new_sum)
    continue i + 1, new_sum
  } nobreak {
    result
  } where {
    proof_invariant: i >= k && i <= n,
    proof_reasoning: (
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
/// Find the length of the longest contiguous subarray whose sum is at most
/// `target`.
///
/// Uses the two-pointer (variable sliding window) technique.  The right
/// pointer expands the window by one element per iteration; when the running
/// sum exceeds `target`, the left pointer advances until the invariant is
/// restored.
///
/// Assumes all elements are **non-negative** so that advancing `left` can
/// only decrease the sum.  (With negative elements use prefix sums + binary
/// search instead.)
///
/// Parameters:
/// - `arr`    -- input array of non-negative `Int64` values.
/// - `target` -- upper bound on the window sum (inclusive).
///
/// Returns the length of the longest valid subarray, or 0 if none exists
/// (e.g. every element exceeds `target`).
///
/// Time: O(n). Space: O(1).
///
/// Example:
/// ```
/// longest_subarray_with_sum_le([1, 2, 3, 4, 5], 6)
/// // => 3  ([1, 2, 3])
/// ```
pub fn longest_subarray_with_sum_le(arr : Array[Int64], target : Int64) -> Int {
  let n = arr.length()
  if n == 0 {
    return 0
  }
  for right = 0, left = 0, sum = 0L, max_len = 0; right < n; {
    let (left, sum) = for left = left, sum = sum + arr[right]; sum > target &&
                         left <= right; {
      continue left + 1, sum - arr[left]
    } nobreak {
      (left, sum)
    }
    let new_max_len = if sum <= target {
      let len = right - left + 1
      if len > max_len {
        len
      } else {
        max_len
      }
    } else {
      max_len
    }
    continue right + 1, left, sum, new_max_len
  } nobreak {
    max_len
  } where {
    proof_invariant: right >= 0 && right <= n && left >= 0 && left <= right + 1,
    proof_reasoning: (
      #|INVARIANT 1 (Bounds): left/right stay within [0, n] with at most one-step
      #|gap when the window becomes empty.
      #|MAINTENANCE:
      #|right increments each step; left only moves forward during shrinking.
      #|TERMINATION:
      #|At right = n, all elements have been processed.
    ),
    proof_invariant: max_len >= 0 && max_len <= right,
    proof_reasoning: (
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
}

///|
/// Find the minimum length of a contiguous subarray whose sum is at least
/// `target`.
///
/// Uses the two-pointer (variable sliding window) technique.  The right
/// pointer expands the window; once the running sum meets `target`, the left
/// pointer advances as far as possible while the sum remains valid, recording
/// the shortest window seen at each step.
///
/// Assumes all elements are **non-negative** (positive elements are the
/// canonical use case).  With negative elements the shrinking invariant does
/// not hold.
///
/// Parameters:
/// - `arr`    -- input array of non-negative `Int64` values.
/// - `target` -- lower bound on the window sum (inclusive).
///
/// Returns the minimum window length, or 0 if no subarray meets the target
/// (i.e. the total array sum is less than `target`).
///
/// Time: O(n). Space: O(1).
///
/// Example:
/// ```
/// min_subarray_with_sum_ge([2, 3, 1, 2, 4, 3], 7)
/// // => 2  ([4, 3])
/// ```
pub fn min_subarray_with_sum_ge(arr : Array[Int64], target : Int64) -> Int {
  let n = arr.length()
  if n == 0 {
    return 0
  }
  let min_len = for right = 0, left = 0, sum = 0L, min_len = n + 1; right < n; {
    let (left, sum, min_len) = for left = left, sum = sum + arr[right], min_len = min_len; sum >=
                                  target &&
                                  left <= right; {
      let len = right - left + 1
      let min_len = if len < min_len { len } else { min_len }
      continue left + 1, sum - arr[left], min_len
    } nobreak {
      (left, sum, min_len)
    }
    continue right + 1, left, sum, min_len
  } nobreak {
    min_len
  } where {
    proof_invariant: right >= 0 && right <= n && left >= 0 && left <= right + 1,
    proof_reasoning: (
      #|INVARIANT 1 (Bounds): left/right stay within [0, n] with at most one-step
      #|gap when the window becomes empty.
      #|MAINTENANCE:
      #|right increments each step; left only moves forward during shrinking.
      #|TERMINATION:
      #|At right = n, all elements have been processed.
    ),
    proof_invariant: min_len >= 1 && min_len <= n + 1,
    proof_reasoning: (
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
  inspect(longest_subarray_with_sum_le(arr, -1L), content="0") // shrink past right
}

///|
test "min subarray sum ge" {
  let arr : Array[Int64] = [2L, 3L, 1L, 2L, 4L, 3L]
  inspect(min_subarray_with_sum_ge(arr, 7L), content="2") // [4,3]
  inspect(min_subarray_with_sum_ge(arr, 100L), content="0") // impossible
  inspect(min_subarray_with_sum_ge(arr, 0L), content="1") // any single element
}
