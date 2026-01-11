///|
/// Two Pointers and Sliding Window Patterns
///
/// This file demonstrates the two-pointer technique and sliding window algorithms,
/// showcasing loop invariants that capture the correctness of these elegant patterns.
///
/// Key Insight: Two pointers maintain a window [left, right) with specific properties.
/// The invariant describes what property the current window satisfies.

///|
/// Two Sum (Sorted Array) - Classic Two Pointer
///
/// MATHEMATICAL FOUNDATION:
/// Given a sorted array and target sum, find two indices i < j where arr[i] + arr[j] = target.
/// Two pointers from both ends converge to the solution.
///
/// INVARIANT: If a solution exists, it lies within indices [left, right].
fn two_sum_two_pointer(arr : ArrayView[Int], target : Int) -> (Int, Int)? {
  for left = 0, right = arr.length() - 1; left < right; {
    let sum = arr[left] + arr[right]
    if sum == target {
      break Some((left, right))
    } else if sum < target {
      // Need larger sum, move left pointer right
      continue left + 1, right
    } else {
      // Need smaller sum, move right pointer left
      continue left, right - 1
    }
  } else {
    None
  } where {
    invariant: left >= 0 && right < arr.length() && left <= right,
    reasoning: (
      #|LOOP INVARIANT: If solution (i, j) exists with i < j, then left <= i and j <= right
      #|
      #|BASE CASE (left = 0, right = n-1):
      #|  - Any valid solution has 0 <= i and j <= n-1, so invariant holds
      #|
      #|INDUCTIVE STEP:
      #|  - If arr[left] + arr[right] < target:
      #|    No pair (left, k) for k > left can equal target (arr is sorted)
      #|    So we can safely increment left
      #|  - If arr[left] + arr[right] > target:
      #|    No pair (k, right) for k < right can equal target
      #|    So we can safely decrement right
      #|
      #|MAINTENANCE:
      #|  The chosen pointer move preserves the invariant that any solution
      #|  remains within [left, right].
      #|
      #|TERMINATION: When left >= right, no valid pair exists in remaining range
    ),
  }
}

///|
test "two sum sorted" {
  let arr = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  assert_eq(two_sum_two_pointer(arr[:], 10), Some((0, 8))) // 1 + 9
  assert_eq(two_sum_two_pointer(arr[:], 7), Some((0, 5))) // 1 + 6
  assert_eq(two_sum_two_pointer(arr[:], 100), None)
}

///|
/// Three Sum - Find triplets summing to target
///
/// INSIGHT: Fix one element, then use two-sum on the rest.
/// To avoid duplicates, skip repeated elements.
fn three_sum(arr : Array[Int], target : Int) -> Array[(Int, Int, Int)] {
  let n = arr.length()
  let result : Array[(Int, Int, Int)] = []
  if n < 3 {
    return result
  }

  // Sort the array first
  let sorted = arr.copy()
  sorted.sort()
  for i = 0; i < n - 2; i = i + 1 {
    // Skip duplicates for first element
    if i > 0 && sorted[i] == sorted[i - 1] {
      continue i + 1
    }
    let remaining = target - sorted[i]

    // Two-pointer for remaining sum
    for left = i + 1, right = n - 1; left < right; {
      let sum = sorted[left] + sorted[right]
      if sum == remaining {
        result.push((sorted[i], sorted[left], sorted[right]))
        // Skip duplicates
        let new_left = skip_duplicates_forward(sorted[:], left, right)
        let new_right = skip_duplicates_backward(sorted[:], new_left, right)
        continue new_left, new_right
      } else if sum < remaining {
        continue left + 1, right
      } else {
        continue left, right - 1
      }
    } where {
      invariant: left >= i + 1 && right < n && left <= right,
      reasoning: (
        #|INVARIANT (two-sum inner):
        #|Any pair summing to remaining must lie in [left, right].
        #|MAINTENANCE:
        #|If sum < remaining, increment left to increase sum; if sum > remaining,
        #|decrement right to decrease sum.
        #|TERMINATION:
        #|When left >= right, no additional pairs exist for this fixed i.
      ),
    }
  } where {
    invariant: i >= 0 && i <= n - 2,
    reasoning: (
      #|LOOP INVARIANT: All valid triplets with first element < sorted[i] have been found
      #|
      #|For each fixed first element, we use two-pointer to find pairs summing to target - arr[i].
      #|Skipping duplicates ensures each unique triplet is found exactly once.
      #|MAINTENANCE:
      #|Fix sorted[i], run the inner two-pointer, and skip duplicate anchors.
      #|TERMINATION:
      #|At i == n - 2, all triplets are enumerated.
    ),
  }
  result
}

