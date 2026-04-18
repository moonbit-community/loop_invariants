// ============================================================================
// CARTESIAN TREE - Bridging Sequences and Binary Trees
// ============================================================================
//
// A Cartesian Tree is a binary tree derived from a sequence with two properties:
// 1. HEAP PROPERTY: Each node's value <= all values in its subtree (min-heap)
// 2. IN-ORDER PROPERTY: In-order traversal yields the original sequence
//
// KEY INSIGHT: These two properties uniquely define the tree structure!
// The root must be the minimum element, its left subtree is the Cartesian Tree
// of elements to its left, and right subtree is from elements to its right.
//
// CONSTRUCTION (O(n) using monotonic stack):
// Process elements left to right, maintaining rightmost path on a stack.
// For each new element:
// 1. Pop nodes from stack while they have larger values
// 2. Last popped node becomes left child of new node
// 3. New node becomes right child of stack top
// 4. Push new node onto stack
//
// EXAMPLE for arr = [3, 2, 6, 1, 9]:
//
//        1 (index 3)
//       / \
//      2   9 (index 4)
//     / \
//    3   6
// (idx 0) (idx 2)
//
// In-order: 3, 2, 6, 1, 9 ✓
// Heap: 1 < {2,9}, 2 < {3,6} ✓
//
// RMQ VIA LCA:
// The minimum in range [l, r] is at the LCA of nodes at positions l and r.
// This is because LCA is the highest (shallowest) common ancestor, which
// by the heap property, has the smallest value among all nodes in the range.
//
// APPLICATIONS:
// - O(1) Range Minimum Query (with O(n log n) preprocessing)
// - Treaps (BST with random priorities forms Cartesian Tree)
// - All nearest smaller values problem
// - Histogram largest rectangle
//
// TIME COMPLEXITY:
// - Construction: O(n)
// - LCA preprocessing: O(n log n)
// - RMQ query: O(log n) with binary lifting, O(1) with Euler tour
//
// SPACE COMPLEXITY: O(n log n)

///|
/// A single node stored inside the flat node array of a `CartesianTree`.
///
/// Nodes are allocated contiguously in `CartesianTree.nodes` so that parent,
/// left-child, and right-child relationships are encoded as integer indices
/// rather than pointers.  The sentinel value `-1` means "no such node".
///
/// Fields:
/// - `value`  -- the array element at this position
/// - `index`  -- the original array position (0-based)
/// - `left`   -- index into `nodes` of the left child, or `-1`
/// - `right`  -- index into `nodes` of the right child, or `-1`
/// - `parent` -- index into `nodes` of the parent, or `-1` for the root
priv struct CartesianNode {
  value : Int64
  index : Int // Position in original array
  mut left : Int // Index of left child in nodes array (-1 if none)
  mut right : Int // Index of right child in nodes array (-1 if none)
  mut parent : Int // Index of parent (-1 for root)
}

///|
/// A Cartesian tree built from a sequence, with binary-lifting tables for O(log n) LCA.
///
/// The structure satisfies two invariants simultaneously:
///
/// - **Min-heap property**: every node's value is <= the values of its children,
///   so the root always holds the global minimum.
/// - **In-order / BST property**: an in-order traversal of the tree yields the
///   original array in its original left-to-right order.
///
/// Fields:
/// - `nodes`          -- flat array of all `CartesianNode` records (index = node id)
/// - `root`           -- node id of the root (the global minimum), or `-1` when empty
/// - `index_to_node`  -- maps original array position `i` to the node id at that position
/// - `depth`          -- depth of each node (root has depth 0)
/// - `ancestors`      -- binary-lifting table: `ancestors[k][v]` is the 2^k-th ancestor
///                       of node `v`, or `-1` if no such ancestor exists
/// - `n`              -- number of elements / nodes
/// - `log_n`          -- ceiling of log2(n), used as the table height for binary lifting
priv struct CartesianTree {
  nodes : Array[CartesianNode]
  root : Int // Index of root node
  index_to_node : Array[Int] // Maps array index to node index
  depth : Array[Int] // Depth of each node
  ancestors : Array[Array[Int]] // ancestors[k][v] = 2^k-th ancestor of v
  n : Int
  log_n : Int
}

