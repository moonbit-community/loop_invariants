// ============================================================================
// Challenge: Persistent Binomial Heap
// Array-of-trees representation with carry merging
// ============================================================================

///|
struct Tree[T] {
  value : T
  rank : Int
  children : Array[Tree[T]]
} derive(Show)

///|
pub struct Heap[T] {
  trees : Array[Tree[T]?]
} derive(Show)

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
  let mut carry : Tree[T]? = None
  for i = 0; i < len; i = i + 1 {
    let t1 = if i < a.trees.length() { a.trees[i] } else { None }
    let t2 = if i < b.trees.length() { b.trees[i] } else { None }
    let mut count = 0
    if t1 is Some(_) {
      count = count + 1
    }
    if t2 is Some(_) {
      count = count + 1
    }
    if carry is Some(_) {
      count = count + 1
    }
    match count {
      0 => out[i] = None
      1 => {
        out[i] = if t1 is Some(_) {
          t1
        } else if t2 is Some(_) {
          t2
        } else {
          carry
        }
        carry = None
      }
      2 => {
        let a_tree = if t1 is Some(_) { t1 } else { t2 }
        let b_tree = if t1 is Some(_) && t2 is Some(_) { t2 } else { carry }
        match (a_tree, b_tree) {
          (Some(x), Some(y)) => {
            carry = Some(link(x, y))
            out[i] = None
          }
          _ => {
            out[i] = None
            carry = None
          }
        }
      }
      _ => {
        let first = t1
        let second = t2
        out[i] = carry
        match (first, second) {
          (Some(x), Some(y)) => carry = Some(link(x, y))
          _ => carry = None
        }
      }
    }
  } where {
    invariant: i >= 0 && i <= len,
    invariant: valid_prefix(out, i),
    invariant: carry is None || (carry is Some(t) && tree_rank(t) == i),
    reasoning: (
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
  let mut min_val : T? = None
  for tree in h.trees {
    match tree {
      None => ()
      Some(t) =>
        match min_val {
          None => min_val = Some(t.value)
          Some(best) => if t.value < best { min_val = Some(t.value) }
        }
    }
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
  let mut min_idx : Int? = None
  let mut min_val : T? = None
  for i, tree in h.trees {
    match tree {
      None => ()
      Some(t) =>
        match min_val {
          None => {
            min_idx = Some(i)
            min_val = Some(t.value)
          }
          Some(best) =>
            if t.value < best {
              min_idx = Some(i)
              min_val = Some(t.value)
            }
        }
    }
  }
  match min_idx {
    None => None
    Some(idx) =>
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
