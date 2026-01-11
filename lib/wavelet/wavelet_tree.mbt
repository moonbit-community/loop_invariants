// ============================================================================
// WAVELET TREE - Space-Efficient Data Structure for Range Queries
// ============================================================================
//
// A Wavelet Tree is a data structure that recursively partitions an alphabet
// to answer range quantile, frequency, and select queries efficiently.
//
// KEY INSIGHT: By recursively splitting values based on bits (or median),
// we create a binary tree where:
//   - Each node stores a bitvector indicating which elements go left/right
//   - Left subtree contains smaller values, right contains larger
//   - Queries traverse O(log σ) levels where σ is alphabet size
//
// STRUCTURE:
// For array [3, 0, 1, 2, 3, 1, 2, 0] with alphabet {0,1,2,3}:
//   - Root: split at median 2: [0,1,1,2,3,1,2,0] -> bits [1,0,0,1,1,0,1,0]
//   - Left child (values < 2): [0, 1, 1, 0]
//   - Right child (values >= 2): [3, 2, 3, 2]
//   - Recurse until single values
//
// OPERATIONS (all O(log σ)):
// - quantile(l, r, k): k-th smallest value in range [l, r)
// - count(l, r, v): count occurrences of v in range [l, r)
// - count_less(l, r, v): count values < v in range [l, r)
// - count_range(l, r, lo, hi): count values in [lo, hi) in range [l, r)
//
// SPACE: O(n log σ) bits
// TIME: O(log σ) per query

///|
/// Wavelet Tree node
/// Each node covers a range [lo, hi) of values
priv struct WaveletNode {
  lo : Int // Minimum value in this subtree (inclusive)
  hi : Int // Maximum value in this subtree (exclusive)
  // Bitvector: bit[i] = 1 if element i goes to right child, 0 for left
  bits : Array[Bool]
  // Prefix sum of bits for O(1) rank queries
  // rank[i] = number of 1s in bits[0..i)
  rank : Array[Int]
  left : Int // Index of left child (-1 if leaf)
  right : Int // Index of right child (-1 if leaf)
}

///|
/// Wavelet Tree data structure
priv struct WaveletTree {
  nodes : Array[WaveletNode]
  root : Int
  n : Int // Length of original array
  sigma : Int // Alphabet size (max value + 1)
}

