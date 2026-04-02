// ============================================================================
// Challenge: Line Sweep for Maximum Overlap
// ============================================================================

///|
priv struct Event {
  pos : Int
  delta : Int
}

///|
/// Compute the maximum number of overlapping intervals.
pub fn max_overlap(intervals : ArrayView[(Int, Int)]) -> Int {
  let events : Array[Event] = []
  for interval in intervals {
    let (l, r) = interval
    if l <= r {
      events.push({ pos: l, delta: 1 })
      events.push({ pos: r + 1, delta: -1 })
    }
  }
  events.sort_by((a, b) => {
    if a.pos < b.pos {
      -1
    } else if a.pos > b.pos {
      1
    } else {
      a.delta - b.delta
    }
  })
  let mut cur = 0
  let mut best = 0
  for ev in events {
    cur = cur + ev.delta
    if cur > best {
      best = cur
    }
  }
  best
}

///|
test "max_overlap" {
  let intervals : Array[(Int, Int)] = [(1, 3), (2, 5), (4, 6)]
  assert_eq(max_overlap(intervals[:]), 2)
  let intervals2 : Array[(Int, Int)] = [(1, 2), (3, 4)]
  assert_eq(max_overlap(intervals2[:]), 1)
}
