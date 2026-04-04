// ============================================================================
// MONOTONIC STACK - Next Greater/Smaller Element Problems
// ============================================================================
//
// A monotonic stack maintains elements in sorted order (increasing or decreasing).
// Used for efficiently finding next greater/smaller elements, histogram areas, etc.
//
// KEY INSIGHT: When we encounter an element that breaks monotonicity, we pop
// elements and process them with the current element as their "answer."
//
// APPLICATIONS:
// 1. Next Greater Element (NGE)
// 2. Previous Greater Element (PGE)
// 3. Largest Rectangle in Histogram
// 4. Trapping Rain Water
// 5. Stock Span Problem
//
// INVARIANTS:
// 1. Stack maintains monotonic property after each operation
// 2. Each element is pushed and popped at most once → O(n) total
// 3. When element is popped, the popping element is its answer
//
// TIME COMPLEXITY: O(n) for all problems
// SPACE COMPLEXITY: O(n) for stack

///|
/// Returns the index of the next strictly greater element for each position.
///
/// For each index `i`, `result[i]` is the smallest `j > i` such that
/// `arr[j] > arr[i]`, or `-1` if no such `j` exists.
///
/// Uses a **decreasing** monotonic stack: indices are kept on the stack
/// while their values decrease.  When a new value is larger than the top,
/// the top's "next greater" is found and it is popped.
///
/// Time complexity: O(n).  Each element is pushed and popped at most once.
///
/// # Example
///
/// ```
/// arr    = [4, 5, 2, 10, 8]
/// result = [1, 3, 3, -1, -1]   // indices of the next greater element
/// ```
fn next_greater_element(arr : Array[Int64]) -> Array[Int] {
  let n = arr.length()
  let result = Array::make(n, -1)
  let stack : Array[Int] = [] // Stack of indices
  for i in 0..<n {
    // Pop elements smaller than current
    for pop_next = stack.length() > 0 && arr[stack[stack.length() - 1]] < arr[i]; pop_next; {
      let top = stack[stack.length() - 1]
      let _ = stack.pop()
      result[top] = i
      continue stack.length() > 0 && arr[stack[stack.length() - 1]] < arr[i]
    }
    stack.push(i)
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (NGE scan):
      #|Indices in stack are in decreasing value order, and result is finalized
      #|for all indices < i that have already found their next greater element.
      #|MAINTENANCE:
      #|Pop all smaller elements; the current index i is their first greater
      #|to the right. Then push i to preserve decreasing order.
      #|TERMINATION:
      #|After i = n, remaining stack elements have no greater element to the
      #|right, so their result stays -1.
    ),
  }
  result
}

///|
/// Returns the index of the next strictly smaller element for each position.
///
/// For each index `i`, `result[i]` is the smallest `j > i` such that
/// `arr[j] < arr[i]`, or `-1` if no such `j` exists.
///
/// Uses an **increasing** monotonic stack: indices are kept on the stack
/// while their values increase.  When a new value is smaller than the top,
/// the top's "next smaller" is found and it is popped.
///
/// Time complexity: O(n).
///
/// # Example
///
/// ```
/// arr    = [4, 5, 2, 10, 8]
/// result = [2, 2, -1,  4, -1]  // indices of the next smaller element
/// ```
fn next_smaller_element(arr : Array[Int64]) -> Array[Int] {
  let n = arr.length()
  let result = Array::make(n, -1)
  let stack : Array[Int] = []
  for i in 0..<n {
    for pop_next = stack.length() > 0 && arr[stack[stack.length() - 1]] > arr[i]; pop_next; {
      let top = stack[stack.length() - 1]
      let _ = stack.pop()
      result[top] = i
      continue stack.length() > 0 && arr[stack[stack.length() - 1]] > arr[i]
    }
    stack.push(i)
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (NSE scan):
      #|Indices in stack are in increasing value order, and result is finalized
      #|for processed indices whose next smaller element has been found.
      #|MAINTENANCE:
      #|Pop all larger elements; the current index i is their first smaller
      #|to the right. Push i to preserve increasing order.
      #|TERMINATION:
      #|After i = n, remaining stack elements have no next smaller element.
    ),
  }
  result
}

