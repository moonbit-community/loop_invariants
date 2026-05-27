// ============================================================================
// EXPONENTIAL SEARCH  -  Bentley & Yao 1976 ("unbounded search")
// ============================================================================
//
// PROBLEM
//
// Locate a target `t` inside a **sorted** array `a[0..n)` when `n` is
// huge (or even unknown). Plain binary search starts from `lo = 0, hi = n`
// and pays `O(log n)` regardless of where `t` actually lives. If `t` is
// near the start, exponential search pays only `O(log k)` where `k` is
// the position of `t` -- exponentially faster in the "found early" case.
//
// ALGORITHM
//
//   1. **Locate** a bound `b = 2^i` such that `a[b] > t` (or `b >= n`).
//      Start at `i = 0`, double until the condition holds.
//   2. **Binary search** in the interval `[b/2, min(b, n))`.
//
// COMPLEXITY
//
//   Time : O(log k) where k is the smallest index with `a[k] >= t`.
//          Worst case `O(log n)`.
//   Space: O(1)
//
// USE
//
//   - Searching in an array of unknown length (Bentley & Yao's original
//     "unbounded search" problem).
//   - As a "galloping" primitive inside merge / Timsort: when one input
//     is much smaller than the other, galloping skips long stretches.
//   - Looking up boundary keys when the distribution is heavily front-
//     loaded.
//
// THE INVARIANT
//
//   Phase 1:  "After step i, b = 2^i and a[b-1] < t (if b - 1 in range)."
//   Phase 2:  Standard binary-search invariant
//             "a[lo - 1] < t  and  (hi >= n  or  a[hi] >= t)."

///|
/// Smallest index `i` with `a[i] >= t`, found in `O(log i)`. Returns
/// `arr.length()` if no such index exists.
///
/// `arr` must be sorted non-decreasing.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // [1, 3, 5, 7, 9, 11]; smallest index with a[i] >= 6 is 3.
///   @debug.assert_eq(@exponential_search.lower_bound([1, 3, 5, 7, 9, 11], 6), 3)
/// }
/// ```
pub fn lower_bound(arr : Array[Int], target : Int) -> Int {
  let n = arr.length()
  if n == 0 {
    return 0
  }
  if arr[0] >= target {
    return 0
  }
  // Phase 1: double until we overshoot or reach n.
  let mut bound = 1
  while bound < n && arr[bound] < target {
    bound = bound * 2
  }
  // Now arr[bound/2] < target, and either bound >= n or arr[bound] >= target.
  // Binary search in [bound/2 + 1, min(bound, n) - 1].
  let mut lo = bound / 2 + 1
  let mut hi = if bound < n { bound } else { n - 1 }
  // Invariant: arr[lo - 1] < target  and  arr[hi + ?] checked.
  // We want first index in [lo, hi] with arr[i] >= target; if none, return n.
  while lo <= hi {
    let mid = lo + (hi - lo) / 2
    if arr[mid] >= target {
      hi = mid - 1
    } else {
      lo = mid + 1
    }
  }
  lo
}

///|
/// Return `Some(i)` such that `arr[i] == target`, or `None` if absent.
/// Uses exponential search to bound the binary search.
pub fn find(arr : Array[Int], target : Int) -> Int? {
  let n = arr.length()
  let i = lower_bound(arr, target)
  if i < n && arr[i] == target {
    Some(i)
  } else {
    None
  }
}

///|
/// "Galloping" probe used by merge / Timsort: given a sorted array `arr`
/// and a `start` index, returns the smallest index `>= start` with
/// `arr[i] >= target`.
///
/// Runs in `O(log (returned_index - start))`, which is the whole point.
pub fn gallop(arr : Array[Int], start : Int, target : Int) -> Int {
  let n = arr.length()
  if start >= n {
    return n
  }
  if arr[start] >= target {
    return start
  }
  let mut offset = 1
  while start + offset < n && arr[start + offset] < target {
    offset = offset * 2
  }
  // Binary search in [start + offset/2 + 1, min(start + offset, n) - 1].
  let mut lo = start + offset / 2 + 1
  let mut hi = if start + offset < n { start + offset } else { n - 1 }
  while lo <= hi {
    let mid = lo + (hi - lo) / 2
    if arr[mid] >= target {
      hi = mid - 1
    } else {
      lo = mid + 1
    }
  }
  lo
}

///|
test "lower_bound basic" {
  let a = [1, 3, 5, 7, 9, 11]
  @debug.assert_eq(lower_bound(a, 0), 0)
  @debug.assert_eq(lower_bound(a, 1), 0)
  @debug.assert_eq(lower_bound(a, 2), 1)
  @debug.assert_eq(lower_bound(a, 5), 2)
  @debug.assert_eq(lower_bound(a, 6), 3)
  @debug.assert_eq(lower_bound(a, 11), 5)
  @debug.assert_eq(lower_bound(a, 12), 6)
  @debug.assert_eq(lower_bound(a, 100), 6)
}

///|
test "lower_bound empty and single" {
  @debug.assert_eq(lower_bound([], 5), 0)
  @debug.assert_eq(lower_bound([3], 1), 0)
  @debug.assert_eq(lower_bound([3], 3), 0)
  @debug.assert_eq(lower_bound([3], 5), 1)
}

///|
test "lower_bound duplicates" {
  // First occurrence, not last.
  let a = [1, 2, 2, 2, 5]
  @debug.assert_eq(lower_bound(a, 2), 1)
  @debug.assert_eq(lower_bound(a, 3), 4)
}

///|
test "find present and absent" {
  let a = [1, 3, 5, 7, 9, 11]
  @debug.assert_eq(find(a, 7), Some(3))
  @debug.assert_eq(find(a, 6), None)
  @debug.assert_eq(find(a, 1), Some(0))
  @debug.assert_eq(find(a, 11), Some(5))
  @debug.assert_eq(find(a, 100), None)
  @debug.assert_eq(find([], 5), None)
}

///|
test "lower_bound large front-loaded" {
  // Build a 10000-element sorted array; target lives at small index.
  // Exponential search should still be correct (we just check it -- not
  // timing).
  let a = Array::makei(10000, i => i * 2)
  for x in [0, 1, 2, 3, 100, 9999, 19998, 19999, 20000] {
    let lo = lower_bound(a, x)
    // Confirm the boundary property.
    if lo > 0 {
      @debug.assert_eq(a[lo - 1] < x, true)
    }
    if lo < a.length() {
      @debug.assert_eq(a[lo] >= x, true)
    }
  }
}

///|
test "gallop from start" {
  let a = [1, 3, 5, 7, 9, 11]
  @debug.assert_eq(gallop(a, 0, 8), 4)
  @debug.assert_eq(gallop(a, 2, 8), 4)
  @debug.assert_eq(gallop(a, 4, 8), 4) // already >= 8
  @debug.assert_eq(gallop(a, 5, 100), 6) // past end
  @debug.assert_eq(gallop(a, 6, 100), 6)
}

///|
test "exponential_search agrees with naive" {
  fn naive(arr : Array[Int], target : Int) -> Int {
    let mut i = 0
    while i < arr.length() && arr[i] < target {
      i = i + 1
    }
    i
  }

  let arrays = [
    [0, 1, 2, 3, 4, 5],
    [1, 1, 1, 1, 1],
    [10, 20, 30, 40, 50, 60, 70, 80, 90, 100],
    [],
    [42],
  ]
  for a in arrays {
    for t in [-1, 0, 1, 5, 10, 35, 100, 101] {
      @debug.assert_eq(lower_bound(a, t), naive(a, t))
    }
  }
}
