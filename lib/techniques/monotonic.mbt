// ============================================================================
// Monotonic Data Structure Examples
// Algorithms using monotonic stacks and deques for O(n) solutions
// ============================================================================

// ============================================================================
// Example M1: Next Greater Element
// For each element, find the next element to the right that is greater
// ============================================================================

///|
/// Find next greater element for each position.
/// Returns array where result[i] = index of next greater element, or -1 if none.
#warnings("+missing_invariant+missing_reasoning")
fn next_greater_element(arr : ArrayView[Int]) -> Array[Int] {
  let n = arr.length()
  guard n > 0 else { return [] }
  let result : Array[Int] = Array::make(n, -1)
  let stack : Array[Int] = [] // Indices of elements waiting for their NGE
  for i in 0..<n {
    // Pop elements smaller than current - current is their NGE
    for pop_next = stack.length() > 0 &&
          arr[stack[stack.length() - 1]] < arr[i]; pop_next; {
      match stack.pop() {
        Some(top) => result[top] = i
        None => break
      }
      continue stack.length() > 0 && arr[stack[stack.length() - 1]] < arr[i]
    }
    stack.push(i)
  }
  result
}

///|
test "next_greater_element" {
  let arr : Array[Int] = [4, 5, 2, 10, 8]
  let nge = next_greater_element(arr[:])
  assert_eq(nge[0], 1) // 4 -> 5 at index 1
  assert_eq(nge[1], 3) // 5 -> 10 at index 3
  assert_eq(nge[2], 3) // 2 -> 10 at index 3
  assert_eq(nge[3], -1) // 10 -> none
  assert_eq(nge[4], -1) // 8 -> none
}

// ============================================================================
// Example M2: Sliding Window Maximum
// Find maximum in each window of size k as window slides through array
// ============================================================================

///|
/// Find maximum in each sliding window of size k.
/// Returns array of (n-k+1) maximums.
#warnings("+missing_invariant+missing_reasoning")
fn sliding_window_maximum(arr : ArrayView[Int], k : Int) -> Array[Int] {
  let n = arr.length()
  guard n >= k && k > 0 else { return [] }
  let result : Array[Int] = []
  // Deque stores indices; values at these indices are monotonic decreasing
  let deque : @deque.Deque[Int] = @deque.new()
  for i in 0..<n {
    // Remove elements outside current window from front
    for pop_front = deque.front() is Some(front) && front <= i - k; pop_front; {
      let _ = deque.pop_front()
      continue deque.front() is Some(front) && front <= i - k
    }

    // Remove elements smaller than current from back (they can't be max)
    for pop_back = deque.back() is Some(back) && arr[back] < arr[i]; pop_back; {
      let _ = deque.pop_back()
      continue deque.back() is Some(back) && arr[back] < arr[i]
    }

    // Add current element
    deque.push_back(i)

    // Once we have a full window, record the maximum
    if i >= k - 1 && deque.front() is Some(front) {
      result.push(arr[front])
    }
  }
  result
}

///|
test "sliding_window_maximum" {
  let arr : Array[Int] = [1, 3, -1, -3, 5, 3, 6, 7]
  let result = sliding_window_maximum(arr[:], 3)
  // Windows: [1,3,-1]=3, [3,-1,-3]=3, [-1,-3,5]=5, [-3,5,3]=5, [5,3,6]=6, [3,6,7]=7
  assert_eq(result, [3, 3, 5, 5, 6, 7])
}

// ============================================================================
// Example M3: Largest Rectangle in Histogram
// Find area of largest rectangle that fits under histogram bars
// ============================================================================

