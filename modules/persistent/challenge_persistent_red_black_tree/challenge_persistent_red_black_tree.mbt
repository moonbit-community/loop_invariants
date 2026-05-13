// ============================================================================
// Challenge: Persistent Red-Black Tree (Okasaki)
// Balanced BST with two-bit balance state and path-copying inserts
// ============================================================================
//
// A red-black tree is a binary search tree where every node carries a single
// `Red` / `Black` color bit. The tree satisfies four classical invariants:
//
//   RB1.  Every node is either red or black.
//   RB2.  The root is black.
//   RB3.  No red node has a red child (no two reds in a row).
//   RB4.  Every root-to-leaf path passes through the same number of black
//         nodes (the "black height" is uniform).
//
// Together RB3 and RB4 force the tree height to be at most `2 * log2(n + 1)`,
// so search and insert run in `O(log n)` time. This implementation follows
// Okasaki's functional formulation: every operation is non-destructive and
// returns a new tree that shares all untouched subtrees with the input
// (path copying), so a chain of inserts produces a chain of versions all
// usable simultaneously.

///|
/// Node color in a red-black tree. `Red` nodes may not have red children
/// (invariant RB3); the root is always painted `Black` after insertion
/// (invariant RB2).
pub enum Color {
  Red
  Black
} derive(Debug, Eq)

///|
/// A persistent red-black set storing keys of type `T`.
///
/// Each interior node records its own `color` so the four classical RB
/// invariants (color, root-black, no red-red, uniform black height) can be
/// preserved by a single pattern-matching `balance` step after each
/// recursive insert. Operations are non-destructive: `insert` returns a new
/// tree that shares every untouched subtree with the source, copying only
/// the root-to-leaf path (`O(log n)` extra memory per insert). See `empty`,
/// `insert`, `contains`, `inorder`, `size`, and `from_array`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let s = @challenge_persistent_red_black_tree.from_array(
///     [3, 1, 4, 1, 5, 9, 2, 6][:],
///   )
///   @debug.assert_eq(@challenge_persistent_red_black_tree.contains(s, 4), true)
///   @debug.assert_eq(@challenge_persistent_red_black_tree.contains(s, 7), false)
///   @debug.assert_eq(@challenge_persistent_red_black_tree.inorder(s), [
///     1, 2, 3, 4, 5, 6, 9,
///   ])
/// }
/// ```
pub enum RB[T] {
  Empty
  Node(color~ : Color, key~ : T, left~ : RB[T], right~ : RB[T])
} derive(Debug)

///|
fn[T] color_of(t : RB[T]) -> Color {
  match t {
    Empty => Black
    Node(color~, key=_, left=_, right=_) => color
  }
}

///|
/// Return the number of keys stored in the set.
pub fn[T] size(t : RB[T]) -> Int {
  match t {
    Empty => 0
    Node(color=_, key=_, left~, right~) => 1 + size(left) + size(right)
  }
}

///|
fn[T : Compare] within_bounds(value : T, lo : T?, hi : T?) -> Bool {
  let lo_ok = match lo {
    None => true
    Some(l) => value > l
  }
  let hi_ok = match hi {
    None => true
    Some(h) => value < h
  }
  lo_ok && hi_ok
}

///|
/// Number of black nodes on any root-to-leaf path of `t`, counting the
/// implicit black `Empty` leaves. Returns `-1` when the tree violates the
/// uniform black-height invariant; otherwise returns the common count.
fn[T] black_height(t : RB[T]) -> Int {
  match t {
    Empty => 1
    Node(color~, key=_, left~, right~) => {
      let lh = black_height(left)
      let rh = black_height(right)
      if lh < 0 || rh < 0 || lh != rh {
        -1
      } else if color == Black {
        lh + 1
      } else {
        lh
      }
    }
  }
}

///|
/// Whether the tree satisfies RB1-RB4 (color, BST order under `(lo, hi)`,
/// no red-red, uniform black height) and additionally requires the root to
/// be black (RB2). Used by tests; not exposed publicly.
fn[T : Compare] rb_valid(t : RB[T], lo : T?, hi : T?) -> Bool {
  bst_valid(t, lo, hi) &&
  color_of(t) == Black &&
  no_red_red(t) &&
  black_height(t) > 0
}

///|
fn[T : Compare] bst_valid(t : RB[T], lo : T?, hi : T?) -> Bool {
  match t {
    Empty => true
    Node(color=_, key=k, left~, right~) =>
      within_bounds(k, lo, hi) &&
      bst_valid(left, lo, Some(k)) &&
      bst_valid(right, Some(k), hi)
  }
}

///|
fn[T] no_red_red(t : RB[T]) -> Bool {
  match t {
    Empty => true
    Node(color~, key=_, left~, right~) => {
      let parent_ok = if color == Red {
        color_of(left) == Black && color_of(right) == Black
      } else {
        true
      }
      parent_ok && no_red_red(left) && no_red_red(right)
    }
  }
}

