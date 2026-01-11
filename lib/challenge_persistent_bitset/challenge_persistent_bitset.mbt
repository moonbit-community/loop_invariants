// ============================================================================
// Challenge: Persistent Bitset
// Path-copying segment tree for set/test/count
// ============================================================================

///|
enum Node {
  Leaf(count~ : Int)
  Branch(count~ : Int, left~ : Node, right~ : Node)
} derive(Show)

///|
pub struct Bitset {
  root : Node
  n : Int
} derive(Show)

///|
fn node_count(node : Node) -> Int {
  match node {
    Node::Leaf(count~) => count
    Node::Branch(count~, left=_, right=_) => count
  }
}

///|
fn tree_valid(node : Node, len : Int) -> Bool {
  match node {
    Node::Leaf(count=_) => len == 1
    Node::Branch(count=cv, left~, right~) =>
      if len <= 1 {
        false
      } else {
        let mid = len / 2
        tree_valid(left, mid) &&
        tree_valid(right, len - mid) &&
        cv == node_count(left) + node_count(right)
      }
  }
}

///|
fn build_zero(l : Int, r : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(count=0)
  } else {
    let mid = (l + r) / 2
    let left = build_zero(l, mid)
    let right = build_zero(mid, r)
    Node::Branch(count=0, left~, right~)
  }
}

///|
fn set_bit(node : Node, l : Int, r : Int, idx : Int, value : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(count=value)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(count=_) => Node::Leaf(count=value)
      Node::Branch(left~, right~, count=_) =>
        if idx < mid {
          let new_left = set_bit(left, l, mid, idx, value)
          Node::Branch(
            count=node_count(new_left) + node_count(right),
            left=new_left,
            right~,
          )
        } else {
          let new_right = set_bit(right, mid, r, idx, value)
          Node::Branch(
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
    Node::Leaf(count~) => count
    Node::Branch(left~, right~, count=_) => {
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
      Node::Leaf(count=_) => node_count(node)
      Node::Branch(left~, right~, count=_) =>
        count_range_node(left, l, mid, ql, qr) +
        count_range_node(right, mid, r, ql, qr)
    }
  }
}

///|
pub fn make(n : Int) -> Bitset {
  { root: build_zero(0, n), n }
}

///|
pub fn set(bs : Bitset, idx : Int, value : Int) -> Bitset {
  if idx < 0 || idx >= bs.n {
    bs
  } else {
    { root: set_bit(bs.root, 0, bs.n, idx, value), n: bs.n }
  }
}

///|
pub fn get(bs : Bitset, idx : Int) -> Int {
  if idx < 0 || idx >= bs.n {
    0
  } else {
    get_bit(bs.root, 0, bs.n, idx)
  }
}

///|
pub fn length(bs : Bitset) -> Int {
  bs.n
}

///|
pub fn count_range(bs : Bitset, ql : Int, qr : Int) -> Int {
  count_range_node(bs.root, 0, bs.n, ql, qr)
}

///|
/// Build a bitset by setting indices to 1.
#warnings("+missing_invariant+missing_reasoning")
pub fn from_indices(n : Int, idxs : ArrayView[Int]) -> Bitset {
  let m = idxs.length()
  for i = 0, bs = make(n) {
    if i >= m {
      break bs
    } else {
      continue i + 1, set(bs, idxs[i], 1)
    }
  } where {
    invariant: i >= 0 && i <= m,
    invariant: tree_valid(bs.root, bs.n),
    reasoning: (
      #|INVARIANT (Bitset build):
      #|bs reflects the first i indices set to 1.
      #|MAINTENANCE:
      #|Set idxs[i], preserving the count invariants.
      #|TERMINATION:
      #|At i = m, all indices are set.
    ),
  }
}

///|
test "persistent_bitset" {
  let bs0 = make(8)
  let bs1 = set(bs0, 2, 1)
  let bs2 = set(bs1, 5, 1)
  assert_eq(get(bs2, 2), 1)
  assert_eq(get(bs2, 3), 0)
  assert_eq(count_range(bs2, 0, 6), 2)
  let built : Bitset = from_indices(8, [1, 4, 7][:])
  assert_eq(count_range(built, 0, 8), 3)
}
