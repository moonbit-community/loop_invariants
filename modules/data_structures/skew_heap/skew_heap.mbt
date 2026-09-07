// ============================================================================
// SKEW HEAP  -  Sleator & Tarjan 1986
// ============================================================================
//
// A **mergeable** min-heap that is structurally identical to a leftist
// heap *except* the rank book-keeping is dropped. Instead, **every**
// `merge` unconditionally swaps left and right children. Counter-
// intuitively, this still gives `O(log n)` *amortised* cost via a
// potential argument.
//
// MERGE
//
//   merge(Empty, h) = h
//   merge(h, Empty) = h
//   merge(t1, t2) with t1.key <= t2.key:
//     // unconditional swap of children
//     Node(t1.key, merge(t1.right, t2), t1.left)
//
// PUSH and POP reduce to merge:
//
//   push(x, h) = merge(singleton(x), h)
//   pop(h)     = merge(h.left, h.right)
//
// COMPLEXITY
//
//   merge, push, pop : O(log n) amortised
//   peek_min          : O(1) worst case
//
// THE INVARIANT
//
//   "Every internal node satisfies the heap order (parent <= children).
//    No structural invariant is maintained between merges; the random
//    swap is what gives the amortised guarantee."

///|
enum Tree {
  Empty
  Node(Int64, Tree, Tree) // key, left, right
}

///|
/// A persistent skew min-heap of `Int64` keys.
pub struct SkewHeap {
  root : Tree
  size : Int
}

///|
fn merge_trees(t1 : Tree, t2 : Tree) -> Tree {
  match (t1, t2) {
    (Empty, h) => h
    (h, Empty) => h
    (Node(k1, l1, r1), Node(k2, _, _)) =>
      if k1 <= k2 {
        // Unconditional left/right swap.
        Node(k1, merge_trees(r1, t2), l1)
      } else {
        match t2 {
          Node(k2_, l2, r2) => Node(k2_, merge_trees(t1, r2), l2)
          Empty => t1
        }
      }
  }
}

///|
/// Empty heap.
pub fn SkewHeap::new() -> SkewHeap {
  { root: Empty, size: 0, }
}

///|
/// Insert a key.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let h = @skew_heap.new().push(3L).push(1L).push(2L)
///   @debug.assert_eq(h.peek_min(), Some(1L))
/// }
/// ```
pub fn SkewHeap::push(self : SkewHeap, key : Int64) -> SkewHeap {
  let leaf : Tree = Node(key, Empty, Empty)
  { root: merge_trees(self.root, leaf), size: self.size + 1, }
}

///|
/// Minimum, if present.
pub fn SkewHeap::peek_min(self : SkewHeap) -> Int64? {
  match self.root {
    Empty => None
    Node(k, _, _) => Some(k)
  }
}

///|
/// Remove the minimum. Returns `(key, new_heap)`, or `None` for empty.
pub fn SkewHeap::pop_min(self : SkewHeap) -> (Int64, SkewHeap)? {
  match self.root {
    Empty => None
    Node(k, l, r) =>
      Some((k, { root: merge_trees(l, r), size: self.size - 1, }))
  }
}

///|
/// Merge two heaps. Both originals are unchanged.
pub fn SkewHeap::merge(self : SkewHeap, other : SkewHeap) -> SkewHeap {
  { root: merge_trees(self.root, other.root), size: self.size + other.size, }
}

///|
/// Number of elements.
pub fn SkewHeap::length(self : SkewHeap) -> Int {
  self.size
}

///|
/// `true` iff the heap is empty.
pub fn SkewHeap::is_empty(self : SkewHeap) -> Bool {
  self.size == 0
}

///|
test "skew basic push pop" {
  let h = SkewHeap::new()
    .push(3L)
    .push(1L)
    .push(4L)
    .push(1L)
    .push(5L)
    .push(9L)
    .push(2L)
    .push(6L)
  @debug.assert_eq(h.peek_min(), Some(1L))
  let out : Array[Int64] = []
  let mut cur = h
  while !cur.is_empty() {
    match cur.pop_min() {
      Some((k, h2)) => {
        out.push(k)
        cur = h2
      }
      None => break
    }
  }
  @debug.assert_eq(out, [1L, 1L, 2L, 3L, 4L, 5L, 6L, 9L])
}

///|
test "skew empty operations" {
  let h = SkewHeap::new()
  @debug.assert_eq(h.peek_min(), None)
  @debug.assert_eq(h.length(), 0)
  @debug.assert_eq(h.is_empty(), true)
  match h.pop_min() {
    None => ()
    Some(_) => @debug.assert_eq(true, false)
  }
}

///|
test "skew persistence" {
  let h1 = SkewHeap::new().push(5L).push(3L)
  let h2 = h1.push(1L)
  @debug.assert_eq(h1.peek_min(), Some(3L))
  @debug.assert_eq(h2.peek_min(), Some(1L))
}

///|
test "skew merge" {
  let a = SkewHeap::new().push(1L).push(7L).push(3L)
  let b = SkewHeap::new().push(2L).push(8L).push(0L)
  let m = a.merge(b)
  @debug.assert_eq(m.length(), 6)
  let out : Array[Int64] = []
  let mut cur = m
  while !cur.is_empty() {
    match cur.pop_min() {
      Some((k, h)) => {
        out.push(k)
        cur = h
      }
      None => break
    }
  }
  @debug.assert_eq(out, [0L, 1L, 2L, 3L, 7L, 8L])
}

///|
test "skew sort" {
  let mut h = SkewHeap::new()
  let input : ReadOnlyArray[Int64] = [
    13L, 7L, 1L, 17L, 4L, 9L, 2L, 11L, 8L, 5L, 0L, 16L, 12L,
  ]
  for x in input {
    h = h.push(x)
  }
  let sorted : Array[Int64] = []
  while !h.is_empty() {
    match h.pop_min() {
      Some((k, h2)) => {
        sorted.push(k)
        h = h2
      }
      None => break
    }
  }
  @debug.assert_eq(sorted, [
    0L, 1L, 2L, 4L, 5L, 7L, 8L, 9L, 11L, 12L, 13L, 16L, 17L,
  ])
}

///|
test "skew larger amortised stress" {
  let mut h = SkewHeap::new()
  for i in 0L..<1000L {
    h = h.push(i * 31L % 997L)
  }
  @debug.assert_eq(h.length(), 1000)
  // 31 and 997 are coprime, so 0 is hit.
  @debug.assert_eq(h.peek_min(), Some(0L))
}
