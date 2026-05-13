// ============================================================================
// QUICKSELECT WITH MEDIAN-OF-MEDIANS - Guaranteed worst-case O(n) selection
// ============================================================================
//
// Given an array `arr` and an index `k` in `[0, arr.length())`, return
// the `k`-th smallest element (0-indexed). Naive `quickselect` with a
// random pivot is O(n) expected but O(n^2) worst case. The
// **median-of-medians** pivot construction (Blum-Floyd-Pratt-Rivest-
// Tarjan, 1973) guarantees a pivot that is between the 30th and 70th
// percentile of the input, giving **O(n) worst case**.
//
// THE RECURSION
//
//   select(arr, k):
//     if |arr| <= 5:
//       return sort(arr)[k]
//     groups = partition arr into chunks of 5
//     medians = [median of each group]
//     pivot = select(medians, |medians| / 2)        # median of medians
//     L, M, R = partition arr around pivot
//     if k < |L|:        return select(L, k)
//     if k < |L| + |M|:  return pivot
//     else:              return select(R, k - |L| - |M|)
//
// THE 30-70 GUARANTEE
//
// Let p = the median of medians; m = |medians| ~ n / 5. By construction
// p is the median of m values, so at least m / 2 ~ n / 10 medians are
// >= p. Each such median came from a group of 5 in which at least 3
// elements are >= the group's median, so at least 3 * n / 10 elements
// of `arr` are >= p. Symmetrically at least 3 * n / 10 elements are
// <= p. Therefore p sits between rank 0.3 n and rank 0.7 n.
//
// THE RECURRENCE
//
//   T(n)  <=  T(n / 5)        # recurse to find the median of medians
//          + T(7 n / 10)      # recurse on the larger of L / R
//          + O(n)             # partitioning work
//
// Since 1/5 + 7/10 = 9/10 < 1, the recurrence resolves to T(n) = O(n).
//
// TIME COMPLEXITY  : O(n)  worst case (no expectation)
// SPACE COMPLEXITY : O(n)  total (geometric series of recursive arrays)

///|
/// Return the `k`-th smallest element of `arr` (0-indexed), with
/// **worst-case** linear time. Returns `None` when `arr` is empty or
/// when `k` is out of range.
///
/// ## Parameters
///
/// - `arr` : input view; the function does not mutate it.
/// - `k`   : the rank we want, 0-indexed. `k = 0` is the minimum,
///           `k = arr.length() - 1` is the maximum.
///
/// ## Returns
///
/// `Some(v)` where `v` is the value at rank `k` in a sorted copy of
/// `arr`. `None` for out-of-range `k` or empty input.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let arr = [7, 3, 9, 1, 5, 8, 2, 6, 4][:]
///   // sorted: [1, 2, 3, 4, 5, 6, 7, 8, 9]; rank 4 is the median.
///   assert_eq(@quickselect_median_of_medians.select_kth(arr, 4), Some(5))
/// }
/// ```
pub fn select_kth(arr : ArrayView[Int], k : Int) -> Int? {
  let n = arr.length()
  if n == 0 || k < 0 || k >= n {
    return None
  }
  Some(select_kth_inner(arr.to_owned(), k))
}

///|
/// Convenience: the lower median of `arr`. Returns the element at
/// rank `(n - 1) / 2`, which is the smaller of the two middle elements
/// when `n` is even. `None` for an empty input.
pub fn median(arr : ArrayView[Int]) -> Int? {
  let n = arr.length()
  if n == 0 {
    return None
  }
  select_kth(arr, (n - 1) / 2)
}

///|
/// Recursive worker. Owns its input array `a` so it can rely on
/// length-based indexing without worrying about aliasing with a caller.
fn select_kth_inner(a : Array[Int], k : Int) -> Int {
  let n = a.length()
  if n <= 5 {
    // Base case: full sort plus indexing.
    let sorted = a.copy()
    sorted.sort()
    return sorted[k]
  }
  // Step 1: build the array of group medians. Each group has 5
  // elements except possibly the last.
  let num_groups = (n + 4) / 5
  let medians = Array::make(num_groups, 0)
  for g = 0; g < num_groups; {
    let start = g * 5
    let group_end = if start + 5 < n { start + 5 } else { n }
    let group = Array::make(group_end - start, 0)
    for i in 0..<group.length() {
      group[i] = a[start + i]
    }
    group.sort()
    medians[g] = group[group.length() / 2]
    continue g + 1
  } where {
    proof_invariant: g >= 0 && g <= num_groups,
    proof_reasoning: (
      #|INVARIANT (Group median collection):
      #|For each i in [0..g), medians[i] is the median of the i-th
      #|five-element group of `a` (or the last group, which may have
      #|fewer than 5 elements).
      #|MAINTENANCE:
      #|Sort the group of size <= 5 and pick the middle element.
      #|TERMINATION:
      #|At g = num_groups every group has a recorded median.
    ),
  }
  // Step 2: recursively find the median of medians, used as pivot.
  let pivot = select_kth_inner(medians, medians.length() / 2)
  // Step 3: partition `a` around `pivot` into Less, Equal, Greater.
  // This is a three-way split (Dutch national flag) so we don't waste
  // work on equal elements.
  let less : Array[Int] = []
  let equal : Array[Int] = []
  let greater : Array[Int] = []
  for i in 0..<n {
    let v = a[i]
    if v < pivot {
      less.push(v)
    } else if v == pivot {
      equal.push(v)
    } else {
      greater.push(v)
    }
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_invariant: less.length() + equal.length() + greater.length() == i,
    proof_reasoning: (
      #|INVARIANT (Three-way partition):
      #|At iteration i, less, equal, greater together contain every
      #|element of a[0..i), each routed by its comparison with pivot:
      #|less holds strictly smaller values, equal holds copies of the
      #|pivot, and greater holds strictly larger values.
      #|MAINTENANCE:
      #|One element a[i] is routed into exactly one of the three buckets.
      #|TERMINATION:
      #|At i = n every element has been placed.
    ),
  }
  // Step 4: recurse into the bucket containing rank k.
  if k < less.length() {
    select_kth_inner(less, k)
  } else if k < less.length() + equal.length() {
    pivot
  } else {
    select_kth_inner(greater, k - less.length() - equal.length())
  }
}

