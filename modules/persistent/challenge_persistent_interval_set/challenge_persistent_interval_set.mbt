// ============================================================================
// Challenge: Persistent Interval Set
// Store disjoint intervals by rebuilding from merged lists
// ============================================================================

///|
/// Persistent set of disjoint integer intervals.
///
/// Each node stores one closed interval `[start, end]`; the tree is
/// ordered by `start` and the invariant is that all stored intervals are
/// pairwise disjoint and non-adjacent. `insert_interval` flattens the
/// tree to a sorted list, splices in the new range, merges overlapping
/// or touching intervals, and rebuilds a balanced tree in `O(n)`.
/// `contains_point` uses BST lookup in `O(log n)`. Operations return
/// fresh trees; previous versions stay valid. See `empty`, `to_array`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let t = @challenge_persistent_interval_set.empty()
///   let t = @challenge_persistent_interval_set.insert_interval(t, 2, 5)
///   let t = @challenge_persistent_interval_set.insert_interval(t, 4, 7)
///   assert_eq(@challenge_persistent_interval_set.contains_point(t, 6), true)
///   assert_eq(@challenge_persistent_interval_set.to_array(t), [(2, 7)])
/// }
/// ```
pub enum Tree {
  Empty
  Node(start~ : Int, end~ : Int, left~ : Tree, right~ : Tree)
} derive(Debug)

///|
fn inorder(t : Tree) -> Array[(Int, Int)] {
  match t {
    Empty => []
    Node(start=s, end=e, left=l, right=r) => inorder(l) + [(s, e)] + inorder(r)
  }
}

///|
fn build(arr : ArrayView[(Int, Int)], l : Int, r : Int) -> Tree {
  if l >= r {
    Empty
  } else {
    let mid = (l + r) / 2
    let (s, e) = arr[mid]
    Node(start=s, end=e, left=build(arr, l, mid), right=build(arr, mid + 1, r))
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
  let inserted = for pair in arr; inserted = false {
    let (s1, e1) = pair
    if !inserted && s < s1 {
      out.push((s, e))
      out.push((s1, e1))
      continue true
    }
    out.push((s1, e1))
    continue inserted
  } nobreak {
    inserted
  }
  if !inserted {
    out.push((s, e))
  }
  out
}

///|
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
  Empty
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
  let with_new = insert_sorted(list, (start, end))
  let merged = merge_sorted(with_new)
  build(merged, 0, merged.length())
}

///|
/// Check whether point x is contained in any interval.
pub fn contains_point(t : Tree, x : Int) -> Bool {
  match t {
    Empty => false
    Node(start=s, end=e, left=l, right=r) =>
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
  let t0 = Empty
  let t1 = insert_interval(t0, 2, 5)
  let t2 = insert_interval(t1, 8, 9)
  let t3 = insert_interval(t2, 4, 7)
  assert_eq(contains_point(t3, 3), true)
  assert_eq(contains_point(t3, 6), true)
  assert_eq(contains_point(t3, 10), false)
  assert_eq(contains_point(t1, 6), false)
}

///|
test "persistent_interval_set_middle_insert" {
  let t1 = insert_interval(Empty, 1, 2)
  let t2 = insert_interval(t1, 5, 6)
  let t3 = insert_interval(t2, 8, 9)
  let t4 = insert_interval(t3, 3, 4)
  assert_eq(to_array(t3), [(1, 2), (5, 6), (8, 9)])
  assert_eq(to_array(t4), [(1, 6), (8, 9)])
}
