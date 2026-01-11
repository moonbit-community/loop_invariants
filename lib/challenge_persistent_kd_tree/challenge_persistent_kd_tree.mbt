// ============================================================================
// Challenge: Persistent KD-Tree (2D)
// Immutable insertion with alternating split axis
// ============================================================================

///|
struct Point {
  x : Int
  y : Int
} derive(Show, Eq)

///|
enum Kd {
  Empty
  Node(point~ : Point, axis~ : Int, left~ : Kd, right~ : Kd)
} derive(Show)

///|
fn size(t : Kd) -> Int {
  match t {
    Kd::Empty => 0
    Kd::Node(point=_, axis=_, left~, right~) => 1 + size(left) + size(right)
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
fn insert(t : Kd, p : Point, axis : Int) -> Kd {
  match t {
    Kd::Empty => Kd::Node(point=p, axis~, left=Kd::Empty, right=Kd::Empty)
    Kd::Node(point=pt, axis=ax, left=l, right=r) =>
      if p == pt {
        t
      } else if coord(p, ax) < coord(pt, ax) {
        Kd::Node(point=pt, axis=ax, left=insert(l, p, 1 - ax), right=r)
      } else {
        Kd::Node(point=pt, axis=ax, left=l, right=insert(r, p, 1 - ax))
      }
  }
}

///|
fn contains(t : Kd, p : Point) -> Bool {
  match t {
    Kd::Empty => false
    Kd::Node(point=pt, axis=ax, left=l, right=r) =>
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
#warnings("+missing_invariant+missing_reasoning")
fn contains_iter(t : Kd, p : Point) -> Bool {
  for cur = t {
    match cur {
      Kd::Empty => break false
      Kd::Node(point=pt, axis=ax, left=l, right=r) =>
        if p == pt {
          break true
        } else if coord(p, ax) < coord(pt, ax) {
          continue l
        } else {
          continue r
        }
    }
  } where {
    invariant: cur is Kd::Empty || size(cur) >= 1,
    reasoning: (
      #|INVARIANT (KD-tree walk):
      #|cur is the subtree that can still contain p based on prior splits.
      #|MAINTENANCE:
      #|Use the stored axis to choose the side consistent with p.
      #|TERMINATION:
      #|Empty subtree means absent; matching point returns true.
    ),
  }
}

///|
/// Build a KD-tree by inserting points in order.
#warnings("+missing_invariant+missing_reasoning")
fn from_array(arr : ArrayView[Point]) -> Kd {
  let n = arr.length()
  for i = 0, tree = Kd::Empty {
    if i >= n {
      break tree
    } else {
      continue i + 1, insert(tree, arr[i], 0)
    }
  } where {
    invariant: i >= 0 && i <= n,
    invariant: size(tree) == i,
    reasoning: (
      #|INVARIANT (KD-tree build):
      #|tree contains the first i points with axis alternating down the path.
      #|MAINTENANCE:
      #|Insert arr[i], preserving the split rule and increasing size by one.
      #|TERMINATION:
      #|At i = n, all points are inserted.
    ),
  }
}

///|
test "persistent_kd_tree" {
  let pts = [
    Point::{ x: 2, y: 3 },
    Point::{ x: 5, y: 4 },
    Point::{ x: 1, y: 7 },
  ]
  let tree = from_array(pts[:])
  assert_eq(contains(tree, Point::{ x: 5, y: 4 }), true)
  assert_eq(contains_iter(tree, Point::{ x: 1, y: 7 }), true)
  assert_eq(contains_iter(tree, Point::{ x: 4, y: 4 }), false)
}