///|
test "select returns each rank for small sorted array" {
  let a = [10, 20, 30, 40, 50][:]
  @debug.assert_eq(select_kth(a, 0), Some(10))
  @debug.assert_eq(select_kth(a, 1), Some(20))
  @debug.assert_eq(select_kth(a, 2), Some(30))
  @debug.assert_eq(select_kth(a, 3), Some(40))
  @debug.assert_eq(select_kth(a, 4), Some(50))
}

///|
test "select handles reverse-sorted input" {
  let a = [9, 7, 5, 3, 1][:]
  @debug.assert_eq(select_kth(a, 0), Some(1))
  @debug.assert_eq(select_kth(a, 4), Some(9))
  @debug.assert_eq(select_kth(a, 2), Some(5))
}

///|
test "select agrees with sort for many ranks" {
  // Use a moderately sized stream so the recursion fires the
  // median-of-medians branch (n > 5).
  let a = [
      12, 3, 5, 7, 4, 19, 26, 23, 2, 9, 15, 6, 1, 18, 11, 8, 17, 22, 14, 13,
    ][:]
  let sorted = a.to_owned()
  sorted.sort()
  for k in 0..<a.length() {
    @debug.assert_eq(select_kth(a, k), Some(sorted[k]))
  }
}

///|
test "select with duplicates" {
  let a = [5, 1, 5, 3, 5, 2, 5, 4, 5][:]
  // sorted: [1, 2, 3, 4, 5, 5, 5, 5, 5]
  @debug.assert_eq(select_kth(a, 0), Some(1))
  @debug.assert_eq(select_kth(a, 3), Some(4))
  @debug.assert_eq(select_kth(a, 4), Some(5))
  @debug.assert_eq(select_kth(a, 8), Some(5))
}

///|
test "select on all-equal array" {
  let a = [7, 7, 7, 7, 7, 7, 7][:]
  for k in 0..<7 {
    @debug.assert_eq(select_kth(a, k), Some(7))
  }
}

///|
test "select edge cases" {
  let empty : ReadOnlyArray[Int] = []
  @debug.assert_eq(select_kth(empty[:], 0), None)
  let one = [42][:]
  @debug.assert_eq(select_kth(one, 0), Some(42))
  @debug.assert_eq(select_kth(one, 1), None)
  @debug.assert_eq(select_kth(one, -1), None)
}

///|
test "median helper" {
  let odd = [3, 1, 4, 1, 5, 9, 2][:]
  // sorted: [1, 1, 2, 3, 4, 5, 9]; lower median = 3.
  @debug.assert_eq(median(odd), Some(3))
  let even = [3, 1, 4, 1, 5, 9, 2, 6][:]
  // sorted: [1, 1, 2, 3, 4, 5, 6, 9]; lower median = 3.
  @debug.assert_eq(median(even), Some(3))
}

///|
test "select large input correctness" {
  // 31 elements -- forces a deeper recursion through the
  // median-of-medians branch.
  let a = [
      19, 7, 14, 2, 11, 25, 30, 5, 18, 9, 1, 27, 23, 16, 3, 21, 13, 6, 28, 17, 22,
      8, 4, 24, 29, 10, 20, 15, 26, 12, 31,
    ][:]
  let sorted = a.to_owned()
  sorted.sort()
  // Spot-check a few ranks.
  @debug.assert_eq(select_kth(a, 0), Some(sorted[0]))
  @debug.assert_eq(select_kth(a, 15), Some(sorted[15])) // exact median
  @debug.assert_eq(select_kth(a, 30), Some(sorted[30]))
}
