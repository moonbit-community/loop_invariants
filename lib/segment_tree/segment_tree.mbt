// ============================================================================
// SEGMENT TREE - Range Queries and Point Updates
// ============================================================================
//
// A Segment Tree supports O(log n) range queries and point updates.
// It's a complete binary tree where each node stores aggregate information
// about a range of the underlying array.
//
// STRUCTURE:
// - Leaves store individual elements
// - Internal nodes store aggregate (sum, min, max, etc.) of their children's ranges
// - Node i has children 2i and 2i+1 (1-indexed)
//
// EXAMPLE for array [1, 2, 3, 4, 5]:
//               [1-5]=15
//              /        \
//         [1-3]=6     [4-5]=9
//         /    \       /    \
//      [1-2]=3 [3]=3 [4]=4 [5]=5
//      /    \
//    [1]=1 [2]=2
//
// OPERATIONS:
// - build(): O(n) - construct tree from array
// - update(i, val): O(log n) - update element at index i
// - query(l, r): O(log n) - query range [l, r]
//
// INVARIANTS:
// 1. tree[node] = aggregate of arr[start..end] for node's range
// 2. tree[node] = combine(tree[2*node], tree[2*node+1]) for internal nodes
// 3. Height is O(log n), so operations are O(log n)
//
// TIME COMPLEXITY: O(log n) per query/update, O(n) build
// SPACE COMPLEXITY: O(n)

///|
/// Segment Tree for range sum queries
priv struct SegmentTree {
  n : Int
  tree : Array[Int64]
}

///|
/// Build segment tree from array
fn SegmentTree::new(arr : Array[Int64]) -> SegmentTree {
  let n = arr.length()
  if n == 0 {
    return { n: 0, tree: [] }
  }
  let tree = Array::make(4 * n, 0L)
  build_tree(arr, tree, 1, 0, n - 1)
  { n, tree }
}

///|
fn build_tree(
  arr : Array[Int64],
  tree : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
) -> Unit {
  if start == end {
    tree[node] = arr[start]
    return
  }
  let mid = (start + end) / 2
  build_tree(arr, tree, 2 * node, start, mid)
  build_tree(arr, tree, 2 * node + 1, mid + 1, end)
  tree[node] = tree[2 * node] + tree[2 * node + 1]
}

///|
/// Update element at index i to value val
fn SegmentTree::update(self : SegmentTree, i : Int, val : Int64) -> Unit {
  if i < 0 || i >= self.n {
    return
  }
  update_helper(self.tree, 1, 0, self.n - 1, i, val)
}

///|
fn update_helper(
  tree : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
  i : Int,
  val : Int64,
) -> Unit {
  if start == end {
    tree[node] = val
    return
  }
  let mid = (start + end) / 2
  if i <= mid {
    update_helper(tree, 2 * node, start, mid, i, val)
  } else {
    update_helper(tree, 2 * node + 1, mid + 1, end, i, val)
  }
  tree[node] = tree[2 * node] + tree[2 * node + 1]
}

///|
/// Query sum of range [l, r]
fn SegmentTree::query(self : SegmentTree, l : Int, r : Int) -> Int64 {
  if l < 0 || r >= self.n || l > r {
    return 0L
  }
  query_helper(self.tree, 1, 0, self.n - 1, l, r)
}

///|
fn query_helper(
  tree : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
  l : Int,
  r : Int,
) -> Int64 {
  if r < start || end < l {
    return 0L // No overlap
  }
  if l <= start && end <= r {
    return tree[node] // Complete overlap
  }
  let mid = (start + end) / 2
  let left = query_helper(tree, 2 * node, start, mid, l, r)
  let right = query_helper(tree, 2 * node + 1, mid + 1, end, l, r)
  left + right
}

///|
fn SegmentTree::length(self : SegmentTree) -> Int {
  self.n
}

// ============================================================================
// SEGMENT TREE FOR RANGE MINIMUM QUERIES (RMQ)
// ============================================================================

///|
priv struct SegmentTreeMin {
  n : Int
  tree : Array[Int64]
}

///|
const ST_INF : Int64 = 9223372036854775807L

