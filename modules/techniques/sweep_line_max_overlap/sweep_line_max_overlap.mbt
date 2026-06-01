// ============================================================================
// MAXIMUM INTERVAL OVERLAP  -  O(n log n) line sweep
// ============================================================================
//
// PROBLEM
//
// Given `n` half-open intervals `[l_i, r_i)`, find the **maximum
// number of intervals that simultaneously contain a single point**.
// Also report a witness point where that maximum is achieved.
//
// CLASSIC APPLICATION: minimum number of rooms / channels / locks
// needed to schedule overlapping reservations.
//
// THE ALGORITHM
//
// Emit two events per interval -- (start, +1) and (end, -1) -- sort by
// coordinate, breaking ties so that **-1 (end) comes before +1 (start)**
// (so that touching intervals `[0, 5)` and `[5, 10)` are *not* counted
// as overlapping). Scan; track the running sum and its maximum.
//
// COMPLEXITY
//
//   Time : O(n log n) -- the sort dominates
//   Space: O(n) for the events array
//
// THE INVARIANT
//
//   "After processing the first k events in sorted order, the running
//    counter equals the number of intervals that contain a point
//    slightly to the right of the last processed event."

///|
/// Maximum number of intervals overlapping at a single point. Each
/// interval is a half-open pair `(l, r)` with `l < r`. Returns
/// `(max_overlap, witness_point)`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let ivs = [(1L, 5L), (2L, 6L), (4L, 7L)]
///   let r = @sweep_line_max_overlap.max_overlap(ivs)
///   @debug.assert_eq(r.0, 3) // point 4 is in all three intervals
/// }
/// ```
pub fn max_overlap(intervals : Array[(Int64, Int64)]) -> (Int, Int64) {
  let n = intervals.length()
  if n == 0 {
    return (0, 0L)
  }
  // Events: (coord, delta). Delta = +1 at start, -1 at end. Sort by
  // coord; on tie, +1 first.
  let events = Array::make(2 * n, (0L, 0))
  for i in 0..<n {
    let (l, r) = intervals[i]
    events[2 * i] = (l, 1)
    events[2 * i + 1] = (r, -1)
  }
  sort_events(events, 0, events.length())
  let mut cur = 0
  let mut best = 0
  let mut best_point = events[0].0
  for e in events {
    cur = cur + e.1
    if cur > best {
      best = cur
      best_point = e.0
    }
  }
  (best, best_point)
}

///|
fn sort_events(arr : Array[(Int64, Int)], lo : Int, hi : Int) -> Unit {
  if hi - lo <= 1 {
    return
  }
  let mid = lo + (hi - lo) / 2
  sort_events(arr, lo, mid)
  sort_events(arr, mid, hi)
  merge(arr, lo, mid, hi)
}

///|
fn merge(arr : Array[(Int64, Int)], lo : Int, mid : Int, hi : Int) -> Unit {
  let buf = Array::make(hi - lo, (0L, 0))
  let mut i = lo
  let mut j = mid
  let mut k = 0
  while i < mid && j < hi {
    if cmp_event(arr[i], arr[j]) <= 0 {
      buf[k] = arr[i]
      i = i + 1
    } else {
      buf[k] = arr[j]
      j = j + 1
    }
    k = k + 1
  }
  while i < mid {
    buf[k] = arr[i]
    i = i + 1
    k = k + 1
  }
  while j < hi {
    buf[k] = arr[j]
    j = j + 1
    k = k + 1
  }
  for x in 0..<(hi - lo) {
    arr[lo + x] = buf[x]
  }
}

///|
fn cmp_event(a : (Int64, Int), b : (Int64, Int)) -> Int {
  if a.0 < b.0 {
    -1
  } else if a.0 > b.0 {
    1
    // Same coord: -1 (end) before +1 (start) so touching half-open
    // intervals [0, 5) and [5, 10) do not double-count at 5. Smaller
    // delta first.
  } else if a.1 < b.1 {
    -1
  } else if a.1 > b.1 {
    1
  } else {
    0
  }
}

///|
test "overlap classic" {
  let ivs : Array[(Int64, Int64)] = [(1L, 5L), (2L, 6L), (4L, 7L)]
  let (n, p) = max_overlap(ivs)
  @debug.assert_eq(n, 3)
  @debug.assert_eq(p, 4L)
}

///|
test "overlap touching intervals not overlapping" {
  // [0, 5) and [5, 10): point 5 is in the second only.
  let ivs : Array[(Int64, Int64)] = [(0L, 5L), (5L, 10L)]
  let (n, _) = max_overlap(ivs)
  @debug.assert_eq(n, 1)
}

///|
test "overlap empty" {
  let ivs : Array[(Int64, Int64)] = []
  let (n, _) = max_overlap(ivs)
  @debug.assert_eq(n, 0)
}

///|
test "overlap single" {
  let ivs : Array[(Int64, Int64)] = [(2L, 10L)]
  let (n, p) = max_overlap(ivs)
  @debug.assert_eq(n, 1)
  @debug.assert_eq(p, 2L)
}

///|
test "overlap many same start" {
  // 5 intervals all starting at 0, ending at 1, 2, 3, 4, 5.
  let ivs : Array[(Int64, Int64)] = [
    (0L, 1L),
    (0L, 2L),
    (0L, 3L),
    (0L, 4L),
    (0L, 5L),
  ]
  let (n, p) = max_overlap(ivs)
  @debug.assert_eq(n, 5)
  @debug.assert_eq(p, 0L)
}

///|
test "overlap nested intervals" {
  // [0, 10), [1, 9), [2, 8), [3, 7), [4, 6): max overlap = 5.
  let ivs : Array[(Int64, Int64)] = [
    (0L, 10L),
    (1L, 9L),
    (2L, 8L),
    (3L, 7L),
    (4L, 6L),
  ]
  let (n, _) = max_overlap(ivs)
  @debug.assert_eq(n, 5)
}

///|
test "overlap disjoint" {
  let ivs : Array[(Int64, Int64)] = [(0L, 1L), (2L, 3L), (4L, 5L), (6L, 7L)]
  let (n, _) = max_overlap(ivs)
  @debug.assert_eq(n, 1)
}

///|
test "overlap agrees with brute force" {
  fn brute(ivs : Array[(Int64, Int64)]) -> Int {
    // Sweep all coordinate-and-coordinate+0.5 candidate points.
    let candidates : Array[Int64] = []
    for iv in ivs {
      candidates.push(iv.0)
      candidates.push(iv.1 - 1L)
    }
    let mut best = 0
    for p in candidates {
      let mut c = 0
      for iv in ivs {
        if iv.0 <= p && p < iv.1 {
          c = c + 1
        }
      }
      if c > best {
        best = c
      }
    }
    best
  }

  let cases : ReadOnlyArray[Array[(Int64, Int64)]] = [
    [(1L, 5L), (3L, 8L), (4L, 6L), (2L, 7L)],
    [(0L, 100L), (10L, 20L), (15L, 25L)],
    [(1L, 2L), (2L, 3L), (3L, 4L)],
  ]
  for c in cases {
    let (n, _) = max_overlap(c)
    @debug.assert_eq(n, brute(c))
  }
}
