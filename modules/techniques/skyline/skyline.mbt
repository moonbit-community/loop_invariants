// ============================================================================
// SKYLINE PROBLEM  -  sweep line + lazy max-heap
// ============================================================================
//
// PROBLEM
//
// Given a list of rectangles `(left, right, height)` representing
// buildings projected against a horizontal x-axis, return the
// **outline** of their silhouette as a sequence of `(x, height)`
// key points where the height changes.
//
// THE ALGORITHM
//
// Sweep left-to-right over **events**:
//
//   - At each building's left edge `l`, push its `height` into an
//     active max-heap.
//   - At each building's right edge `r`, mark the building's height as
//     expired (lazy removal).
//   - The current skyline height equals the *non-expired* root of the heap.
//   - When the height changes between events, emit a key point.
//
// COMPLEXITY
//
//   Time : O(n log n)
//   Space: O(n)
//
// THE INVARIANT
//
//   "After processing the events at x = X, the heap's active root
//    equals the height of the skyline at x = X."

///|
priv struct HeapEntry {
  height : Int64
  expires_at : Int64
}

///|
priv struct MaxHeap {
  data : Array[HeapEntry]
}

///|
fn MaxHeap::new() -> MaxHeap {
  { data: [] }
}

///|
fn MaxHeap::push(self : MaxHeap, e : HeapEntry) -> Unit {
  self.data.push(e)
  let mut i = self.data.length() - 1
  while i > 0 {
    let p = (i - 1) / 2
    if self.data[i].height > self.data[p].height {
      let t = self.data[i]
      self.data[i] = self.data[p]
      self.data[p] = t
      i = p
    } else {
      break
    }
  }
}

///|
fn MaxHeap::pop(self : MaxHeap) -> Unit {
  let n = self.data.length()
  if n == 0 {
    return
  }
  let last = self.data[n - 1]
  self.data.pop() |> ignore
  if n == 1 {
    return
  }
  self.data[0] = last
  let m = self.data.length()
  let mut i = 0
  while true {
    let l = 2 * i + 1
    let r = 2 * i + 2
    let mut best = i
    if l < m && self.data[l].height > self.data[best].height {
      best = l
    }
    if r < m && self.data[r].height > self.data[best].height {
      best = r
    }
    if best == i {
      break
    }
    let t = self.data[i]
    self.data[i] = self.data[best]
    self.data[best] = t
    i = best
  }
}

///|
fn MaxHeap::peek_height(self : MaxHeap, now : Int64) -> Int64 {
  while self.data.length() > 0 && self.data[0].expires_at <= now {
    self.pop()
  }
  if self.data.length() == 0 {
    0L
  } else {
    self.data[0].height
  }
}

///|
/// Compute the skyline of a building list. Input is
/// `[(left, right, height), ...]`. Returns the silhouette as a
/// `(x, height)` array. The final point has height `0` indicating
/// the trailing right edge.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   // Two stacked rectangles produce a multi-step skyline.
///   let s = @skyline.compute([(0L, 4L, 5L), (2L, 6L, 3L)])
///   @debug.assert_eq(s.length() > 0, true)
/// }
/// ```
pub fn compute(
  buildings : Array[(Int64, Int64, Int64)],
) -> Array[(Int64, Int64)] {
  let n = buildings.length()
  // Events: (x, +height for start, -height for end). Sort by x.
  let events : Array[(Int64, Int, Int64, Int64)] = []
  for b in buildings {
    let (l, r, h) = b
    // start: type 0, end: type 1.
    events.push((l, 0, h, r))
    events.push((r, 1, h, r))
  }
  sort_events(events, 0, events.length())
  let res : Array[(Int64, Int64)] = []
  let heap = MaxHeap::new()
  let mut i = 0
  let mut prev_height = 0L
  while i < events.length() {
    let x = events[i].0
    // Process all events at this x.
    while i < events.length() && events[i].0 == x {
      let ev = events[i]
      if ev.1 == 0 {
        heap.push({ height: ev.2, expires_at: ev.3 })
      }
      i = i + 1
    }
    let cur = heap.peek_height(x)
    if cur != prev_height {
      res.push((x, cur))
      prev_height = cur
    }
  }
  let _ = n
  res
}

///|
fn sort_events(
  arr : Array[(Int64, Int, Int64, Int64)],
  lo : Int,
  hi : Int,
) -> Unit {
  if hi - lo <= 1 {
    return
  }
  let mid = lo + (hi - lo) / 2
  sort_events(arr, lo, mid)
  sort_events(arr, mid, hi)
  let buf = Array::make(hi - lo, (0L, 0, 0L, 0L))
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
fn cmp_event(
  a : (Int64, Int, Int64, Int64),
  b : (Int64, Int, Int64, Int64),
) -> Int {
  if a.0 < b.0 {
    -1
  } else if a.0 > b.0 {
    1
  } else if a.1 < b.1 {
    -1
  } else if a.1 > b.1 {
    1
  } else {
    0
  }
}

///|
test "skyline simple" {
  // Three buildings: heights 5, 3, 5 at columns [0,4), [2,6), [4,8).
  let s = compute([(0L, 4L, 5L), (2L, 6L, 3L), (4L, 8L, 5L)])
  // Expected key points: (0, 5), (6, 0). Actually heights 5 throughout
  // until x=8, with a dip? Let's hand-trace:
  // x in [0, 4): tallest is 5 (from first building). Profile = 5.
  // x in [4, 6): first ends, second still there (3) and third begins (5). Max = 5.
  // x in [6, 8): only third remains, height 5.
  // x in [8, inf): height 0.
  @debug.assert_eq(s, [(0L, 5L), (8L, 0L)])
}

///|
test "skyline classic LC 218 example" {
  // [[2,9,10],[3,7,15],[5,12,12],[15,20,10],[19,24,8]]
  let bs = [
    (2L, 9L, 10L),
    (3L, 7L, 15L),
    (5L, 12L, 12L),
    (15L, 20L, 10L),
    (19L, 24L, 8L),
  ]
  let s = compute(bs)
  let expected : Array[(Int64, Int64)] = [
    (2L, 10L),
    (3L, 15L),
    (7L, 12L),
    (12L, 0L),
    (15L, 10L),
    (20L, 8L),
    (24L, 0L),
  ]
  @debug.assert_eq(s, expected)
}

///|
test "skyline empty" {
  @debug.assert_eq(compute([]), [])
}

///|
test "skyline single building" {
  @debug.assert_eq(compute([(0L, 5L, 3L)]), [(0L, 3L), (5L, 0L)])
}

///|
test "skyline same height adjacency" {
  // Two adjacent equal-height buildings produce a single roof line.
  let s = compute([(0L, 5L, 4L), (5L, 10L, 4L)])
  @debug.assert_eq(s, [(0L, 4L), (10L, 0L)])
}