///|
/// Build a `CartesianTree` from `arr` in O(n) time using a monotonic stack.
///
/// After construction the tree satisfies:
/// - **Min-heap**: each node's value <= the values of all descendants.
/// - **In-order**: left-to-right traversal reproduces `arr` exactly.
///
/// The algorithm maintains a stack of node indices representing the rightmost
/// spine of the tree built so far.  For each new element at position `i`:
/// 1. Pop nodes whose values are strictly greater than `arr[i]` (they become
///    part of the left subtree of the new node).
/// 2. The last popped node becomes the left child of node `i`.
/// 3. Node `i` becomes the right child of the new stack top (if any).
/// 4. Push `i` onto the stack.
///
/// Every index is pushed and popped at most once, so the total work is O(n).
/// After tree construction, depths and binary-lifting tables are computed in
/// O(n log n) for LCA preprocessing.
fn CartesianTree::new(arr : Array[Int64]) -> CartesianTree {
  let n = arr.length()
  if n == 0 {
    return {
      nodes: [],
      root: -1,
      index_to_node: [],
      depth: [],
      ancestors: [],
      n: 0,
      log_n: 0,
    }
  }

  // Create nodes
  let nodes = [
    for i in 0..<n => {
      { value: arr[i], index: i, left: -1, right: -1, parent: -1 }
    }
  ]

  // Build tree using monotonic stack
  // INVARIANT: Stack contains nodes on rightmost path, in increasing depth order
  // Stack values are decreasing (since we're building min-heap)
  let stack : Array[Int] = []
  for i in 0..<n {
    // Pop nodes with larger values
    // INVARIANT: Popped nodes will become left subtree of current node
    let last_popped = for last_popped = -1; stack.length() > 0; {
      let top = stack[stack.length() - 1]
      if nodes[top].value > arr[i] {
        let _ = stack.pop()
        continue top
      } else {
        break last_popped
      }
    } nobreak {
      last_popped
    } where {
      proof_invariant: last_popped >= -1,
      proof_reasoning: (
        #|INVARIANT (pop larger values):
        #|last_popped is the most recently popped node with larger value.
        #|MAINTENANCE:
        #|Pop nodes with value > arr[i], updating last_popped each time.
        #|TERMINATION:
        #|Stack is finite; eventually empty or top <= arr[i].
      ),
    }

    // Last popped becomes left child
    if last_popped != -1 {
      nodes[i].left = last_popped
      nodes[last_popped].parent = i
    }

    // Current becomes right child of stack top
    if stack.length() > 0 {
      let parent = stack[stack.length() - 1]
      nodes[parent].right = i
      nodes[i].parent = parent
    }
    stack.push(i)
  }

  // Find root (node with no parent)
  let root = match nodes.search_by(node => node.parent == -1) {
    Some(idx) => idx
    None => 0
  }

  // Create index to node mapping (node i corresponds to array position i)
  let index_to_node = [ for i in 0..<n => nodes[i].index ]

  // Compute depths using BFS
  let depth = Array::make(n, 0)
  let queue : Array[Int] = [root]
  depth[root] = 0
  for head = 0; head < queue.length(); {
    let v = queue[head]
    if nodes[v].left != -1 {
      let left = nodes[v].left
      depth[left] = depth[v] + 1
      queue.push(left)
    }
    if nodes[v].right != -1 {
      let right = nodes[v].right
      depth[right] = depth[v] + 1
      queue.push(right)
    }
    continue head + 1
  } where {
    proof_invariant: head >= 0 && head <= queue.length(),
    proof_reasoning: (
      #|INVARIANT (BFS):
      #|queue[0..head) is processed with depths assigned; queue[head..] is discovered.
      #|MAINTENANCE:
      #|Process queue[head], assign children depths, and enqueue them.
      #|TERMINATION:
      #|At head = queue.length(), all reachable nodes are processed.
    ),
  }

  // Compute log_n for binary lifting
  let log_n = highest_bit(n) + 1

  // Binary lifting preprocessing
  // ancestors[k][v] = 2^k-th ancestor of v
  // INVARIANT: ancestors[k][v] = ancestors[k-1][ancestors[k-1][v]]
  let ancestors : Array[Array[Int]] = [
    for _ in 0..<log_n => Array::make(n, -1)
  ]

  // Base case: 2^0 = 1st ancestor is parent
  for i in 0..<n {
    ancestors[0][i] = nodes[i].parent
  }

  // Build using dynamic programming
  // INVARIANT: After iteration k, ancestors[k][v] correctly stores 2^k-th ancestor
  for k in 1..<log_n {
    for v in 0..<n {
      let mid = ancestors[k - 1][v]
      if mid != -1 {
        ancestors[k][v] = ancestors[k - 1][mid]
      }
    }
  }
  { nodes, root, index_to_node, depth, ancestors, n, log_n }
}

