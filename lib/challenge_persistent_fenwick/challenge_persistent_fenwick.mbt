// ============================================================================
// Challenge: Persistent Fenwick Tree
// Persistent BIT via a path-copying array
// ============================================================================

///|
enum Node {
  Leaf(value~ : Int)
  Branch(left~ : Node, right~ : Node)
} derive(Show)

///|
pub struct Fenwick {
  root : Node
  n : Int
} derive(Show)

///|
fn build_zero(l : Int, r : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(value=0)
  } else {
    let mid = (l + r) / 2
    let left = build_zero(l, mid)
    let right = build_zero(mid, r)
    Node::Branch(left~, right~)
  }
}

///|
fn array_get(node : Node, l : Int, r : Int, idx : Int) -> Int {
  match node {
    Node::Leaf(value~) => value
    Node::Branch(left~, right~) => {
      let mid = (l + r) / 2
      if idx < mid {
        array_get(left, l, mid, idx)
      } else {
        array_get(right, mid, r, idx)
      }
    }
  }
}

///|
fn array_set(node : Node, l : Int, r : Int, idx : Int, value : Int) -> Node {
  if r - l == 1 {
    Node::Leaf(value~)
  } else {
    let mid = (l + r) / 2
    match node {
      Node::Leaf(value=_) => Node::Leaf(value~)
      Node::Branch(left~, right~) =>
        if idx < mid {
          Node::Branch(left=array_set(left, l, mid, idx, value), right~)
        } else {
          Node::Branch(left~, right=array_set(right, mid, r, idx, value))
        }
    }
  }
}

///|
fn tree_shape(node : Node, len : Int) -> Bool {
  match node {
    Node::Leaf(value=_) => len == 1
    Node::Branch(left~, right~) =>
      if len <= 1 {
        false
      } else {
        let mid = len / 2
        tree_shape(left, mid) && tree_shape(right, len - mid)
      }
  }
}

///|
/// Create a persistent Fenwick tree with n zeroed elements.
pub fn make(n : Int) -> Fenwick {
  let size = n + 1
  { root: build_zero(0, size), n }
}

///|
/// Return the number of elements tracked by the tree.
pub fn length(fw : Fenwick) -> Int {
  fw.n
}

///|
/// Add delta at index idx (0-based).
#warnings("+missing_invariant+missing_reasoning")
pub fn add(fw : Fenwick, idx : Int, delta : Int) -> Fenwick {
  if idx < 0 || idx >= fw.n {
    return fw
  }
  let size = fw.n + 1
  for i = idx + 1, tree = fw.root {
    if i >= size {
      break { root: tree, n: fw.n }
    } else {
      let current = array_get(tree, 0, size, i)
      let updated = array_set(tree, 0, size, i, current + delta)
      continue i + (i & -i), updated
    }
  } where {
    invariant: i >= 1 && i <= size,
    invariant: tree_shape(tree, size),
    reasoning: (
      #|INVARIANT (Fenwick update):
      #|tree stores the original BIT with delta applied to all visited indices.
      #|MAINTENANCE:
      #|Update position i, then advance to i + lowbit(i), preserving structure.
      #|TERMINATION:
      #|When i >= size, all affected BIT nodes have been updated.
    ),
  }
}

///|
/// Prefix sum for [0, idx] (0-based, inclusive).
#warnings("+missing_invariant+missing_reasoning")
pub fn prefix_sum(fw : Fenwick, idx : Int) -> Int {
  if idx < 0 {
    return 0
  }
  let capped = if idx >= fw.n { fw.n - 1 } else { idx }
  let size = fw.n + 1
  for i = capped + 1, acc = 0 {
    if i <= 0 {
      break acc
    } else {
      let current = array_get(fw.root, 0, size, i)
      continue i - (i & -i), acc + current
    }
  } where {
    invariant: i >= 0 && i <= size,
    invariant: tree_shape(fw.root, size),
    reasoning: (
      #|INVARIANT (Prefix sum accumulation):
      #|acc equals the sum of BIT blocks already traversed for the prefix.
      #|MAINTENANCE:
      #|Add tree[i] and move to i - lowbit(i), covering the next block.
      #|TERMINATION:
      #|At i = 0, acc equals the full prefix sum.
    ),
  }
}

///|
/// Query the sum over [l, r] (inclusive).
pub fn range_sum(fw : Fenwick, l : Int, r : Int) -> Int {
  if l > r {
    0
  } else {
    let left = if l <= 0 { 0 } else { prefix_sum(fw, l - 1) }
    prefix_sum(fw, r) - left
  }
}

///|
test "persistent_fenwick" {
  let fw0 = make(5)
  let fw1 = add(fw0, 0, 3)
  let fw2 = add(fw1, 2, 4)
  let fw3 = add(fw2, 4, 1)
  assert_eq(prefix_sum(fw3, 2), 7)
  assert_eq(range_sum(fw3, 1, 4), 5)
  assert_eq(prefix_sum(fw0, 4), 0)
}
