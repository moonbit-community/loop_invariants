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
fn max_non_overlapping(intervals : Array[Interval]) -> Int {
  if intervals.length() == 0 {
    return 0
  }
  intervals.sort_by_key(it => it.end)
  for it in intervals; count = 0, last_end = -1_000_000_000 {
    if it.start >= last_end {
      continue count + 1, it.end
    } else {
      continue count, last_end
    }
  } nobreak {
    count
  }
}

///|
/// Return the maximum number of non-overlapping intervals.
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
  @debug.assert_eq(max_non_overlapping(intervals), 3)
}
