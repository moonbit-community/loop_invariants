// ============================================================================
// Challenge: Persistent Union-Find
// Parent and size arrays via path-copying segment tree
// ============================================================================

///|
enum Node {
  Leaf(value~ : Int)
  Branch(left~ : Node, right~ : Node)
} derive(Show)

///|
struct PArray {
  root : Node
  n : Int
} derive(Show)

///|
pub struct DSU {
  parent : PArray
  size : PArray
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
fn get(node : Node, l : Int, r : Int, idx : Int) -> Int {
  match node {
    Node::Leaf(value~) => value
    Node::Branch(left~, right~) => {
      let mid = (l + r) / 2
      if idx < mid {
        get(left, l, mid, idx)
      } else {
        get(right, mid, r, idx)
      }
    }
  }
}

///|
fn set(node : Node, l : Int, r : Int, idx : Int, value : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(value~)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(value=_) => Node::Leaf(value~)
      Node::Branch(left~, right~) =>
        if idx < mid {
          Node::Branch(left=set(left, l, mid, idx, value), right~)
        } else {
          Node::Branch(left~, right=set(right, mid, r, idx, value))
        }
    }
  }
}

///|
fn make_array(arr : ArrayView[Int]) -> PArray {
  let n = arr.length()
  { root: build(arr, 0, n), n }
}

///|
fn array_get(arr : PArray, idx : Int) -> Int {
  get(arr.root, 0, arr.n, idx)
}

///|
fn array_set(arr : PArray, idx : Int, value : Int) -> PArray {
  { root: set(arr.root, 0, arr.n, idx, value), n: arr.n }
}

///|
/// Create a persistent DSU with n singleton elements.
pub fn make(n : Int) -> DSU {
  let parents = Array::makei(n, i => i)
  let sizes = Array::make(n, 1)
  { parent: make_array(parents[:]), size: make_array(sizes[:]) }
}

///|
/// Find the representative of x without path compression.
pub fn find(dsu : DSU, x : Int) -> Int {
  let p = array_get(dsu.parent, x)
  if p == x {
    x
  } else {
    find(dsu, p)
  }
}

///|
/// Return a new DSU after unioning the sets containing a and b.
pub fn union(dsu : DSU, a : Int, b : Int) -> DSU {
  let ra = find(dsu, a)
  let rb = find(dsu, b)
  if ra == rb {
    dsu
  } else {
    let sa = array_get(dsu.size, ra)
    let sb = array_get(dsu.size, rb)
    if sa < sb {
      let parent2 = array_set(dsu.parent, ra, rb)
      let size2 = array_set(dsu.size, rb, sa + sb)
      { parent: parent2, size: size2 }
    } else {
      let parent2 = array_set(dsu.parent, rb, ra)
      let size2 = array_set(dsu.size, ra, sa + sb)
      { parent: parent2, size: size2 }
    }
  }
}

///|
/// Check whether a and b belong to the same set.
pub fn same(dsu : DSU, a : Int, b : Int) -> Bool {
  find(dsu, a) == find(dsu, b)
}
