// ============================================================================
// Challenge: Persistent Binomial Heap
// Array-of-trees representation with carry merging
// ============================================================================

///|
struct Tree[T] {
  value : T
  rank : Int
  children : Array[Tree[T]]
} derive(Debug)

///|
/// A persistent min-binomial heap with priorities of type `T`.
///
/// The heap is stored as an array of optional binomial trees indexed by
/// rank, mirroring the binary representation of the heap's size; merging
/// proceeds rank by rank with a carry, just like binary addition. `insert`
/// and `merge` take `O(log n)` time, `find_min` scans the rank array in
/// `O(log n)`, and `delete_min` reassembles the heap in `O(log n)`. New
/// versions share the bulk of the old `trees` array, so older heaps stay
/// valid. See `empty`, `insert`, `merge`, `find_min`, and `delete_min`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let h = @challenge_persistent_binomial_heap.empty()
///   let h = @challenge_persistent_binomial_heap.insert(h, 3)
///   let h = @challenge_persistent_binomial_heap.insert(h, 1)
///   let h = @challenge_persistent_binomial_heap.insert(h, 2)
///   assert_eq(@challenge_persistent_binomial_heap.find_min(h), Some(1))
/// }
/// ```
pub struct Heap[T] {
  trees : Array[Tree[T]?]
} derive(Debug)

///|
fn[T] tree_rank(t : Tree[T]) -> Int {
  t.rank
}

///|
fn[T : Compare] link(a : Tree[T], b : Tree[T]) -> Tree[T] {
  if a.value <= b.value {
    { value: a.value, rank: a.rank + 1, children: a.children + [b] }
  } else {
    { value: b.value, rank: b.rank + 1, children: b.children + [a] }
  }
}

///|
fn[T] valid_prefix(arr : Array[Tree[T]?], i : Int) -> Bool {
  if i <= 0 {
    true
  } else {
    match arr[i - 1] {
      None => valid_prefix(arr, i - 1)
      Some(t) => tree_rank(t) == i - 1 && valid_prefix(arr, i - 1)
    }
  }
}

///|
fn[T : Compare] merge_heaps(a : Heap[T], b : Heap[T]) -> Heap[T] {
  let len = max2(a.trees.length(), b.trees.length()) + 1
  let out : Array[Tree[T]?] = Array::make(len, None)
  let _ = for i in 0..<len; carry = None {
    let t1 = if i < a.trees.length() { a.trees[i] } else { None }
    let t2 = if i < b.trees.length() { b.trees[i] } else { None }
    let count = (if t1 is Some(_) { 1 } else { 0 }) +
      (if t2 is Some(_) { 1 } else { 0 }) +
      (if carry is Some(_) { 1 } else { 0 })
    let new_carry = match count {
      0 => {
        out[i] = None
        None
      }
      1 => {
        out[i] = if t1 is Some(_) {
          t1
        } else if t2 is Some(_) {
          t2
        } else {
          carry
        }
        None
      }
      2 => {
        let a_tree = if t1 is Some(_) { t1 } else { t2 }
        let b_tree = if t1 is Some(_) && t2 is Some(_) { t2 } else { carry }
        out[i] = None
        match (a_tree, b_tree) {
          (Some(x), Some(y)) => Some(link(x, y))
          _ => None
        }
      }
      _ => {
        out[i] = carry
        match (t1, t2) {
          (Some(x), Some(y)) => Some(link(x, y))
          _ => None
        }
      }
    }
    continue new_carry
  } nobreak {
    carry
  } where {
    proof_invariant: i >= 0 && i <= len,
    proof_invariant: valid_prefix(out, i),
    proof_invariant: carry is None || (carry is Some(t) && tree_rank(t) == i),
    proof_reasoning: (
      #|INVARIANT (Binomial carry):
      #|out[0..i) holds finalized ranks, and carry (if any) has rank i.
      #|MAINTENANCE:
      #|Combine up to three trees at rank i and produce at most one carry.
      #|TERMINATION:
      #|After len steps, all ranks are resolved and carry is placed if needed.
    ),
  }
  { trees: out }
}

///|
/// Create an empty binomial heap.
pub fn[T] empty() -> Heap[T] {
  { trees: [] }
}

///|
/// Merge two heaps and return the result.
pub fn[T : Compare] merge(a : Heap[T], b : Heap[T]) -> Heap[T] {
  merge_heaps(a, b)
}

///|
fn max2(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn[T] singleton(value : T) -> Heap[T] {
  let tree = { value, rank: 0, children: [] }
  { trees: [Some(tree)] }
}

///|
/// Insert a value and return the new heap.
pub fn[T : Compare] insert(h : Heap[T], value : T) -> Heap[T] {
  merge_heaps(h, singleton(value))
}

///|
/// Return the minimum value in the heap, or None if empty.
pub fn[T : Compare] find_min(h : Heap[T]) -> T? {
  let min_val : T? = for tree in h.trees; min_val = None {
    match tree {
      None => continue min_val
      Some(t) =>
        match min_val {
          None => continue Some(t.value)
          Some(best) =>
            continue if t.value < best { Some(t.value) } else { min_val }
        }
    }
  } nobreak {
    min_val
  }
  min_val
}

///|
fn[T] heap_from_children(children : Array[Tree[T]], rank : Int) -> Heap[T] {
  let out : Array[Tree[T]?] = Array::make(rank, None)
  for child in children {
    out[child.rank] = Some(child)
  }
  { trees: out }
}

///|
/// Delete the minimum element and return the new heap.
pub fn[T : Compare] delete_min(h : Heap[T]) -> Heap[T]? {
  let min : (Int, T)? = for i, tree in h.trees; min = None {
    match tree {
      None => continue min
      Some(t) =>
        match min {
          None => continue Some((i, t.value))
          Some((_, best)) =>
            continue if t.value < best { Some((i, t.value)) } else { min }
        }
    }
  } nobreak {
    min
  }
  match min {
    None => None
    Some((idx, _)) =>
      match h.trees[idx] {
        None => None
        Some(tree) => {
          let base : Array[Tree[T]?] = h.trees.copy()
          base[idx] = None
          let heap1 = { trees: base }
          let heap2 = heap_from_children(tree.children, tree.rank)
          Some(merge_heaps(heap1, heap2))
        }
      }
  }
}

///|
test "persistent binomial heap rank invariant" {
  let heap = insert(insert(empty(), 3), 1)
  assert_true(valid_prefix(heap.trees, heap.trees.length()))
}

///|
test "persistent binomial heap keeps earlier minimum" {
  let h1 = insert(empty(), 1)
  let h2 = insert(insert(empty(), 10), 20)
  let merged = merge(h1, h2)
  debug_inspect(find_min(merged), content="Some(1)")
  guard delete_min(merged) is Some(rest) else { fail("expected delete_min") }
  debug_inspect(find_min(rest), content="Some(10)")
}
