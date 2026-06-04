// ============================================================================
// MIN-MAX HEAP  -  Atkinson, Sack, Santoro, Strothotte 1986
// ============================================================================
//
// A binary heap that supports **both** O(log n) min-extract and
// O(log n) max-extract on the same structure. Encodes both orderings
// by alternating min/max levels in a single array:
//
//   Level 0 (root): min
//   Level 1: max
//   Level 2: min
//   Level 3: max
//   ...
//
// The minimum is the root; the maximum is the larger of the two root
// children (the level-1 maxes).
//
// COMPLEXITY
//
//   push        : O(log n)
//   peek_min    : O(1)
//   peek_max    : O(1)
//   pop_min     : O(log n)
//   pop_max     : O(log n)
//
// THE INVARIANT
//
//   For any node at a min-level, it is less than or equal to every
//   descendant.
//   For any node at a max-level, it is greater than or equal to every
//   descendant.

///|
/// A min-max heap of `Int64`.
pub struct MinMaxHeap {
  data : Array[Int64]
}

///|
/// Empty heap.
pub fn MinMaxHeap::new() -> MinMaxHeap {
  { data: [] }
}

///|
/// Number of elements.
pub fn MinMaxHeap::length(self : MinMaxHeap) -> Int {
  self.data.length()
}

///|
/// `true` iff the heap is empty.
pub fn MinMaxHeap::is_empty(self : MinMaxHeap) -> Bool {
  self.data.length() == 0
}

///|
fn level(i : Int) -> Int {
  // 0-indexed level: floor(log2(i + 1)).
  let mut x = i + 1
  let mut l = 0
  while x > 1 {
    x = x >> 1
    l = l + 1
  }
  l
}

///|
fn is_min_level(i : Int) -> Bool {
  level(i) % 2 == 0
}

///|
fn MinMaxHeap::swap(self : MinMaxHeap, a : Int, b : Int) -> Unit {
  let t = self.data[a]
  self.data[a] = self.data[b]
  self.data[b] = t
}

///|
fn parent(i : Int) -> Int {
  (i - 1) / 2
}

///|
fn has_parent(i : Int) -> Bool {
  i > 0
}

///|
fn has_grandparent(i : Int) -> Bool {
  i > 2
}

///|
fn grandparent(i : Int) -> Int {
  ((i - 1) / 2 - 1) / 2
}

///|
fn MinMaxHeap::push_up(self : MinMaxHeap, i : Int) -> Unit {
  if !has_parent(i) {
    return
  }
  let p = parent(i)
  if is_min_level(i) {
    if self.data[i] > self.data[p] {
      self.swap(i, p)
      self.push_up_aux(p, false) // now in a max-level
    } else {
      self.push_up_aux(i, true)
    }
  } else if self.data[i] < self.data[p] {
    self.swap(i, p)
    self.push_up_aux(p, true)
  } else {
    self.push_up_aux(i, false)
  }
}

///|
fn MinMaxHeap::push_up_aux(
  self : MinMaxHeap,
  i : Int,
  on_min_level : Bool,
) -> Unit {
  // Repeatedly compare with grandparent on the same min/max sense.
  let mut cur = i
  while has_grandparent(cur) {
    let g = grandparent(cur)
    if on_min_level {
      if self.data[cur] < self.data[g] {
        self.swap(cur, g)
        cur = g
      } else {
        break
      }
    } else if self.data[cur] > self.data[g] {
      self.swap(cur, g)
      cur = g
    } else {
      break
    }
  }
}

///|
/// Insert a key.
pub fn MinMaxHeap::push(self : MinMaxHeap, x : Int64) -> Unit {
  self.data.push(x)
  self.push_up(self.data.length() - 1)
}

///|
/// Minimum element (or `None`).
pub fn MinMaxHeap::peek_min(self : MinMaxHeap) -> Int64? {
  if self.data.length() == 0 {
    None
  } else {
    Some(self.data[0])
  }
}

///|
/// Maximum element (or `None`).
pub fn MinMaxHeap::peek_max(self : MinMaxHeap) -> Int64? {
  let n = self.data.length()
  if n == 0 {
    return None
  }
  if n == 1 {
    return Some(self.data[0])
  }
  if n == 2 {
    return Some(self.data[1])
  }
  Some(if self.data[1] > self.data[2] { self.data[1] } else { self.data[2] })
}

///|
fn MinMaxHeap::smallest_descendant_index(self : MinMaxHeap, root : Int) -> Int {
  // Return the index (root, children, grandchildren) with the smallest
  // value in this min-level subtree (for trickle-down on pop_min).
  let n = self.data.length()
  let mut best = root
  // Children indices: 2*root+1, 2*root+2.
  let candidates : Array[Int] = [
    2 * root + 1,
    2 * root + 2,
    4 * root + 3,
    4 * root + 4,
    4 * root + 5,
    4 * root + 6,
  ]
  for c in candidates {
    if c < n && self.data[c] < self.data[best] {
      best = c
    }
  }
  best
}