///|
/// Find largest rectangle area in histogram.
/// Heights array represents bar heights; each bar has width 1.
#warnings("+missing_invariant+missing_reasoning")
fn largest_rectangle_histogram(heights : ArrayView[Int]) -> Int {
  let n = heights.length()
  guard n > 0 else { return 0 }

  // Stack stores indices of bars in increasing height order
  let stack : Array[Int] = []

  // Process all bars, plus one "sentinel" bar of height 0
  for i in 0..<=n; max_area = 0 {
    let curr_height = if i == n { 0 } else { heights[i] }

    // Pop bars taller than current - they can't extend further right
    let max_area = for max_area = max_area; stack.length() > 0 &&
                      heights[stack[stack.length() - 1]] > curr_height; {
      match stack.pop() {
        Some(h_idx) => {
          let height = heights[h_idx]

          // Width = distance from previous stack element to current position
          let width = if stack.length() == 0 {
            i
          } else {
            i - stack[stack.length() - 1] - 1
          }
          let area = height * width
          let max_area = if area > max_area { area } else { max_area }
          continue max_area
        }
        None => break max_area
      }
    } nobreak {
      max_area
    }
    stack.push(i)
    continue max_area
  } nobreak {
    max_area
  } where {
    invariant: max_area >= 0,
    reasoning: (
      #|INVARIANT 1 (Bounds and sentinel):
      #|i scans bars from left to right, and the extra step at i == n acts
      #|as a sentinel height 0 that flushes any remaining bars on the stack.
      #|MAINTENANCE:
      #|Each iteration processes bar i (or sentinel) and advances i by one.
      #|TERMINATION:
      #|At i = n + 1, all bars have been flushed and max_area is final.
    ),
    invariant: max_area >= 0,
    reasoning: (
      #|INVARIANT 2 (Stack property):
      #|Stack contains indices in increasing order, AND heights at those
      #|indices are in strictly increasing order.
      #|
      #|INVARIANT 3 (Correctness):
      #|When we pop index h_idx from stack:
      #|  - heights[h_idx] is the MINIMUM height in some range
      #|  - Left boundary: stack top (or 0 if empty) + 1
      #|  - Right boundary: i - 1
      #|
      #|KEY INSIGHT:
      #|For a rectangle of height h, we need to find how far it extends:
      #|  - Left: until we hit a bar shorter than h
      #|  - Right: until we hit a bar shorter than h
      #|
      #|When heights[h_idx] is popped because heights[i] < heights[h_idx]:
      #|  - Right boundary is i-1 (current bar is shorter)
      #|  - Left boundary is stack[top]+1 (previous bar in stack is shorter
      #|    or nothing, so all bars in between are >= heights[h_idx])
      #|
      #|WHY THIS GIVES CORRECT BOUNDARIES:
      #|  - Everything between stack[top] and h_idx was popped earlier
      #|  - Bars are popped when we see something shorter
      #|  - So all bars in (stack[top], h_idx) are >= heights[h_idx]
      #|  - Similarly for (h_idx, i)
      #|
      #|THE SENTINEL (height 0):
      #|Processing index n with height 0 forces all remaining bars to be
      #|popped, ensuring we compute areas for all bars.
      #|
      #|TIME: O(n) - each bar pushed and popped exactly once.
      #|SPACE: O(n) - stack can hold all bars if heights are increasing.
      #|
      #|EXTENSION: This technique applies to:
      #|  - Maximal rectangle in binary matrix
      #|  - Container with most water (variant)
      #|  - Trapping rain water (related problem)
      #|MAINTENANCE:
      #|Stack remains increasing in height after pops and the push of i.
      #|TERMINATION:
      #|When the sentinel is processed, all candidate rectangles are accounted for.
    ),
  }
}

///|
test "largest_rectangle_histogram" {
  let heights : Array[Int] = [2, 1, 5, 6, 2, 3]
  assert_eq(largest_rectangle_histogram(heights[:]), 10) // 5*2 = 10 (bars 5,6)
  let heights2 : Array[Int] = [2, 4]
  assert_eq(largest_rectangle_histogram(heights2[:]), 4) // 2*2 or 4*1
  let heights3 : Array[Int] = [6, 2, 5, 4, 5, 1, 6]
  assert_eq(largest_rectangle_histogram(heights3[:]), 12) // 4*3 = 12
}

// ============================================================================
// Example M4: Trapping Rain Water
// Calculate how much water can be trapped between bars after rain
// ============================================================================