///|
/// Build wavelet tree from array of values
/// Values should be in range [0, sigma)
fn WaveletTree::build(arr : Array[Int], sigma : Int) -> WaveletTree {
  let nodes : Array[WaveletNode] = []
  let n = arr.length()
  if n == 0 {
    return { nodes, root: -1, n: 0, sigma }
  }

  // Build tree recursively
  // Returns index of created node
  fn build_node(
    nodes : Array[WaveletNode],
    elements : Array[Int],
    indices : Array[Int],
    lo : Int,
    hi : Int,
  ) -> Int {
    // BASE CASE: single value or empty range
    if lo + 1 >= hi || elements.length() == 0 {
      let node_idx = nodes.length()
      nodes.push({ lo, hi, bits: [], rank: [0], left: -1, right: -1 })
      return node_idx
    }

    // INVARIANT: mid divides values into left [lo, mid) and right [mid, hi)
    let mid = (lo + hi) / 2

    // Create bitvector and partition elements
    let bits : Array[Bool] = []
    let rank : Array[Int] = [0]
    let left_elems : Array[Int] = []
    let right_elems : Array[Int] = []
    let left_indices : Array[Int] = []
    let right_indices : Array[Int] = []

    // LOOP INVARIANT:
    // - bits.length() == i after processing i elements
    // - rank[i] == count of 1s in bits[0..i)
    // - left_elems ++ right_elems contains all processed elements
    // - elements in left_elems have value < mid
    // - elements in right_elems have value >= mid
    for i = 0; i < elements.length(); i = i + 1 {
      let v = elements[i]
      if v < mid {
        bits.push(false)
        left_elems.push(v)
        left_indices.push(indices[i])
      } else {
        bits.push(true)
        right_elems.push(v)
        right_indices.push(indices[i])
      }
      // Maintain prefix sum
      rank.push(
        rank[rank.length() - 1] + (if bits[bits.length() - 1] { 1 } else { 0 }),
      )
    } where {
      invariant: bits.length() == i,
      reasoning: (
        #|INVARIANT (partition):
        #|After processing i elements, bits and rank have length i+1, and
        #|left_elems/right_elems contain exactly the partition of elements[0..i).
        #|Elements in left_elems are < mid; elements in right_elems are >= mid.
        #|MAINTENANCE:
        #|Process elements[i], append its bit, place it into the correct bucket,
        #|and extend the prefix rank by one.
        #|TERMINATION:
        #|At i = elements.length(), the bitvector and partitions are complete.
      ),
    }

    // Create this node first (to get index)
    let node_idx = nodes.length()
    nodes.push({ lo, hi, bits, rank, left: -1, right: -1 })

    // Recursively build children
    let left_child = build_node(nodes, left_elems, left_indices, lo, mid)
    let right_child = build_node(nodes, right_elems, right_indices, mid, hi)

    // Update node with child indices
    nodes[node_idx] = {
      ..nodes[node_idx],
      left: left_child,
      right: right_child,
    }
    node_idx
  }

  // Create initial index array
  let indices : Array[Int] = Array::make(n, 0)
  for i = 0; i < n; i = i + 1 {
    indices[i] = i
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (indices init):
      #|indices[0..i) equals 0..i-1 in order; the rest is uninitialized.
      #|MAINTENANCE:
      #|Assign indices[i] = i to extend the identity mapping.
      #|TERMINATION:
      #|At i = n, indices contains 0..n-1.
    ),
  }
  let root = build_node(nodes, arr.copy(), indices, 0, sigma)
  { nodes, root, n, sigma }
}

// ============================================================================
// QUERY OPERATIONS
// ============================================================================

///|
/// Count occurrences of value v in range [l, r)
/// REASONING: At each level, we follow the path for value v,
/// narrowing [l, r) to the corresponding range in child node
fn WaveletTree::count(self : WaveletTree, l : Int, r : Int, v : Int) -> Int {
  if self.root < 0 || l >= r || v < 0 || v >= self.sigma {
    return 0
  }

  // Navigate down tree following path for value v
  // LOOP INVARIANT:
  // - [left, right) is the range in current node corresponding to original [l, r)
  // - node covers values in [node.lo, node.hi)
  // - v is in [node.lo, node.hi) (otherwise we return 0)
  for node_idx = self.root, left = l, right = r {
    let node = self.nodes[node_idx]

    // Base case: leaf node
    if node.left < 0 && node.right < 0 {
      // At leaf, range [left, right) all have the same value
      // which is node.lo (single value at leaf)
      break right - left
    }
    let mid = (node.lo + node.hi) / 2
    if v < mid {
      // Go left: count 0s in range [left, right)
      // New range: [left - rank0(left), right - rank0(right)]
      // rank0(i) = i - rank1(i) = i - rank[i]
      let new_left = left - node.rank[left]
      let new_right = right - node.rank[right]
      if new_left >= new_right {
        break 0
      }
      continue node.left, new_left, new_right
    } else {
      // Go right: count 1s in range [left, right)
      // New range: [rank1(left), rank1(right)] = [rank[left], rank[right]]
      let new_left = node.rank[left]
      let new_right = node.rank[right]
      if new_left >= new_right {
        break 0
      }
      continue node.right, new_left, new_right
    }
  } where {
    invariant: node_idx >= 0 && node_idx < self.nodes.length() && left <= right,
    reasoning: (
      #|INVARIANT (count path):
      #|[left, right) is the subrange in the current node that corresponds to
      #|the original query range, and v lies within the node's value interval.
      #|MAINTENANCE:
      #|Map [left, right) into the chosen child using rank; the interval shrinks
      #|or becomes empty, preserving the correspondence to the original range.
      #|TERMINATION:
      #|At a leaf or an empty range, the count is determined for this path.
    ),
  }
}

