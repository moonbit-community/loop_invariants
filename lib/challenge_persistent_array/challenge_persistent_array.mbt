// ============================================================================
// Challenge: Persistent Array
// Point updates via a path-copying segment tree
// ============================================================================

///|
enum Node[T] {
  Leaf(value~ : T)
  Branch(left~ : Node[T], right~ : Node[T])
} derive(Show)

///|
pub struct PArray[T] {
  root : Node[T]
  n : Int
} derive(Show)

///|
fn[T] build(arr : ArrayView[T], l : Int, r : Int) -> Node[T] {
  if r - l == 1 {
    Node::Leaf(value=arr[l])
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    Node::Branch(left~, right~)
  }
}

///|
fn[T] get_node(node : Node[T], l : Int, r : Int, idx : Int) -> T {
  match node {
    Node::Leaf(value~) => value
    Node::Branch(left~, right~) => {
      let mid = (l + r) / 2
      if idx < mid {
        get_node(left, l, mid, idx)
      } else {
        get_node(right, mid, r, idx)
      }
    }
  }
}

///|
fn[T] set_node(
  node : Node[T],
  l : Int,
  r : Int,
  idx : Int,
  value : T,
) -> Node[T] {
  if r - l == 1 {
    Node::Leaf(value~)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(value=_) => Node::Leaf(value~)
      Node::Branch(left~, right~) =>
        if idx < mid {
          Node::Branch(left=set_node(left, l, mid, idx, value), right~)
        } else {
          Node::Branch(left~, right=set_node(right, mid, r, idx, value))
        }
    }
  }
}

///|
/// Build a persistent array from a mutable array view.
pub fn[T] from_array(arr : ArrayView[T]) -> PArray[T] {
  let n = arr.length()
  { root: build(arr, 0, n), n }
}

///|
/// Return the length of the persistent array.
pub fn[T] length(arr : PArray[T]) -> Int {
  arr.n
}

///|
/// Get the value at idx, or None if out of range.
pub fn[T] get_at(arr : PArray[T], idx : Int) -> T? {
  if idx < 0 || idx >= arr.n {
    None
  } else {
    Some(get_node(arr.root, 0, arr.n, idx))
  }
}

///|
/// Set the value at idx and return the new persistent array.
pub fn[T] set_at(arr : PArray[T], idx : Int, value : T) -> PArray[T] {
  if idx < 0 || idx >= arr.n {
    arr
  } else {
    { root: set_node(arr.root, 0, arr.n, idx, value), n: arr.n }
  }
}

///|
/// Materialize the persistent array to a mutable array.
#warnings("+missing_invariant+missing_reasoning")
pub fn[T] to_array(arr : PArray[T]) -> Array[T] {
  let out = Array::new()
  for i = 0; i < arr.n; i = i + 1 {
    out.push(get_node(arr.root, 0, arr.n, i))
  } where {
    invariant: i >= 0 && i <= arr.n,
    invariant: out.length() == i,
    reasoning: (
      #|INVARIANT (Prefix materialization):
      #|out holds get_at(arr, 0..i) in order, and i equals out.length().
      #|MAINTENANCE:
      #|Append index i, preserving prefix correctness.
      #|TERMINATION:
      #|At i = n, out is the full materialization.
    ),
  }
  out
}