///|
fn SegmentTreeMin::new(arr : Array[Int64]) -> SegmentTreeMin {
  let n = arr.length()
  if n == 0 {
    return { n: 0, tree: [] }
  }
  let tree = Array::make(4 * n, ST_INF)
  build_min_tree(arr, tree, 1, 0, n - 1)
  { n, tree }
}

///|
fn build_min_tree(
  arr : Array[Int64],
  tree : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
) -> Unit {
  if start == end {
    tree[node] = arr[start]
    return
  }
  let mid = (start + end) / 2
  build_min_tree(arr, tree, 2 * node, start, mid)
  build_min_tree(arr, tree, 2 * node + 1, mid + 1, end)
  tree[node] = if tree[2 * node] < tree[2 * node + 1] {
    tree[2 * node]
  } else {
    tree[2 * node + 1]
  }
}

///|
fn SegmentTreeMin::update(self : SegmentTreeMin, i : Int, val : Int64) -> Unit {
  if i < 0 || i >= self.n {
    return
  }
  update_min_helper(self.tree, 1, 0, self.n - 1, i, val)
}

///|
fn update_min_helper(
  tree : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
  i : Int,
  val : Int64,
) -> Unit {
  if start == end {
    tree[node] = val
    return
  }
  let mid = (start + end) / 2
  if i <= mid {
    update_min_helper(tree, 2 * node, start, mid, i, val)
  } else {
    update_min_helper(tree, 2 * node + 1, mid + 1, end, i, val)
  }
  tree[node] = if tree[2 * node] < tree[2 * node + 1] {
    tree[2 * node]
  } else {
    tree[2 * node + 1]
  }
}

///|
fn SegmentTreeMin::query(self : SegmentTreeMin, l : Int, r : Int) -> Int64 {
  if l < 0 || r >= self.n || l > r {
    return ST_INF
  }
  query_min_helper(self.tree, 1, 0, self.n - 1, l, r)
}

///|
fn query_min_helper(
  tree : Array[Int64],
  node : Int,
  start : Int,
  end : Int,
  l : Int,
  r : Int,
) -> Int64 {
  if r < start || end < l {
    return ST_INF
  }
  if l <= start && end <= r {
    return tree[node]
  }
  let mid = (start + end) / 2
  let left = query_min_helper(tree, 2 * node, start, mid, l, r)
  let right = query_min_helper(tree, 2 * node + 1, mid + 1, end, l, r)
  if left < right {
    left
  } else {
    right
  }
}

// ============================================================================
// ITERATIVE SEGMENT TREE (more efficient, uses 2n space)
// ============================================================================

///|
/// Iterative Segment Tree - uses only 2n space and is cache-friendly
priv struct IterativeSegTree {
  n : Int
  tree : Array[Int64] // 0-indexed, leaves at indices [n, 2n)
}

///|
fn IterativeSegTree::new(arr : Array[Int64]) -> IterativeSegTree {
  let n = arr.length()
  if n == 0 {
    return { n: 0, tree: [] }
  }
  let tree = Array::make(2 * n, 0L)

  // Copy leaves
  for i = 0; i < n; i = i + 1 {
    tree[n + i] = arr[i]
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (leaf copy):
      #|tree[n..n+i) mirrors arr[0..i).
      #|MAINTENANCE:
      #|Copy arr[i] into leaf position n + i.
      #|TERMINATION:
      #|At i = n, all leaves store the array values.
    ),
  }

  // Build internal nodes from bottom up
  for i = n - 1; i > 0; i = i - 1 {
    tree[i] = tree[2 * i] + tree[2 * i + 1]
  } where {
    invariant: i >= 0 && i <= n - 1,
    reasoning: (
      #|INVARIANT (build internal nodes):
      #|For all indices > i, internal node sums are correct.
      #|MAINTENANCE:
      #|Compute tree[i] as the sum of its two children, which are already built.
      #|TERMINATION:
      #|At i = 1, the entire tree stores correct range sums.
    ),
  }
  { n, tree }
}

///|
fn IterativeSegTree::update(
  self : IterativeSegTree,
  i : Int,
  val : Int64,
) -> Unit {
  if i < 0 || i >= self.n {
    return
  }

  // Update leaf
  let mut idx = i + self.n
  self.tree[idx] = val

  // Propagate up to root
  while idx > 1 {
    idx = idx / 2
    self.tree[idx] = self.tree[2 * idx] + self.tree[2 * idx + 1]
  }
}