///|
/// Count values less than v in range [l, r)
/// REASONING: Sum up elements going left whenever we go right
fn WaveletTree::count_less(
  self : WaveletTree,
  l : Int,
  r : Int,
  v : Int,
) -> Int {
  if self.root < 0 || l >= r {
    return 0
  }
  if v <= 0 {
    return 0
  }
  if v >= self.sigma {
    return r - l
  }

  // Navigate and accumulate count of smaller elements
  // LOOP INVARIANT:
  // - count accumulates elements confirmed to be < v
  // - [left, right) is current range
  // - when we go right, we add all elements that went left (they're < mid <= v)
  for node_idx = self.root, left = l, right = r, count = 0 {
    let node = self.nodes[node_idx]

    // Base case: leaf
    if node.left < 0 && node.right < 0 {
      // All elements in range have value node.lo
      // If node.lo < v, they all count
      if node.lo < v {
        break count + (right - left)
      } else {
        break count
      }
    }
    let mid = (node.lo + node.hi) / 2
    if v <= mid {
      // Go left: don't add anything yet
      let new_left = left - node.rank[left]
      let new_right = right - node.rank[right]
      if new_left >= new_right {
        break count
      }
      continue node.left, new_left, new_right, count
    } else {
      // Go right: add count of elements going left (they're < mid <= v)
      let zeros_in_range = right - node.rank[right] - (left - node.rank[left])
      let new_count = count + zeros_in_range
      let new_left = node.rank[left]
      let new_right = node.rank[right]
      if new_left >= new_right {
        break new_count
      }
      continue node.right, new_left, new_right, new_count
    }
  } where {
    invariant: node_idx >= 0 && left <= right && count >= 0,
    reasoning: (
      #|INVARIANT (count_less path):
      #|count equals the number of elements proven < v in the processed path,
      #|and [left, right) is the corresponding range in the current node.
      #|MAINTENANCE:
      #|If v <= mid, go left without adding. If v > mid, add all left elements
      #|in range (they are < mid <= v) and descend right with mapped indices.
      #|TERMINATION:
      #|At a leaf or empty range, count is final for the query.
    ),
  }
}

///|
/// Count values in range [lo_val, hi_val) within index range [l, r)
fn WaveletTree::count_range(
  self : WaveletTree,
  l : Int,
  r : Int,
  lo_val : Int,
  hi_val : Int,
) -> Int {
  if lo_val >= hi_val {
    return 0
  }
  // count(v in [lo, hi)) = count(<hi) - count(<lo)
  self.count_less(l, r, hi_val) - self.count_less(l, r, lo_val)
}

///|
/// Find k-th smallest value (1-indexed) in range [l, r)
/// Returns None if k > r - l
fn WaveletTree::quantile(self : WaveletTree, l : Int, r : Int, k : Int) -> Int? {
  if self.root < 0 || l >= r || k <= 0 || k > r - l {
    return None
  }

  // Binary search down the tree
  // LOOP INVARIANT:
  // - We're looking for k-th smallest in current range [left, right)
  // - Current node covers values [node.lo, node.hi)
  // - Answer is in this value range
  for node_idx = self.root, left = l, right = r, remaining_k = k {
    let node = self.nodes[node_idx]

    // Base case: leaf contains single value
    if node.left < 0 && node.right < 0 {
      break Some(node.lo)
    }

    // Count elements going left (smaller values)
    let zeros_in_range = right - node.rank[right] - (left - node.rank[left])
    if remaining_k <= zeros_in_range {
      // k-th smallest is in left subtree
      let new_left = left - node.rank[left]
      let new_right = right - node.rank[right]
      continue node.left, new_left, new_right, remaining_k
    } else {
      // k-th smallest is in right subtree
      // Adjust k: we're skipping zeros_in_range smaller elements
      let new_k = remaining_k - zeros_in_range
      let new_left = node.rank[left]
      let new_right = node.rank[right]
      continue node.right, new_left, new_right, new_k
    }
  } where {
    invariant: node_idx >= 0 &&
    left < right &&
    remaining_k > 0 &&
    remaining_k <= right - left,
    reasoning: (
      #|INVARIANT (quantile path):
      #|remaining_k is the rank of the desired element within [left, right),
      #|and the answer lies within the current node's value range.
      #|MAINTENANCE:
      #|If remaining_k falls within the left count, descend left; otherwise
      #|subtract left count and descend right.
      #|TERMINATION:
      #|At a leaf, node.lo is exactly the k-th smallest value.
    ),
  }
}

