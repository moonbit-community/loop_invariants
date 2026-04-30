// ============================================================================
// Challenge: Persistent Bitset
// Path-copying segment tree for set/test/count
// ============================================================================

///|
enum Node {
  Leaf(count~ : Int)
  Branch(count~ : Int, left~ : Node, right~ : Node)
} derive(Debug)

///|
pub struct Bitset {
  root : Node
  n : Int
} derive(Debug)

///|
fn node_count(node : Node) -> Int {
  match node {
    Leaf(count~) => count
    Branch(count~, left=_, right=_) => count
  }
}

///|

///|
fn build_zero(l : Int, r : Int) -> Node {
  if r - l == 1 {
    Leaf(count=0)
  } else {
    let mid = (l + r) / 2
    let left = build_zero(l, mid)
    let right = build_zero(mid, r)
    Branch(count=0, left~, right~)
  }
}

///|
fn set_bit(node : Node, l : Int, r : Int, idx : Int, value : Int) -> Node {
  if r - l == 1 {
    Leaf(count=value)
  } else {
    let mid = (l + r) / 2
    match node {
      Leaf(count=_) => Leaf(count=value)
      Branch(left~, right~, count=_) =>
        if idx < mid {
          let new_left = set_bit(left, l, mid, idx, value)
          Branch(
            count=node_count(new_left) + node_count(right),
            left=new_left,
            right~,
          )
        } else {
          let new_right = set_bit(right, mid, r, idx, value)
          Branch(
            count=node_count(left) + node_count(new_right),
            left~,
            right=new_right,
          )
        }
    }
  }
}

///|
fn get_bit(node : Node, l : Int, r : Int, idx : Int) -> Int {
  match node {
    Leaf(count~) => count
    Branch(left~, right~, count=_) => {
      let mid = (l + r) / 2
      if idx < mid {
        get_bit(left, l, mid, idx)
      } else {
        get_bit(right, mid, r, idx)
      }
    }
  }
}

///|
fn count_range_node(node : Node, l : Int, r : Int, ql : Int, qr : Int) -> Int {
  if qr <= l || r <= ql {
    0
  } else if ql <= l && r <= qr {
    node_count(node)
  } else {
    let mid = (l + r) / 2
    match node {
      Leaf(count=_) => node_count(node)
      Branch(left~, right~, count=_) =>
        count_range_node(left, l, mid, ql, qr) +
        count_range_node(right, mid, r, ql, qr)
    }
  }
}

///|
/// Create a bitset of length n initialized to zeros.
pub fn make(n : Int) -> Bitset {
  { root: build_zero(0, n), n }
}

///|
/// Set index idx to value (0 or 1) and return the new bitset.
pub fn set(bs : Bitset, idx : Int, value : Int) -> Bitset {
  if idx < 0 || idx >= bs.n {
    bs
  } else {
    { root: set_bit(bs.root, 0, bs.n, idx, value), n: bs.n }
  }
}

///|
/// Get the bit at idx (0 if out of range).
pub fn get(bs : Bitset, idx : Int) -> Int {
  if idx < 0 || idx >= bs.n {
    0
  } else {
    get_bit(bs.root, 0, bs.n, idx)
  }
}

///|
/// Return the length of the bitset.
pub fn length(bs : Bitset) -> Int {
  bs.n
}

///|
/// Count number of set bits in [ql, qr).
pub fn count_range(bs : Bitset, ql : Int, qr : Int) -> Int {
  count_range_node(bs.root, 0, bs.n, ql, qr)
}

///|
/// Build a bitset by setting indices to 1.
pub fn from_indices(n : Int, idxs : ArrayView[Int]) -> Bitset {
  for idx in idxs; bs = make(n) {
    continue set(bs, idx, 1)
  } nobreak {
    bs
  }
}
