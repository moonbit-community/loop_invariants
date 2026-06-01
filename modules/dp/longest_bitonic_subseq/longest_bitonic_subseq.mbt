// ============================================================================
// LONGEST BITONIC SUBSEQUENCE
// ============================================================================
//
// PROBLEM
//
// A **bitonic** sequence is one that first **strictly increases** then
// **strictly decreases** (either half may be empty). Given an array
// `arr`, find the longest bitonic subsequence (not necessarily
// contiguous).
//
// E.g. arr = [1, 11, 2, 10, 4, 5, 2, 1] -> length 6 (1, 2, 10, 4, 2, 1
// or 1, 11, 10, 5, 2, 1).
//
// DP
//
//   inc[i] = length of the longest strictly-increasing subsequence
//            ending at index i.
//   dec[i] = length of the longest strictly-decreasing subsequence
//            starting at index i.
//   ans = max over i of inc[i] + dec[i] - 1
//
// The "-1" is because arr[i] is counted once in each half.
//
// COMPLEXITY
//
//   Time : O(n^2)
//   Space: O(n)
//
// THE INVARIANT
//
//   "After computing inc[0..i], inc[k] holds the length of the longest
//    strictly-increasing subsequence of arr[0..i] ending at k."

///|
/// Length of the longest bitonic subsequence. Both ascending and
/// descending halves must be **strict** (no equal neighbours).
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(
///     @longest_bitonic_subseq.length([1L, 11L, 2L, 10L, 4L, 5L, 2L, 1L]),
///     6,
///   )
/// }
/// ```
pub fn length(arr : Array[Int64]) -> Int {
  let n = arr.length()
  if n == 0 {
    return 0
  }
  let inc = Array::make(n, 1)
  let dec = Array::make(n, 1)
  for i in 1..<n {
    for j in 0..<i {
      if arr[j] < arr[i] && inc[j] + 1 > inc[i] {
        inc[i] = inc[j] + 1
      }
    }
  }
  let mut i = n - 2
  while i >= 0 {
    for j in (i + 1)..<n {
      if arr[j] < arr[i] && dec[j] + 1 > dec[i] {
        dec[i] = dec[j] + 1
      }
    }
    i = i - 1
  }
  let mut best = 1
  for k in 0..<n {
    let total = inc[k] + dec[k] - 1
    if total > best {
      best = total
    }
  }
  best
}

///|
/// Length plus the inc/dec lengths at the peak index, useful for
/// path reconstruction or analysis.
pub fn length_with_split(arr : Array[Int64]) -> (Int, Int, Int) {
  let n = arr.length()
  if n == 0 {
    return (0, 0, 0)
  }
  let inc = Array::make(n, 1)
  let dec = Array::make(n, 1)
  for i in 1..<n {
    for j in 0..<i {
      if arr[j] < arr[i] && inc[j] + 1 > inc[i] {
        inc[i] = inc[j] + 1
      }
    }
  }
  let mut i = n - 2
  while i >= 0 {
    for j in (i + 1)..<n {
      if arr[j] < arr[i] && dec[j] + 1 > dec[i] {
        dec[i] = dec[j] + 1
      }
    }
    i = i - 1
  }
  let mut best = 1
  let mut best_inc = 1
  let mut best_dec = 1
  for k in 0..<n {
    let total = inc[k] + dec[k] - 1
    if total > best {
      best = total
      best_inc = inc[k]
      best_dec = dec[k]
    }
  }
  (best, best_inc, best_dec)
}

///|
test "bitonic classic example" {
  @debug.assert_eq(length([1L, 11L, 2L, 10L, 4L, 5L, 2L, 1L]), 6)
}

///|
test "bitonic strictly increasing" {
  @debug.assert_eq(length([1L, 2L, 3L, 4L, 5L]), 5)
}

///|
test "bitonic strictly decreasing" {
  @debug.assert_eq(length([5L, 4L, 3L, 2L, 1L]), 5)
}

///|
test "bitonic mountain shape" {
  @debug.assert_eq(length([1L, 4L, 9L, 7L, 3L, 2L]), 6)
}

///|
test "bitonic small" {
  @debug.assert_eq(length([]), 0)
  @debug.assert_eq(length([42L]), 1)
  @debug.assert_eq(length([1L, 1L, 1L]), 1) // strict; only one survives
  @debug.assert_eq(length([1L, 2L]), 2)
  @debug.assert_eq(length([2L, 1L]), 2)
}

///|
test "bitonic with plateau" {
  // [1, 2, 2, 3] -> strict LIS is 1,2,3 = 3, no decreasing -> 3.
  @debug.assert_eq(length([1L, 2L, 2L, 3L]), 3)
}

///|
test "bitonic with split parts" {
  let (total, inc, dec) = length_with_split([1L, 11L, 2L, 10L, 4L, 5L, 2L, 1L])
  @debug.assert_eq(total, 6)
  @debug.assert_eq(inc + dec - 1, total)
}

///|
test "bitonic agrees with brute force" {
  fn brute(arr : Array[Int64]) -> Int {
    let n = arr.length()
    if n == 0 {
      return 0
    }
    let mut best = 1
    let mut mask = 1
    while mask < 1 << n {
      let sub : Array[Int64] = []
      for k in 0..<n {
        if ((mask >> k) & 1) == 1 {
          sub.push(arr[k])
        }
      }
      if sub.length() <= best {
        mask = mask + 1
        continue
      }
      // Find peak index; first must strictly increase, then strictly decrease.
      let l = sub.length()
      let mut peak = 0
      while peak + 1 < l && sub[peak] < sub[peak + 1] {
        peak = peak + 1
      }
      let mut ok = true
      let mut i = peak + 1
      while i < l {
        if sub[i - 1] <= sub[i] {
          ok = false
          break
        }
        i = i + 1
      }
      if ok && l > best {
        best = l
      }
      mask = mask + 1
    }
    best
  }

  let cases : ReadOnlyArray[Array[Int64]] = [
    [1L, 4L, 2L, 7L, 5L],
    [3L, 1L, 4L, 1L, 5L, 9L, 2L, 6L],
    [10L],
    [1L, 2L, 3L, 2L, 1L],
  ]
  for c in cases {
    @debug.assert_eq(length(c), brute(c))
  }
}