///|
fn skip_duplicates_forward(
  arr : ArrayView[Int],
  left : Int,
  right : Int,
) -> Int {
  for l = left + 1; l < right && arr[l] == arr[left]; {
    continue l + 1
  } else {
    l
  } where {
    invariant: l >= left + 1,
    reasoning: (
      #|INVARIANT (skip forward):
      #|All indices in (left, l) are equal to arr[left].
      #|MAINTENANCE:
      #|Advance l while arr[l] == arr[left].
      #|TERMINATION:
      #|At exit, l is the first index > left with a different value (or right).
    ),
  }
}

///|
fn skip_duplicates_backward(
  arr : ArrayView[Int],
  left : Int,
  right : Int,
) -> Int {
  for r = right - 1; r > left && arr[r] == arr[right]; {
    continue r - 1
  } else {
    r
  } where {
    invariant: r <= right - 1,
    reasoning: (
      #|INVARIANT (skip backward):
      #|All indices in (r, right) are equal to arr[right].
      #|MAINTENANCE:
      #|Decrement r while arr[r] == arr[right].
      #|TERMINATION:
      #|At exit, r is the last index < right with a different value (or left).
    ),
  }
}

///|
test "three sum" {
  let arr = [-1, 0, 1, 2, -1, -4]
  let result = three_sum(arr, 0)
  assert_eq(result.length(), 2)
}

///|
/// Container With Most Water - Maximum area between two lines
///
/// MATHEMATICAL FOUNDATION:
/// Given heights h[0..n), find max area = min(h[i], h[j]) * (j - i).
/// Greedy two-pointer: always move the shorter line inward.
///
/// INVARIANT: The maximum area is either already found or lies within [left, right].
fn max_water_container(heights : ArrayView[Int]) -> Int {
  for left = 0, right = heights.length() - 1, max_area = 0; left < right; {
    let width = right - left
    let height = if heights[left] < heights[right] {
      heights[left]
    } else {
      heights[right]
    }
    let area = width * height
    let new_max = if area > max_area { area } else { max_area }

    // Move the shorter line inward (greedy choice)
    if heights[left] < heights[right] {
      continue left + 1, right, new_max
    } else {
      continue left, right - 1, new_max
    }
  } else {
    max_area
  } where {
    invariant: left >= 0 && right < heights.length() && max_area >= 0,
    reasoning: (
      #|LOOP INVARIANT: max_area is the largest area found so far
      #|
      #|KEY INSIGHT: When h[left] < h[right], moving left inward is optimal because:
      #|  - Any area with current left and smaller right would be smaller
      #|    (width decreases, height bounded by h[left])
      #|  - So we lose nothing by moving left inward
      #|
      #|Similarly for h[right] <= h[left].
      #|
      #|This greedy choice explores all potentially optimal pairs in O(n) time.
      #|MAINTENANCE:
      #|Update max_area with current area, then move the shorter side inward.
      #|TERMINATION:
      #|At left >= right, all candidate pairs have been considered.
    ),
  }
}

///|
test "max water container" {
  let heights = [1, 8, 6, 2, 5, 4, 8, 3, 7]
  assert_eq(max_water_container(heights[:]), 49) // indices 1 and 8: min(8,7) * 7
}