///|
/// Return floor(log2(x)) for x >= 1, or 0 for x <= 0.
///
/// Used to determine the height of the binary-lifting table: `log_n = highest_bit(n) + 1`.
///
/// Example: `highest_bit(5)` returns `2` because 2^2 = 4 <= 5 < 8 = 2^3.
fn highest_bit(x : Int) -> Int {
  if x <= 0 {
    return 0
  }
  for result = 0, val = x; val > 1; {
    continue result + 1, val / 2
  } nobreak {
    result
  } where {
    proof_invariant: val > 0 && result >= 0,
    proof_reasoning: (
      #|INVARIANT (highest_bit):
      #|val == floor(x / 2^result) and val > 0 while looping.
      #|MAINTENANCE:
      #|Halve val and increment result, preserving the relation.
      #|TERMINATION:
      #|When val <= 1, result is floor(log2(x)).
    ),
  }
}

///|
/// Find the lowest common ancestor (LCA) of nodes `u` and `v` using binary lifting.
///
/// Returns the node index of the LCA, or `-1` if either index is out of bounds.
///
/// The algorithm has two phases:
/// 1. **Depth equalisation**: lift the deeper node up by the depth difference,
///    using the precomputed `ancestors` table to jump by powers of two.
/// 2. **Joint lifting**: lift both nodes simultaneously in decreasing powers of
///    two; skip a jump only when both nodes would reach the same ancestor (that
///    ancestor is at or above the LCA).  After all bits are processed, both
///    nodes are the immediate children of the LCA.
///
/// Time complexity: O(log n).
fn CartesianTree::lca(self : CartesianTree, u : Int, v : Int) -> Int {
  if u < 0 || v < 0 || u >= self.n || v >= self.n {
    return -1
  }

  // Make u the deeper node
  let (u, v) = if self.depth[u] < self.depth[v] { (v, u) } else { (u, v) }

  // Lift u to same depth as v
  // INVARIANT: After each iteration, depth difference decreases
  let diff = self.depth[u] - self.depth[v]
  let u = for k = 0, u = u; k < self.log_n; {
    let new_u = if ((diff >> k) & 1) == 1 { self.ancestors[k][u] } else { u }
    continue k + 1, new_u
  } nobreak {
    u
  } where {
    proof_invariant: k >= 0 && k <= self.log_n,
    proof_reasoning: (
      #|INVARIANT (lift depth):
      #|u has been lifted by the sum of 2^bit for all processed bits in diff.
      #|MAINTENANCE:
      #|If bit k is set, jump u by 2^k.
      #|TERMINATION:
      #|At k = log_n, u and v are at the same depth.
    ),
  }
  if u == v {
    return u
  }

  // Binary lift both until they meet
  // INVARIANT: u and v are at same depth, and LCA is an ancestor of both
  let (u, _) = for k = self.log_n - 1, u = u, v = v; k >= 0; {
    let (new_u, new_v) = if self.ancestors[k][u] != self.ancestors[k][v] {
      (self.ancestors[k][u], self.ancestors[k][v])
    } else {
      (u, v)
    }
    continue k - 1, new_u, new_v
  } nobreak {
    (u, v)
  } where {
    proof_invariant: k >= -1 && k < self.log_n,
    proof_reasoning: (
      #|INVARIANT (lift together):
      #|u and v remain at the same depth, and the LCA is above both.
      #|MAINTENANCE:
      #|From higher powers downward, lift u and v when their 2^k ancestors
      #|differ, keeping them just below the LCA.
      #|TERMINATION:
      #|After k < 0, u and v are children of the LCA.
    ),
  }

  // Now u and v are children of LCA
  self.ancestors[0][u]
}

