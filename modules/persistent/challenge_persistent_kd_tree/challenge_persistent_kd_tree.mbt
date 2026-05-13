// ============================================================================
// Challenge: Persistent KD-Tree (2D)
// Immutable insertion with alternating split axis
// ============================================================================

///|
/// A point in the 2D plane stored by the KD-tree.
///
/// Holds integer coordinates `x` and `y`. The KD-tree compares points
/// along one axis at each level — axis 0 compares `x`, axis 1 compares
/// `y` — and equality is structural (`derive(Eq)`) so duplicates are
/// detected and not re-inserted. Construct with the struct literal
/// `{ x: ..., y: ... }`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let p : @challenge_persistent_kd_tree.Point = { x: 1, y: 2 }
///   let t = @challenge_persistent_kd_tree.insert(
///     @challenge_persistent_kd_tree.empty(),
///     p,
///   )
///   @debug.assert_eq(@challenge_persistent_kd_tree.contains(t, p), true)
/// }
/// ```
pub(all) struct Point {
  x : Int
  y : Int
} derive(Debug, Eq)

///|
/// Persistent 2D KD-tree over `Point` values.
///
/// A binary tree that splits the plane on alternating axes (x at
/// even depths, y at odd depths). `insert` walks to the correct leaf
/// in `O(log n)` expected time on random input (worst case `O(n)`)
/// and copies only the spine, sharing untouched subtrees with the
/// previous version. `contains` follows the same path. Duplicate
/// points are deduplicated. See `empty`, `from_array`, `size`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let t = @challenge_persistent_kd_tree.from_array([
///     ({ x: 1, y: 2 } : @challenge_persistent_kd_tree.Point),
///     { x: 3, y: 4 },
///   ])
///   @debug.assert_eq(@challenge_persistent_kd_tree.size(t), 2)
///   @debug.assert_eq(
///     @challenge_persistent_kd_tree.contains(t, { x: 3, y: 4 }),
///     true,
///   )
/// }
/// ```
pub enum Kd {
  Empty
  Node(point~ : Point, axis~ : Int, left~ : Kd, right~ : Kd)
} derive(Debug)

///|
/// Return the number of points stored in the tree.
pub fn size(t : Kd) -> Int {
  match t {
    Empty => 0
    Node(point=_, axis=_, left~, right~) => 1 + size(left) + size(right)
  }
}

///|
fn coord(p : Point, axis : Int) -> Int {
  if axis == 0 {
    p.x
  } else {
    p.y
  }
}

///|
fn insert_node(t : Kd, p : Point, axis : Int) -> Kd {
  match t {
    Empty => Node(point=p, axis~, left=Empty, right=Empty)
    Node(point=pt, axis=ax, left=l, right=r) =>
      if p == pt {
        t
      } else if coord(p, ax) < coord(pt, ax) {
        Node(point=pt, axis=ax, left=insert_node(l, p, 1 - ax), right=r)
      } else {
        Node(point=pt, axis=ax, left=l, right=insert_node(r, p, 1 - ax))
      }
  }
}

///|
/// Create an empty KD-tree.
pub fn empty() -> Kd {
  Empty
}

///|
/// Insert a point and return the new tree.
pub fn insert(t : Kd, p : Point) -> Kd {
  insert_node(t, p, 0)
}

///|
/// Check whether a point exists in the tree.
pub fn contains(t : Kd, p : Point) -> Bool {
  match t {
    Empty => false
    Node(point=pt, axis=ax, left=l, right=r) =>
      if p == pt {
        true
      } else if coord(p, ax) < coord(pt, ax) {
        contains(l, p)
      } else {
        contains(r, p)
      }
  }
}

///|
/// Iterative containment with reasoning on split axis.
pub fn contains_iter(t : Kd, p : Point) -> Bool {
  match t {
    Empty => false
    Node(point=pt, axis=ax, left=l, right=r) =>
      if p == pt {
        true
      } else if coord(p, ax) < coord(pt, ax) {
        contains_iter(l, p)
      } else {
        contains_iter(r, p)
      }
  }
}

///|
/// Build a KD-tree by inserting points in order.
pub fn from_array(arr : ArrayView[Point]) -> Kd {
  for point in arr; tree = Empty {
    continue insert(tree, point)
  } nobreak {
    tree
  }
}

///|
test "persistent_kd_tree_from_array" {
  let empty_tree = from_array([])
  @debug.assert_eq(size(empty_tree), 0)
  let points : ReadOnlyArray[Point] = [
    { x: 1, y: 2 },
    { x: 3, y: 4 },
    { x: 1, y: 2 },
  ]
  let tree = from_array(points)
  @debug.assert_eq(size(tree), 2)
  @debug.assert_eq(contains(tree, { x: 1, y: 2 }), true)
  @debug.assert_eq(contains(tree, { x: 3, y: 4 }), true)
  @debug.assert_eq(contains(tree, { x: 5, y: 6 }), false)
}