///|
/// Find previous greater element for each position
fn previous_greater_element(arr : Array[Int64]) -> Array[Int] {
  let n = arr.length()
  let result = Array::make(n, -1)
  let stack : Array[Int] = []
  for i in 0..<n {
    // Pop elements smaller than or equal to current
    for pop_next = stack.length() > 0 &&
          arr[stack[stack.length() - 1]] <= arr[i]; pop_next; {
      let _ = stack.pop()
      continue stack.length() > 0 && arr[stack[stack.length() - 1]] <= arr[i]
    }
    // Top of stack (if exists) is previous greater
    if stack.length() > 0 {
      result[i] = stack[stack.length() - 1]
    }
    stack.push(i)
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (PGE scan):
      #|Stack holds indices with strictly decreasing values from bottom to top,
      #|so the top is the nearest previous greater element for the next index.
      #|MAINTENANCE:
      #|Pop elements <= current (they cannot be previous greater for future).
      #|The new top (if any) is the PGE for i; push i to continue.
      #|TERMINATION:
      #|After i = n, each position has its previous greater index or -1.
    ),
  }
  result
}

///|
/// Find previous smaller element for each position
fn previous_smaller_element(arr : Array[Int64]) -> Array[Int] {
  let n = arr.length()
  let result = Array::make(n, -1)
  let stack : Array[Int] = []
  for i in 0..<n {
    for pop_next = stack.length() > 0 &&
          arr[stack[stack.length() - 1]] >= arr[i]; pop_next; {
      let _ = stack.pop()
      continue stack.length() > 0 && arr[stack[stack.length() - 1]] >= arr[i]
    }
    if stack.length() > 0 {
      result[i] = stack[stack.length() - 1]
    }
    stack.push(i)
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (PSE scan):
      #|Stack holds indices with strictly increasing values, so the top is the
      #|nearest previous smaller element for the next index.
      #|MAINTENANCE:
      #|Pop elements >= current; the remaining top (if any) is the PSE for i.
      #|Push i to preserve monotonicity.
      #|TERMINATION:
      #|After i = n, each position has its previous smaller index or -1.
    ),
  }
  result
}

// ============================================================================
// LARGEST RECTANGLE IN HISTOGRAM
// ============================================================================

///|
/// Find largest rectangle area in histogram
/// heights[i] = height of bar at position i
fn largest_rectangle_in_histogram(heights : Array[Int64]) -> Int64 {
  let n = heights.length()
  if n == 0 {
    return 0L
  }

  // Find previous and next smaller elements
  let prev_smaller = Array::make(n, -1)
  let next_smaller = Array::make(n, n) // Default to n (past the end)

  // Compute previous smaller
  let stack : Array[Int] = []
  for i in 0..<n {
    for pop_next = stack.length() > 0 &&
          heights[stack[stack.length() - 1]] >= heights[i]; pop_next; {
      let _ = stack.pop()
      continue stack.length() > 0 &&
        heights[stack[stack.length() - 1]] >= heights[i]
    }
    if stack.length() > 0 {
      prev_smaller[i] = stack[stack.length() - 1]
    }
    stack.push(i)
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (prev smaller):
      #|Stack stores indices of a strictly increasing height sequence for
      #|positions in [0, i). For processed bars, prev_smaller is correct.
      #|MAINTENANCE:
      #|Pop while height >= current so the top is the nearest smaller to left,
      #|record prev_smaller[i], then push i to maintain monotonicity.
      #|TERMINATION:
      #|At i = n, prev_smaller is computed for all bars.
    ),
  }

  // Compute next smaller
  stack.clear()
  for i in n>..0 {
    for pop_next = stack.length() > 0 &&
          heights[stack[stack.length() - 1]] >= heights[i]; pop_next; {
      let _ = stack.pop()
      continue stack.length() > 0 &&
        heights[stack[stack.length() - 1]] >= heights[i]
    }
    if stack.length() > 0 {
      next_smaller[i] = stack[stack.length() - 1]
    }
    stack.push(i)
  }

  // Calculate max area using fold
  for i in 0..<n; max_area = 0L {
    let width = (next_smaller[i] - prev_smaller[i] - 1).to_int64()
    let area = heights[i] * width
    continue if area > max_area { area } else { max_area }
  } nobreak {
    max_area
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (max area):
      #|max_area is the largest rectangle area among bars in [0, i).
      #|MAINTENANCE:
      #|For bar i, compute width between prev_smaller and next_smaller and
      #|update max_area if this rectangle is larger.
      #|TERMINATION:
      #|After i = n, max_area is the largest histogram rectangle.
    ),
  }
}

