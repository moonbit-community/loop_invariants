// ============================================================================
// Challenge: Persistent Segment Tree (Max)
// Point updates with range maximum queries
// ============================================================================

///|
/// Persistent segment tree over the `max` monoid, supporting point
/// assignments and range-maximum queries.
///
/// Each node caches the maximum of its index range. `set_value`
/// overwrites a single position in `O(log n)` and `range_max` answers
/// a half-open `[ql, qr)` query in `O(log n)`; `build` is `O(n)`.
/// Out-of-range queries return the sentinel `-0x3fffffff` so that the
/// recursive combiner treats them as `-infinity`. Persistence is
/// achieved by path copying so each version shares all untouched
/// subtrees with its predecessor.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let arr = [5, 2, 7, 4][:]
///   let root = build(arr, 0, arr.length())
///   let updated = apply_updates(root, arr.length(), [(2, 1), (0, 6)])
///   @debug.assert_eq(range_max(root, 0, arr.length(), 0, 4), 7)
///   @debug.assert_eq(range_max(updated, 0, arr.length(), 0, 4), 6)
/// }
/// ```
pub enum Node {
  Leaf(max~ : Int)
  Branch(max~ : Int, left~ : Node, right~ : Node)
} derive(Debug)

///|
fn node_max(node : Node) -> Int {
  match node {
    Leaf(max~) => max
    Branch(max~, left=_, right=_) => max
  }
}

///|

///|
/// Return the maximum stored at the root.
pub fn max_value(node : Node) -> Int {
  node_max(node)
}

///|
/// Build a segment tree over arr[l..r).
pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
  if r - l == 1 {
    Leaf(max=arr[l])
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    let m = if node_max(left) > node_max(right) {
      node_max(left)
    } else {
      node_max(right)
    }
    Branch(max=m, left~, right~)
  }
}

///|
/// Set index idx to value and return the new tree.
pub fn set_value(node : Node, l : Int, r : Int, idx : Int, value : Int) -> Node {
  if r - l == 1 {
    Leaf(max=value)
  } else {
    let mid = (l + r) / 2
    match node {
      Leaf(max=_) => Leaf(max=value)
      Branch(left~, right~, max=_) =>
        if idx < mid {
          let new_left = set_value(left, l, mid, idx, value)
          let m = if node_max(new_left) > node_max(right) {
            node_max(new_left)
          } else {
            node_max(right)
          }
          Branch(max=m, left=new_left, right~)
        } else {
          let new_right = set_value(right, mid, r, idx, value)
          let m = if node_max(left) > node_max(new_right) {
            node_max(left)
          } else {
            node_max(new_right)
          }
          Branch(max=m, left~, right=new_right)
        }
    }
  }
}

///|
/// Query the maximum over [ql, qr).
pub fn range_max(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
  if qr <= l || r <= ql {
    -0x3fffffff
  } else if ql <= l && r <= qr {
    node_max(node)
  } else {
    let mid = (l + r) / 2
    match node {
      Leaf(max=_) => node_max(node)
      Branch(left~, right~, max=_) => {
        let left_max = range_max(left, l, mid, ql, qr)
        let right_max = range_max(right, mid, r, ql, qr)
        if left_max > right_max {
          left_max
        } else {
          right_max
        }
      }
    }
  }
}

///|
/// Apply point updates (idx, value).
pub fn apply_updates(
  root : Node,
  n : Int,
  updates : ArrayView[(Int, Int)],
) -> Node {
  for update in updates; tree = root {
    let (idx, value) = update
    continue set_value(tree, 0, n, idx, value)
  } nobreak {
    tree
  }
}

///|
test "persistent_segment_tree_max" {
  let arr = [5, 2, 7, 4][:]
  let root = build(arr, 0, arr.length())
  let updated = apply_updates(root, arr.length(), [(2, 1), (0, 6)])
  @debug.assert_eq(range_max(root, 0, arr.length(), 0, 4), 7)
  @debug.assert_eq(range_max(updated, 0, arr.length(), 0, 4), 6)
  @debug.assert_eq(range_max(updated, 0, arr.length(), 1, 3), 2)
}