///|
fn IterativeSegTree::query(self : IterativeSegTree, l : Int, r : Int) -> Int64 {
  if l < 0 || r >= self.n || l > r {
    return 0L
  }

  // Convert to tree indices
  let mut left = l + self.n
  let mut right = r + self.n + 1
  let mut sum = 0L

  // Traverse from leaves to root
  while left < right {
    if (left & 1) == 1 {
      // Left is right child, include it
      sum = sum + self.tree[left]
      left = left + 1
    }
    if (right & 1) == 1 {
      // Right is right child, include left sibling
      right = right - 1
      sum = sum + self.tree[right]
    }
    left = left / 2
    right = right / 2
  }
  sum
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "segment tree basic" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let st = SegmentTree::new(arr)
  inspect(st.query(0, 4), content="15")
  inspect(st.query(0, 2), content="6")
  inspect(st.query(2, 4), content="12")
  inspect(st.query(1, 3), content="9")
}

///|
test "segment tree update" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let st = SegmentTree::new(arr)
  st.update(2, 10L)
  inspect(st.query(0, 4), content="22") // 1+2+10+4+5
  inspect(st.query(2, 2), content="10")
}

///|
test "segment tree single element" {
  let arr : Array[Int64] = [42L]
  let st = SegmentTree::new(arr)
  inspect(st.query(0, 0), content="42")
  st.update(0, 100L)
  inspect(st.query(0, 0), content="100")
}

///|
test "segment tree min basic" {
  let arr : Array[Int64] = [5L, 2L, 8L, 1L, 9L]
  let st = SegmentTreeMin::new(arr)
  inspect(st.query(0, 4), content="1")
  inspect(st.query(0, 2), content="2")
  inspect(st.query(2, 4), content="1")
}

///|
test "segment tree min update" {
  let arr : Array[Int64] = [5L, 2L, 8L, 1L, 9L]
  let st = SegmentTreeMin::new(arr)
  st.update(3, 100L) // Change 1 to 100
  inspect(st.query(0, 4), content="2")
  inspect(st.query(2, 4), content="8")
}

///|
test "iterative segment tree basic" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let st = IterativeSegTree::new(arr)
  inspect(st.query(0, 4), content="15")
  inspect(st.query(0, 2), content="6")
  inspect(st.query(2, 4), content="12")
}

///|
test "iterative segment tree update" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L]
  let st = IterativeSegTree::new(arr)
  st.update(2, 10L)
  inspect(st.query(0, 4), content="22")
}

///|
test "segment tree empty" {
  let arr : Array[Int64] = []
  let st = SegmentTree::new(arr)
  inspect(st.length(), content="0")
}

///|
test "segment tree boundary" {
  let arr : Array[Int64] = [1L, 2L, 3L]
  let st = SegmentTree::new(arr)
  inspect(st.query(-1, 0), content="0") // Invalid
  inspect(st.query(0, 10), content="0") // Invalid
  inspect(st.query(2, 1), content="0") // Invalid
}

///|
test "segment tree large" {
  let n = 100
  let arr : Array[Int64] = []
  for i = 0; i < n; i = i + 1 {
    arr.push(i.to_int64())
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (build test array):
      #|arr has length i and contains values 0..i-1.
      #|MAINTENANCE:
      #|Push i to extend the sequence by one element.
      #|TERMINATION:
      #|At i = n, arr contains 0..n-1.
    ),
  }
  let st = SegmentTree::new(arr)
  // Sum of 0..99 = 99*100/2 = 4950
  inspect(st.query(0, 99), content="4950")
}

///|
test "iterative vs recursive" {
  let arr : Array[Int64] = [1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L]
  let st1 = SegmentTree::new(arr)
  let st2 = IterativeSegTree::new(arr)

  // Both should give same results
  inspect(st1.query(0, 7) == st2.query(0, 7), content="true")
  inspect(st1.query(2, 5) == st2.query(2, 5), content="true")
  inspect(st1.query(0, 0) == st2.query(0, 0), content="true")
}