///|
/// Calculate total water trapped between histogram bars.
#warnings("+missing_invariant+missing_reasoning")
fn trap_rain_water(heights : ArrayView[Int]) -> Int {
  let n = heights.length()
  guard n >= 3 else { return 0 }

  // Two-pointer approach: converge from both ends
  for lo = 0, hi = n - 1, left_max = 0, right_max = 0, water = 0 {
    if lo >= hi {
      break water
    } else if heights[lo] < heights[hi] {
      if heights[lo] >= left_max {
        continue lo + 1, hi, heights[lo], right_max, water
      } else {
        let trapped = left_max - heights[lo]
        continue lo + 1, hi, left_max, right_max, water + trapped
      }
    } else if heights[hi] >= right_max {
      continue lo, hi - 1, left_max, heights[hi], water
    } else {
      let trapped = right_max - heights[hi]
      continue lo, hi - 1, left_max, right_max, water + trapped
    }
  } where {
    invariant: 0 <= lo && lo <= hi + 1 && hi < n && water >= 0,
    reasoning: (
      #|INVARIANT 1 (Bounds and processed region):
      #|All positions outside [lo, hi] have been finalized and their trapped
      #|water accounted for in water. The pointers only move inward, so the
      #|unprocessed region shrinks until lo > hi.
      #|MAINTENANCE:
      #|Move the smaller side inward, finalizing exactly one position.
      #|TERMINATION:
      #|When lo > hi, every position is finalized and water is complete.
    ),
    invariant: left_max >= 0 && right_max >= 0,
    reasoning: (
      #|INVARIANT 2 (Maximum tracking):
      #|  left_max = max(heights[0..lo))
      #|  right_max = max(heights[hi+1..n))
      #|
      #|INVARIANT 3 (Water calculation):
      #|  water = Σ(water trapped at positions 0..lo and hi+1..n)
      #|
      #|KEY INSIGHT:
      #|Water at position i = min(max_left[i], max_right[i]) - heights[i]
      #|where:
      #|  max_left[i] = max(heights[0..i])
      #|  max_right[i] = max(heights[i+1..n))
      #|
      #|TWO-POINTER MAGIC:
      #|When heights[lo] < heights[hi]:
      #|  - We know max_right[lo] >= heights[hi] > heights[lo]
      #|  - So water at lo = min(left_max, max_right[lo]) - heights[lo]
      #|                   = min(left_max, something >= heights[hi]) - heights[lo]
      #|
      #|  If left_max <= heights[hi] (which it is since heights[lo] < heights[hi]
      #|  and left_max >= heights[lo]):
      #|    water at lo = left_max - heights[lo] (if left_max > heights[lo])
      #|                 or 0 (if left_max <= heights[lo])
      #|
      #|  We can compute water at lo without knowing exact max_right!
      #|
      #|SYMMETRY:
      #|Similar reasoning when heights[hi] <= heights[lo] - we can compute
      #|water at hi using right_max.
      #|
      #|PROOF OF CORRECTNESS:
      #|The "bottleneck" principle: water level at any point is determined
      #|by the smaller of the maximum heights on left and right.
      #|
      #|By always processing the side with smaller current height, we ensure
      #|that side's maximum is the constraining factor, so we can compute
      #|water correctly without the other side's exact maximum.
      #|
      #|TIME: O(n) - single pass with two pointers
      #|SPACE: O(1) - only a few variables
      #|MAINTENANCE:
      #|Update left_max/right_max and water as the pointers move inward.
      #|TERMINATION:
      #|At loop end, water equals the total trapped water.
    ),
  }
}

///|
test "trap_rain_water" {
  let heights : Array[Int] = [0, 1, 0, 2, 1, 0, 1, 3, 2, 1, 2, 1]
  assert_eq(trap_rain_water(heights[:]), 6)
  let heights2 : Array[Int] = [4, 2, 0, 3, 2, 5]
  assert_eq(trap_rain_water(heights2[:]), 9)
}

// ============================================================================
// Example M5: Sum of Subarray Minimums
// Sum of minimum values of all contiguous subarrays
// ============================================================================