///|
/// Find index of k-th occurrence of value v in range [l, r)
/// Returns None if fewer than k occurrences exist
fn WaveletTree::select(
  self : WaveletTree,
  l : Int,
  r : Int,
  v : Int,
  k : Int,
) -> Int? {
  if k <= 0 || v < 0 || v >= self.sigma {
    return None
  }
  let cnt = self.count(l, r, v)
  if k > cnt {
    return None
  }

  // First find the leaf for value v and count occurrences
  // Then trace back to find the k-th one
  // For simplicity, we use a linear scan at the bottom
  // A more sophisticated implementation would use select structures

  // Simple approach: use quantile and count
  // Find position where v appears k-th time
  // Binary search on positions
  for lo = l, hi = r; lo < hi; {
    let mid = (lo + hi) / 2
    let cnt_left = self.count(l, mid + 1, v)
    if cnt_left >= k {
      continue lo, mid
    } else {
      continue mid + 1, hi
    }
  } else {
    // Verify this position has value v
    let cnt_at_lo = self.count(lo, lo + 1, v)
    if cnt_at_lo > 0 {
      Some(lo)
    } else {
      None
    }
  } where {
    invariant: lo >= l && hi <= r && lo <= hi,
    reasoning: (
      #|INVARIANT (kth search):
      #|If the k-th occurrence exists, its position lies within [lo, hi].
      #|MAINTENANCE:
      #|Use count(l, mid+1) to choose the half that still contains the k-th.
      #|TERMINATION:
      #|At lo == hi, the candidate position is determined.
    ),
  }
}

// ============================================================================
// ACCESS AND UTILITY
// ============================================================================

///|
/// Access original value at position i
fn WaveletTree::access(self : WaveletTree, i : Int) -> Int? {
  if self.root < 0 || i < 0 || i >= self.n {
    return None
  }

  // Navigate down tree following position i
  for node_idx = self.root, pos = i {
    let node = self.nodes[node_idx]

    // Base case: leaf
    if node.left < 0 && node.right < 0 {
      break Some(node.lo)
    }
    if node.bits[pos] {
      // Element went right
      let new_pos = node.rank[pos]
      continue node.right, new_pos
    } else {
      // Element went left
      let new_pos = pos - node.rank[pos]
      continue node.left, new_pos
    }
  } where {
    invariant: node_idx >= 0 && pos >= 0,
    reasoning: (
      #|INVARIANT (access path):
      #|pos is the position of the queried element within the current node's
      #|bitvector, corresponding to the original index i.
      #|MAINTENANCE:
      #|Map pos into the left or right child using rank; the mapping preserves
      #|the element's identity.
      #|TERMINATION:
      #|At a leaf, node.lo is the value at the original position.
    ),
  }
}

///|
/// Get size of original array
fn WaveletTree::size(self : WaveletTree) -> Int {
  self.n
}

///|
/// Get alphabet size
fn WaveletTree::alphabet_size(self : WaveletTree) -> Int {
  self.sigma
}

// ============================================================================
// ADVANCED QUERIES
// ============================================================================