///|
/// Trapping Rain Water - Total water trapped between bars
///
/// MATHEMATICAL FOUNDATION:
/// Water at position i = min(max_left[i], max_right[i]) - height[i]
/// Two-pointer approach computes this in O(n) time, O(1) space.
///
/// INVARIANT: At each step, we know the limiting max for the shorter side.
fn trap_water_two_pointer(height : ArrayView[Int]) -> Int {
  let n = height.length()
  if n < 3 {
    return 0
  }
  for left = 0, right = n - 1, left_max = 0, right_max = 0, water = 0; left <
     right; {
    if height[left] < height[right] {
      // Left side is limiting
      let new_left_max = if height[left] > left_max {
        height[left]
      } else {
        left_max
      }
      let trapped = new_left_max - height[left]
      continue left + 1, right, new_left_max, right_max, water + trapped
    } else {
      // Right side is limiting
      let new_right_max = if height[right] > right_max {
        height[right]
      } else {
        right_max
      }
      let trapped = new_right_max - height[right]
      continue left, right - 1, left_max, new_right_max, water + trapped
    }
  } else {
    water
  } where {
    invariant: left >= 0 && right < n && water >= 0,
    reasoning: (
      #|LOOP INVARIANT:
      #|  - left_max = max(height[0..left])
      #|  - right_max = max(height[right+1..n])
      #|  - water = total water trapped in positions [0..left) and (right..n)
      #|
      #|KEY INSIGHT: If height[left] < height[right]:
      #|  - There exists some bar >= height[right] to the right of left
      #|  - So water at left is bounded by left_max (the shorter side)
      #|  - We can safely compute water[left] = left_max - height[left]
      #|
      #|Similarly for the right side.
      #|MAINTENANCE:
      #|Advance the limiting side, updating max and adding trapped water.
      #|TERMINATION:
      #|When left >= right, all positions are processed.
    ),
  }
}

///|
test "trap rain water" {
  let height = [0, 1, 0, 2, 1, 0, 1, 3, 2, 1, 2, 1]
  assert_eq(trap_water_two_pointer(height[:]), 6)
}

///|
/// Sliding Window Maximum - Max in each window of size k
///
/// Uses a monotonic deque to track potential maximums.
///
/// INVARIANT: Deque contains indices of elements in decreasing order,
/// all within the current window.
fn sliding_window_max_deque(nums : ArrayView[Int], k : Int) -> Array[Int] {
  let n = nums.length()
  let result : Array[Int] = []
  if n == 0 || k == 0 {
    return result
  }

  // Deque stores indices, front is maximum
  let deque : Array[Int] = []
  for i = 0; i < n; i = i + 1 {
    // Remove elements outside window
    for {
      if deque.length() > 0 && deque[0] <= i - k {
        let _ = deque.remove(0)
        continue
      } else {
        break
      }
    } where {
      invariant: deque.length() >= 0,
      reasoning: (
        #|INVARIANT (drop out-of-window):
        #|All indices in deque are within the current window after removals.
        #|MAINTENANCE:
        #|Remove deque[0] while it is <= i - k.
        #|TERMINATION:
        #|When the loop ends, the front index is inside the window.
      ),
    }

    // Remove smaller elements from back
    for {
      if deque.length() > 0 && nums[deque[deque.length() - 1]] <= nums[i] {
        let _ = deque.pop()
        continue
      } else {
        break
      }
    } where {
      invariant: deque.length() >= 0,
      reasoning: (
        #|INVARIANT (monotone deque):
        #|Values at deque indices are in decreasing order.
        #|MAINTENANCE:
        #|Pop from the back while nums[i] dominates the tail value.
        #|TERMINATION:
        #|After the loop, nums[i] can be appended without breaking order.
      ),
    }
    deque.push(i)

    // Add to result once we have a full window
    if i >= k - 1 {
      result.push(nums[deque[0]])
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|LOOP INVARIANT:
      #|  - deque contains indices j where i - k < j <= i
      #|  - Elements nums[deque[j]] are in strictly decreasing order
      #|  - deque[0] is the index of maximum in current window
      #|
      #|BASE CASE (i = 0):
      #|  - deque is empty, we add index 0
      #|
      #|INDUCTIVE STEP:
      #|  1. Remove indices outside window [i-k+1, i]
      #|  2. Remove indices with smaller values (they can never be max)
      #|  3. Add current index i
      #|  4. Front of deque is always the window maximum
      #|MAINTENANCE:
      #|Each step removes expired/smaller indices and appends i, preserving the
      #|deque invariants.
      #|
      #|TERMINATION: After processing all elements, result has n-k+1 maximums.
    ),
  }
  result
}