///|
/// Return the minimum value in the subarray corresponding to positions `[l, r]` (inclusive).
///
/// The minimum equals the value stored at the lowest common ancestor of the nodes
/// at array positions `l` and `r`.  This is correct because:
/// - The heap property guarantees the LCA node holds the minimum of its subtree.
/// - The in-order property guarantees the LCA's subtree covers exactly `[l, r]`.
///
/// Returns `None` when `l < 0`, `r >= n`, or `l > r`.
///
/// Time complexity: O(log n).
fn CartesianTree::query_min(self : CartesianTree, l : Int, r : Int) -> Int64? {
  if l < 0 || r >= self.n || l > r || self.n == 0 {
    return None
  }

  // Get node indices for positions l and r
  let node_l = self.index_to_node[l]
  let node_r = self.index_to_node[r]

  // Find LCA
  let lca_node = self.lca(node_l, node_r)
  if lca_node == -1 {
    return None
  }
  Some(self.nodes[lca_node].value)
}

///|
/// Return the minimum value in `arr[l..=r]` (inclusive), or `None` for an invalid range.
///
/// This function builds a fresh `CartesianTree` from `arr` and answers the query
/// via LCA lookup.  It is intended for one-shot or illustrative use; callers that
/// issue many queries over the same array should build the tree once and reuse it.
///
/// Parameters:
/// - `arr` -- a view of the source array (elements are `Int64`)
/// - `l`   -- left bound of the query range (inclusive, 0-based)
/// - `r`   -- right bound of the query range (inclusive, 0-based)
///
/// Returns `Some(min)` when `0 <= l <= r < arr.length()`, otherwise `None`.
///
/// Time complexity: O(n log n) to build + O(log n) per query.
///
/// Example:
/// ```mbt nocheck
/// let arr : Array[Int64] = [3L, 2L, 6L, 1L, 9L]
/// assert_eq!(@cartesian_tree.range_min(arr[:], 1, 3), Some(1L))
/// ```
pub fn range_min(arr : ArrayView[Int64], l : Int, r : Int) -> Int64? {
  let tree = CartesianTree::new(arr.to_array())
  tree.query_min(l, r)
}

///|
/// Return the array position of the minimum value in `arr[l..=r]` (inclusive).
///
/// Equivalent to `query_min` but returns the **index** of the minimum element
/// instead of its value.  When multiple positions share the minimum value the
/// leftmost one is returned (because ties are broken leftward during tree
/// construction).
///
/// Returns `None` when `l < 0`, `r >= n`, or `l > r`.
///
/// Time complexity: O(log n).
fn CartesianTree::query_min_index(
  self : CartesianTree,
  l : Int,
  r : Int,
) -> Int? {
  if l < 0 || r >= self.n || l > r || self.n == 0 {
    return None
  }
  let node_l = self.index_to_node[l]
  let node_r = self.index_to_node[r]
  let lca_node = self.lca(node_l, node_r)
  if lca_node == -1 {
    return None
  }
  Some(self.nodes[lca_node].index)
}

///|
/// Return the number of elements in the tree (same as the source array length).
fn CartesianTree::length(self : CartesianTree) -> Int {
  self.n
}

///|
/// Return the value stored at the root node, which is the global minimum of the
/// source array.  Returns `None` when the tree is empty.
fn CartesianTree::root_value(self : CartesianTree) -> Int64? {
  if self.n == 0 {
    None
  } else {
    Some(self.nodes[self.root].value)
  }
}

