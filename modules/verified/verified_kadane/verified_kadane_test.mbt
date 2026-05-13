///|
/// Reference O(n^3) ground truth: enumerate every (l, r) with l <= r,
/// sum arr[l..=r], and return the maximum.
fn brute_force_max_subarray(arr : ArrayView[Int]) -> Int {
  let n = arr.length()
  let mut best = arr[0]
  for l in 0..<n {
    for r in l..<n {
      let mut s = 0
      for k in l..<=r {
        s = s + arr[k]
      }
      if s > best {
        best = s
      }
    }
  }
  best
}

///|
test "max_subarray_sum_singletons" {
  @debug.assert_eq(@verified_kadane.max_subarray_sum([1][:]), 1)
  @debug.assert_eq(@verified_kadane.max_subarray_sum([-1][:]), -1)
}

///|
test "max_subarray_sum_classic_example" {
  // Subarray [4, -1, 2, 1] gives 6.
  let arr : Array[Int] = [-2, 1, -3, 4, -1, 2, 1, -5, 4]
  @debug.assert_eq(@verified_kadane.max_subarray_sum(arr[:]), 6)
}

///|
test "max_subarray_sum_no_cuts" {
  // Whole array is best.
  let arr : Array[Int] = [5, 4, -1, 7, 8]
  @debug.assert_eq(@verified_kadane.max_subarray_sum(arr[:]), 23)
}

///|
test "max_subarray_sum_all_negatives" {
  // Best subarray is the single element with the largest value.
  let arr : Array[Int] = [-3, -2, -5, -1, -4]
  @debug.assert_eq(@verified_kadane.max_subarray_sum(arr[:]), -1)
}

///|
test "max_subarray_sum_brute_force_agreement" {
  // Compare against the O(n^3) triple loop on a length-8 array.
  let arr : Array[Int] = [3, -2, 5, -1, 6, -8, 4, -3]
  let fast = @verified_kadane.max_subarray_sum(arr[:])
  let slow = brute_force_max_subarray(arr[:])
  debug_inspect(fast, content="11")
  @debug.assert_eq(fast, slow)
}
