// ============================================================================
// Challenge: Interval Scheduling (Greedy by End Time)
// Select maximum number of non-overlapping intervals
// ============================================================================

///|
priv struct Interval {
  start : Int
  end : Int
}

///|
/// Return the maximum number of non-overlapping intervals.
#warnings("+missing_invariant+missing_reasoning")
fn max_non_overlapping(intervals : Array[Interval]) -> Int {
  if intervals.length() == 0 {
    return 0
  }
  intervals.sort_by_key(fn(it) { it.end })
  for i = 0, count = 0, last_end = -1_000_000_000 {
    if i >= intervals.length() {
      break count
    } else {
      let it = intervals[i]
      if it.start >= last_end {
        continue i + 1, count + 1, it.end
      } else {
        continue i + 1, count, last_end
      }
    }
  } where {
    invariant: i >= 0 && i <= intervals.length(),
    invariant: count >= 0,
    reasoning: (
      #|INVARIANT (Greedy selection):
      #|count is the number of selected non-overlapping intervals among
      #|intervals[0..i) in end-time order, and last_end is the end of the
      #|most recently selected interval (or a sentinel if none selected).
      #|MAINTENANCE:
      #|If intervals[i] starts after the last chosen end, select it; otherwise
      #|skip it. Greedy by earliest end preserves optimality.
      #|TERMINATION:
      #|At i = n, count is the maximum number of non-overlapping intervals.
    ),
  }
}

///|
/// Return the maximum number of non-overlapping intervals.
#warnings("-missing_invariant-missing_reasoning")
pub fn max_non_overlapping_pairs(intervals : ArrayView[(Int, Int)]) -> Int {
  let arr : Array[Interval] = []
  for pair in intervals {
    let (start, end) = pair
    arr.push({ start, end })
  }
  max_non_overlapping(arr)
}

///|
test "interval_scheduling" {
  let intervals : Array[Interval] = [
    { start: 1, end: 3 },
    { start: 2, end: 4 },
    { start: 3, end: 5 },
    { start: 0, end: 7 },
    { start: 5, end: 9 },
    { start: 8, end: 9 },
  ]
  assert_eq(max_non_overlapping(intervals), 3)
}
