// ============================================================================
// Challenge: Persistent Array
// Point updates via a path-copying segment tree
// ============================================================================

///|
enum Node {
  Leaf(value~ : Int)
  Branch(left~ : Node, right~ : Node)
} derive(Show)

///|
pub struct PArray {
  root : Node
  n : Int
} derive(Show)

///|
fn build(arr : ArrayView[Int], l : Int, r : Int) -> Node {
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
fn get_node(node : Node, l : Int, r : Int, idx : Int) -> Int {
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
fn set_node(node : Node, l : Int, r : Int, idx : Int, value : Int) -> Node {
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
pub fn from_array(arr : ArrayView[Int]) -> PArray {
  let n = arr.length()
  { root: build(arr, 0, n), n }
}

///|
/// Return the length of the persistent array.
pub fn length(arr : PArray) -> Int {
  arr.n
}

///|
/// Get the value at idx, or None if out of range.
pub fn get_at(arr : PArray, idx : Int) -> Int? {
  if idx < 0 || idx >= arr.n {
    None
  } else {
    Some(get_node(arr.root, 0, arr.n, idx))
  }
}

///|
/// Set the value at idx and return the new persistent array.
pub fn set_at(arr : PArray, idx : Int, value : Int) -> PArray {
  if idx < 0 || idx >= arr.n {
    arr
  } else {
    { root: set_node(arr.root, 0, arr.n, idx, value), n: arr.n }
  }
}

///|
/// Materialize the persistent array to a mutable array.
#warnings("+missing_invariant+missing_reasoning")
pub fn to_array(arr : PArray) -> Array[Int] {
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

///|
test "persistent_array" {
  let arr = from_array([1, 2, 3, 4][:])
  assert_eq(get_at(arr, 2), Some(3))
  let arr2 = set_at(arr, 1, 10)
  assert_eq(get_at(arr, 1), Some(2))
  assert_eq(get_at(arr2, 1), Some(10))
  assert_eq(to_array(arr2), [1, 10, 3, 4])
}
