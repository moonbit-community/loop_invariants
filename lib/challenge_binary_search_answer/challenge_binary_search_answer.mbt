// ============================================================================
// Challenge: Binary Search on Answer
// Minimize capacity while satisfying a monotone predicate
// ============================================================================

///|
/// Check if weights can be shipped within days using the given capacity.
#warnings("+missing_invariant+missing_reasoning")
pub fn can_ship(weights : ArrayView[Int], days : Int, capacity : Int) -> Bool {
  if days <= 0 {
    return false
  }
  for i = 0, used = 1, load = 0 {
    if i >= weights.length() {
      break used <= days
    } else if weights[i] > capacity {
      break false
    } else if load + weights[i] > capacity {
      continue i + 1, used + 1, weights[i]
    } else {
      continue i + 1, used, load + weights[i]
    }
  } where {
    invariant: i >= 0 && i <= weights.length(),
    invariant: used >= 1 && load >= 0 && load <= capacity,
    reasoning: (
      #|INVARIANT (Shipping state):
      #|The first i items are assigned to 'used' days, and load is the total
      #|weight loaded on the current day (never exceeding capacity).
      #|MAINTENANCE:
      #|If the next item fits, add it to load; otherwise, start a new day
      #|with that item as the first load.
      #|TERMINATION:
      #|At i = weights.length(), we succeeded iff used <= days.
    ),
  }
}

///|
/// Minimum capacity to ship all weights within the given days.
#warnings("+missing_invariant+missing_reasoning")
pub fn min_capacity(weights : ArrayView[Int], days : Int) -> Int {
  let mut lo = 0
  let mut hi = 0
  for w in weights {
    if w > lo {
      lo = w
    }
    hi = hi + w
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
    invariant: lo <= low && low <= high && high <= hi,
    reasoning: (
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
  assert_eq(min_capacity(weights[:], 5), 15)
  assert_eq(min_capacity([3, 2, 2, 4, 1, 4][:], 3), 6)
}
