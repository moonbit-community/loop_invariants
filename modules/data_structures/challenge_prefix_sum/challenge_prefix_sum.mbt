// ============================================================================
// Challenge: Prefix Sum Array
// Build prefix sums with precise loop invariants
// ============================================================================

///|
fn build_prefix_sum_fixed(
  arr : FixedArray[Int],
) -> FixedArray[Int] where {
  proof_ensure: result => prefix_sum_ok(arr, result),
} {
  let n = arr.length()
  let prefix = FixedArray::make(n + 1, 0)
  for i in 0..<n; sum = 0 {
    let next = sum + arr[i]
    prefix[i + 1] = next
    continue next
  } nobreak {
    prefix
  } where {
    proof_invariant: 0 <= i,
    proof_invariant: i <= n,
    proof_invariant: prefix_prefix_ok(arr, prefix, i, sum),
    proof_reasoning: (
      #|This is the proof-carrying prefix-sum kernel.
      #|
      #|`sum` is the running prefix total for the first `i` elements, and
      #|`prefix_prefix_ok` records the exact local equations that define a
      #|prefix-sum array over the already processed region.
      #|
      #|Each step extends that relation by one position via
      #|`prefix[i + 1] = prefix[i] + arr[i]`.
    ),
  }
}

///|
/// Build prefix sums where prefix[i] = sum(arr[0..i)).
pub fn build_prefix_sum(arr : ArrayView[Int]) -> Array[Int] {
  let fixed = FixedArray::make(arr.length(), 0)
  for i, val in arr {
    fixed[i] = val
  }
  let prefix_fixed = build_prefix_sum_fixed(fixed)
  let prefix : Array[Int] = Array::make(prefix_fixed.length(), 0)
  for i in 0..<prefix_fixed.length() {
    prefix[i] = prefix_fixed[i]
  }
  prefix
}

///|
/// Range sum for inclusive bounds [l, r] using prefix sums.
pub fn range_sum(prefix : ArrayView[Int], l : Int, r : Int) -> Int {
  if l < 0 || r < l || r + 1 >= prefix.length() {
    return 0
  }
  prefix[r + 1] - prefix[l]
}

///|
test "prefix_sum" {
  let arr : Array[Int] = [3, -1, 4, 2]
  let prefix = build_prefix_sum(arr)
  @debug.assert_eq(prefix, [0, 3, 2, 6, 8])
  @debug.assert_eq(range_sum(prefix, 0, 0), 3)
  @debug.assert_eq(range_sum(prefix, 1, 2), 3) // -1 + 4
  @debug.assert_eq(range_sum(prefix, 0, 3), 8)
}
