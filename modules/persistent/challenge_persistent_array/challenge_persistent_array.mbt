// ============================================================================
// Challenge: Persistent Array
// Point updates via a path-copying segment tree
// ============================================================================

///|
enum Node[T] {
  Leaf(value~ : T)
  Branch(left~ : Node[T], right~ : Node[T])
} derive(Debug)

///|
/// A persistent array of length `n` backed by a balanced binary tree.
///
/// Random access (`get_at`) and point update (`set_at`) both run in
/// `O(log n)`; each update returns a new `PArray` that shares all
/// unchanged subtrees with the source, copying only the `O(log n)` nodes
/// on the path to the modified leaf. Construct values with `from_array`
/// and convert back via `to_array`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let a0 = @challenge_persistent_array.from_array([10, 20, 30, 40])
///   let a1 = @challenge_persistent_array.set_at(a0, 2, 99)
///   @debug.assert_eq(@challenge_persistent_array.get_at(a0, 2), Some(30))
///   @debug.assert_eq(@challenge_persistent_array.get_at(a1, 2), Some(99))
/// }
/// ```
pub struct PArray[T] {
  root : Node[T]
  n : Int
} derive(Debug)

///|
fn[T] build(arr : ArrayView[T], l : Int, r : Int) -> Node[T] {
  if r - l == 1 {
    Leaf(value=arr[l])
  } else {
    let mid = (l + r) / 2
    let left = build(arr, l, mid)
    let right = build(arr, mid, r)
    Branch(left~, right~)
  }
}

///|
fn[T] get_node(node : Node[T], l : Int, r : Int, idx : Int) -> T {
  match node {
    Leaf(value~) => value
    Branch(left~, right~) => {
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
    Leaf(value~)
  } else {
    let mid = (l + r) / 2
    match node {
      Leaf(value=_) => Leaf(value~)
      Branch(left~, right~) =>
        if idx < mid {
          Branch(left=set_node(left, l, mid, idx, value), right~)
        } else {
          Branch(left~, right=set_node(right, mid, r, idx, value))
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
pub fn[T] to_array(arr : PArray[T]) -> Array[T] {
  let out = Array::new()
  for i in 0..<arr.n {
    out.push(get_node(arr.root, 0, arr.n, i))
  }
  out
}