///|
/// Okasaki's balance step. After inserting recursively, the only way RB3
/// can fail is for a black node to have a red child that itself has a red
/// grandchild. The four `Node(Black, ..)` shapes below enumerate the four
/// positions the offending red-red pair can occupy; in every case we
/// rewrite the local subtree into a red parent with two black children,
/// pushing the red upwards. Any other shape is already balanced.
fn[T] balance(color : Color, key : T, left : RB[T], right : RB[T]) -> RB[T] {
  match (color, left, right) {
    // Left-left:  Black(z, Red(y, Red(x, a, b), c), d)
    (
      Black,
      Node(
        color=Red,
        key=y,
        left=Node(color=Red, key=x, left=a, right=b),
        right=c
      ),
      d,
    ) =>
      Node(
        color=Red,
        key=y,
        left=Node(color=Black, key=x, left=a, right=b),
        right=Node(color=Black, key~, left=c, right=d),
      )
    // Left-right: Black(z, Red(x, a, Red(y, b, c)), d)
    (
      Black,
      Node(
        color=Red,
        key=x,
        left=a,
        right=Node(color=Red, key=y, left=b, right=c)
      ),
      d,
    ) =>
      Node(
        color=Red,
        key=y,
        left=Node(color=Black, key=x, left=a, right=b),
        right=Node(color=Black, key~, left=c, right=d),
      )
    // Right-left: Black(x, a, Red(z, Red(y, b, c), d))
    (
      Black,
      a,
      Node(
        color=Red,
        key=z,
        left=Node(color=Red, key=y, left=b, right=c),
        right=d
      ),
    ) =>
      Node(
        color=Red,
        key=y,
        left=Node(color=Black, key~, left=a, right=b),
        right=Node(color=Black, key=z, left=c, right=d),
      )
    // Right-right: Black(x, a, Red(y, b, Red(z, c, d)))
    (
      Black,
      a,
      Node(
        color=Red,
        key=y,
        left=b,
        right=Node(color=Red, key=z, left=c, right=d)
      ),
    ) =>
      Node(
        color=Red,
        key=y,
        left=Node(color=Black, key~, left=a, right=b),
        right=Node(color=Black, key=z, left=c, right=d),
      )
    _ => Node(color~, key~, left~, right~)
  }
}

///|
fn[T : Compare] ins(t : RB[T], key : T) -> RB[T] {
  match t {
    Empty => Node(color=Red, key~, left=Empty, right=Empty)
    Node(color~, key=k, left~, right~) =>
      if key == k {
        t
      } else if key < k {
        balance(color, k, ins(left, key), right)
      } else {
        balance(color, k, left, ins(right, key))
      }
  }
}

///|
/// Create an empty red-black set.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let s : @challenge_persistent_red_black_tree.RB[Int] = @challenge_persistent_red_black_tree.empty()
///   @debug.assert_eq(@challenge_persistent_red_black_tree.size(s), 0)
/// }
/// ```
pub fn[T] empty() -> RB[T] {
  Empty
}

///|
/// Insert `key` and return a new red-black set. The original tree is
/// preserved and shares all subtrees off the insertion path.
///
/// After the recursive insert restores RB3 in every interior subtree, the
/// root is repainted black to enforce RB2; this may increase the black
/// height by one but never violates RB4.
///
/// ## Parameters
///
/// - `t`   : the source tree (any version).
/// - `key` : key to insert; duplicates are ignored (set semantics).
///
/// ## Returns
///
/// A new tree containing `key`, sharing every off-path subtree with `t`.
/// Time and extra memory: `O(log n)`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let s = @challenge_persistent_red_black_tree.empty()
///   let s = @challenge_persistent_red_black_tree.insert(s, 5)
///   let s = @challenge_persistent_red_black_tree.insert(s, 2)
///   @debug.assert_eq(@challenge_persistent_red_black_tree.contains(s, 5), true)
/// }
/// ```
pub fn[T : Compare] insert(t : RB[T], key : T) -> RB[T] {
  match ins(t, key) {
    Empty => Empty
    Node(color=_, key=k, left~, right~) =>
      Node(color=Black, key=k, left~, right~)
  }
}

///|
/// Membership test for `key`. Runs in `O(log n)` time on a tree of `n`
/// keys, descending left or right at each step like a standard BST search.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let s = @challenge_persistent_red_black_tree.from_array([1, 2, 3][:])
///   @debug.assert_eq(@challenge_persistent_red_black_tree.contains(s, 2), true)
///   @debug.assert_eq(@challenge_persistent_red_black_tree.contains(s, 9), false)
/// }
/// ```
pub fn[T : Compare] contains(t : RB[T], key : T) -> Bool {
  let none : T? = None
  for cur = t, lo = none, hi = none {
    match cur {
      Empty => break false
      Node(color=_, key=k, left~, right~) =>
        if key == k {
          break true
        } else if key < k {
          continue left, lo, Some(k)
        } else {
          continue right, Some(k), hi
        }
    }
  } where {
    proof_invariant: bst_valid(cur, lo, hi),
    proof_invariant: within_bounds(key, lo, hi),
    proof_reasoning: (
      #|INVARIANT (BST search bounds):
      #|cur is a valid BST subtree whose keys lie strictly between lo and hi
      #|(when present), and the target key also lies in that open interval.
      #|MAINTENANCE:
      #|Descending left tightens hi to the current node's key; descending
      #|right tightens lo. Both moves preserve BST validity and shrink the
      #|live window around key.
      #|TERMINATION:
      #|Reaching Empty means key is absent; matching the current node's key
      #|means it is present. Each step descends one level, so the loop runs
      #|at most `height(t) = O(log n)` iterations.
    ),
  }
}

