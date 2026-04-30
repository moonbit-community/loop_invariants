// ============================================================================
// IMPLICIT TREAP - Split and Merge Operations
// ============================================================================
//
// Split and merge are the fundamental operations of the treap.
// All other operations (insert, delete, range queries) are built on these.
//
// SPLIT OPERATION:
// ```
//   split(t, k) → (left, right)
//
//   Divides treap into two parts:
//     left:  elements at positions [0, k)
//     right: elements at positions [k, n)
//
//   Example: split([A,B,C,D,E], 2) → ([A,B], [C,D,E])
//
//   Time: O(log n) expected
// ```
//
// MERGE OPERATION:
// ```
//   merge(left, right) → combined
//
//   Combines two treaps where all positions in left < all positions in right.
//   The result preserves order: left elements, then right elements.
//
//   Example: merge([A,B], [C,D]) → [A,B,C,D]
//
//   Time: O(log n) expected
// ```
//
// WHY THEY WORK TOGETHER:
// ```
//   1. Split preserves BST property by recursive descent
//   2. Merge preserves heap property by comparing priorities
//   3. Both operations update subtree sizes for implicit keys
//   4. Lazy flags are pushed before any structural change
// ```

///|
/// Split treap at position k.
///
/// RETURNS: (left, right) where:
///   - left contains positions [0, k)
///   - right contains positions [k, n)
///
/// ALGORITHM:
/// ```
///   At each node, compare k with left subtree size:
///
///   If k <= left_size:
///     - Current node and its right subtree go to RIGHT part
///     - Recursively split left subtree
///     - Left part of split becomes left result
///     - Right part becomes left child of current node
///
///   If k > left_size:
///     - Current node and its left subtree go to LEFT part
///     - Recursively split right subtree at (k - left_size - 1)
///     - Left part becomes right child of current node
///     - Right part of split becomes right result
/// ```
///
/// VISUAL:
/// ```
///   split([A,B,C,D,E], 2):
///
///   Before:          After split(2):
///       C                  B              C
///      / \                /              / \
///     B   D      →       A              -   D
///    /     \                                 \
///   A       E                                 E
///
///   Left = [A,B], Right = [C,D,E]
/// ```
pub fn ImplicitTreap::split(
  self : ImplicitTreap,
  node : Int,
  k : Int,
) -> (Int, Int) {
  if node < 0 {
    return (-1, -1)
  }

  // Push lazy reversal before accessing children
  self.push_down(node)
  let left_size = self.get_size(self.nodes[node].left)
  if k <= left_size {
    // Current node goes to right part
    // Split left subtree, right part becomes our new left child
    let (ll, lr) = self.split(self.nodes[node].left, k)
    self.nodes[node].left = lr
    self.update(node)
    (ll, node)
  } else {
    // Current node goes to left part
    // Split right subtree at (k - left_size - 1)
    let (rl, rr) = self.split(self.nodes[node].right, k - left_size - 1)
    self.nodes[node].right = rl
    self.update(node)
    (node, rr)
  }
}

///|
/// Merge two treaps.
///
/// PRECONDITION: All positions in left < all positions in right
/// (This is automatically satisfied when using results from split)
///
/// ALGORITHM:
/// ```
///   Compare priorities of roots:
///
///   If left.priority > right.priority:
///     - left becomes root
///     - Recursively merge left.right with right
///     - Result becomes left's new right child
///
///   Else:
///     - right becomes root
///     - Recursively merge left with right.left
///     - Result becomes right's new left child
/// ```
///
/// WHY PRIORITIES MATTER:
/// ```
///   Heap property: parent.priority > children.priority
///
///   By always choosing the higher priority node as root,
///   we maintain the heap property and thus balance.
/// ```
///
/// VISUAL:
/// ```
///   merge([A,B], [C,D,E]):
///
///   Left:    Right:       Result (if C has highest priority):
///     B        C                  C
///    /        / \                / \
///   A        -   D              B   D
///                 \            /     \
///                  E          A       E
/// ```
pub fn ImplicitTreap::merge(
  self : ImplicitTreap,
  left : Int,
  right : Int,
) -> Int {
  if left < 0 {
    return right
  }
  if right < 0 {
    return left
  }

  // Push lazy flags before structural changes
  self.push_down(left)
  self.push_down(right)
  if self.nodes[left].priority > self.nodes[right].priority {
    // Left becomes root
    self.nodes[left].right = self.merge(self.nodes[left].right, right)
    self.update(left)
    left
  } else {
    // Right becomes root
    self.nodes[right].left = self.merge(left, self.nodes[right].left)
    self.update(right)
    right
  }
}
