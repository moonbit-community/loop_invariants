// ============================================================================
// LONGEST INCREASING SUBSEQUENCE WITH RECONSTRUCTION  -  O(n log n)
// ============================================================================
//
// PROBLEM
//
// Given an integer array `a`, find both the **length** and an actual
// realising **subsequence** (in original order) of the longest strictly
// increasing subsequence (LIS).
//
// PATIENCE-SORTING DP
//
// Maintain `tails[k] = ` the **smallest possible last element** of any
// LIS of length `k + 1` seen so far. For each `a[i]`:
//
//   - Binary-search for the smallest `j` with `tails[j] >= a[i]`.
//   - Replace `tails[j]` with `a[i]` (or append, if `a[i]` exceeds all).
//   - Record `parent[i] = ` the index that occupied position `j - 1`,
//     so we can rebuild the actual subsequence afterwards.
//
// At the end, `tails.length()` is the LIS length and we walk back
// through `parent` from the index that produced the last `tails` slot.
//
// COMPLEXITY
//
//   Time : O(n log n)
//   Space: O(n) for parent + indices
//
// THE INVARIANT
//
//   "After processing index i, for every k in [0, tails.length()),
//    tails[k] = min over j <= i of a[j] such that j ends an increasing
//    subsequence of length k + 1."
//
// Because `tails` is strictly increasing, the binary search is valid.

///|
/// Smallest index `i` in `arr[0..len)` with `arr[i] >= target`.
fn lower_bound_int(arr : Array[Int], len : Int, target : Int) -> Int {
  let mut lo = 0
  let mut hi = len
  while lo < hi {
    let mid = lo + (hi - lo) / 2
    if arr[mid] >= target {
      hi = mid
    } else {
      lo = mid + 1
    }
  }
  lo
}

///|
/// Length of the LIS of `arr` (strictly increasing).
pub fn length(arr : Array[Int]) -> Int {
  let n = arr.length()
  if n == 0 {
    return 0
  }
  let tails : Array[Int] = []
  for x in arr {
    let pos = lower_bound_int(tails, tails.length(), x)
    if pos == tails.length() {
      tails.push(x)
    } else {
      tails[pos] = x
    }
  }
  tails.length()
}

///|
/// Length and one realising subsequence (in original order).
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let (len, seq) = @lis_reconstruction.length_and_path([10, 9, 2, 5, 3, 7, 101, 18])
///   @debug.assert_eq(len, 4)
///   // One valid sequence: [2, 3, 7, 18] or [2, 5, 7, 101].
/// }
/// ```
pub fn length_and_path(arr : Array[Int]) -> (Int, Array[Int]) {
  let n = arr.length()
  if n == 0 {
    return (0, [])
  }
  // tails[k] = index in arr giving the smallest LIS-ending value of length k+1.
  let tails_idx : Array[Int] = []
  // parent[i] = previous index in arr in the LIS ending at i, or -1.
  let parent = Array::make(n, -1)
  for i in 0..<n {
    // Mirror of lower_bound on tails-by-value.
    let mut lo = 0
    let mut hi = tails_idx.length()
    while lo < hi {
      let mid = lo + (hi - lo) / 2
      if arr[tails_idx[mid]] >= arr[i] {
        hi = mid
      } else {
        lo = mid + 1
      }
    }
    if lo > 0 {
      parent[i] = tails_idx[lo - 1]
    }
    if lo == tails_idx.length() {
      tails_idx.push(i)
    } else {
      tails_idx[lo] = i
    }
  }
  // Walk parent chain from the last tail.
  let path : Array[Int] = []
  let mut idx = tails_idx[tails_idx.length() - 1]
  while idx != -1 {
    path.push(arr[idx])
    idx = parent[idx]
  }
  // Reverse.
  let mut i = 0
  let mut j = path.length() - 1
  while i < j {
    let t = path[i]
    path[i] = path[j]
    path[j] = t
    i = i + 1
    j = j - 1
  }
  (tails_idx.length(), path)
}

///|
test "lis basic" {
  @debug.assert_eq(length([10, 9, 2, 5, 3, 7, 101, 18]), 4)
  @debug.assert_eq(length([0, 1, 0, 3, 2, 3]), 4)
  @debug.assert_eq(length([7, 7, 7, 7, 7]), 1)
}

///|
test "lis edge cases" {
  @debug.assert_eq(length([]), 0)
  @debug.assert_eq(length([5]), 1)
  @debug.assert_eq(length([5, 5]), 1) // strictly increasing -> length 1
  @debug.assert_eq(length([1, 2, 3, 4]), 4)
  @debug.assert_eq(length([4, 3, 2, 1]), 1)
}

///|
test "lis path is valid LIS" {
  let arrs = [
    [10, 9, 2, 5, 3, 7, 101, 18],
    [3, 10, 2, 1, 20],
    [50, 3, 10, 7, 40, 80],
    [],
    [42],
    [5, 4, 3, 2, 1],
    [1, 2, 3, 4, 5],
  ]
  for arr in arrs {
    let (len, seq) = length_and_path(arr)
    // Length matches.
    @debug.assert_eq(length(arr), len)
    @debug.assert_eq(seq.length(), len)
    // Strictly increasing.
    for k in 0..<(seq.length() - 1) {
      @debug.assert_eq(seq[k] < seq[k + 1], true)
    }
    // Each element appears in arr in the right relative order.
    let mut p = 0
    let mut k = 0
    while p < arr.length() && k < seq.length() {
      if arr[p] == seq[k] {
        k = k + 1
      }
      p = p + 1
    }
    @debug.assert_eq(k, seq.length())
  }
}

///|
test "lis large" {
  let arr = Array::makei(1000, i => (i * 7 % 23) + i / 50)
  let len = length(arr)
  let (len2, _) = length_and_path(arr)
  @debug.assert_eq(len, len2)
  @debug.assert_eq(len > 0, true)
}
