// ============================================================================
// Challenge: Meet-in-the-Middle Subset Sum
// ============================================================================

///|
fn subset_sums(arr : ArrayView[Int]) -> Array[Int] {
  let n = arr.length()
  let total = 1 << n
  let sums : Array[Int] = Array::make(total, 0)
  for mask in 0..<total {
    let mut acc = 0
    for i in 0..<n {
      if ((mask >> i) & 1) == 1 {
        acc = acc + arr[i]
      }
    }
    sums[mask] = acc
  }
  sums
}

///|
fn upper_bound(arr : ArrayView[Int], target : Int) -> Int {
  for lo = 0, hi = arr.length() {
    if lo >= hi {
      break lo
    } else {
      let mid = lo + (hi - lo) / 2
      if arr[mid] <= target {
        continue mid + 1, hi
      } else {
        continue lo, mid
      }
    }
  } where {
    invariant: lo >= 0 && lo <= hi && hi <= arr.length(),
    reasoning: (
      #|INVARIANT (Upper bound):
      #|All indices < lo are <= target and all indices >= hi are > target.
      #|MAINTENANCE:
      #|Shrink [lo, hi) based on mid comparison.
      #|TERMINATION:
      #|At lo = hi, lo is the first index with arr[lo] > target.
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
  let mut best = 0
  for val in left_sums {
    let remaining = target - val
    let idx = upper_bound(right_sums[:], remaining)
    if idx > 0 {
      let cand = val + right_sums[idx - 1]
      if cand > best {
        best = cand
      }
    }
  }
  best
}

///|
test "meet_in_middle" {
  let nums : Array[Int] = [3, 34, 4, 12, 5, 2]
  assert_eq(best_subset_sum_leq(nums[:], 9), 9)
  assert_eq(best_subset_sum_leq(nums[:], 10), 10)
}