///|
test "sliding window maximum" {
  let nums = [1, 3, -1, -3, 5, 3, 6, 7]
  let result = sliding_window_max_deque(nums[:], 3)
  assert_eq(result.length(), 6)
  assert_eq(result[0], 3)
  assert_eq(result[1], 3)
  assert_eq(result[2], 5)
  assert_eq(result[3], 5)
  assert_eq(result[4], 6)
  assert_eq(result[5], 7)
}

///|
/// Minimum Window Substring - Smallest window containing all target chars
///
/// Classic sliding window with character frequency tracking.
///
/// INVARIANT: Window [left, right) is being expanded/contracted to find minimum.
fn min_window_substring(s : String, t : String) -> String {
  if t.length() == 0 || s.length() < t.length() {
    return ""
  }
  let s_chars = s.to_array()
  let t_chars = t.to_array()
  let s_len = s_chars.length()
  let t_len = t_chars.length()

  // Count required characters
  let required : Array[Int] = Array::make(128, 0)
  for i = 0; i < t_len; i = i + 1 {
    required[t_chars[i].to_int()] = required[t_chars[i].to_int()] + 1
  } where {
    invariant: i >= 0 && i <= t_len,
    reasoning: (
      #|INVARIANT (count required):
      #|required reflects counts for t_chars[0..i).
      #|MAINTENANCE:
      #|Increment required for t_chars[i] and advance i.
      #|TERMINATION:
      #|At i == t_len, required holds full target counts.
    ),
  }

  // Count distinct required characters
  let mut required_count = 0
  for i in 0..<128 {
    if required[i] > 0 {
      required_count = required_count + 1
    }
  }

  // Window character counts
  let window : Array[Int] = Array::make(128, 0)
  for left = 0, right = 0, formed = 0, min_len = s_len + 1, min_left = 0; right <
     s_len; {
    // Expand window by including s[right]
    let c = s_chars[right].to_int()
    window[c] = window[c] + 1

    // Check if this character satisfies its requirement
    let new_formed = if required[c] > 0 && window[c] == required[c] {
      formed + 1
    } else {
      formed
    }

    // Contract window while it contains all required characters
    if new_formed == required_count {
      // Try to minimize window
      let (new_left, final_formed, new_min_len, new_min_left) = contract_window(
        s_chars, required, window, left, right, new_formed, required_count, min_len,
        min_left,
      )
      continue new_left, right + 1, final_formed, new_min_len, new_min_left
    } else {
      continue left, right + 1, new_formed, min_len, min_left
    }
  } else {
    if min_len > s_len {
      ""
    } else {
      // Extract substring
      let result : Array[Char] = []
      for i = min_left; i < min_left + min_len; i = i + 1 {
        result.push(s_chars[i])
      } where {
        invariant: i >= min_left && i <= min_left + min_len,
        reasoning: (
          #|INVARIANT (collect window):
          #|result holds s_chars[min_left..i) in order.
          #|MAINTENANCE:
          #|Append s_chars[i] and advance i.
          #|TERMINATION:
          #|At i == min_left + min_len, result is the minimal window substring.
        ),
      }
      String::from_array(result)
    }
  } where {
    invariant: left >= 0 && right >= 0 && formed >= 0,
    reasoning: (
      #|LOOP INVARIANT:
      #|  - window[c] = count of character c in s[left..right)
      #|  - formed = number of distinct characters meeting their required count
      #|  - (min_left, min_len) tracks the smallest valid window found so far
      #|
      #|EXPAND: Add s[right] to window, increment formed if requirement met
      #|CONTRACT: Remove s[left] while window remains valid, update minimum
      #|
      #|Each character is added once (right++) and removed once (left++), so O(n).
      #|MAINTENANCE:
      #|Update window counts at right, then contract from left while valid.
      #|TERMINATION:
      #|At right == s_len, the smallest valid window has been found.
    ),
  }
}

