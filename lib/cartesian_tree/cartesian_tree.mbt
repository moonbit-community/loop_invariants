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
/// Node in the Cartesian Tree
priv struct CartesianNode {
  value : Int64
  index : Int // Position in original array
  mut left : Int // Index of left child in nodes array (-1 if none)
  mut right : Int // Index of right child in nodes array (-1 if none)
  mut parent : Int // Index of parent (-1 for root)
}

///|
/// Cartesian Tree with LCA preprocessing for RMQ
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
/// Build Cartesian Tree from array in O(n) time
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
  let nodes = Array::makei(n, i => {
    value: arr[i],
    index: i,
    left: -1,
    right: -1,
    parent: -1,
  })

  // Build tree using monotonic stack
  // INVARIANT: Stack contains nodes on rightmost path, in increasing depth order
  // Stack values are decreasing (since we're building min-heap)
  let stack : Array[Int] = []
  for i = 0; i < n; i = i + 1 {
    let mut last_popped = -1

    // Pop nodes with larger values
    // INVARIANT: Popped nodes will become left subtree of current node
    while stack.length() > 0 {
      let top = stack[stack.length() - 1]
      if nodes[top].value > arr[i] {
        last_popped = top
        let _ = stack.pop()

      } else {
        break
      }
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
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (stack build):
      #|Indices in [0..i) are processed and the monotonic stack is consistent.
      #|MAINTENANCE:
      #|Process index i, pop larger nodes, set links, then push i onto the stack.
      #|TERMINATION:
      #|At i = n, all nodes are integrated into the Cartesian tree.
    ),
  }

  // Find root (node with no parent)
  let root = match nodes.search_by(fn(node) { node.parent == -1 }) {
    Some(idx) => idx
    None => 0
  }

  // Create index to node mapping (node i corresponds to array position i)
  let index_to_node = Array::makei(n, i => nodes[i].index)

  // Compute depths using BFS
  let depth = Array::make(n, 0)
  let queue : Array[Int] = [root]
  depth[root] = 0
  for head = 0; head < queue.length(); head = head + 1 {
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
  } where {
    invariant: head >= 0 && head <= queue.length(),
    reasoning: (
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
  let ancestors : Array[Array[Int]] = []
  for j = 0; j < log_n; j = j + 1 {
    ancestors.push(Array::make(n, -1))
  } where {
    invariant: j >= 0 && j <= log_n,
    reasoning: (
      #|INVARIANT (allocate levels):
      #|ancestors contains tables for levels in [0, j), each sized n.
      #|MAINTENANCE:
      #|Append a fresh length-n table for level j.
      #|TERMINATION:
      #|At j = log_n, all binary lifting levels are allocated.
    ),
  }

  // Base case: 2^0 = 1st ancestor is parent
  for i = 0; i < n; i = i + 1 {
    ancestors[0][i] = nodes[i].parent
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (level 0):
      #|ancestors[0][0..i) stores the immediate parent for each node.
      #|MAINTENANCE:
      #|Assign the parent of node i.
      #|TERMINATION:
      #|At i = n, level-0 ancestors are initialized for all nodes.
    ),
  }

  // Build using dynamic programming
  // INVARIANT: After iteration k, ancestors[k][v] correctly stores 2^k-th ancestor
  for k = 1; k < log_n; k = k + 1 {
    for v = 0; v < n; v = v + 1 {
      let mid = ancestors[k - 1][v]
      if mid != -1 {
        ancestors[k][v] = ancestors[k - 1][mid]
      }
    } where {
      invariant: v >= 0 && v <= n,
      reasoning: (
        #|INVARIANT (build level k):
        #|For v in [0, v), ancestors[k][v] is the 2^k-th ancestor, computed
        #|via the 2^(k-1)-th ancestor.
        #|MAINTENANCE:
        #|If the 2^(k-1)-th ancestor exists, jump once more to fill level k.
        #|TERMINATION:
        #|At v = n, level k is fully computed.
      ),
    }
  } where {
    invariant: k >= 1 && k <= log_n,
    reasoning: (
      #|INVARIANT (levels complete):
      #|All levels in [1, k) are fully built.
      #|MAINTENANCE:
      #|Construct level k using level k-1.
      #|TERMINATION:
      #|At k = log_n, all binary lifting levels are available.
    ),
  }
  { nodes, root, index_to_node, depth, ancestors, n, log_n }
}

