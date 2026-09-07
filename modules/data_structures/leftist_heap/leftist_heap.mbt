// ============================================================================
// LEFTIST HEAP  -  Crane 1972
// ============================================================================
//
// A **mergeable min-heap** with O(log n) push / pop / merge. The key
// idea: each node stores an `s-value` (also called "rank" or "null
// path length"), the length of the shortest path from the node to a
// `Empty` child, and the tree is built so that the right child always
// has the smaller s-value. This forces the right spine to have length
// `O(log n)`, which is where `merge` recurses.
//
// THE LEFTIST PROPERTY
//
// For every internal node `t`:
//   rank(t.right) <= rank(t.left)
//
// As a consequence, `rank(t) = rank(t.right) + 1` and the right
// spine has at most `floor(log2(n + 1))` nodes.
//
// MERGE (the workhorse)
//
//   merge(Empty, h) = h
//   merge(h, Empty) = h
//   merge(t1, t2): put the smaller root on top, recursively merge the
//   *right* child with the other heap; fix up so the leftist property
//   holds.
//
// All other operations are expressible in terms of merge:
//
//   push(x, h)   = merge(singleton(x), h)
//   pop(h)       = merge(h.left, h.right)
//
// COMPLEXITY
//
//   push, pop, merge : O(log n)
//   peek_min          : O(1)
//
// THE INVARIANT
//
//   "Every internal node satisfies the heap order (parent <= children)
//    and the leftist property (rank(left) >= rank(right))."

///|
enum Tree {
  Empty
  Node(Int, Int64, Tree, Tree) // rank, key, left, right
}

///|
/// A persistent leftist min-heap of `Int64` keys.
pub struct LeftistHeap {
  root : Tree
  size : Int
}

///|
fn rank(t : Tree) -> Int {
  match t {
    Empty => 0
    Node(r, _, _, _) => r
  }
}

///|
fn make_node(key : Int64, a : Tree, b : Tree) -> Tree {
  // Put the larger-rank subtree on the left to satisfy the leftist
  // property.
  let ra = rank(a)
  let rb = rank(b)
  if ra >= rb {
    Node(rb + 1, key, a, b)
  } else {
    Node(ra + 1, key, b, a)
  }
}

///|
fn merge_trees(t1 : Tree, t2 : Tree) -> Tree {
  match (t1, t2) {
    (Empty, h) => h
    (h, Empty) => h
    (Node(_, k1, l1, r1), Node(_, k2, _, _) as h2) =>
      if k1 <= k2 {
        make_node(k1, l1, merge_trees(r1, h2))
      } else {
        match t2 {
          Node(_, k2_, l2, r2) => make_node(k2_, l2, merge_trees(t1, r2))
          Empty => t1
        }
      }
  }
}

///|
/// Empty heap.
pub fn LeftistHeap::new() -> LeftistHeap {
  { root: Empty, size: 0, }
}

///|
/// Insert a key. Returns a new heap; the old one is unchanged.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let h = @leftist_heap.new().push(3L).push(1L).push(2L)
///   @debug.assert_eq(h.peek_min(), Some(1L))
/// }
/// ```
pub fn LeftistHeap::push(self : LeftistHeap, key : Int64) -> LeftistHeap {
  let leaf : Tree = Node(1, key, Empty, Empty)
  { root: merge_trees(self.root, leaf), size: self.size + 1, }
}

///|
/// Minimum key, or `None` if empty.
pub fn LeftistHeap::peek_min(self : LeftistHeap) -> Int64? {
  match self.root {
    Empty => None
    Node(_, k, _, _) => Some(k)
  }
}

///|
/// Remove the minimum and return `(key, new_heap)`, or `None` if empty.
pub fn LeftistHeap::pop_min(self : LeftistHeap) -> (Int64, LeftistHeap)? {
  match self.root {
    Empty => None
    Node(_, k, l, r) =>
      Some((k, { root: merge_trees(l, r), size: self.size - 1, }))
  }
}

///|
/// Merge two heaps. Both originals are unchanged.
pub fn LeftistHeap::merge(
  self : LeftistHeap,
  other : LeftistHeap,
) -> LeftistHeap {
  { root: merge_trees(self.root, other.root), size: self.size + other.size, }
}

///|
/// Number of elements.
pub fn LeftistHeap::length(self : LeftistHeap) -> Int {
  self.size
}

///|
/// `true` iff the heap is empty.
pub fn LeftistHeap::is_empty(self : LeftistHeap) -> Bool {
  self.size == 0
}

///|
test "leftist basic push pop" {
  let h = LeftistHeap::new()
    .push(3L)
    .push(1L)
    .push(4L)
    .push(1L)
    .push(5L)
    .push(9L)
    .push(2L)
    .push(6L)
  @debug.assert_eq(h.peek_min(), Some(1L))
  // Drain min order; should be sorted.
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
test "leftist empty operations" {
  let h = LeftistHeap::new()
  @debug.assert_eq(h.peek_min(), None)
  match h.pop_min() {
    None => ()
    Some(_) => @debug.assert_eq(true, false)
  }
  @debug.assert_eq(h.length(), 0)
  @debug.assert_eq(h.is_empty(), true)
}

///|
test "leftist persistence" {
  // Pushing into an old heap should not change it.
  let h1 = LeftistHeap::new().push(5L).push(3L)
  let h2 = h1.push(1L)
  @debug.assert_eq(h1.peek_min(), Some(3L))
  @debug.assert_eq(h2.peek_min(), Some(1L))
}

///|
test "leftist merge" {
  let a = LeftistHeap::new().push(1L).push(7L).push(3L)
  let b = LeftistHeap::new().push(2L).push(8L).push(0L)
  let m = a.merge(b)
  @debug.assert_eq(m.length(), 6)
  let out : Array[Int64] = []
  let mut cur = m
  while !cur.is_empty() {
    match cur.pop_min() {
      Some((k, h2)) => {
        out.push(k)
        cur = h2
      }
      None => break
    }
  }
  @debug.assert_eq(out, [0L, 1L, 2L, 3L, 7L, 8L])
}

///|
test "leftist as a sort" {
  // Insert a deliberately scrambled sequence; popping should be sorted.
  let mut h = LeftistHeap::new()
  let input = [13L, 7L, 1L, 17L, 4L, 9L, 2L, 11L, 8L, 5L, 0L, 16L, 12L]
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
  // Now sort `input` by a baseline and compare.
  let expected = [0L, 1L, 2L, 4L, 5L, 7L, 8L, 9L, 11L, 12L, 13L, 16L, 17L]
  @debug.assert_eq(sorted, expected)
}

///|
test "leftist large" {
  let mut h = LeftistHeap::new()
  for i in 0L..<1000L {
    h = h.push(i * 31L % 997L)
  }
  @debug.assert_eq(h.length(), 1000)
  // The minimum must be 0 since 31 and 997 are coprime so the orbit
  // covers all residues including 0.
  @debug.assert_eq(h.peek_min(), Some(0L))
}