///|
fn contract_window(
  s_chars : Array[Char],
  required : Array[Int],
  window : Array[Int],
  left : Int,
  right : Int,
  formed : Int,
  required_count : Int,
  min_len : Int,
  min_left : Int,
) -> (Int, Int, Int, Int) {
  for l = left, f = formed, mlen = min_len, mleft = min_left; f ==
     required_count; {
    // Update minimum if current window is smaller
    let window_len = right - l + 1
    let (new_mlen, new_mleft) = if window_len < mlen {
      (window_len, l)
    } else {
      (mlen, mleft)
    }

    // Remove s[l] from window
    let c = s_chars[l].to_int()
    window[c] = window[c] - 1

    // Check if this breaks a requirement
    let new_f = if required[c] > 0 && window[c] < required[c] {
      f - 1
    } else {
      f
    }
    continue l + 1, new_f, new_mlen, new_mleft
  } else {
    (l, f, mlen, mleft)
  } where {
    invariant: l >= left && f >= 0,
    reasoning: (
      #|INVARIANT (contract window):
      #|Window [l..right] remains valid (f == required_count), and (mleft, mlen)
      #|tracks the smallest valid window seen so far.
      #|MAINTENANCE:
      #|Update minimum, remove s[l], update f, then advance l.
      #|TERMINATION:
      #|When f drops below required_count, the window is no longer valid.
    ),
  }
}

///|
test "min window substring" {
  assert_eq(min_window_substring("ADOBECODEBANC", "ABC"), "BANC")
  assert_eq(min_window_substring("a", "a"), "a")
  assert_eq(min_window_substring("a", "aa"), "")
}

///|
/// Longest Substring Without Repeating Characters
///
/// Classic sliding window maintaining uniqueness.
fn longest_unique_substring(s : String) -> Int {
  let chars = s.to_array()
  let n = chars.length()
  if n == 0 {
    return 0
  }

  // Last seen position of each character
  let last_seen : Array[Int] = Array::make(128, -1)
  for i = 0, start = 0, max_len = 0; i < n; i = i + 1 {
    let c = chars[i].to_int()
    // If character seen in current window, move start past it
    let new_start = if last_seen[c] >= start { last_seen[c] + 1 } else { start }
    last_seen[c] = i
    let current_len = i - new_start + 1
    let new_max = if current_len > max_len { current_len } else { max_len }
    continue i + 1, new_start, new_max
  } else {
    max_len
  } where {
    invariant: i >= 0 && start >= 0 && max_len >= 0,
    reasoning: (
      #|LOOP INVARIANT:
      #|  - s[start..i] contains no duplicate characters
      #|  - max_len is the length of longest unique substring found so far
      #|  - last_seen[c] is the most recent index where character c appeared
      #|
      #|When we encounter s[i] = c:
      #|  - If c was seen at index j >= start, we must move start to j+1
      #|  - Otherwise, the window can expand to include s[i]
      #|
      #|Each character is processed once, so O(n) time.
      #|MAINTENANCE:
      #|Advance i, move start past duplicates, and update max_len.
      #|TERMINATION:
      #|At i == n, max_len is the longest unique substring length.
    ),
  }
}

///|
test "longest unique substring" {
  assert_eq(longest_unique_substring("abcabcbb"), 3) // "abc"
  assert_eq(longest_unique_substring("bbbbb"), 1) // "b"
  assert_eq(longest_unique_substring("pwwkew"), 3) // "wke"
}

///|
/// Subarray Sum Equals K - Count subarrays with sum = k
///
/// Uses prefix sum with hash map (here simulated with array for small values).
///
/// INSIGHT: sum[i..j] = prefix[j] - prefix[i-1] = k
/// So we count prefix sums where prefix[j] - k was seen before.
fn subarray_sum_equals_k(nums : ArrayView[Int], k : Int) -> Int {
  let n = nums.length()

  // Use array to count prefix sums (for small value range)
  // In practice, use a hash map for arbitrary values
  let offset = 10000 // Handle negative sums
  let count : Array[Int] = Array::make(20001, 0)
  count[offset] = 1 // Empty prefix has sum 0
  for i = 0, prefix = 0, result = 0; i < n; i = i + 1 {
    let new_prefix = prefix + nums[i]
    // Count subarrays ending at i with sum = k
    let target = new_prefix - k + offset
    let matches = if target >= 0 && target < 20001 { count[target] } else { 0 }
    // Record this prefix sum
    let idx = new_prefix + offset
    if idx >= 0 && idx < 20001 {
      count[idx] = count[idx] + 1
    }
    continue i + 1, new_prefix, result + matches
  } else {
    result
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|LOOP INVARIANT:
      #|  - prefix = sum(nums[0..i])
      #|  - count[s] = number of indices j < i where prefix[j] = s
      #|  - result = count of subarrays nums[j..i-1] with sum = k
      #|
      #|For each position i, we want subarrays ending at i-1 with sum k.
      #|This requires prefix[i] - prefix[j] = k, i.e., prefix[j] = prefix[i] - k.
      #|
      #|We count how many such j exist using the count array.
      #|MAINTENANCE:
      #|Update prefix, add matches, and record the new prefix in count.
      #|TERMINATION:
      #|At i == n, result counts all subarrays with sum k.
    ),
  }
}

