// ============================================================================
// Challenge: Persistent Segment Tree (GCD)
// Point updates with range gcd queries
// ============================================================================

///|
fn abs_int(x : Int) -> Int {
  if x < 0 {
    -x
  } else {
    x
  }
}

///|
/// Compute the greatest common divisor of a and b.
pub fn gcd(a : Int, b : Int) -> Int {
  let x = abs_int(a)
  let y = abs_int(b)
  if y == 0 {
    x
  } else {
    gcd(y, x % y)
  }
}

///|
/// Persistent segment tree over the GCD monoid, supporting point
/// assignments and range-gcd queries.
///
/// Each node caches the greatest common divisor of its index range,
/// combined with the helper `gcd`. `set_value` overwrites a single
/// position in `O(log n)` and `range_gcd` answers a half-open
/// `[ql, qr)` query in `O(log n * log V)` including the inner
/// Euclidean steps; `build` is `O(n * log V)`. Persistence is achieved
/// by path copying so previous versions remain valid and share all
/// untouched subtrees.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let arr = [6, 10, 15, 25][:]
///   let root = build(arr, 0, arr.length())
///   let updated = apply_updates(root, arr.length(), [(2, 5), (0, 9)])
///   @debug.assert_eq(range_gcd(root, 0, arr.length(), 0, 4), 1)
///   @debug.assert_eq(range_gcd(updated, 0, arr.length(), 0, 2), 1)
/// }
/// ```
pub enum Node {
  Leaf(g~ : Int)
  Branch(g~ : Int, left~ : Node, right~ : Node)
} derive(Debug)

///|
fn node_gcd(node : Node) -> Int {
  match node {
    Leaf(g~) => g
    Branch(g~, left=_, right=_) => g
  }
}

///|

///|
/// Return the GCD stored at the root.
pub fn gcd_value(node : Node) -> Int {
  node_gcd(node)
}

///|
/// Build a segment tree over arr[l..r).
pub fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
  if r - l == 1 {
    Leaf(g=arr[l])
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    Branch(g=gcd(node_gcd(left), node_gcd(right)), left~, right~)
  }
}

///|
/// Set index idx to value and return the new tree.
pub fn set_value(node : Node, l : Int, r : Int, idx : Int, value : Int) -> Node {
  if r - l == 1 {
    Leaf(g=value)
  } else {
    let mid = (l + r) / 2
    match node {
      Leaf(g=_) => Leaf(g=value)
      Branch(left~, right~, g=_) =>
        if idx < mid {
          let new_left = set_value(left, l, mid, idx, value)
          Branch(
            g=gcd(node_gcd(new_left), node_gcd(right)),
            left=new_left,
            right~,
          )
        } else {
          let new_right = set_value(right, mid, r, idx, value)
          Branch(
            g=gcd(node_gcd(left), node_gcd(new_right)),
            left~,
            right=new_right,
          )
        }
    }
  }
}

///|
/// Query the GCD over [ql, qr).
pub fn range_gcd(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
  if qr <= l || r <= ql {
    0
  } else if ql <= l && r <= qr {
    node_gcd(node)
  } else {
    let mid = (l + r) / 2
    match node {
      Leaf(g=_) => node_gcd(node)
      Branch(left~, right~, g=_) =>
        gcd(range_gcd(left, l, mid, ql, qr), range_gcd(right, mid, r, ql, qr))
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
test "persistent_segment_tree_gcd" {
  let arr = [6, 10, 15, 25][:]
  let root = build(arr, 0, arr.length())
  let updated = apply_updates(root, arr.length(), [(2, 5), (0, 9)])
  @debug.assert_eq(range_gcd(root, 0, arr.length(), 0, 4), 1)
  @debug.assert_eq(range_gcd(updated, 0, arr.length(), 0, 4), 1)
  @debug.assert_eq(range_gcd(updated, 0, arr.length(), 0, 2), 1)
}
