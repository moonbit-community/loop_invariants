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
/// Find next greater element for each position
/// Returns -1 if no greater element exists to the right
fn next_greater_element(arr : Array[Int64]) -> Array[Int] {
  let n = arr.length()
  let result = Array::make(n, -1)
  let stack : Array[Int] = [] // Stack of indices
  for i = 0; i < n; i = i + 1 {
    // Pop elements smaller than current
    while stack.length() > 0 && arr[stack[stack.length() - 1]] < arr[i] {
      let top = stack[stack.length() - 1]
      let _ = stack.pop()
      result[top] = i
    }
    stack.push(i)
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
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
/// Find next smaller element for each position
fn next_smaller_element(arr : Array[Int64]) -> Array[Int] {
  let n = arr.length()
  let result = Array::make(n, -1)
  let stack : Array[Int] = []
  for i = 0; i < n; i = i + 1 {
    while stack.length() > 0 && arr[stack[stack.length() - 1]] > arr[i] {
      let top = stack[stack.length() - 1]
      let _ = stack.pop()
      result[top] = i
    }
    stack.push(i)
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
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
  for i = 0; i < n; i = i + 1 {
    // Pop elements smaller than or equal to current
    while stack.length() > 0 && arr[stack[stack.length() - 1]] <= arr[i] {
      let _ = stack.pop()

    }
    // Top of stack (if exists) is previous greater
    if stack.length() > 0 {
      result[i] = stack[stack.length() - 1]
    }
    stack.push(i)
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
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
  for i = 0; i < n; i = i + 1 {
    while stack.length() > 0 && arr[stack[stack.length() - 1]] >= arr[i] {
      let _ = stack.pop()

    }
    if stack.length() > 0 {
      result[i] = stack[stack.length() - 1]
    }
    stack.push(i)
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
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
  for i = 0; i < n; i = i + 1 {
    while stack.length() > 0 && heights[stack[stack.length() - 1]] >= heights[i] {
      let _ = stack.pop()

    }
    if stack.length() > 0 {
      prev_smaller[i] = stack[stack.length() - 1]
    }
    stack.push(i)
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
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
  for i = n - 1; i >= 0; i = i - 1 {
    while stack.length() > 0 && heights[stack[stack.length() - 1]] >= heights[i] {
      let _ = stack.pop()

    }
    if stack.length() > 0 {
      next_smaller[i] = stack[stack.length() - 1]
    }
    stack.push(i)
  } where {
    invariant: i >= -1 && i <= n - 1,
    reasoning: (
      #|INVARIANT (next smaller):
      #|Stack stores indices of a strictly increasing height sequence to the
      #|right of i, so the top is the nearest smaller to the right.
      #|MAINTENANCE:
      #|Pop while height >= current, record next_smaller[i] (or keep n), then
      #|push i to preserve monotonicity.
      #|TERMINATION:
      #|At i = -1, next_smaller is computed for all bars.
    ),
  }

  // Calculate max area
  let mut max_area = 0L
  for i = 0; i < n; i = i + 1 {
    let width = (next_smaller[i] - prev_smaller[i] - 1).to_int64()
    let area = heights[i] * width
    if area > max_area {
      max_area = area
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (max area):
      #|max_area is the largest rectangle area among bars in [0, i).
      #|MAINTENANCE:
      #|For bar i, compute width between prev_smaller and next_smaller and
      #|update max_area if this rectangle is larger.
      #|TERMINATION:
      #|After i = n, max_area is the largest histogram rectangle.
    ),
  }
  max_area
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
  let mut water = 0L
  for i = 0; i < n; i = i + 1 {
    while stack.length() > 0 && heights[stack[stack.length() - 1]] < heights[i] {
      let mid = stack[stack.length() - 1]
      let _ = stack.pop()
      if stack.length() == 0 {
        break
      }
      let left = stack[stack.length() - 1]
      let width = (i - left - 1).to_int64()
      let bounded_height = (if heights[left] < heights[i] {
          heights[left]
        } else {
          heights[i]
        }) -
        heights[mid]
      water = water + width * bounded_height
    }
    stack.push(i)
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
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
  for i = 0; i < n; i = i + 1 {
    // Pop days with price <= current
    while stack.length() > 0 && prices[stack[stack.length() - 1]] <= prices[i] {
      let _ = stack.pop()

    }
    // Span is distance to previous greater element (or i+1 if none)
    span[i] = if stack.length() == 0 {
      i + 1
    } else {
      i - stack[stack.length() - 1]
    }
    stack.push(i)
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
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
  for i = 0; i < n; i = i + 1 {
    while stack.length() > 0 && arr[stack[stack.length() - 1]] >= arr[i] {
      let _ = stack.pop()

    }
    left[i] = if stack.length() == 0 {
      i + 1
    } else {
      i - stack[stack.length() - 1]
    }
    stack.push(i)
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
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
  for i = n - 1; i >= 0; i = i - 1 {
    while stack.length() > 0 && arr[stack[stack.length() - 1]] > arr[i] {
      let _ = stack.pop()

    }
    right[i] = if stack.length() == 0 {
      n - i
    } else {
      stack[stack.length() - 1] - i
    }
    stack.push(i)
  } where {
    invariant: i >= -1 && i <= n - 1,
    reasoning: (
      #|INVARIANT (right distances):
      #|Stack stores indices with non-decreasing values to the right of i, so
      #|the top is the next smaller-or-equal element.
      #|MAINTENANCE:
      #|Pop while value > current; set right[i] to the distance to the next
      #|smaller-or-equal (or to n), then push i.
      #|TERMINATION:
      #|At i = -1, right distances are computed for all positions.
    ),
  }

  // Sum contributions
  let mut result = 0L
  for i = 0; i < n; i = i + 1 {
    let contribution = arr[i] *
      left[i].to_int64() %
      mod_val *
      right[i].to_int64() %
      mod_val
    result = (result + contribution) % mod_val
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (sum mins):
      #|result equals the sum of contributions from indices in [0, i). Each
      #|contribution counts subarrays where arr[i] is the minimum.
      #|MAINTENANCE:
      #|Add arr[i] * left[i] * right[i] (mod mod_val) to the running sum.
      #|TERMINATION:
      #|At i = n, result is the sum of all subarray minimums.
    ),
  }
  result
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