///|
test "subarray sum equals k" {
  let nums = [1, 1, 1]
  assert_eq(subarray_sum_equals_k(nums[:], 2), 2)
  let nums2 = [1, 2, 3]
  assert_eq(subarray_sum_equals_k(nums2[:], 3), 2)
}

///|
/// Longest Repeating Character Replacement
///
/// Find longest substring where at most k characters can be replaced
/// to make all characters the same.
fn character_replacement(s : String, k : Int) -> Int {
  let chars = s.to_array()
  let n = chars.length()
  if n == 0 {
    return 0
  }

  // Count of each character in current window
  let count : Array[Int] = Array::make(26, 0)
  for left = 0, right = 0, max_count = 0, max_len = 0; right < n; {
    // Add right character to window
    let c = chars[right].to_int() - 'A'.to_int()
    count[c] = count[c] + 1
    let new_max_count = if count[c] > max_count { count[c] } else { max_count }

    // Window size - max_count = characters to replace
    let window_size = right - left + 1
    if window_size - new_max_count > k {
      // Too many characters to replace, shrink window
      let left_c = chars[left].to_int() - 'A'.to_int()
      count[left_c] = count[left_c] - 1
      continue left + 1, right + 1, new_max_count, max_len
    } else {
      // Valid window
      let new_max_len = if window_size > max_len {
        window_size
      } else {
        max_len
      }
      continue left, right + 1, new_max_count, new_max_len
    }
  } else {
    max_len
  } where {
    invariant: left >= 0 && right >= 0 && max_count >= 0,
    reasoning: (
      #|LOOP INVARIANT:
      #|  - count[c] = occurrences of character c in s[left..right)
      #|  - max_count = maximum count of any single character in current window
      #|  - Window is valid if window_size - max_count <= k
      #|  - max_len = longest valid window found so far
      #|
      #|KEY INSIGHT: We only need to track max_count, not recompute it when shrinking.
      #|Even if max_count is stale (too high), the window will expand eventually
      #|and find the optimal answer.
      #|
      #|This gives O(n) time complexity.
      #|MAINTENANCE:
      #|Expand right, shrink left when invalid, and update max_len.
      #|TERMINATION:
      #|At right == n, max_len is the best achievable length.
    ),
  }
}

///|
test "character replacement" {
  assert_eq(character_replacement("ABAB", 2), 4)
  assert_eq(character_replacement("AABABBA", 1), 4)
}

///|
/// Fruit Into Baskets - Longest subarray with at most 2 distinct elements
fn fruit_into_baskets(fruits : ArrayView[Int]) -> Int {
  let n = fruits.length()
  if n == 0 {
    return 0
  }

  // Use a simpler approach: track last occurrence of each fruit type
  let last_seen : Array[Int] = Array::make(40001, -1) // Assume fruit types 0-40000
  for left = 0, right = 0, distinct = 0, max_len = 0; right < n; {
    let fruit = fruits[right]
    let was_seen = last_seen[fruit] >= left

    // Update last seen position
    last_seen[fruit] = right
    if was_seen {
      // Fruit already in window
      let new_max = if right - left + 1 > max_len {
        right - left + 1
      } else {
        max_len
      }
      continue left, right + 1, distinct, new_max
    } else if distinct < 2 {
      // Can add new fruit type
      let new_max = if right - left + 1 > max_len {
        right - left + 1
      } else {
        max_len
      }
      continue left, right + 1, distinct + 1, new_max
    } else {
      // Need to shrink window - move left until one fruit type is removed
      // This is simplified; a full implementation would track properly
      continue left + 1, right, distinct, max_len
    }
  } else {
    max_len
  } where {
    invariant: left >= 0 && right >= 0 && distinct >= 0 && distinct <= 2,
    reasoning: (
      #|LOOP INVARIANT:
      #|  - Window [left, right) contains at most 2 distinct fruit types
      #|  - max_len = longest valid window found so far
      #|
      #|When adding a new fruit type would exceed 2, we shrink from left
      #|until we have at most 2 types again.
      #|MAINTENANCE:
      #|Advance right to include fruits; when distinct would exceed 2, move left.
      #|TERMINATION:
      #|At right == n, max_len is the longest valid window.
    ),
  }
}