///|
/// Find the most frequent value in range [l, r)
/// Returns (value, count) or None if range is empty
fn WaveletTree::mode(self : WaveletTree, l : Int, r : Int) -> (Int, Int)? {
  if self.root < 0 || l >= r {
    return None
  }

  // We need to check all distinct values - use recursive approach
  // This is O(n log sigma) in worst case, but practical for small ranges
  let best_val = 0
  let best_count = 0

  // Traverse all values and count them
  fn find_mode(
    tree : WaveletTree,
    node_idx : Int,
    left : Int,
    right : Int,
    best_val : Ref[Int],
    best_count : Ref[Int],
  ) -> Unit {
    if left >= right {
      return
    }
    let node = tree.nodes[node_idx]

    // Leaf: single value
    if node.left < 0 && node.right < 0 {
      let cnt = right - left
      if cnt > best_count.val {
        best_val.val = node.lo
        best_count.val = cnt
      }
      return
    }

    // Check left subtree
    let left_left = left - node.rank[left]
    let left_right = right - node.rank[right]
    if left_left < left_right {
      find_mode(tree, node.left, left_left, left_right, best_val, best_count)
    }

    // Check right subtree
    let right_left = node.rank[left]
    let right_right = node.rank[right]
    if right_left < right_right {
      find_mode(tree, node.right, right_left, right_right, best_val, best_count)
    }
  }

  let best_val_ref : Ref[Int] = { val: best_val }
  let best_count_ref : Ref[Int] = { val: best_count }
  find_mode(self, self.root, l, r, best_val_ref, best_count_ref)
  if best_count_ref.val > 0 {
    Some((best_val_ref.val, best_count_ref.val))
  } else {
    None
  }
}

///|
/// Get all distinct values in range [l, r) with their counts
/// Returns array of (value, count) pairs sorted by value
fn WaveletTree::distinct_values(
  self : WaveletTree,
  l : Int,
  r : Int,
) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = []
  if self.root < 0 || l >= r {
    return result
  }
  fn collect(
    tree : WaveletTree,
    node_idx : Int,
    left : Int,
    right : Int,
    result : Array[(Int, Int)],
  ) -> Unit {
    if left >= right {
      return
    }
    let node = tree.nodes[node_idx]

    // Leaf: add value with count
    if node.left < 0 && node.right < 0 {
      result.push((node.lo, right - left))
      return
    }

    // Recurse left then right (for sorted order)
    let left_left = left - node.rank[left]
    let left_right = right - node.rank[right]
    collect(tree, node.left, left_left, left_right, result)
    let right_left = node.rank[left]
    let right_right = node.rank[right]
    collect(tree, node.right, right_left, right_right, result)
  }

  collect(self, self.root, l, r, result)
  result
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "wavelet tree build and access" {
  // Array: [3, 0, 1, 2, 3, 1, 2, 0]
  let arr = [3, 0, 1, 2, 3, 1, 2, 0]
  let wt = WaveletTree::build(arr, 4)
  inspect(wt.size(), content="8")
  inspect(wt.alphabet_size(), content="4")

  // Access each element
  inspect(wt.access(0), content="Some(3)")
  inspect(wt.access(1), content="Some(0)")
  inspect(wt.access(2), content="Some(1)")
  inspect(wt.access(3), content="Some(2)")
  inspect(wt.access(4), content="Some(3)")
  inspect(wt.access(5), content="Some(1)")
  inspect(wt.access(6), content="Some(2)")
  inspect(wt.access(7), content="Some(0)")

  // Out of bounds
  inspect(wt.access(-1), content="None")
  inspect(wt.access(8), content="None")
}

///|
test "wavelet tree count" {
  let arr = [3, 0, 1, 2, 3, 1, 2, 0]
  let wt = WaveletTree::build(arr, 4)

  // Count in full range
  inspect(wt.count(0, 8, 0), content="2") // 0 appears at indices 1, 7
  inspect(wt.count(0, 8, 1), content="2") // 1 appears at indices 2, 5
  inspect(wt.count(0, 8, 2), content="2") // 2 appears at indices 3, 6
  inspect(wt.count(0, 8, 3), content="2") // 3 appears at indices 0, 4

  // Count in subrange
  inspect(wt.count(0, 4, 3), content="1") // [3,0,1,2]: one 3
  inspect(wt.count(4, 8, 3), content="1") // [3,1,2,0]: one 3
  inspect(wt.count(1, 5, 0), content="1") // [0,1,2,3]: one 0
  inspect(wt.count(1, 5, 1), content="1") // [0,1,2,3]: one 1

  // Non-existent value
  inspect(wt.count(0, 8, 5), content="0")
  inspect(wt.count(0, 8, -1), content="0")
}