///|
/// Return all keys in sorted order via an in-order traversal. Runs in
/// `O(n)` time and allocates a fresh array.
pub fn[T] inorder(t : RB[T]) -> Array[T] {
  match t {
    Empty => []
    Node(color=_, key=k, left~, right~) => inorder(left) + [k] + inorder(right)
  }
}

///|
/// Build a red-black set by inserting each element of `arr` in order.
///
/// The intermediate trees are discarded; the returned tree contains all
/// distinct elements of `arr`. Duplicates are ignored (set semantics).
///
/// ## Complexity
///
/// `O(n log n)` time and `O(log n)` working extra memory per step (the
/// path-copied insertion path).
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let s = @challenge_persistent_red_black_tree.from_array([4, 1, 3, 2][:])
///   @debug.assert_eq(@challenge_persistent_red_black_tree.inorder(s), [1, 2, 3, 4])
/// }
/// ```
pub fn[T : Compare] from_array(arr : ArrayView[T]) -> RB[T] {
  let n = arr.length()
  for i in 0..<n; tree = (Empty : RB[T]) {
    continue insert(tree, arr[i])
  } nobreak {
    tree
  } where {
    proof_invariant: i >= 0 && i <= n,
    proof_invariant: rb_valid(tree, None, None),
    proof_reasoning: (
      #|INVARIANT (RB build):
      #|tree is a valid red-black tree (RB1-RB4 plus root-black) containing
      #|exactly the distinct keys among arr[0..i).
      #|MAINTENANCE:
      #|`insert` returns a new RB-valid tree containing every key tree had,
      #|plus arr[i] if it was new. The root is repainted black inside
      #|`insert`, restoring RB2 even when the pre-recoloring root was red.
      #|TERMINATION:
      #|At i = n every element has been inserted; the final tree is a valid
      #|RB set of all distinct values in arr.
    ),
  }
}

///|
test "persistent rb invariants and contains" {
  let tree = from_array([7, 3, 18, 10, 22, 8, 11, 26, 15])
  let none : Int? = None
  assert_true(rb_valid(tree, none, none))
  assert_true(contains(tree, 15))
  assert_true(contains(tree, 26))
  @debug.assert_eq(contains(tree, 99), false)
  @debug.assert_eq(size(tree), 9)
}

///|
test "persistent rb inorder is sorted" {
  let tree = from_array([5, 2, 8, 1, 9, 3, 7, 4, 6])
  @debug.assert_eq(inorder(tree), [1, 2, 3, 4, 5, 6, 7, 8, 9])
}

///|
test "persistent rb duplicates ignored" {
  let t0 = empty()
  let t1 = insert(t0, 4)
  let t2 = insert(t1, 4)
  @debug.assert_eq(size(t1), 1)
  @debug.assert_eq(size(t2), 1)
  @debug.assert_eq(inorder(t2), [4])
}

///|
test "persistent rb versions are independent" {
  let t0 = empty()
  let t1 = insert(t0, 5)
  let t2 = insert(t1, 2)
  let t3 = insert(t2, 8)
  // Older versions are unchanged
  @debug.assert_eq(contains(t0, 5), false)
  @debug.assert_eq(contains(t1, 2), false)
  @debug.assert_eq(contains(t2, 8), false)
  // Newer versions accumulate elements
  @debug.assert_eq(size(t3), 3)
  assert_true(contains(t3, 5))
  assert_true(contains(t3, 2))
  assert_true(contains(t3, 8))
}

///|
test "persistent rb sequential inserts preserve invariants" {
  let none : Int? = None
  for k in 0..<20; tree = (Empty : RB[Int]) {
    let new_tree = insert(tree, k)
    assert_true(rb_valid(new_tree, none, none))
    continue new_tree
  } where {
    proof_invariant: k >= 0 && k <= 20,
    proof_invariant: rb_valid(tree, none, none),
    proof_reasoning: (
      #|INVARIANT:
      #|tree is a valid red-black tree containing 0..k.
      #|MAINTENANCE:
      #|Each insert preserves RB1-RB4 and repaints the root black.
      #|TERMINATION:
      #|At k = 20 the tree contains 0..20 and is RB-valid.
    ),
  }
}

///|
test "persistent rb negative keys" {
  let tree = from_array([-5, 0, -1, 3, -3, 2])
  @debug.assert_eq(inorder(tree), [-5, -3, -1, 0, 2, 3])
}
