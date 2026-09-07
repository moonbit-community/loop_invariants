// ============================================================================
// PAIRING HEAP  -  Fredman, Sedgewick, Sleator, Tarjan 1986
// ============================================================================
//
// A heap that is "stupid simple but fast in practice". A pairing heap
// is a tree whose root holds the minimum, with an arbitrary number of
// children stored as a list.
//
// OPERATIONS
//
//   merge(h1, h2) :  put the smaller root on top, prepend the other tree
//                    to the new root's child list.  O(1).
//   push(x, h)    :  merge with a singleton.                    O(1).
//   peek_min      :  read the root.                              O(1).
//   pop_min       :  consume the root; merge its children in **two
//                    passes**: left-to-right pair up, then right-to-left
//                    fold. **Amortised O(log n)**.
//
// AMORTISED ANALYSIS
//
// The bound for `pop_min` is `O(log n)` amortised; in fact tight bounds
// are still partly open. Worst-case `pop_min` is `O(n)` for adversarial
// input, but in practice pairing heaps are some of the fastest known
// in-memory heaps -- often beating Fibonacci heaps on real workloads.
//
// THE INVARIANT
//
//   "At every node t (including the root), t.key <= every key in t.children.
//    Therefore root holds the minimum."

///|
enum Tree {
  Empty
  Node(Int64, Array[Tree])
}

///|
/// A pairing min-heap of `Int64` keys (persistent / functional style).
pub struct PairingHeap {
  root : Tree
  size : Int
}

///|
fn merge_trees(t1 : Tree, t2 : Tree) -> Tree {
  match (t1, t2) {
    (Empty, h) => h
    (h, Empty) => h
    (Node(k1, c1), Node(k2, c2)) =>
      if k1 <= k2 {
        let children : Array[Tree] = [t2]
        for c in c1 {
          children.push(c)
        }
        Node(k1, children)
      } else {
        let children : Array[Tree] = [t1]
        for c in c2 {
          children.push(c)
        }
        Node(k2, children)
      }
  }
}

///|
fn merge_pairs(children : Array[Tree]) -> Tree {
  let n = children.length()
  if n == 0 {
    return Empty
  }
  if n == 1 {
    return children[0]
  }
  // Pass 1: pair up left-to-right.
  let paired : Array[Tree] = []
  let mut i = 0
  while i + 1 < n {
    paired.push(merge_trees(children[i], children[i + 1]))
    i = i + 2
  }
  if i == n - 1 {
    paired.push(children[i])
  }
  // Pass 2: fold right-to-left.
  let mut acc = paired[paired.length() - 1]
  let mut j = paired.length() - 2
  while j >= 0 {
    acc = merge_trees(paired[j], acc)
    j = j - 1
  }
  acc
}

///|
/// Empty pairing heap.
pub fn PairingHeap::new() -> PairingHeap {
  { root: Empty, size: 0, }
}

///|
/// Insert a key. O(1).
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let h = @pairing_heap.new().push(3L).push(1L).push(4L)
///   @debug.assert_eq(h.peek_min(), Some(1L))
/// }
/// ```
pub fn PairingHeap::push(self : PairingHeap, key : Int64) -> PairingHeap {
  let leaf : Tree = Node(key, [])
  { root: merge_trees(self.root, leaf), size: self.size + 1, }
}

///|
/// Minimum key. O(1).
pub fn PairingHeap::peek_min(self : PairingHeap) -> Int64? {
  match self.root {
    Empty => None
    Node(k, _) => Some(k)
  }
}

///|
/// Remove and return the minimum. Amortised O(log n).
pub fn PairingHeap::pop_min(self : PairingHeap) -> (Int64, PairingHeap)? {
  match self.root {
    Empty => None
    Node(k, children) =>
      Some((k, { root: merge_pairs(children), size: self.size - 1, }))
  }
}

///|
/// Merge two heaps. O(1).
pub fn PairingHeap::merge(
  self : PairingHeap,
  other : PairingHeap,
) -> PairingHeap {
  { root: merge_trees(self.root, other.root), size: self.size + other.size, }
}

///|
/// Number of elements currently stored.
pub fn PairingHeap::length(self : PairingHeap) -> Int {
  self.size
}

///|
/// `true` iff the heap is empty.
pub fn PairingHeap::is_empty(self : PairingHeap) -> Bool {
  self.size == 0
}

///|
test "pairing basic" {
  let h = PairingHeap::new()
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
test "pairing empty" {
  let h = PairingHeap::new()
  @debug.assert_eq(h.peek_min(), None)
  @debug.assert_eq(h.length(), 0)
  @debug.assert_eq(h.is_empty(), true)
  match h.pop_min() {
    None => ()
    Some(_) => @debug.assert_eq(true, false)
  }
}

///|
test "pairing persistence" {
  let h1 = PairingHeap::new().push(3L).push(5L)
  let h2 = h1.push(1L)
  @debug.assert_eq(h1.peek_min(), Some(3L))
  @debug.assert_eq(h2.peek_min(), Some(1L))
}

///|
test "pairing merge" {
  let a = PairingHeap::new().push(2L).push(8L).push(5L)
  let b = PairingHeap::new().push(7L).push(1L).push(11L)
  let m = a.merge(b)
  @debug.assert_eq(m.length(), 6)
  @debug.assert_eq(m.peek_min(), Some(1L))
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
  @debug.assert_eq(out, [1L, 2L, 5L, 7L, 8L, 11L])
}

///|
test "pairing sorts large random-ish" {
  let mut h = PairingHeap::new()
  let mut x = 12345L
  for _ in 0..<500 {
    x = (x * 1103515245L + 12345L) % 2147483648L
    h = h.push(x % 10000L)
  }
  @debug.assert_eq(h.length(), 500)
  let out : Array[Int64] = []
  while !h.is_empty() {
    match h.pop_min() {
      Some((k, h2)) => {
        out.push(k)
        h = h2
      }
      None => break
    }
  }
  // Confirm non-decreasing.
  for i in 0..<(out.length() - 1) {
    @debug.assert_eq(out[i] <= out[i + 1], true)
  }
}