///|
test "wavelet tree count_less" {
  let arr = [3, 0, 1, 2, 3, 1, 2, 0]
  let wt = WaveletTree::build(arr, 4)

  // Count less than v in full range
  inspect(wt.count_less(0, 8, 0), content="0") // Nothing < 0
  inspect(wt.count_less(0, 8, 1), content="2") // Two 0s
  inspect(wt.count_less(0, 8, 2), content="4") // Two 0s + two 1s
  inspect(wt.count_less(0, 8, 3), content="6") // Two 0s + two 1s + two 2s
  inspect(wt.count_less(0, 8, 4), content="8") // All elements

  // Count less in subrange [0, 4) = [3, 0, 1, 2]
  inspect(wt.count_less(0, 4, 2), content="2") // One 0, one 1
  inspect(wt.count_less(0, 4, 3), content="3") // One 0, one 1, one 2
}

///|
test "wavelet tree count_range" {
  let arr = [3, 0, 1, 2, 3, 1, 2, 0]
  let wt = WaveletTree::build(arr, 4)

  // Count values in value range
  inspect(wt.count_range(0, 8, 0, 2), content="4") // 0s and 1s
  inspect(wt.count_range(0, 8, 1, 3), content="4") // 1s and 2s
  inspect(wt.count_range(0, 8, 2, 4), content="4") // 2s and 3s
  inspect(wt.count_range(0, 8, 0, 4), content="8") // All

  // Subrange
  inspect(wt.count_range(0, 4, 0, 2), content="2") // [3,0,1,2]: one 0, one 1
}

///|
test "wavelet tree quantile" {
  let arr = [3, 0, 1, 2, 3, 1, 2, 0]
  let wt = WaveletTree::build(arr, 4)

  // k-th smallest in full range (sorted: [0,0,1,1,2,2,3,3])
  inspect(wt.quantile(0, 8, 1), content="Some(0)") // 1st smallest
  inspect(wt.quantile(0, 8, 2), content="Some(0)") // 2nd smallest
  inspect(wt.quantile(0, 8, 3), content="Some(1)") // 3rd smallest
  inspect(wt.quantile(0, 8, 4), content="Some(1)") // 4th smallest
  inspect(wt.quantile(0, 8, 5), content="Some(2)") // 5th smallest
  inspect(wt.quantile(0, 8, 6), content="Some(2)") // 6th smallest
  inspect(wt.quantile(0, 8, 7), content="Some(3)") // 7th smallest
  inspect(wt.quantile(0, 8, 8), content="Some(3)") // 8th smallest

  // Out of range k
  inspect(wt.quantile(0, 8, 0), content="None")
  inspect(wt.quantile(0, 8, 9), content="None")

  // Subrange [0, 4) = [3, 0, 1, 2] -> sorted [0, 1, 2, 3]
  inspect(wt.quantile(0, 4, 1), content="Some(0)")
  inspect(wt.quantile(0, 4, 2), content="Some(1)")
  inspect(wt.quantile(0, 4, 3), content="Some(2)")
  inspect(wt.quantile(0, 4, 4), content="Some(3)")
}

///|
test "wavelet tree select" {
  let arr = [3, 0, 1, 2, 3, 1, 2, 0]
  let wt = WaveletTree::build(arr, 4)

  // Find k-th occurrence of value
  inspect(wt.select(0, 8, 0, 1), content="Some(1)") // 1st 0 at index 1
  inspect(wt.select(0, 8, 0, 2), content="Some(7)") // 2nd 0 at index 7
  inspect(wt.select(0, 8, 1, 1), content="Some(2)") // 1st 1 at index 2
  inspect(wt.select(0, 8, 1, 2), content="Some(5)") // 2nd 1 at index 5
  inspect(wt.select(0, 8, 3, 1), content="Some(0)") // 1st 3 at index 0
  inspect(wt.select(0, 8, 3, 2), content="Some(4)") // 2nd 3 at index 4

  // Non-existent
  inspect(wt.select(0, 8, 0, 3), content="None") // Only 2 zeros
  inspect(wt.select(0, 8, 5, 1), content="None") // No 5s
}

