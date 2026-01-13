// ============================================================================
// Challenge: Persistent Binomial Heap
// Array-of-trees representation with carry merging
// ============================================================================

///|
struct Tree {
  value : Int
  rank : Int
  children : Array[Tree]
} derive(Show)

///|
pub struct Heap {
  trees : Array[Tree?]
} derive(Show)

///|
fn tree_rank(t : Tree) -> Int {
  t.rank
}

///|
fn link(a : Tree, b : Tree) -> Tree {
  if a.value <= b.value {
    Tree::{ value: a.value, rank: a.rank + 1, children: a.children + [b] }
  } else {
    Tree::{ value: b.value, rank: b.rank + 1, children: b.children + [a] }
  }
}

///|
fn valid_prefix(arr : Array[Tree?], i : Int) -> Bool {
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
fn merge_heaps(a : Heap, b : Heap) -> Heap {
  let len = max2(a.trees.length(), b.trees.length()) + 1
  let out : Array[Tree?] = Array::make(len, None)
  let mut carry : Tree? = None
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
pub fn empty() -> Heap {
  { trees: [] }
}

///|
/// Merge two heaps and return the result.
pub fn merge(a : Heap, b : Heap) -> Heap {
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
fn singleton(value : Int) -> Heap {
  let tree = Tree::{ value, rank: 0, children: [] }
  { trees: [Some(tree)] }
}

///|
/// Insert a value and return the new heap.
pub fn insert(h : Heap, value : Int) -> Heap {
  merge_heaps(h, singleton(value))
}

///|
/// Return the minimum value in the heap, or None if empty.
#warnings("+missing_invariant+missing_reasoning")
pub fn find_min(h : Heap) -> Int? {
  let len = h.trees.length()
  let none : Int? = None
  for i = 0, best = none {
    if i >= len {
      break best
    } else {
      match (best, h.trees[i]) {
        (None, Some(t)) => continue i + 1, Some(t.value)
        (Some(b), Some(t)) =>
          continue i + 1, Some(if t.value < b { t.value } else { b })
        _ => continue i + 1, best
      }
    }
  } where {
    invariant: i >= 0 && i <= len,
    reasoning: (
      #|INVARIANT (Min scan):
      #|best is the minimum root value among trees[0..i).
      #|MAINTENANCE:
      #|Compare the next root and update best if smaller.
      #|TERMINATION:
      #|At i = len, best is the minimum across all trees.
    ),
  }
}

///|
fn heap_from_children(children : Array[Tree], rank : Int) -> Heap {
  let out : Array[Tree?] = Array::make(rank, None)
  for child in children {
    out[child.rank] = Some(child)
  }
  { trees: out }
}

///|
/// Delete the minimum element and return the new heap.
pub fn delete_min(h : Heap) -> Heap? {
  let len = h.trees.length()
  let mut min_idx = -1
  let mut min_val = 0
  for i = 0; i < len; i = i + 1 {
    match h.trees[i] {
      None => ()
      Some(t) =>
        if min_idx < 0 || t.value < min_val {
          min_idx = i
          min_val = t.value
        }
    }
  } where {
    invariant: i >= 0 && i <= len,
    reasoning: (
      #|INVARIANT (Min index scan):
      #|min_idx/min_val track the smallest root seen in trees[0..i).
      #|MAINTENANCE:
      #|Update min_idx when a smaller root is found.
      #|TERMINATION:
      #|At i = len, min_idx is the index of the minimum tree.
    ),
  }
  if min_idx < 0 {
    None
  } else {
    match h.trees[min_idx] {
      None => None
      Some(tree) => {
        let base : Array[Tree?] = h.trees.copy()
        base[min_idx] = None
        let heap1 = { trees: base }
        let heap2 = heap_from_children(tree.children, tree.rank)
        Some(merge_heaps(heap1, heap2))
      }
    }
  }
}
