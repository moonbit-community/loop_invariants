// ============================================================================
// Challenge: Binary Search on Answer
// Minimize capacity while satisfying a monotone predicate
// ============================================================================

///|
fn days_needed_fixed(
  weights : FixedArray[Int],
  capacity : Int,
) -> Int where {
  proof_require: capacity_admissible(weights, capacity),
  proof_ensure: result => days_needed_ok(weights, capacity, result),
} {
  for i in 0..<weights.length(); used = 1, load = 0 {
    let w = weights[i]
    if load + w > capacity {
      continue used + 1, w
    } else {
      continue used, load + w
    }
  } nobreak {
    used
  } where {
    proof_invariant: 0 <= i,
    proof_invariant: i <= weights.length(),
    proof_invariant: 1 <= used,
    proof_invariant: used <= i + 1,
    proof_invariant: 0 <= load,
    proof_invariant: load <= capacity,
    proof_reasoning: (
      #|This helper proves the boundedness properties of the greedy day scan.
      #|
      #|`used` is the number of days opened so far, and `load` is the current
      #|day load. Under the admissibility precondition, every processed item
      #|fits in the capacity on its own, so opening a new day still preserves
      #|`load <= capacity`.
      #|
      #|Each processed item contributes to at most one new day, which yields the
      #|simple but useful bound `used <= i + 1`.
    ),
  }
}

///|
/// Check if weights can be shipped within days using the given capacity.
pub fn can_ship(weights : ArrayView[Int], days : Int, capacity : Int) -> Bool {
  if days <= 0 {
    return false
  }
  if capacity < 0 {
    return false
  }
  let fixed = FixedArray::make(weights.length(), 0)
  for i, w in weights {
    if w < 0 {
      return false
    }
    if w > capacity {
      return false
    }
    fixed[i] = w
  }
  days_needed_fixed(fixed, capacity) <= days
}

///|
/// Minimum capacity to ship all weights within the given days.
pub fn min_capacity(weights : ArrayView[Int], days : Int) -> Int {
  let (lo, hi) = for w in weights; lo = 0, hi = 0 {
    let new_lo = if w > lo { w } else { lo }
    continue new_lo, hi + w
  } nobreak {
    (lo, hi)
  }
  for low = lo, high = hi {
    if low >= high {
      break low
    } else {
      let mid = low + (high - low) / 2
      if can_ship(weights, days, mid) {
        continue low, mid
      } else {
        continue mid + 1, high
      }
    }
  } where {
    proof_invariant: lo <= low && low <= high && high <= hi,
    proof_reasoning: (
      #|INVARIANT (Binary search bounds):
      #|The feasible capacity lies in [low, high].
      #|MAINTENANCE:
      #|If mid works, shrink to [low, mid]; otherwise shrink to [mid+1, high].
      #|TERMINATION:
      #|When low == high, it is the minimum feasible capacity.
    ),
  }
}

///|
test "min_capacity" {
  let weights : Array[Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  assert_eq(min_capacity(weights, 5), 15)
  assert_eq(min_capacity([3, 2, 2, 4, 1, 4], 3), 6)
}