// ============================================================================
// TRAPPING RAIN WATER
// ============================================================================

///|
/// Calculate total water trapped between bars
fn trap_rain_water(heights : Array[Int64]) -> Int64 {
  let n = heights.length()
  if n <= 2 {
    return 0L
  }

  // Method 1: Using monotonic stack
  let stack : Array[Int] = []
  let water = for i in 0..<n; water = 0L {
    let water = for water = water; stack.length() > 0 &&
                   heights[stack[stack.length() - 1]] < heights[i]; {
      let mid = stack[stack.length() - 1]
      let _ = stack.pop()
      if stack.length() == 0 {
        break water
      }
      let left = stack[stack.length() - 1]
      let width = (i - left - 1).to_int64()
      let bounded_height = (if heights[left] < heights[i] {
          heights[left]
        } else {
          heights[i]
        }) -
        heights[mid]
      continue water + width * bounded_height
    } nobreak {
      water
    }
    stack.push(i)
    continue water
  } nobreak {
    water
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (rain water):
      #|Stack holds indices of bars in decreasing height order. All trapped
      #|water for positions < i that can be bounded on the right is accounted for.
      #|MAINTENANCE:
      #|When current bar is taller, pop a "mid" bar and compute water bounded
      #|by the new top (left) and current bar (right). Each basin is counted once.
      #|TERMINATION:
      #|After i = n, all basins with a right boundary are processed.
    ),
  }
  water
}

// ============================================================================
// STOCK SPAN PROBLEM
// ============================================================================

///|
/// Calculate span for each day
/// Span = number of consecutive days before (including current) with price <= current price
fn stock_span(prices : Array[Int64]) -> Array[Int] {
  let n = prices.length()
  let span = Array::make(n, 0)
  let stack : Array[Int] = []
  for i in 0..<n {
    // Pop days with price <= current
    for pop_next = stack.length() > 0 &&
          prices[stack[stack.length() - 1]] <= prices[i]; pop_next; {
      let _ = stack.pop()
      continue stack.length() > 0 &&
        prices[stack[stack.length() - 1]] <= prices[i]
    }
    // Span is distance to previous greater element (or i+1 if none)
    span[i] = if stack.length() == 0 {
      i + 1
    } else {
      i - stack[stack.length() - 1]
    }
    stack.push(i)
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (stock span):
      #|Stack holds indices with strictly greater prices, so the top is the
      #|nearest previous greater day for the current index.
      #|MAINTENANCE:
      #|Pop all days with price <= current; compute span as distance to the
      #|nearest greater (or i+1 if none), then push i.
      #|TERMINATION:
      #|After i = n, each day's span is computed.
    ),
  }
  span
}

// ============================================================================
// SUM OF SUBARRAY MINIMUMS
// ============================================================================

