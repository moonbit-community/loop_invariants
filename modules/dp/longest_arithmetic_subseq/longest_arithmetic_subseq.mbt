// ============================================================================
// LONGEST ARITHMETIC SUBSEQUENCE  -  O(n^2) DP
// ============================================================================
//
// PROBLEM
//
// Given an integer array `arr`, find the length of the **longest
// arithmetic subsequence** (LAS): a subsequence (not necessarily
// contiguous) whose successive differences are all equal.
//
// E.g. arr = [3, 6, 9, 12] -> 4 (the whole array).
//      arr = [9, 4, 7, 2, 10] -> 3 (e.g. 4, 7, 10).
//
// DP STATE
//
//   dp[i][d] = longest arithmetic subsequence ending at index i with
//              common difference d.
//
// RECURRENCE
//
//   dp[i][d] = 1 + max over j < i with arr[i] - arr[j] = d of dp[j][d]
//                          (or 2 if no such j -- the pair (j, i) starts it).
//
// Since `d` can be up to `2 * max(arr)` and negative, we use a HashMap
// per index: `dp_map[i] : Map[d -> len]`.
//
// ANSWER
//
//   max over all i, d of dp[i][d], lower-bounded by 1 (single element).
//
// COMPLEXITY
//
//   Time : O(n^2) -- two nested loops, hashmap update is O(1).
//   Space: O(n^2) in the worst case (one entry per (i, j) pair).
//
// THE INVARIANT
//
//   "After processing index i, dp_map[i][d] is the length of the
//    longest arithmetic subsequence ending at arr[i] with common
//    difference d, considering only previous indices 0..i-1."

///|
fn get_or_zero(map : Map[Int64, Int], key : Int64) -> Int {
  match map.get(key) {
    Some(v) => v
    None => 0
  }
}

///|
/// Length of the longest arithmetic subsequence of `arr`.
/// Returns `0` for empty input and `1` for single elements.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(@longest_arithmetic_subseq.length([9, 4, 7, 2, 10]), 3)
/// }
/// ```
pub fn length(arr : Array[Int64]) -> Int {
  let n = arr.length()
  if n == 0 {
    return 0
  }
  if n == 1 {
    return 1
  }
  let dp : Array[Map[Int64, Int]] = Array::makei(n, _ => Map([], capacity=0))
  let mut best = 1
  for i in 1..<n {
    for j in 0..<i {
      let d = arr[i] - arr[j]
      let prev = get_or_zero(dp[j], d)
      let cand = if prev > 0 { prev + 1 } else { 2 }
      let cur = get_or_zero(dp[i], d)
      if cand > cur {
        dp[i][d] = cand
        if cand > best {
          best = cand
        }
      }
    }
  }
  best
}

///|
/// Length of the longest arithmetic subsequence with a **fixed** common
/// difference `d`. Runs in `O(n)` using a hashmap keyed by the next
/// expected value.
pub fn length_fixed_diff(arr : Array[Int64], d : Int64) -> Int {
  let n = arr.length()
  if n == 0 {
    return 0
  }
  // For each x, end[x] = length of the LAS ending at value x.
  let end : Map[Int64, Int] = Map([], capacity=0)
  let mut best = 1
  for i in 0..<n {
    let prev = arr[i] - d
    let p = get_or_zero(end, prev)
    let cand = if p > 0 { p + 1 } else { 1 }
    let cur = get_or_zero(end, arr[i])
    if cand > cur {
      end[arr[i]] = cand
      if cand > best {
        best = cand
      }
    }
  }
  best
}

///|
test "las basic" {
  @debug.assert_eq(length([3L, 6L, 9L, 12L]), 4)
  @debug.assert_eq(length([9L, 4L, 7L, 2L, 10L]), 3)
  @debug.assert_eq(length([20L, 1L, 15L, 3L, 10L, 5L, 8L]), 4) // 20, 15, 10, 5
}

///|
test "las edge cases" {
  @debug.assert_eq(length([]), 0)
  @debug.assert_eq(length([7L]), 1)
  @debug.assert_eq(length([7L, 7L]), 2) // d = 0
  @debug.assert_eq(length([5L, 5L, 5L, 5L]), 4)
}

///|
test "las negative differences" {
  @debug.assert_eq(length([10L, 8L, 6L, 4L]), 4)
}

///|
test "las with duplicates" {
  // [1, 2, 1, 2, 1, 2] has alternating diff = 1, -1; but as a
  // subsequence, 1, 1, 1 (diff 0) is length 3, 2, 2, 2 also length 3.
  @debug.assert_eq(length([1L, 2L, 1L, 2L, 1L, 2L]), 3)
}

///|
test "las fixed diff" {
  // arr = [1, 7, 4, 5, 8, 6, 7, 11]; diff = 3 -> [1, 4, 7] or [5, 8, 11] = 3.
  let arr = [1L, 7L, 4L, 5L, 8L, 6L, 7L, 11L]
  @debug.assert_eq(length_fixed_diff(arr, 3L), 3)
  // diff = 1 -> [4, 5, 6, 7] = 4.
  @debug.assert_eq(length_fixed_diff(arr, 1L), 4)
  // diff = 0 -> 1 (since no duplicates) or 2 (since 7 appears twice).
  @debug.assert_eq(length_fixed_diff(arr, 0L), 2)
}

///|
test "las by brute force" {
  // For small inputs, enumerate every (i, d) pair and check.
  let arr = [3L, 6L, 9L, 12L, 1L, 4L]
  let n = arr.length()
  let mut brute = 1
  // For every starting pair, walk forward greedily.
  for i in 0..<n {
    for j in (i + 1)..<n {
      let d = arr[j] - arr[i]
      let mut count = 2
      let mut last = arr[j]
      for k in (j + 1)..<n {
        if arr[k] - last == d {
          count = count + 1
          last = arr[k]
        }
      }
      if count > brute {
        brute = count
      }
    }
  }
  @debug.assert_eq(length(arr), brute)
}