///|
/// Return `true` when an in-order traversal of the tree reproduces `arr` exactly.
///
/// This checks the BST / sequence property: visiting nodes left-subtree, root,
/// right-subtree in depth-first order must yield the same values and order as
/// the source array.  Intended for testing and debugging.
fn CartesianTree::verify_inorder(
  self : CartesianTree,
  arr : Array[Int64],
) -> Bool {
  if self.n != arr.length() {
    return false
  }
  if self.n == 0 {
    return true
  }
  let result : Array[Int64] = []
  inorder_collect(self.nodes, self.root, result)
  for i in 0..<arr.length() {
    if result[i] != arr[i] {
      return false
    }
  }
  true
}

///|
/// Collect node values into `result` via recursive in-order traversal.
///
/// Visits left subtree, appends the current node's value, then visits the right
/// subtree.  A node index of `-1` is treated as an empty subtree.
fn inorder_collect(
  nodes : Array[CartesianNode],
  node : Int,
  result : Array[Int64],
) -> Unit {
  if node == -1 {
    return
  }
  inorder_collect(nodes, nodes[node].left, result)
  result.push(nodes[node].value)
  inorder_collect(nodes, nodes[node].right, result)
}

///|
/// Return `true` when every node satisfies the min-heap property.
///
/// The min-heap property requires that each node's value is less than or equal
/// to the values of both its children.  Intended for testing and debugging.
fn CartesianTree::verify_heap(self : CartesianTree) -> Bool {
  if self.n == 0 {
    return true
  }
  verify_heap_recursive(self.nodes, self.root)
}

///|
/// Recursively verify the min-heap property starting from `node`.
///
/// Returns `false` as soon as a violation is found (a child whose value is
/// strictly less than its parent's value), otherwise returns `true`.
fn verify_heap_recursive(nodes : Array[CartesianNode], node : Int) -> Bool {
  if node == -1 {
    return true
  }
  let left = nodes[node].left
  let right = nodes[node].right

  // Check left child
  if left != -1 && nodes[left].value < nodes[node].value {
    return false
  }

  // Check right child
  if right != -1 && nodes[right].value < nodes[node].value {
    return false
  }
  verify_heap_recursive(nodes, left) && verify_heap_recursive(nodes, right)
}

// ============================================================================
// ALL NEAREST SMALLER VALUES
// ============================================================================
// A classic application of Cartesian Tree structure

///|
/// For each position `i`, find the index of the nearest element to the left
/// that is strictly smaller than `arr[i]`.
///
/// Returns an array `result` of length `n` where `result[i]` is the largest
/// index `j < i` with `arr[j] < arr[i]`, or `-1` if no such index exists.
///
/// Uses a monotonic stack that keeps indices in increasing-value order.  Each
/// element is pushed and popped at most once, so total time is O(n).
///
/// This is equivalent to reading off the left-parent pointer in the Cartesian
/// tree: the left parent of node `i` is exactly the nearest smaller value to
/// its left.
fn nearest_smaller_left(arr : Array[Int64]) -> Array[Int] {
  let n = arr.length()
  let result = Array::make(n, -1)

  // Use monotonic stack
  // INVARIANT: Stack contains indices with strictly increasing values
  let stack : Array[Int] = []
  for i in 0..<n {
    // Pop elements >= arr[i]
    for pop_next = stack.length() > 0; pop_next; {
      let top = stack[stack.length() - 1]
      if arr[top] >= arr[i] {
        let _ = stack.pop()
        continue stack.length() > 0
      } else {
        break
      }
    }
    if stack.length() > 0 {
      result[i] = stack[stack.length() - 1]
    }
    stack.push(i)
  }
  result
}

///|
/// For each position `i`, find the index of the nearest element to the right
/// that is strictly smaller than `arr[i]`.
///
/// Returns an array `result` of length `n` where `result[i]` is the smallest
/// index `j > i` with `arr[j] < arr[i]`, or `-1` if no such index exists.
///
/// Mirrors `nearest_smaller_left` but processes the array right to left.
/// Time complexity: O(n).
fn nearest_smaller_right(arr : Array[Int64]) -> Array[Int] {
  let n = arr.length()
  let result = Array::make(n, -1)

  // Process from right to left
  let stack : Array[Int] = []
  for i in n>..0 {
    for pop_next = stack.length() > 0; pop_next; {
      let top = stack[stack.length() - 1]
      if arr[top] >= arr[i] {
        let _ = stack.pop()
        continue stack.length() > 0
      } else {
        break
      }
    }
    if stack.length() > 0 {
      result[i] = stack[stack.length() - 1]
    }
    stack.push(i)
  }
  result
}