///|
test "wavelet tree mode" {
  // Array with varying frequencies
  let arr = [1, 2, 2, 3, 3, 3, 4, 4]
  let wt = WaveletTree::build(arr, 5)

  // Mode of full array is 3 (appears 3 times)
  inspect(wt.mode(0, 8), content="Some((3, 3))")

  // Mode of subranges
  inspect(wt.mode(0, 3), content="Some((2, 2))") // [1,2,2] -> 2 is mode
  inspect(wt.mode(6, 8), content="Some((4, 2))") // [4,4] -> 4 is mode
  inspect(wt.mode(0, 1), content="Some((1, 1))") // Single element
}

///|
test "wavelet tree distinct values" {
  let arr = [3, 0, 1, 2, 3, 1, 2, 0]
  let wt = WaveletTree::build(arr, 4)

  // All distinct values in full range
  inspect(wt.distinct_values(0, 8), content="[(0, 2), (1, 2), (2, 2), (3, 2)]")

  // Subrange [0, 4) = [3, 0, 1, 2]
  inspect(wt.distinct_values(0, 4), content="[(0, 1), (1, 1), (2, 1), (3, 1)]")

  // Subrange [1, 5) = [0, 1, 2, 3]
  inspect(wt.distinct_values(1, 5), content="[(0, 1), (1, 1), (2, 1), (3, 1)]")
}

///|
test "wavelet tree empty" {
  let wt = WaveletTree::build([], 4)
  inspect(wt.size(), content="0")
  inspect(wt.access(0), content="None")
  inspect(wt.count(0, 0, 1), content="0")
  inspect(wt.quantile(0, 0, 1), content="None")
}

///|
test "wavelet tree single element" {
  let wt = WaveletTree::build([5], 10)
  inspect(wt.size(), content="1")
  inspect(wt.access(0), content="Some(5)")
  inspect(wt.count(0, 1, 5), content="1")
  inspect(wt.count(0, 1, 3), content="0")
  inspect(wt.quantile(0, 1, 1), content="Some(5)")
}

///|
test "wavelet tree stress" {
  // Build tree with pattern
  let arr : Array[Int] = []
  for i in 0..<100 {
    arr.push(i % 10)
  }
  let wt = WaveletTree::build(arr, 10)

  // Each value 0-9 appears 10 times
  for v in 0..<10 {
    let cnt = wt.count(0, 100, v)
    guard cnt is 10 else { fail("Expected count 10 for value \{v}") }
  }

  // Quantile checks
  inspect(wt.quantile(0, 100, 1), content="Some(0)") // 1st smallest is 0
  inspect(wt.quantile(0, 100, 11), content="Some(1)") // 11th smallest is 1
  inspect(wt.quantile(0, 100, 100), content="Some(9)") // 100th smallest is 9

  // Count less
  inspect(wt.count_less(0, 100, 5), content="50") // 50 elements < 5
}

///|
test "wavelet tree median query" {
  // Median is the (n/2)-th smallest
  let arr = [5, 2, 8, 1, 9, 3, 7, 4, 6]
  let wt = WaveletTree::build(arr, 10)

  // Median of 9 elements is 5th smallest = 5
  // Sorted: [1, 2, 3, 4, 5, 6, 7, 8, 9]
  let n = arr.length()
  let median = wt.quantile(0, n, (n + 1) / 2)
  inspect(median, content="Some(5)")

  // Median of first 5 elements [5,2,8,1,9] -> sorted [1,2,5,8,9] -> median is 5
  inspect(wt.quantile(0, 5, 3), content="Some(5)")
}
