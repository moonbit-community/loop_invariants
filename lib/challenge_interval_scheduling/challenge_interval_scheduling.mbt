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
  intervals.sort_by_key(it => it.end)
  let mut count = 0
  let mut last_end = -1_000_000_000
  for it in intervals {
    if it.start >= last_end {
      count = count + 1
      last_end = it.end
    }
  }
  count
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
