// ============================================================================
// Challenge: Persistent Fenwick (Range Add / Range Sum)
// Two persistent BITs with path-copying updates
// ============================================================================

///|
enum Node {
  Leaf(value~ : Int)
  Branch(left~ : Node, right~ : Node)
} derive(Debug)

///|
struct Fenwick {
  root : Node
  n : Int
} derive(Debug)

///|
/// A persistent Fenwick structure of `n` integers that supports both
/// range add (`range_add`) and range sum (`range_sum`).
///
/// Two persistent BIT arrays cooperate via the standard
/// `(bit1, bit2)` trick: `bit1` records first-order deltas and `bit2`
/// records weighted deltas so that the prefix sum reconstructs as
/// `bit1.prefix * x - bit2.prefix`. Each `range_add` performs four point
/// updates and costs `O(log^2 n)`; queries cost `O(log^2 n)`. Updates
/// share the unchanged BIT subtrees with the source, so old versions are
/// preserved. Construct with `make`, then call `range_add`,
/// `prefix_sum_range`, `range_sum`, or `apply_updates`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let rf = @challenge_persistent_fenwick_range_add.make(6)
///   let rf = @challenge_persistent_fenwick_range_add.range_add(rf, 1, 3, 5)
///   let rf = @challenge_persistent_fenwick_range_add.range_add(rf, 2, 4, 2)
///   @debug.assert_eq(
///     @challenge_persistent_fenwick_range_add.range_sum(rf, 0, 5),
///     21,
///   )
/// }
/// ```
pub struct RangeFenwick {
  bit1 : Fenwick
  bit2 : Fenwick
  n : Int
} derive(Debug)

///|
fn build_zero(l : Int, r : Int) -> Node {
  if r - l == 1 {
    Leaf(value=0)
  } else {
    let mid = (l + r) / 2
    let left = build_zero(l, mid)
    let right = build_zero(mid, r)
    Branch(left~, right~)
  }
}

///|
fn array_get(node : Node, l : Int, r : Int, idx : Int) -> Int {
  match node {
    Leaf(value~) => value
    Branch(left~, right~) => {
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
    Leaf(value~)
  } else {
    let mid = (l + r) / 2
    match node {
      Leaf(value=_) => Leaf(value~)
      Branch(left~, right~) =>
        if idx < mid {
          Branch(left=array_set(left, l, mid, idx, value), right~)
        } else {
          Branch(left~, right=array_set(right, mid, r, idx, value))
        }
    }
  }
}

///|
fn make_bit(n : Int) -> Fenwick {
  { root: build_zero(0, n), n }
}

///|
fn add_point(bit : Fenwick, idx : Int, delta : Int) -> Fenwick {
  for i = idx, tree = bit.root {
    if i >= bit.n {
      break { root: tree, n: bit.n }
    } else {
      let current = array_get(tree, 0, bit.n, i)
      let updated = array_set(tree, 0, bit.n, i, current + delta)
      continue i + (i & -i), updated
    }
  } where {
    proof_invariant: i >= 1 && i <= bit.n,
    proof_reasoning: (
      #|INVARIANT (BIT add):
      #|tree reflects delta applied to all visited indices so far.
      #|MAINTENANCE:
      #|Update index i and move to i + lowbit(i).
      #|TERMINATION:
      #|When i >= n, all affected nodes are updated.
    ),
  }
}

///|
fn prefix_sum(bit : Fenwick, idx : Int) -> Int {
  for i = idx, acc = 0 {
    if i <= 0 {
      break acc
    } else {
      let current = array_get(bit.root, 0, bit.n, i)
      continue i - (i & -i), acc + current
    }
  } where {
    proof_invariant: i >= 0 && i <= bit.n,
    proof_reasoning: (
      #|INVARIANT (BIT prefix):
      #|acc equals the sum of BIT nodes already traversed.
      #|MAINTENANCE:
      #|Add tree[i] and move to i - lowbit(i).
      #|TERMINATION:
      #|At i = 0, acc is the prefix sum.
    ),
  }
}

///|
/// Create a range-update Fenwick structure with n elements.
pub fn make(n : Int) -> RangeFenwick {
  let size = n + 2
  { bit1: make_bit(size), bit2: make_bit(size), n }
}

///|
/// Return the number of elements tracked by the structure.
pub fn length(rf : RangeFenwick) -> Int {
  rf.n
}

///|
/// Add delta to all indices in [l, r] (inclusive).
pub fn range_add(
  rf : RangeFenwick,
  l : Int,
  r : Int,
  delta : Int,
) -> RangeFenwick {
  if l > r {
    rf
  } else {
    let l1 = l + 1
    let r1 = r + 1
    let bit1a = add_point(rf.bit1, l1, delta)
    let bit1b = add_point(bit1a, r1 + 1, -delta)
    let bit2a = add_point(rf.bit2, l1, delta * (l1 - 1))
    let bit2b = add_point(bit2a, r1 + 1, -delta * r1)
    { bit1: bit1b, bit2: bit2b, n: rf.n }
  }
}

///|
/// Return prefix sum over [0, idx] after range updates.
pub fn prefix_sum_range(rf : RangeFenwick, idx : Int) -> Int {
  if idx < 0 {
    0
  } else {
    let x = idx + 1
    let s1 = prefix_sum(rf.bit1, x)
    let s2 = prefix_sum(rf.bit2, x)
    s1 * x - s2
  }
}

///|
/// Query the sum over [l, r] (inclusive).
pub fn range_sum(rf : RangeFenwick, l : Int, r : Int) -> Int {
  if l > r {
    0
  } else {
    prefix_sum_range(rf, r) - prefix_sum_range(rf, l - 1)
  }
}

///|
/// Apply range adds (l, r, delta) inclusive.
pub fn apply_updates(
  rf : RangeFenwick,
  updates : ArrayView[(Int, Int, Int)],
) -> RangeFenwick {
  for update in updates; cur = rf {
    let (l, r, delta) = update
    continue range_add(cur, l, r, delta)
  } nobreak {
    cur
  }
}