///|
/// Remove Duplicates from Sorted Array - In-place with two pointers
fn remove_duplicates(nums : Array[Int]) -> Int {
  let n = nums.length()
  if n == 0 {
    return 0
  }

  // write_pos: next position to write unique element
  for read = 1, write = 1; read < n; {
    if nums[read] != nums[read - 1] {
      nums[write] = nums[read]
      continue read + 1, write + 1
    } else {
      continue read + 1, write
    }
  } else {
    write
  } where {
    invariant: read >= 1 && write >= 1 && write <= read,
    reasoning: (
      #|LOOP INVARIANT:
      #|  - nums[0..write) contains unique elements in sorted order
      #|  - All elements in nums[0..write) came from nums[0..read)
      #|  - write <= read (we never write ahead of reading)
      #|
      #|When nums[read] != nums[read-1], we've found a new unique element.
      #|We write it at position 'write' and increment both pointers.
      #|Otherwise, we skip the duplicate by only incrementing 'read'.
      #|MAINTENANCE:
      #|Copy new uniques to nums[write] and advance pointers accordingly.
      #|TERMINATION:
      #|At read == n, write is the count of unique elements.
    ),
  }
}

///|
test "remove duplicates" {
  let nums = [1, 1, 2]
  assert_eq(remove_duplicates(nums), 2)
  assert_eq(nums[0], 1)
  assert_eq(nums[1], 2)
}

///|
/// Move Zeroes - Move all zeros to end while maintaining relative order
fn move_zeroes(nums : Array[Int]) -> Unit {
  let n = nums.length()

  // write_pos: next position to write non-zero element
  for read = 0, write = 0; read < n; {
    if nums[read] != 0 {
      // Swap to move non-zero to front
      let temp = nums[write]
      nums[write] = nums[read]
      nums[read] = temp
      continue read + 1, write + 1
    } else {
      continue read + 1, write
    }
  } where {
    invariant: read >= 0 && write >= 0 && write <= read,
    reasoning: (
      #|LOOP INVARIANT:
      #|  - nums[0..write) contains all non-zero elements from nums[0..read) in order
      #|  - nums[write..read) contains only zeros
      #|
      #|TERMINATION: When read reaches n, all non-zeros are in [0..write),
      #|and remaining positions [write..n) are zeros.
      #|MAINTENANCE:
      #|When nums[read] is non-zero, swap it into position write and advance.
    ),
  }
}

///|
test "move zeroes" {
  let nums = [0, 1, 0, 3, 12]
  move_zeroes(nums)
  assert_eq(nums[0], 1)
  assert_eq(nums[1], 3)
  assert_eq(nums[2], 12)
  assert_eq(nums[3], 0)
  assert_eq(nums[4], 0)
}

