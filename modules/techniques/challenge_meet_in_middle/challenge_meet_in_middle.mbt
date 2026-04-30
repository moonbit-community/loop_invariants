// ============================================================================
// Challenge: Meet-in-the-Middle Subset Sum
// ============================================================================

///|
fn subset_sums(arr : ArrayView[Int]) -> Array[Int] {
  let n = arr.length()
  let total = 1 << n
  let sums : Array[Int] = Array::make(total, 0)
  for mask in 0..<total {
    sums[mask] = for i in 0..<n; acc = 0 {
      if ((mask >> i) & 1) == 1 {
        continue acc + arr[i]
      } else {
        continue acc
      }
    } nobreak {
      acc
    }
  }
  sums
}

///|
fn upper_bound_fixed(
  arr : FixedArray[Int],
  target : Int,
) -> Int where {
  proof_require: sorted(arr),
  proof_ensure: result => upper_bound_ok(arr, target, result),
} {
  for lo = 0, hi = arr.length(); lo < hi; {
    let mid = lo + (hi - lo) / 2
    if arr[mid] <= target {
      continue mid + 1, hi
    } else {
      continue lo, mid
    }
  } nobreak {
    lo
  } where {
    proof_invariant: 0 <= lo,
    proof_invariant: lo <= hi,
    proof_invariant: hi <= arr.length(),
    proof_invariant: all_leq_before(arr, target, lo),
    proof_invariant: all_gt_from(arr, target, hi),
    proof_reasoning: (
      #|This is the package's proof-carrying upper-bound kernel.
      #|Every index before `lo` is already known to be `<= target`, and every
      #|index from `hi` onward is already known to be `> target`.
      #|The midpoint comparison extends one side of that proven partition while
      #|shrinking the candidate window.
    ),
  }
}

///|
/// Maximum subset sum <= target using meet-in-the-middle.
pub fn best_subset_sum_leq(nums : ArrayView[Int], target : Int) -> Int {
  let n = nums.length()
  let mid = n / 2
  let left = nums[:mid]
  let right = nums[mid:]
  let left_sums = subset_sums(left)
  let right_sums = subset_sums(right)
  right_sums.sort_by_key(x => x)
  let right_sums_fixed = FixedArray::make(right_sums.length(), 0)
  for i, val in right_sums {
    right_sums_fixed[i] = val
  }
  for val in left_sums; best = 0 {
    let remaining = target - val
    let idx = upper_bound_fixed(right_sums_fixed, remaining)
    let new_best = if idx > 0 {
      let cand = val + right_sums_fixed[idx - 1]
      if cand > best {
        cand
      } else {
        best
      }
    } else {
      best
    }
    continue new_best
  } nobreak {
    best
  }
}

///|
test "meet_in_middle" {
  let nums : Array[Int] = [3, 34, 4, 12, 5, 2]
  assert_eq(best_subset_sum_leq(nums, 9), 9)
  assert_eq(best_subset_sum_leq(nums, 10), 10)
}