///|
/// Compute the area of the largest axis-aligned rectangle that fits entirely
/// within a histogram described by `heights`.
///
/// For each bar at position `i` with height `h = heights[i]`, the widest
/// rectangle with height exactly `h` extends from the first bar to the left
/// that is shorter than `h` (exclusive) to the first bar to the right that is
/// shorter than `h` (exclusive).  These boundaries are the nearest smaller
/// values on each side, which are computed in O(n) with monotonic stacks.
///
/// The answer is the maximum over all bars of `h * width`.
///
/// This is a direct application of the Cartesian tree structure: the nearest
/// smaller bars on both sides correspond to the node's parent relationships in
/// the tree.
///
/// Time complexity: O(n).
///
/// Example: `heights = [2, 1, 5, 6, 2, 3]` returns `10`
/// (the rectangle spanning indices 2-3 with height 5).
fn largest_rectangle_histogram(heights : Array[Int64]) -> Int64 {
  let n = heights.length()
  if n == 0 {
    return 0L
  }
  let left = nearest_smaller_left(heights)
  let right = nearest_smaller_right(heights)

  // For each position, width extends from left+1 to right-1
  let max_area = for i in 0..<n; max_area = 0L {
    let l = if left[i] == -1 { 0 } else { left[i] + 1 }
    let r = if right[i] == -1 { n - 1 } else { right[i] - 1 }
    let width = (r - l + 1).to_int64()
    let area = heights[i] * width
    continue if area > max_area { area } else { max_area }
  } nobreak {
    max_area
  }
  max_area
}

// ============================================================================
// CARTESIAN TREE NUMBER
// ============================================================================
// Unique identifier for tree shape, useful for pattern matching

///|
/// Compute a compact integer fingerprint that uniquely identifies the **shape**
/// of the tree (independent of the actual values stored at each node).
///
/// The encoding uses a preorder traversal where each non-null node contributes
/// a `1` bit and each null (absent) child contributes a `0` bit.  The resulting
/// bit string is interpreted as a big-endian integer.
///
/// Two trees have the same tree number if and only if they have the same binary
/// tree shape.  This is useful for checking whether two arrays with the same
/// relative ordering produce structurally identical Cartesian trees.
///
/// Note: the encoding length is `2n + 1` bits for a tree with `n` nodes, so
/// the result overflows `Int64` for large trees (safe for n <= 30).
fn CartesianTree::tree_number(self : CartesianTree) -> Int64 {
  if self.n == 0 {
    return 0L
  }

  // Generate balanced parentheses encoding
  // ( = 1, ) = 0 in binary
  let bits : Array[Int] = []
  encode_tree(self.nodes, self.root, bits)

  // Convert to number
  let result = for i in 0..<bits.length(); result = 0L {
    continue result * 2L + bits[i].to_int64()
  } nobreak {
    result
  }
  result
}