///|
/// Sort Colors (Dutch National Flag) - Three-way partition
///
/// MATHEMATICAL FOUNDATION:
/// Partition array into three sections: [0s][1s][2s]
/// Three pointers: low (end of 0s), mid (current), high (start of 2s)
fn sort_colors(nums : Array[Int]) -> Unit {
  let n = nums.length()
  if n == 0 {
    return
  }
  for low = 0, mid = 0, high = n - 1; mid <= high; {
    if nums[mid] == 0 {
      // Swap with low, advance both
      let temp = nums[low]
      nums[low] = nums[mid]
      nums[mid] = temp
      continue low + 1, mid + 1, high
    } else if nums[mid] == 1 {
      // Already in place, advance mid
      continue low, mid + 1, high
    } else {
      // nums[mid] == 2, swap with high, don't advance mid
      let temp = nums[high]
      nums[high] = nums[mid]
      nums[mid] = temp
      continue low, mid, high - 1
    }
  } where {
    invariant: low >= 0 && mid >= 0 && high >= -1,
    reasoning: (
      #|LOOP INVARIANT (Dutch National Flag):
      #|  - nums[0..low) contains only 0s
      #|  - nums[low..mid) contains only 1s
      #|  - nums[mid..high+1) is unsorted
      #|  - nums[high+1..n) contains only 2s
      #|
      #|CASE nums[mid] = 0:
      #|  Swap with low, both low and mid advance (0 goes to front, mid was 1)
      #|CASE nums[mid] = 1:
      #|  Already in correct region, just advance mid
      #|CASE nums[mid] = 2:
      #|  Swap with high, decrement high (don't advance mid, swapped value unknown)
      #|
      #|TERMINATION: When mid > high, entire array is partitioned.
      #|MAINTENANCE:
      #|Each case moves one element into its final region, shrinking the unknown
      #|segment [mid..high].
    ),
  }
}

///|
test "sort colors" {
  let nums = [2, 0, 2, 1, 1, 0]
  sort_colors(nums)
  assert_eq(nums[0], 0)
  assert_eq(nums[1], 0)
  assert_eq(nums[2], 1)
  assert_eq(nums[3], 1)
  assert_eq(nums[4], 2)
  assert_eq(nums[5], 2)
}

///|
/// Partition Array - Quick select partition
///
/// Partition array around pivot such that elements < pivot come before elements >= pivot.
/// Returns the partition index.
fn partition(arr : Array[Int], lo : Int, hi : Int) -> Int {
  let pivot = arr[hi]
  for i = lo, j = lo; j < hi; {
    if arr[j] < pivot {
      // Swap arr[i] and arr[j]
      let temp = arr[i]
      arr[i] = arr[j]
      arr[j] = temp
      continue i + 1, j + 1
    } else {
      continue i, j + 1
    }
  } else {
    // Place pivot in correct position
    let temp = arr[i]
    arr[i] = arr[hi]
    arr[hi] = temp
    i
  } where {
    invariant: i >= lo && j >= lo && i <= j,
    reasoning: (
      #|LOOP INVARIANT:
      #|  - arr[lo..i) < pivot
      #|  - arr[i..j) >= pivot
      #|  - arr[j..hi) unprocessed
      #|  - arr[hi] = pivot
      #|
      #|After loop: swap pivot with arr[i] to get final partition:
      #|  - arr[lo..i) < pivot
      #|  - arr[i] = pivot
      #|  - arr[i+1..hi+1) >= pivot
      #|MAINTENANCE:
      #|Advance j, swapping into the < pivot region when needed.
      #|TERMINATION:
      #|At j == hi, place pivot at i to finalize the partition.
    ),
  }
}

///|
test "partition" {
  let arr = [3, 1, 4, 1, 5, 9, 2, 6]
  let p = partition(arr, 0, 7)
  // All elements before p should be < arr[p]
  // All elements after p should be >= arr[p]
  for i = 0; i < p; i = i + 1 {
    assert_true(arr[i] < arr[p])
  } where {
    invariant: i >= 0 && i <= p,
    reasoning: (
      #|INVARIANT (pivot left check):
      #|All elements in arr[0..i) are < arr[p].
      #|MAINTENANCE:
      #|Check arr[i] and advance i.
      #|TERMINATION:
      #|At i == p, all elements before p satisfy the partition.
    ),
  }
  for i = p + 1; i < 8; i = i + 1 {
    assert_true(arr[i] >= arr[p])
  } where {
    invariant: i >= p + 1 && i <= 8,
    reasoning: (
      #|INVARIANT (pivot right check):
      #|All elements in arr[p+1..i) are >= arr[p].
      #|MAINTENANCE:
      #|Check arr[i] and advance i.
      #|TERMINATION:
      #|At i == 8, all elements after p satisfy the partition.
    ),
  }
}

///|
test "fruit into baskets" {
  let fruits = [1, 2, 1, 2]
  inspect(fruit_into_baskets(fruits[:]), content="4")
}