///|
fn MinMaxHeap::largest_descendant_index(self : MinMaxHeap, root : Int) -> Int {
  let n = self.data.length()
  let mut best = root
  let candidates : Array[Int] = [
    2 * root + 1,
    2 * root + 2,
    4 * root + 3,
    4 * root + 4,
    4 * root + 5,
    4 * root + 6,
  ]
  for c in candidates {
    if c < n && self.data[c] > self.data[best] {
      best = c
    }
  }
  best
}

///|
fn MinMaxHeap::trickle_down_min(self : MinMaxHeap, idx : Int) -> Unit {
  let mut i = idx
  let mut keep_going = true
  while keep_going {
    let m = self.smallest_descendant_index(i)
    if m == i {
      return
    }
    if m > 2 * i + 2 {
      // m is a grandchild.
      if self.data[m] < self.data[i] {
        self.swap(m, i)
        let p = parent(m)
        if self.data[m] > self.data[p] {
          self.swap(m, p)
        }
        i = m
      } else {
        keep_going = false
      }
    } else {
      // m is a child.
      if self.data[m] < self.data[i] {
        self.swap(m, i)
      }
      keep_going = false
    }
  }
}

///|
fn MinMaxHeap::trickle_down_max(self : MinMaxHeap, idx : Int) -> Unit {
  let mut i = idx
  let mut keep_going = true
  while keep_going {
    let m = self.largest_descendant_index(i)
    if m == i {
      return
    }
    if m > 2 * i + 2 {
      if self.data[m] > self.data[i] {
        self.swap(m, i)
        let p = parent(m)
        if self.data[m] < self.data[p] {
          self.swap(m, p)
        }
        i = m
      } else {
        keep_going = false
      }
    } else {
      if self.data[m] > self.data[i] {
        self.swap(m, i)
      }
      keep_going = false
    }
  }
}

///|
/// Remove and return the minimum.
pub fn MinMaxHeap::pop_min(self : MinMaxHeap) -> Int64? {
  let n = self.data.length()
  if n == 0 {
    return None
  }
  let min = self.data[0]
  if n == 1 {
    self.data.pop() |> ignore
    return Some(min)
  }
  self.data[0] = self.data[n - 1]
  self.data.pop() |> ignore
  self.trickle_down_min(0)
  Some(min)
}

///|
/// Remove and return the maximum.
pub fn MinMaxHeap::pop_max(self : MinMaxHeap) -> Int64? {
  let n = self.data.length()
  if n == 0 {
    return None
  }
  if n == 1 {
    let v = self.data[0]
    self.data.pop() |> ignore
    return Some(v)
  }
  if n == 2 {
    let v = self.data[1]
    self.data.pop() |> ignore
    return Some(v)
  }
  let max_idx = if self.data[1] > self.data[2] { 1 } else { 2 }
  let max = self.data[max_idx]
  self.data[max_idx] = self.data[n - 1]
  self.data.pop() |> ignore
  if max_idx < self.data.length() {
    self.trickle_down_max(max_idx)
  }
  Some(max)
}

///|
test "mmh basic push and peek" {
  let h = MinMaxHeap::new()
  h.push(5L)
  h.push(2L)
  h.push(8L)
  h.push(1L)
  h.push(7L)
  @debug.assert_eq(h.peek_min(), Some(1L))
  @debug.assert_eq(h.peek_max(), Some(8L))
}

///|
test "mmh pop min order" {
  let h = MinMaxHeap::new()
  for x in [5L, 3L, 8L, 1L, 9L, 2L, 7L, 4L, 6L] {
    h.push(x)
  }
  let out : Array[Int64] = []
  while !h.is_empty() {
    match h.pop_min() {
      Some(v) => out.push(v)
      None => break
    }
  }
  @debug.assert_eq(out, [1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L])
}

///|
test "mmh pop max order" {
  let h = MinMaxHeap::new()
  for x in [5L, 3L, 8L, 1L, 9L, 2L, 7L, 4L, 6L] {
    h.push(x)
  }
  let out : Array[Int64] = []
  while !h.is_empty() {
    match h.pop_max() {
      Some(v) => out.push(v)
      None => break
    }
  }
  @debug.assert_eq(out, [9L, 8L, 7L, 6L, 5L, 4L, 3L, 2L, 1L])
}

///|
test "mmh interleaved pops" {
  let h = MinMaxHeap::new()
  for x in 1L..<=10L {
    h.push(x)
  }
  @debug.assert_eq(h.pop_min(), Some(1L))
  @debug.assert_eq(h.pop_max(), Some(10L))
  @debug.assert_eq(h.pop_min(), Some(2L))
  @debug.assert_eq(h.pop_max(), Some(9L))
  @debug.assert_eq(h.length(), 6)
}

///|
test "mmh empty" {
  let h = MinMaxHeap::new()
  @debug.assert_eq(h.peek_min(), None)
  @debug.assert_eq(h.peek_max(), None)
  @debug.assert_eq(h.pop_min(), None)
  @debug.assert_eq(h.pop_max(), None)
}

///|
test "mmh single element" {
  let h = MinMaxHeap::new()
  h.push(42L)
  @debug.assert_eq(h.peek_min(), Some(42L))
  @debug.assert_eq(h.peek_max(), Some(42L))
  @debug.assert_eq(h.pop_max(), Some(42L))
  @debug.assert_eq(h.is_empty(), true)
}