///|
fn highest_bit(x : Int) -> Int {
  if x <= 0 {
    return 0
  }
  for result = 0, val = x; val > 1; {
    continue result + 1, val / 2
  } else {
    result
  } where {
    invariant: val > 0 && result >= 0,
    reasoning: (
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
/// Find LCA of two nodes using binary lifting
/// REASONING: Move deeper node up to same level, then move both up together
/// until they meet at LCA
fn CartesianTree::lca(self : CartesianTree, u : Int, v : Int) -> Int {
  if u < 0 || v < 0 || u >= self.n || v >= self.n {
    return -1
  }
  let mut u = u
  let mut v = v

  // Make u the deeper node
  if self.depth[u] < self.depth[v] {
    let tmp = u
    u = v
    v = tmp
  }

  // Lift u to same depth as v
  // INVARIANT: After each iteration, depth difference decreases
  let diff = self.depth[u] - self.depth[v]
  for k = 0; k < self.log_n; k = k + 1 {
    if ((diff >> k) & 1) == 1 {
      u = self.ancestors[k][u]
    }
  } where {
    invariant: k >= 0 && k <= self.log_n,
    reasoning: (
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
  for k = self.log_n - 1; k >= 0; k = k - 1 {
    if self.ancestors[k][u] != self.ancestors[k][v] {
      u = self.ancestors[k][u]
      v = self.ancestors[k][v]
    }
  } where {
    invariant: k >= 0 && k < self.log_n,
    reasoning: (
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
/// Query minimum in range [l, r] (inclusive)
/// Uses the property that minimum is at LCA of nodes at positions l and r
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
/// Query position of minimum in range [l, r]
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
fn CartesianTree::length(self : CartesianTree) -> Int {
  self.n
}

///|
/// Get the root value
fn CartesianTree::root_value(self : CartesianTree) -> Int64? {
  if self.n == 0 {
    None
  } else {
    Some(self.nodes[self.root].value)
  }
}

///|
/// Verify in-order traversal yields original sequence
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
  for i = 0; i < arr.length(); i = i + 1 {
    if result[i] != arr[i] {
      return false
    }
  } where {
    invariant: i >= 0 && i <= arr.length(),
    reasoning: (
      #|INVARIANT (inorder check):
      #|All positions in [0, i) match between result and arr.
      #|MAINTENANCE:
      #|Compare result[i] with arr[i] and return false on mismatch.
      #|TERMINATION:
      #|At i = arr.length(), the inorder traversal matches the original array.
    ),
  }
  true
}

///|
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
/// Verify heap property (min-heap)
fn CartesianTree::verify_heap(self : CartesianTree) -> Bool {
  if self.n == 0 {
    return true
  }
  verify_heap_recursive(self.nodes, self.root)
}

///|
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
/// Find nearest smaller element to the left for each position
/// Returns -1 if no smaller element exists
fn nearest_smaller_left(arr : Array[Int64]) -> Array[Int] {
  let n = arr.length()
  let result = Array::make(n, -1)

  // Use monotonic stack
  // INVARIANT: Stack contains indices with strictly increasing values
  let stack : Array[Int] = []
  for i = 0; i < n; i = i + 1 {
    // Pop elements >= arr[i]
    while stack.length() > 0 {
      let top = stack[stack.length() - 1]
      if arr[top] >= arr[i] {
        let _ = stack.pop()

      } else {
        break
      }
    }
    if stack.length() > 0 {
      result[i] = stack[stack.length() - 1]
    }
    stack.push(i)
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (nearest smaller left):
      #|Stack holds indices with strictly increasing values from bottom to top
      #|for processed positions in [0, i).
      #|MAINTENANCE:
      #|Pop indices with value >= arr[i] so the top is the nearest smaller,
      #|record it, then push i to preserve monotonicity.
      #|TERMINATION:
      #|At i = n, nearest smaller to the left is computed for all positions.
    ),
  }
  result
}

///|
/// Find nearest smaller element to the right for each position
fn nearest_smaller_right(arr : Array[Int64]) -> Array[Int] {
  let n = arr.length()
  let result = Array::make(n, -1)

  // Process from right to left
  let stack : Array[Int] = []
  for i = n - 1; i >= 0; i = i - 1 {
    while stack.length() > 0 {
      let top = stack[stack.length() - 1]
      if arr[top] >= arr[i] {
        let _ = stack.pop()

      } else {
        break
      }
    }
    if stack.length() > 0 {
      result[i] = stack[stack.length() - 1]
    }
    stack.push(i)
  } where {
    invariant: i >= 0 && i < n,
    reasoning: (
      #|INVARIANT (nearest smaller right):
      #|Stack holds indices with strictly increasing values from bottom to top
      #|for processed positions in (i, n).
      #|MAINTENANCE:
      #|Pop indices with value >= arr[i] so the top is the nearest smaller,
      #|record it, then push i.
      #|TERMINATION:
      #|At i = -1, nearest smaller to the right is computed for all positions.
    ),
  }
  result
}

///|
/// Largest rectangle in histogram using Cartesian Tree concept
/// For each bar, find the largest rectangle with that bar as the shortest
fn largest_rectangle_histogram(heights : Array[Int64]) -> Int64 {
  let n = heights.length()
  if n == 0 {
    return 0L
  }
  let left = nearest_smaller_left(heights)
  let right = nearest_smaller_right(heights)

  // For each position, width extends from left+1 to right-1
  // INVARIANT: max_area is the largest rectangle found so far
  let mut max_area = 0L
  for i = 0; i < n; i = i + 1 {
    let l = if left[i] == -1 { 0 } else { left[i] + 1 }
    let r = if right[i] == -1 { n - 1 } else { right[i] - 1 }
    let width = (r - l + 1).to_int64()
    let area = heights[i] * width
    if area > max_area {
      max_area = area
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (max rectangle):
      #|max_area is the largest rectangle area among bars in [0, i).
      #|MAINTENANCE:
      #|Compute area for bar i using its maximal span and update max_area.
      #|TERMINATION:
      #|At i = n, max_area is the largest rectangle in the histogram.
    ),
  }
  max_area
}

// ============================================================================
// CARTESIAN TREE NUMBER
// ============================================================================
// Unique identifier for tree shape, useful for pattern matching

///|
/// Compute Cartesian Tree number (unique for each tree shape)
/// Uses the bijection between binary trees and balanced parentheses
fn CartesianTree::tree_number(self : CartesianTree) -> Int64 {
  if self.n == 0 {
    return 0L
  }

  // Generate balanced parentheses encoding
  // ( = 1, ) = 0 in binary
  let bits : Array[Int] = []
  encode_tree(self.nodes, self.root, bits)

  // Convert to number
  let mut result = 0L
  for i = 0; i < bits.length(); i = i + 1 {
    result = result * 2L + bits[i].to_int64()
  } where {
    invariant: i >= 0 && i <= bits.length(),
    reasoning: (
      #|INVARIANT (binary encode):
      #|result equals the binary value of bits[0..i) interpreted left-to-right.
      #|MAINTENANCE:
      #|Shift result by one bit (multiply by 2) and add bits[i].
      #|TERMINATION:
      #|At i = bits.length(), result encodes the full tree shape.
    ),
  }
  result
}

///|
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
  let arr = Array::makei(100, i => (i * 7 % 100).to_int64())
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