///|
/// Compute sum of minimum values of all contiguous subarrays.
/// For array of length n, there are n(n+1)/2 subarrays.
#warnings("+missing_invariant+missing_reasoning")
fn sum_subarray_minimums(arr : ArrayView[Int]) -> Int {
  let n = arr.length()
  guard n > 0 else { return 0 }
  let modulus = 1000000007

  // For each element, find how many subarrays have it as minimum
  // left[i] = distance to previous smaller element (or to start)
  // right[i] = distance to next smaller or equal element (or to end)

  let left : Array[Int] = Array::make(n, 0)
  let right : Array[Int] = Array::make(n, 0)

  // Compute left distances using monotonic stack
  let stack : Array[Int] = []
  for i in 0..<n {
    for pop_next = stack.length() > 0 &&
          arr[stack[stack.length() - 1]] >= arr[i]; pop_next; {
      let _ = stack.pop()
      continue stack.length() > 0 && arr[stack[stack.length() - 1]] >= arr[i]
    }
    left[i] = if stack.length() == 0 {
      i + 1
    } else {
      i - stack[stack.length() - 1]
    }
    stack.push(i)
  }

  // Compute right distances using monotonic stack (process right to left)
  stack.clear()
  for i in n>..0 {
    for pop_next = stack.length() > 0 && arr[stack[stack.length() - 1]] > arr[i]; pop_next; {
      let _ = stack.pop()
      continue stack.length() > 0 && arr[stack[stack.length() - 1]] > arr[i]
    }
    right[i] = if stack.length() == 0 {
      n - i
    } else {
      stack[stack.length() - 1] - i
    }
    stack.push(i)
  }

  // Sum contributions
  for i in 0..<n; total = 0 {
    // Element arr[i] is minimum of left[i] * right[i] subarrays
    let contribution = arr[i] * left[i] % modulus * right[i] % modulus
    continue (total + contribution) % modulus
  } nobreak {
    total
  } where {
    invariant: total >= 0 && total < modulus,
    reasoning: (
      #|INVARIANT (Contribution counting):
      #|total = Σ(contribution of arr[0..i) as minimums)
      #|
      #|KEY INSIGHT:
      #|Instead of iterating over all O(n²) subarrays, we count:
      #|  "How many subarrays have arr[i] as their minimum?"
      #|
      #|For arr[i] to be minimum of subarray [l, r]:
      #|  - l must be in (prev_smaller[i], i] — left[i] choices
      #|  - r must be in [i, next_smaller_or_equal[i]) — right[i] choices
      #|
      #|Total subarrays with arr[i] as minimum = left[i] × right[i]
      #|
      #|WHY "SMALLER OR EQUAL" ON RIGHT?
      #|To avoid double counting. If arr[i] = arr[j] with i < j,
      #|we want exactly one of them to "own" subarrays containing both.
      #|By using strict < on left and <= on right, we ensure i owns
      #|subarrays where it's the leftmost minimum.
      #|
      #|CONTRIBUTION FORMULA:
      #|  arr[i] × left[i] × right[i]
      #|
      #|This counts arr[i] once for each subarray where it's minimum.
      #|
      #|TIME: O(n) - two monotonic stack passes + one summation pass
      #|SPACE: O(n) - left, right arrays and stack
      #|MAINTENANCE:
      #|Add contribution for arr[i] and advance i, keeping total modulo.
      #|TERMINATION:
      #|At i = n, total equals the sum over all subarrays.
    ),
  }
}

///|
test "sum_subarray_minimums" {
  let arr : Array[Int] = [3, 1, 2, 4]
  // Subarrays: [3]=3, [1]=1, [2]=2, [4]=4, [3,1]=1, [1,2]=1, [2,4]=2, [3,1,2]=1, [1,2,4]=1, [3,1,2,4]=1
  // Sum = 3+1+2+4+1+1+2+1+1+1 = 17
  assert_eq(sum_subarray_minimums(arr[:]), 17)
}

// ============================================================================
// Example M6: Online Stock Span
// For each day's price, find span (consecutive days with price <= today)
// ============================================================================

///|
/// Compute stock span for each day.
/// Span[i] = number of consecutive days ending at i where price <= prices[i].
#warnings("+missing_invariant+missing_reasoning")
fn stock_span(prices : ArrayView[Int]) -> Array[Int] {
  let n = prices.length()
  guard n > 0 else { return [] }
  let spans : Array[Int] = Array::make(n, 0)
  let stack : Array[Int] = [] // Indices of "dominant" prices
  for i in 0..<n {
    // Pop prices smaller than current
    for pop_next = stack.length() > 0 &&
          prices[stack[stack.length() - 1]] <= prices[i]; pop_next; {
      let _ = stack.pop()
      continue stack.length() > 0 &&
        prices[stack[stack.length() - 1]] <= prices[i]
    }

    // Span extends back to previous larger price (or to start)
    spans[i] = if stack.length() == 0 {
      i + 1
    } else {
      i - stack[stack.length() - 1]
    }
    stack.push(i)
  }
  spans
}

///|
test "stock_span" {
  let prices : Array[Int] = [100, 80, 60, 70, 60, 75, 85]
  let spans = stock_span(prices[:])
  assert_eq(spans, [1, 1, 1, 2, 1, 4, 6])
  // Day 0 (100): span 1 (just today)
  // Day 1 (80): span 1
  // Day 2 (60): span 1
  // Day 3 (70): span 2 (70, 60)
  // Day 4 (60): span 1
  // Day 5 (75): span 4 (75, 60, 70, 60)
  // Day 6 (85): span 6 (85, 75, 60, 70, 60, 80)
}
