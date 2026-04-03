// ============================================================================
// Challenge: LIS Length (O(n log n))
// Patience sorting with binary search
// ============================================================================

///|
fn lower_bound_prefix(
  arr : FixedArray[Int],
  len : Int,
  target : Int,
) -> Int where {
  proof_require: sorted_prefix(arr, len),
  proof_ensure: result => lower_bound_prefix_ok(arr, len, target, result),
} {
  for lo = 0, hi = len; lo < hi; {
    let mid = (lo + hi) / 2
    if arr[mid] < target {
      continue mid + 1, hi
    } else {
      continue lo, mid
    }
  } nobreak {
    lo
  } where {
    proof_invariant: 0 <= lo,
    proof_invariant: lo <= hi,
    proof_invariant: hi <= len,
    proof_invariant: all_less_before_prefix(arr, target, lo),
    proof_invariant: all_geq_from_prefix(arr, target, hi, len),
    reasoning: (
      #|This is the proof-carrying lower-bound kernel for the active prefix
      #|`arr[0 .. len)`.
      #|
      #|Everything before `lo` is already known to be `< target`, and
      #|everything from `hi` onward inside the active prefix is already known
      #|to be `>= target`.
      #|
      #|The midpoint comparison extends one of those two proven regions while
      #|shrinking the candidate window `[lo, hi)`.
    ),
  }
}

///|
/// Return the length of the longest increasing subsequence.
pub fn lis_length(nums : ArrayView[Int]) -> Int {
  let tails = FixedArray::make(nums.length(), 0)
  for x in nums; len = 0 {
    let pos = lower_bound_prefix(tails, len, x)
    tails[pos] = x
    if pos == len {
      continue len + 1
    } else {
      continue len
    }
  } nobreak {
    len
  }
}

///|
test "lis_length" {
  assert_eq(lis_length([10, 9, 2, 5, 3, 7, 101, 18][:]), 4)
  assert_eq(lis_length([0, 1, 0, 3, 2, 3][:]), 4)
  assert_eq(lis_length([7, 7, 7, 7][:]), 1)
  assert_eq(lis_length([][:]), 0)
}
