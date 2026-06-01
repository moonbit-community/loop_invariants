// ============================================================================
// BINOMIAL HEAP  -  Vuillemin 1978
// ============================================================================
//
// A **binomial heap** is a forest of **binomial trees** -- one of order
// `k` for each set bit in the heap's size written in binary. Each
// binomial tree of order k has exactly `2^k` nodes; its root has
// children of orders `k-1, k-2, ..., 0`.
//
// MERGE
//
// Walk the two root lists in increasing order of tree rank. Whenever
// you have three or fewer trees of the same order, merge two of them
// (smaller root becomes the new root, the other becomes its child),
// producing a single tree of the next order -- exactly like binary
// addition with carry.
//
// COMPLEXITY
//
//   merge / push / pop : O(log n) worst case
//   peek_min            : O(log n) (scan the root list)
//   push                : O(log n) worst case, O(1) amortised
//
// THE INVARIANT
//
//   "The root list is a *strictly increasing* sequence of binomial-tree
//    orders. The total node count equals the sum of 2^order over all
//    trees, matching the heap size."

///|
struct Tree {
  key : Int64
  order : Int
  children : Array[Tree] // strictly decreasing orders: [order-1, ..., 0]
}

///|
/// A binomial min-heap of `Int64` keys.
pub struct BinomialHeap {
  trees : Array[Tree] // sorted by strictly increasing order
  size : Int
}

///|
fn link(a : Tree, b : Tree) -> Tree {
  // Merge two trees of the same order; smaller key becomes root.
  if a.key <= b.key {
    let kids = Array::makei(a.children.length() + 1, i => {
      if i == 0 {
        b
      } else {
        a.children[i - 1]
      }
    })
    { key: a.key, order: a.order + 1, children: kids }
  } else {
    let kids = Array::makei(b.children.length() + 1, i => {
      if i == 0 {
        a
      } else {
        b.children[i - 1]
      }
    })
    { key: b.key, order: b.order + 1, children: kids }
  }
}

///|
fn merge_root_lists(la : Array[Tree], lb : Array[Tree]) -> Array[Tree] {
  let mut i = 0
  let mut j = 0
  let merged : Array[Tree] = []
  while i < la.length() && j < lb.length() {
    if la[i].order <= lb[j].order {
      merged.push(la[i])
      i = i + 1
    } else {
      merged.push(lb[j])
      j = j + 1
    }
  }
  while i < la.length() {
    merged.push(la[i])
    i = i + 1
  }
  while j < lb.length() {
    merged.push(lb[j])
    j = j + 1
  }
  // Now consolidate equal orders.
  let result : Array[Tree] = []
  let mut k = 0
  while k < merged.length() {
    let cur = merged[k]
    if k + 1 < merged.length() && merged[k + 1].order == cur.order {
      if k + 2 < merged.length() && merged[k + 2].order == cur.order {
        // Three of same order: emit first, link the other two.
        result.push(cur)
        let combined = link(merged[k + 1], merged[k + 2])
        // Replace position k+2 with the combined; advance accordingly.
        merged[k + 2] = combined
        k = k + 2
      } else {
        let combined = link(cur, merged[k + 1])
        merged[k + 1] = combined
        k = k + 1
      }
    } else {
      result.push(cur)
      k = k + 1
    }
  }
  result
}

///|
/// Empty binomial heap.
pub fn BinomialHeap::new() -> BinomialHeap {
  { trees: [], size: 0 }
}

///|
/// Insert a key.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let h = @binomial_heap.new().push(3L).push(1L).push(2L)
///   @debug.assert_eq(h.peek_min(), Some(1L))
/// }
/// ```
pub fn BinomialHeap::push(self : BinomialHeap, key : Int64) -> BinomialHeap {
  let leaf : Tree = { key, order: 0, children: [] }
  let new_trees = merge_root_lists(self.trees, [leaf])
  { trees: new_trees, size: self.size + 1 }
}

///|
/// Minimum, if present. O(log n) (scan the root list).
pub fn BinomialHeap::peek_min(self : BinomialHeap) -> Int64? {
  if self.trees.length() == 0 {
    return None
  }
  let mut best = self.trees[0].key
  for t in self.trees {
    if t.key < best {
      best = t.key
    }
  }
  Some(best)
}

///|
/// Remove and return the minimum.
pub fn BinomialHeap::pop_min(self : BinomialHeap) -> (Int64, BinomialHeap)? {
  if self.trees.length() == 0 {
    return None
  }
  let mut best_idx = 0
  for i in 1..<self.trees.length() {
    if self.trees[i].key < self.trees[best_idx].key {
      best_idx = i
    }
  }
  let best_tree = self.trees[best_idx]
  // Remove best_idx from trees.
  let rest : Array[Tree] = []
  for i in 0..<self.trees.length() {
    if i != best_idx {
      rest.push(self.trees[i])
    }
  }
  let kids_increasing : Array[Tree] = Array::makei(
    best_tree.children.length(),
    i => best_tree.children[best_tree.children.length() - 1 - i],
  )
  let merged = merge_root_lists(rest, kids_increasing)
  Some((best_tree.key, { trees: merged, size: self.size - 1 }))
}

///|
/// Merge two binomial heaps.
pub fn BinomialHeap::merge(
  self : BinomialHeap,
  other : BinomialHeap,
) -> BinomialHeap {
  {
    trees: merge_root_lists(self.trees, other.trees),
    size: self.size + other.size,
  }
}

///|
/// Number of elements.
pub fn BinomialHeap::length(self : BinomialHeap) -> Int {
  self.size
}

///|
/// `true` iff the heap is empty.
pub fn BinomialHeap::is_empty(self : BinomialHeap) -> Bool {
  self.size == 0
}

///|
test "binomial basic" {
  let h = BinomialHeap::new()
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
test "binomial empty" {
  let h = BinomialHeap::new()
  @debug.assert_eq(h.peek_min(), None)
  @debug.assert_eq(h.length(), 0)
  @debug.assert_eq(h.is_empty(), true)
  match h.pop_min() {
    None => ()
    Some(_) => @debug.assert_eq(true, false)
  }
}

///|
test "binomial persistence" {
  let h1 = BinomialHeap::new().push(5L).push(3L)
  let h2 = h1.push(1L)
  @debug.assert_eq(h1.peek_min(), Some(3L))
  @debug.assert_eq(h2.peek_min(), Some(1L))
}

///|
test "binomial merge" {
  let a = BinomialHeap::new().push(1L).push(7L).push(3L)
  let b = BinomialHeap::new().push(2L).push(8L).push(0L)
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
test "binomial sort" {
  let mut h = BinomialHeap::new()
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
test "binomial larger size" {
  let mut h = BinomialHeap::new()
  for i in 0L..<500L {
    h = h.push(i * 17L % 991L)
  }
  @debug.assert_eq(h.length(), 500)
  // Drain and check non-decreasing.
  let mut prev = -1L
  while !h.is_empty() {
    match h.pop_min() {
      Some((k, h2)) => {
        @debug.assert_eq(k >= prev, true)
        prev = k
        h = h2
      }
      None => break
    }
  }
}
