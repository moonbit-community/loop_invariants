// ============================================================================
// Challenge: Meet-in-the-Middle Subset Sum
// ============================================================================

///|
fn subset_sums(arr : ArrayView[Int]) -> Array[Int] {
  let n = arr.length()
  let total = 1 << n
  let sums : Array[Int] = Array::make(total, 0)
  for mask = 0; mask < total; mask = mask + 1 {
    let sum = for i = 0, acc = 0 {
      if i >= n {
        break acc
      } else {
        let add = if ((mask >> i) & 1) == 1 { arr[i] } else { 0 }
        continue i + 1, acc + add
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (Bit accumulation):
        #|acc equals the sum of bits selected in positions [0..i).
        #|MAINTENANCE:
        #|Add arr[i] if the bit is set, then advance i.
        #|TERMINATION:
        #|At i = n, acc is the subset sum for mask.
      ),
    }
    sums[mask] = sum
  } where {
    invariant: mask >= 0 && mask <= total,
    reasoning: (
      #|INVARIANT (Subset enumeration):
      #|sums[0..mask) contains subset sums for all prior masks.
      #|MAINTENANCE:
      #|Compute sum for mask and store it.
      #|TERMINATION:
      #|At mask = total, all subset sums are generated.
    ),
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
#warnings("+missing_invariant+missing_reasoning")
fn best_subset_sum_leq(nums : ArrayView[Int], target : Int) -> Int {
  let n = nums.length()
  let mid = n / 2
  let left = nums[:mid]
  let right = nums[mid:]
  let left_sums = subset_sums(left)
  let right_sums = subset_sums(right)
  right_sums.sort_by_key(fn(x) { x })
  for i = 0, best = 0 {
    if i >= left_sums.length() {
      break best
    } else {
      let remaining = target - left_sums[i]
      let idx = upper_bound(right_sums[:], remaining)
      if idx > 0 {
        let cand = left_sums[i] + right_sums[idx - 1]
        if cand > best {
          continue i + 1, cand
        }
      }
      continue i + 1, best
    }
  } where {
    invariant: i >= 0 && i <= left_sums.length(),
    reasoning: (
      #|INVARIANT (Best so far):
      #|best is the maximum subset sum <= target using left_sums[0..i).
      #|MAINTENANCE:
      #|For left_sums[i], pick the best compatible right sum and update best.
      #|TERMINATION:
      #|At i = left_sums.length(), best is optimal.
    ),
  }
}

///|
test "meet_in_middle" {
  let nums : Array[Int] = [3, 34, 4, 12, 5, 2]
  assert_eq(best_subset_sum_leq(nums[:], 9), 9)
  assert_eq(best_subset_sum_leq(nums[:], 10), 10)
}
