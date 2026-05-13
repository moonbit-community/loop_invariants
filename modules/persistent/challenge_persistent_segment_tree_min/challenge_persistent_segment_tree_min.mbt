// ============================================================================
// Challenge: Persistent Segment Tree (Min)
// Point updates with range minimum queries
// ============================================================================

///|
/// Persistent segment tree over the `min` monoid, supporting point
/// assignments and range-minimum queries.
///
/// Each node caches the minimum of its index range. `set_value`
/// overwrites a single position in `O(log n)` and `range_min` answers
/// a half-open `[ql, qr)` query in `O(log n)`; `build` is `O(n)`.
/// Out-of-range queries return the sentinel `0x3fffffff` so that the
/// recursive combiner treats them as `+infinity`. Persistence is
/// achieved by path copying so each version shares all untouched
/// subtrees with its predecessor.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let arr = [5, 2, 7, 4][:]
///   let root = build(arr, 0, arr.length())
///   let updated = apply_updates(root, arr.length(), [(2, 1), (0, 6)])
///   @debug.assert_eq(range_min(root, 0, arr.length(), 0, 4), 2)
///   @debug.assert_eq(range_min(updated, 0, arr.length(), 0, 4), 1)
/// }
/// ```
pub enum Node {
  Leaf(min~ : Int)
  Branch(min~ : Int, left~ : Node, right~ : Node)
} derive(Debug)

///|
fn node_min(node : Node) -> Int {
  match node {
    Leaf(min~) => min
    Branch(min~, left=_, right=_) => min
  }
}

///|

///|
/// Return the minimum stored at the root.
pub fn min_value(node : Node) -> Int {
  node_min(node)
}

///|
/// Build a segment tree over arr[l..r).
pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
  if r - l == 1 {
    Leaf(min=arr[l])
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    let m = if node_min(left) < node_min(right) {
      node_min(left)
    } else {
      node_min(right)
    }
    Branch(min=m, left~, right~)
  }
}

///|
/// Set index idx to value and return the new tree.
pub fn set_value(node : Node, l : Int, r : Int, idx : Int, value : Int) -> Node {
  if r - l == 1 {
    Leaf(min=value)
  } else {
    let mid = (l + r) / 2
    match node {
      Leaf(min=_) => Leaf(min=value)
      Branch(left~, right~, min=_) =>
        if idx < mid {
          let new_left = set_value(left, l, mid, idx, value)
          let m = if node_min(new_left) < node_min(right) {
            node_min(new_left)
          } else {
            node_min(right)
          }
          Branch(min=m, left=new_left, right~)
        } else {
          let new_right = set_value(right, mid, r, idx, value)
          let m = if node_min(left) < node_min(new_right) {
            node_min(left)
          } else {
            node_min(new_right)
          }
          Branch(min=m, left~, right=new_right)
        }
    }
  }
}

///|
/// Query the minimum over [ql, qr).
pub fn range_min(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
  if qr <= l || r <= ql {
    0x3fffffff
  } else if ql <= l && r <= qr {
    node_min(node)
  } else {
    let mid = (l + r) / 2
    match node {
      Leaf(min=_) => node_min(node)
      Branch(left~, right~, min=_) => {
        let left_min = range_min(left, l, mid, ql, qr)
        let right_min = range_min(right, mid, r, ql, qr)
        if left_min < right_min {
          left_min
        } else {
          right_min
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
  updates.fold(init=root, (tree, update) => {
    let (idx, value) = update
    set_value(tree, 0, n, idx, value)
  })
}

///|
test "persistent_segment_tree_min" {
  let arr = [5, 2, 7, 4][:]
  let root = build(arr, 0, arr.length())
  let updated = apply_updates(root, arr.length(), [(2, 1), (0, 6)])
  @debug.assert_eq(range_min(root, 0, arr.length(), 0, 4), 2)
  @debug.assert_eq(range_min(updated, 0, arr.length(), 0, 4), 1)
  @debug.assert_eq(range_min(updated, 0, arr.length(), 1, 3), 1)
}
