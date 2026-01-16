// ============================================================================
// Challenge: Persistent Interval Set
// Store disjoint intervals by rebuilding from merged lists
// ============================================================================

///|
pub enum Tree {
  Empty
  Node(start~ : Int, end~ : Int, left~ : Tree, right~ : Tree)
} derive(Show)

///|
fn inorder(t : Tree) -> Array[(Int, Int)] {
  match t {
    Tree::Empty => []
    Tree::Node(start=s, end=e, left=l, right=r) =>
      inorder(l) + [(s, e)] + inorder(r)
  }
}

///|
fn build(arr : ArrayView[(Int, Int)], l : Int, r : Int) -> Tree {
  if l >= r {
    Tree::Empty
  } else {
    let mid = (l + r) / 2
    let (s, e) = arr[mid]
    Tree::Node(
      start=s,
      end=e,
      left=build(arr, l, mid),
      right=build(arr, mid + 1, r),
    )
  }
}

///|
fn insert_sorted(
  arr : ArrayView[(Int, Int)],
  interval : (Int, Int),
) -> Array[(Int, Int)] {
  let (s0, e0) = interval
  let s = if s0 <= e0 { s0 } else { e0 }
  let e = if s0 <= e0 { e0 } else { s0 }
  let out = Array::new()
  let mut inserted = false
  for pair in arr {
    let (s1, e1) = pair
    if !inserted && s < s1 {
      out.push((s, e))
      inserted = true
    }
    out.push((s1, e1))
  }
  if !inserted {
    out.push((s, e))
  }
  out
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn merge_sorted(arr : ArrayView[(Int, Int)]) -> Array[(Int, Int)] {
  let out = Array::new()
  for pair in arr {
    let (s, e) = pair
    if out.length() == 0 {
      out.push((s, e))
    } else {
      let idx = out.length() - 1
      let (ls, le) = out[idx]
      if s <= le + 1 {
        let new_end = if e > le { e } else { le }
        out[idx] = (ls, new_end)
      } else {
        out.push((s, e))
      }
    }
  }
  out
}

///|
/// Create an empty interval set.
pub fn empty() -> Tree {
  Tree::Empty
}

///|
/// Return all intervals in sorted order.
pub fn to_array(t : Tree) -> Array[(Int, Int)] {
  inorder(t)
}

///|
/// Insert an interval [start, end] and return the merged set.
pub fn insert_interval(t : Tree, start : Int, end : Int) -> Tree {
  let list = inorder(t)
  let with_new = insert_sorted(list[:], (start, end))
  let merged = merge_sorted(with_new[:])
  build(merged[:], 0, merged.length())
}

///|
/// Check whether point x is contained in any interval.
pub fn contains_point(t : Tree, x : Int) -> Bool {
  match t {
    Tree::Empty => false
    Tree::Node(start=s, end=e, left=l, right=r) =>
      if x < s {
        contains_point(l, x)
      } else if x > e {
        contains_point(r, x)
      } else {
        true
      }
  }
}

///|
test "persistent_interval_set" {
  let t0 = Tree::Empty
  let t1 = insert_interval(t0, 2, 5)
  let t2 = insert_interval(t1, 8, 9)
  let t3 = insert_interval(t2, 4, 7)
  assert_eq(contains_point(t3, 3), true)
  assert_eq(contains_point(t3, 6), true)
  assert_eq(contains_point(t3, 10), false)
  assert_eq(contains_point(t1, 6), false)
}