///|
/// Sum of minimum values of all contiguous subarrays
fn sum_subarray_mins(arr : Array[Int64]) -> Int64 {
  let n = arr.length()
  if n == 0 {
    return 0L
  }
  let mod_val = 1000000007L

  // For each element, count subarrays where it's the minimum
  // left[i] = distance to previous smaller element
  // right[i] = distance to next smaller or equal element
  let left = Array::make(n, 0)
  let right = Array::make(n, 0)
  let stack : Array[Int] = []

  // Previous smaller (strictly less)
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
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (left distances):
      #|Stack stores indices with strictly increasing values for [0, i), so
      #|the top is the nearest previous smaller element.
      #|MAINTENANCE:
      #|Pop until a strictly smaller element remains; set left[i] to the
      #|distance to that element (or i+1 if none), then push i.
      #|TERMINATION:
      #|At i = n, left distances are computed for all positions.
    ),
  }

  // Next smaller or equal (to handle duplicates correctly)
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

  // Sum contributions using functional for loop
  for i in 0..<n; result = 0L {
    let contribution = arr[i] *
      left[i].to_int64() %
      mod_val *
      right[i].to_int64() %
      mod_val
    continue (result + contribution) % mod_val
  } nobreak {
    result
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_reasoning: (
      #|INVARIANT (sum mins):
      #|result equals the sum of contributions from indices in [0, i). Each
      #|contribution counts subarrays where arr[i] is the minimum.
      #|MAINTENANCE:
      #|Add arr[i] * left[i] * right[i] (mod mod_val) to the running sum.
      #|TERMINATION:
      #|At i = n, result is the sum of all subarray minimums.
    ),
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "next greater element" {
  let arr : Array[Int64] = [4L, 5L, 2L, 10L, 8L]
  let nge = next_greater_element(arr)
  // NGE: 5(idx 1), 10(idx 3), 10(idx 3), none(-1), none(-1)
  inspect(nge[0], content="1")
  inspect(nge[1], content="3")
  inspect(nge[2], content="3")
  inspect(nge[3], content="-1")
  inspect(nge[4], content="-1")
}

///|
test "next smaller element" {
  let arr : Array[Int64] = [4L, 5L, 2L, 10L, 8L]
  let nse = next_smaller_element(arr)
  // NSE: 2(idx 2), 2(idx 2), none(-1), 8(idx 4), none(-1)
  inspect(nse[0], content="2")
  inspect(nse[1], content="2")
  inspect(nse[2], content="-1")
  inspect(nse[3], content="4")
  inspect(nse[4], content="-1")
}

///|
test "previous greater element" {
  let arr : Array[Int64] = [4L, 5L, 2L, 10L, 8L]
  let pge = previous_greater_element(arr)
  // PGE: none(-1), none(-1), 5(idx 1), none(-1), 10(idx 3)
  inspect(pge[0], content="-1")
  inspect(pge[1], content="-1")
  inspect(pge[2], content="1")
  inspect(pge[3], content="-1")
  inspect(pge[4], content="3")
}

///|
test "previous smaller element" {
  let arr : Array[Int64] = [4L, 5L, 2L, 10L, 8L]
  let pse = previous_smaller_element(arr)
  // PSE: none(-1), 4(idx 0), none(-1), 2(idx 2), 2(idx 2)
  inspect(pse[0], content="-1")
  inspect(pse[1], content="0")
  inspect(pse[2], content="-1")
  inspect(pse[3], content="2")
  inspect(pse[4], content="2")
}

///|
test "largest rectangle in histogram" {
  let heights : Array[Int64] = [2L, 1L, 5L, 6L, 2L, 3L]
  // Largest rectangle: height 5, width 2 (indices 2-3) = 10
  inspect(largest_rectangle_in_histogram(heights), content="10")
}

///|
test "largest rectangle uniform" {
  let heights : Array[Int64] = [3L, 3L, 3L, 3L]
  inspect(largest_rectangle_in_histogram(heights), content="12")
}

///|
test "trap rain water" {
  let heights : Array[Int64] = [0L, 1L, 0L, 2L, 1L, 0L, 1L, 3L, 2L, 1L, 2L, 1L]
  // Classic example: traps 6 units of water
  inspect(trap_rain_water(heights), content="6")
}

///|
test "trap rain water simple" {
  let heights : Array[Int64] = [3L, 0L, 2L]
  // Traps 2 units at index 1
  inspect(trap_rain_water(heights), content="2")
}

///|
test "stock span" {
  let prices : Array[Int64] = [100L, 80L, 60L, 70L, 60L, 75L, 85L]
  let span = stock_span(prices)
  // Spans: 1, 1, 1, 2, 1, 4, 6
  inspect(span[0], content="1")
  inspect(span[1], content="1")
  inspect(span[2], content="1")
  inspect(span[3], content="2")
  inspect(span[4], content="1")
  inspect(span[5], content="4")
  inspect(span[6], content="6")
}

///|
test "sum subarray mins" {
  let arr : Array[Int64] = [3L, 1L, 2L, 4L]
  // Subarrays: [3]=3, [1]=1, [2]=2, [4]=4,
  //            [3,1]=1, [1,2]=1, [2,4]=2,
  //            [3,1,2]=1, [1,2,4]=1,
  //            [3,1,2,4]=1
  // Sum = 3+1+2+4+1+1+2+1+1+1 = 17
  inspect(sum_subarray_mins(arr), content="17")
}

///|
test "monotonic stack empty" {
  let arr : Array[Int64] = []
  inspect(next_greater_element(arr).length(), content="0")
  inspect(largest_rectangle_in_histogram(arr), content="0")
}

///|
test "monotonic stack single" {
  let arr : Array[Int64] = [5L]
  let nge = next_greater_element(arr)
  inspect(nge[0], content="-1")
  inspect(largest_rectangle_in_histogram(arr), content="5")
}
