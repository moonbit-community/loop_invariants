// ============================================================================
// INVERSION COUNT  -  via stable merge sort
// ============================================================================
//
// PROBLEM
//
// Count the number of *inversions* in an array `arr`: pairs `(i, j)`
// with `i < j` and `arr[i] > arr[j]`. The inversion count is the
// minimum number of adjacent swaps that bubble-sort would perform.
//
// ALGORITHM
//
// Modified merge sort. During the merge step, whenever we pull an
// element from the right run before exhausting the left run, the
// remaining `(mid - i)` left-run elements are all greater than the
// pulled one, contributing that many inversions.
//
// COMPLEXITY
//
//   Time : O(n log n)
//   Space: O(n) auxiliary buffer
//
// THE INVARIANT
//
//   "After merging runs `[lo, mid)` and `[mid, hi)`, the counter has
//    been incremented by exactly the number of `(i, j)` inversion
//    pairs with `i in [lo, mid)`, `j in [mid, hi)`."

///|
/// Number of inversions in `arr` (left untouched). Returns `Int64` to
/// support arrays up to `2 * 10^9` long.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   @debug.assert_eq(@inversion_count.count([3, 1, 2]), 2L)
/// }
/// ```
pub fn count(arr : Array[Int]) -> Int64 {
  let n = arr.length()
  if n <= 1 {
    return 0L
  }
  let a = Array::makei(n, i => arr[i])
  let buf = Array::make(n, 0)
  merge_sort(a, buf, 0, n)
}

///|
fn merge_sort(arr : Array[Int], buf : Array[Int], lo : Int, hi : Int) -> Int64 {
  if hi - lo <= 1 {
    return 0L
  }
  let mid = lo + (hi - lo) / 2
  let mut total = merge_sort(arr, buf, lo, mid)
  total = total + merge_sort(arr, buf, mid, hi)
  total = total + merge_run(arr, buf, lo, mid, hi)
  total
}

///|
fn merge_run(
  arr : Array[Int],
  buf : Array[Int],
  lo : Int,
  mid : Int,
  hi : Int,
) -> Int64 {
  let mut i = lo
  let mut j = mid
  let mut k = lo
  let mut count = 0L
  while i < mid && j < hi {
    if arr[i] <= arr[j] {
      buf[k] = arr[i]
      i = i + 1
    } else {
      buf[k] = arr[j]
      j = j + 1
      count = count + (mid - i).to_int64()
    }
    k = k + 1
  }
  while i < mid {
    buf[k] = arr[i]
    i = i + 1
    k = k + 1
  }
  while j < hi {
    buf[k] = arr[j]
    j = j + 1
    k = k + 1
  }
  for x in lo..<hi {
    arr[x] = buf[x]
  }
  count
}

///|
test "inv basic" {
  @debug.assert_eq(count([3, 1, 2]), 2L)
  @debug.assert_eq(count([5, 4, 3, 2, 1]), 10L) // n*(n-1)/2
  @debug.assert_eq(count([1, 2, 3, 4, 5]), 0L)
}

///|
test "inv empty / single" {
  @debug.assert_eq(count([]), 0L)
  @debug.assert_eq(count([42]), 0L)
}

///|
test "inv duplicates" {
  // [2, 4, 1, 3, 5] has inversions (2,1), (4,1), (4,3) = 3.
  @debug.assert_eq(count([2, 4, 1, 3, 5]), 3L)
  // Duplicates do not contribute.
  @debug.assert_eq(count([1, 1, 1, 1]), 0L)
}

///|
test "inv agrees with brute force" {
  fn brute(arr : Array[Int]) -> Int64 {
    let n = arr.length()
    let mut c = 0L
    for i in 0..<n {
      for j in (i + 1)..<n {
        if arr[i] > arr[j] {
          c = c + 1L
        }
      }
    }
    c
  }

  let cases : ReadOnlyArray[Array[Int]] = [
    [3, 1, 4, 1, 5, 9, 2, 6],
    [10, 20, 5, 30, 15],
    [],
    [7],
    [4, 4, 4, 4],
    [1, 100, 2, 99, 3, 98],
  ]
  for arr in cases {
    @debug.assert_eq(count(arr), brute(arr))
  }
}

///|
test "inv large reverse" {
  let n = 1000
  let arr = Array::makei(n, i => n - i)
  // (n-1)*n/2 = 499500.
  @debug.assert_eq(count(arr), 499500L)
}