///|
/// Append the preorder shape encoding of the subtree rooted at `node` to `bits`.
///
/// A present node contributes `1`; an absent child (null, index `-1`)
/// contributes `0`.  The full encoding of an n-node tree is `2n + 1` bits long.
fn encode_tree(
  nodes : Array[CartesianNode],
  node : Int,
  bits : Array[Int],
) -> Unit {
  // Encode using null markers to distinguish left vs right children
  // null = 0, has_node = 1
  if node == -1 {
    bits.push(0) // null marker
    return
  }
  bits.push(1) // has node
  encode_tree(nodes, nodes[node].left, bits)
  encode_tree(nodes, nodes[node].right, bits)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "cartesian tree construction" {
  let arr : Array[Int64] = [3L, 2L, 6L, 1L, 9L]
  let tree = CartesianTree::new(arr)

  // Root should be minimum (1 at index 3)
  inspect(tree.root_value(), content="Some(1)")

  // Verify in-order property
  inspect(tree.verify_inorder(arr), content="true")

  // Verify heap property
  inspect(tree.verify_heap(), content="true")
}

///|
test "cartesian tree rmq basic" {
  let arr : Array[Int64] = [3L, 2L, 6L, 1L, 9L]
  let tree = CartesianTree::new(arr)

  // Query [0, 4]: min is 1
  inspect(tree.query_min(0, 4), content="Some(1)")

  // Query [0, 2]: min is 2
  inspect(tree.query_min(0, 2), content="Some(2)")

  // Query [2, 4]: min is 1
  inspect(tree.query_min(2, 4), content="Some(1)")

  // Query [0, 0]: single element
  inspect(tree.query_min(0, 0), content="Some(3)")
}

///|
test "cartesian tree rmq index" {
  let arr : Array[Int64] = [3L, 2L, 6L, 1L, 9L]
  let tree = CartesianTree::new(arr)

  // Position of min in [0, 4] is 3
  inspect(tree.query_min_index(0, 4), content="Some(3)")

  // Position of min in [0, 2] is 1
  inspect(tree.query_min_index(0, 2), content="Some(1)")
}

///|
test "cartesian tree empty" {
  let arr : Array[Int64] = []
  let tree = CartesianTree::new(arr)
  inspect(tree.length(), content="0")
  inspect(tree.root_value(), content="None")
  inspect(tree.query_min(0, 0), content="None")
}

///|
test "cartesian tree single" {
  let arr : Array[Int64] = [42L]
  let tree = CartesianTree::new(arr)
  inspect(tree.root_value(), content="Some(42)")
  inspect(tree.query_min(0, 0), content="Some(42)")
  inspect(tree.verify_inorder(arr), content="true")
  inspect(tree.verify_heap(), content="true")
}

///|
test "cartesian tree sorted ascending" {
  // Ascending array creates right-skewed tree
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let tree = CartesianTree::new(arr)
  inspect(tree.root_value(), content="Some(1)")
  inspect(tree.verify_inorder(arr), content="true")
  inspect(tree.verify_heap(), content="true")

  // RMQ should work correctly
  inspect(tree.query_min(0, 4), content="Some(1)")
  inspect(tree.query_min(2, 4), content="Some(3)")
}

///|
test "cartesian tree sorted descending" {
  // Descending array creates left-skewed tree
  let arr : Array[Int64] = [5L, 4L, 3L, 2L, 1L]
  let tree = CartesianTree::new(arr)
  inspect(tree.root_value(), content="Some(1)")
  inspect(tree.verify_inorder(arr), content="true")
  inspect(tree.verify_heap(), content="true")
  inspect(tree.query_min(0, 4), content="Some(1)")
  inspect(tree.query_min(0, 2), content="Some(3)")
}

///|
test "cartesian tree all same" {
  let arr : Array[Int64] = [5L, 5L, 5L, 5L]
  let tree = CartesianTree::new(arr)
  inspect(tree.root_value(), content="Some(5)")
  inspect(tree.query_min(0, 3), content="Some(5)")
  inspect(tree.query_min(1, 2), content="Some(5)")
}

///|
test "nearest smaller left" {
  let arr : Array[Int64] = [3L, 2L, 6L, 1L, 9L]
  let result = nearest_smaller_left(arr)

  // 3: no smaller to left -> -1
  // 2: no smaller to left -> -1
  // 6: 2 at index 1 -> 1
  // 1: no smaller to left -> -1
  // 9: 1 at index 3 -> 3
  inspect(result[0], content="-1")
  inspect(result[1], content="-1")
  inspect(result[2], content="1")
  inspect(result[3], content="-1")
  inspect(result[4], content="3")
}

///|
test "nearest smaller right" {
  let arr : Array[Int64] = [3L, 2L, 6L, 1L, 9L]
  let result = nearest_smaller_right(arr)

  // 3: 2 at index 1 -> 1
  // 2: 1 at index 3 -> 3
  // 6: 1 at index 3 -> 3
  // 1: no smaller to right -> -1
  // 9: no smaller to right -> -1
  inspect(result[0], content="1")
  inspect(result[1], content="3")
  inspect(result[2], content="3")
  inspect(result[3], content="-1")
  inspect(result[4], content="-1")
}

///|
test "largest rectangle histogram" {
  // Classic example: [2, 1, 5, 6, 2, 3]
  let heights : Array[Int64] = [2L, 1L, 5L, 6L, 2L, 3L]
  let area = largest_rectangle_histogram(heights)

  // Largest is 10 (height 5, width 2 from indices 2-3, or height 2, width 5)
  // Actually: heights[2]=5, heights[3]=6, min=5, width=2, area=10
  inspect(area, content="10")
}

///|
test "largest rectangle histogram all same" {
  let heights : Array[Int64] = [3L, 3L, 3L, 3L]
  let area = largest_rectangle_histogram(heights)

  // 3 * 4 = 12
  inspect(area, content="12")
}

///|
test "largest rectangle histogram ascending" {
  let heights : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let area = largest_rectangle_histogram(heights)

  // Best is 3*3 = 9 (indices 2-4 with height 3)
  // Actually: let's calculate
  // idx 0: height 1, width 5 -> 5
  // idx 1: height 2, width 4 -> 8
  // idx 2: height 3, width 3 -> 9
  // idx 3: height 4, width 2 -> 8
  // idx 4: height 5, width 1 -> 5
  inspect(area, content="9")
}

///|
test "largest rectangle empty" {
  let heights : Array[Int64] = []
  inspect(largest_rectangle_histogram(heights), content="0")
}

///|
test "cartesian tree number different shapes" {
  // Different arrays with different shapes should have different tree numbers
  let arr1 : Array[Int64] = [1L, 2L, 3L] // Right-skewed
  let arr2 : Array[Int64] = [3L, 2L, 1L] // Left-skewed
  let arr3 : Array[Int64] = [2L, 1L, 3L] // Balanced
  let tree1 = CartesianTree::new(arr1)
  let tree2 = CartesianTree::new(arr2)
  let tree3 = CartesianTree::new(arr3)
  let num1 = tree1.tree_number()
  let num2 = tree2.tree_number()
  let num3 = tree3.tree_number()

  // All three should be different
  inspect(num1 != num2, content="true")
  inspect(num2 != num3, content="true")
  inspect(num1 != num3, content="true")
}

///|
test "cartesian tree number same shape" {
  // Arrays with same relative ordering produce same shape
  let arr1 : Array[Int64] = [10L, 20L, 30L]
  let arr2 : Array[Int64] = [1L, 2L, 3L]
  let tree1 = CartesianTree::new(arr1)
  let tree2 = CartesianTree::new(arr2)

  // Same shape, same tree number
  inspect(tree1.tree_number() == tree2.tree_number(), content="true")
}

///|
test "cartesian tree rmq invalid range" {
  let arr : Array[Int64] = [3L, 2L, 6L, 1L, 9L]
  let tree = CartesianTree::new(arr)
  inspect(tree.query_min(-1, 0), content="None")
  inspect(tree.query_min(0, 10), content="None")
  inspect(tree.query_min(3, 1), content="None")
}

///|
test "cartesian tree lca" {
  let arr : Array[Int64] = [3L, 2L, 6L, 1L, 9L]
  let tree = CartesianTree::new(arr)

  // LCA of same node is itself
  let node0 = tree.index_to_node[0]
  inspect(tree.lca(node0, node0) == node0, content="true")
}

///|
test "cartesian tree large" {
  // Test with larger array
  let arr = [ for i in 0..<100 => (i * 7 % 100).to_int64() ]
  let tree = CartesianTree::new(arr)
  inspect(tree.verify_inorder(arr), content="true")
  inspect(tree.verify_heap(), content="true")

  // Find global minimum
  let min_val = tree.query_min(0, 99)
  inspect(min_val is Some(_), content="true")
}

///|
test "histogram single bar" {
  let heights : Array[Int64] = [5L]
  inspect(largest_rectangle_histogram(heights), content="5")
}

///|
test "histogram two bars" {
  let heights : Array[Int64] = [2L, 4L]
  // Min(2*2, 4*1) vs max = 4
  inspect(largest_rectangle_histogram(heights), content="4")
}
