// ============================================================================
// UNION-FIND (Disjoint Set Union) with Path Compression and Union by Rank
// ============================================================================
//
// Union-Find maintains a collection of disjoint sets and supports:
// 1. find(x): Find the representative (root) of x's set
// 2. union(x, y): Merge the sets containing x and y
//
// KEY OPTIMIZATIONS:
// 1. Path Compression: During find, make all nodes point directly to root
// 2. Union by Rank: Attach smaller tree under root of larger tree
//
// Together, these give nearly O(1) amortized time per operation.
// Formally, O(α(n)) where α is the inverse Ackermann function.
//
// PATH COMPRESSION:
// When finding root of x, we make all nodes on the path point to root.
// This flattens the tree, speeding up future operations.
//
// Before find(5): 1 ← 2 ← 3 ← 4 ← 5
// After find(5):  1 ← 2, 1 ← 3, 1 ← 4, 1 ← 5 (all point to 1)
//
// UNION BY RANK:
// rank[x] approximates log of subtree size.
// When unioning, attach smaller rank tree under larger rank tree.
// Only increase rank when both have equal rank.
//
// INVARIANTS:
// 1. parent[x] == x iff x is a root
// 2. Following parent pointers always leads to a root
// 3. rank[x] >= rank[y] for all y in x's subtree (with path compression, approximately)
// 4. x and y are in same set iff find(x) == find(y)
//
// TIME COMPLEXITY: O(α(n)) amortized per operation
// SPACE COMPLEXITY: O(n)

///|
/// Union-Find (Disjoint Set Union) data structure with path compression and
/// union by rank.
///
/// Each element is identified by an integer index in `[0, n)`. Internally the
/// structure stores a `parent` array and a `rank` array.  When `parent[x] == x`
/// the element `x` is a root (representative) of its set.
///
/// Space complexity: O(n).
pub struct UnionFind {
  parent : Array[Int]
  rank : Array[Int]
  mut num_sets : Int
}

///|
/// Create a new Union-Find structure with `n` elements (indices `0` to `n-1`).
///
/// Initially every element is its own root, so there are `n` singleton sets.
///
/// Parameters:
/// - `n`: number of elements; must be non-negative.
///
/// Returns a new `UnionFind` value ready for use.
///
/// Time complexity: O(n).
pub fn UnionFind::UnionFind(n : Int) -> UnionFind {
  // Each element is its own parent (self-loop = root)
  let parent = [ for i in 0..<n => i ]
  let rank = Array::make(n, 0)
  { parent, rank, num_sets: n }
}

///|
/// Find the representative (root) of the set that contains element `x`.
///
/// Applies **full path compression**: after the call every node on the path
/// from `x` to the root has its `parent` updated to point directly to the
/// root, flattening the tree for future queries.
///
/// Parameters:
/// - `x`: the element whose representative is requested; must be in `[0, n)`.
///
/// Returns the root element of `x`'s set, or `-1` if `x` is out of bounds.
///
/// Time complexity: O(α(n)) amortized, where α is the inverse Ackermann
/// function (effectively constant for all practical inputs).
///
/// INVARIANT: Following parent pointers leads to root.
/// PATH COMPRESSION: Makes all nodes on path point directly to root.
pub fn UnionFind::find(self : UnionFind, x : Int) -> Int {
  if x < 0 || x >= self.parent.length() {
    return -1
  }

  // Find root with path compression
  // We first find the root, then make all nodes point to it
  let root = for root = x {
    if self.parent[root] != root {
      continue self.parent[root]
    } else {
      break root
    }
  }

  // Path compression: make all nodes on path point to root
  let _ = for curr = x {
    if curr != root {
      let next = self.parent[curr]
      self.parent[curr] = root
      continue next
    } else {
      break ()
    }
  }
  root
}

///|
/// Merge the sets that contain elements `x` and `y`.
///
/// Uses **union by rank**: the root with the lower rank is attached under the
/// root with the higher rank, keeping trees shallow.  When both roots have the
/// same rank the rank of the chosen root is incremented by one.
///
/// Parameters:
/// - `x`: an element in the first set; must be in `[0, n)`.
/// - `y`: an element in the second set; must be in `[0, n)`.
///
/// Returns `true` when `x` and `y` were in different sets and a merge was
/// performed; `false` when they were already in the same set or when either
/// index is out of bounds.
///
/// Time complexity: O(α(n)) amortized.
///
/// INVARIANT: Smaller rank tree goes under larger rank tree.
pub fn UnionFind::union(self : UnionFind, x : Int, y : Int) -> Bool {
  let root_x = self.find(x)
  let root_y = self.find(y)
  if root_x < 0 || root_y < 0 {
    return false
  }
  if root_x == root_y {
    return false // Already in same set
  }

  // Union by rank: attach smaller tree under larger tree
  if self.rank[root_x] < self.rank[root_y] {
    self.parent[root_x] = root_y
  } else if self.rank[root_x] > self.rank[root_y] {
    self.parent[root_y] = root_x
  } else {
    // Equal ranks: choose one as root and increment its rank
    self.parent[root_y] = root_x
    self.rank[root_x] = self.rank[root_x] + 1
  }
  self.num_sets = self.num_sets - 1
  true
}

///|
/// Test whether elements `x` and `y` belong to the same set.
///
/// Parameters:
/// - `x`: an element index in `[0, n)`.
/// - `y`: an element index in `[0, n)`.
///
/// Returns `true` if `x` and `y` share the same representative, `false`
/// otherwise (including when either index is out of bounds).
///
/// Time complexity: O(α(n)) amortized.
pub fn UnionFind::connected(self : UnionFind, x : Int, y : Int) -> Bool {
  let root_x = self.find(x)
  let root_y = self.find(y)
  root_x >= 0 && root_x == root_y
}

///|
/// Return the current number of disjoint sets.
///
/// Starts at `n` (one set per element) and decreases by one each time
/// `union` successfully merges two distinct sets.
///
/// Returns the count of disjoint sets remaining.
///
/// Time complexity: O(1).
pub fn UnionFind::count_sets(self : UnionFind) -> Int {
  self.num_sets
}

///|
/// Return the number of elements in the set that contains element `x`.
///
/// Parameters:
/// - `x`: an element index in `[0, n)`.
///
/// Returns the size of `x`'s set, or `0` if `x` is out of bounds.
///
/// Note: this operation scans all `n` elements once and calls `find` on each,
/// so it is more expensive than the other operations.
///
/// Time complexity: O(n · α(n)).
pub fn UnionFind::set_size(self : UnionFind, x : Int) -> Int {
  let root = self.find(x)
  if root < 0 {
    return 0
  }
  self.parent.foldi(init=0, (i, acc, _) => {
    if self.find(i) == root {
      acc + 1
    } else {
      acc
    }
  })
}

// ============================================================================
// WEIGHTED UNION-FIND (for tracking relative weights/distances)
// ============================================================================

///|
/// Weighted Union-Find where each element has a weight relative to its parent.
///
/// Useful for problems where elements carry a numeric relationship to each
/// other, for example "A is X units heavier than B".  The weight stored at
/// each node is the signed distance from that node to its parent; path
/// compression accumulates these distances so that after `find_with_weight`
/// the stored weight is the total distance to the root.
///
/// This type is private; use `WeightedUnionFind::new`, `union_with_weight`,
/// and `diff` to interact with it.
priv struct WeightedUnionFind {
  parent : Array[Int]
  rank : Array[Int]
  weight : Array[Int64] // weight[x] = weight of x relative to parent[x]
}

///|
/// Create a new `WeightedUnionFind` with `n` elements (indices `0` to `n-1`).
///
/// Parameters:
/// - `n`: number of elements; must be non-negative.
///
/// Returns a new structure in which every element is its own root with weight
/// `0`.
///
/// Time complexity: O(n).
fn WeightedUnionFind::WeightedUnionFind(n : Int) -> WeightedUnionFind {
  let parent = [ for i in 0..<n => i ]
  let rank = Array::make(n, 0)
  let weight = Array::make(n, 0L)
  { parent, rank, weight }
}

///|
/// Find the root of element `x` and compute its total weight relative to that
/// root.
///
/// Performs path compression: after the call `parent[x]` points directly to
/// the root and `weight[x]` holds the accumulated distance from `x` to the
/// root.
///
/// Parameters:
/// - `x`: an element index in `[0, n)`.
///
/// Returns a pair `(root, weight_to_root)` where `root` is the representative
/// of `x`'s set and `weight_to_root` is the total signed weight from `x` to
/// `root`.  Returns `(-1, 0)` if `x` is out of bounds.
///
/// Time complexity: O(α(n)) amortized.
fn WeightedUnionFind::find_with_weight(
  self : WeightedUnionFind,
  x : Int,
) -> (Int, Int64) {
  if x < 0 || x >= self.parent.length() {
    return (-1, 0L)
  }
  if self.parent[x] == x {
    return (x, 0L)
  }

  // Recursively find root and accumulate weights
  let (root, parent_weight) = self.find_with_weight(self.parent[x])
  let total_weight = self.weight[x] + parent_weight

  // Path compression: update parent and weight
  self.parent[x] = root
  self.weight[x] = total_weight
  (root, total_weight)
}

///|
/// Compute the signed weight difference `weight(x) - weight(y)` when `x` and
/// `y` are in the same set.
///
/// The difference is well-defined because all weights are stored relative to
/// the common root; the root cancels out in the subtraction.
///
/// Parameters:
/// - `x`: an element index in `[0, n)`.
/// - `y`: an element index in `[0, n)`.
///
/// Returns `Some(weight(x) - weight(y))` if both elements are in the same set,
/// or `None` if they are in different sets or either index is out of bounds.
///
/// Time complexity: O(α(n)) amortized.
fn WeightedUnionFind::diff(
  self : WeightedUnionFind,
  x : Int,
  y : Int,
) -> Int64? {
  let (root_x, wx) = self.find_with_weight(x)
  let (root_y, wy) = self.find_with_weight(y)
  if root_x < 0 || root_y < 0 || root_x != root_y {
    return None
  }
  Some(wx - wy)
}

///|
/// Merge the sets of `x` and `y` subject to the constraint
/// `weight(x) - weight(y) = w`.
///
/// If `x` and `y` are already in the same set the constraint is checked for
/// consistency with existing weights: the function returns `true` only when
/// the stored difference already equals `w`.
///
/// Uses union by rank to keep trees balanced.
///
/// Parameters:
/// - `x`: an element index in `[0, n)`.
/// - `y`: an element index in `[0, n)`.
/// - `w`: the required value of `weight(x) - weight(y)`.
///
/// Returns `true` when the union was performed or when `x` and `y` were
/// already in the same set with a consistent constraint; `false` when the
/// constraint is inconsistent or either index is out of bounds.
///
/// Time complexity: O(α(n)) amortized.
fn WeightedUnionFind::union_with_weight(
  self : WeightedUnionFind,
  x : Int,
  y : Int,
  w : Int64,
) -> Bool {
  let (root_x, wx) = self.find_with_weight(x)
  let (root_y, wy) = self.find_with_weight(y)
  if root_x < 0 || root_y < 0 {
    return false
  }
  if root_x == root_y {
    // Check consistency: wx - wy should equal w
    return wx - wy == w
  }

  // Union by rank
  if self.rank[root_x] < self.rank[root_y] {
    self.parent[root_x] = root_y
    // weight(root_x) relative to root_y:
    // weight(x) - weight(y) = w
    // (weight(root_x) + wx) - (weight(root_y) + wy) = w
    // weight(root_x) = w + wy - wx (since weight(root_y) = 0)
    self.weight[root_x] = w + wy - wx
  } else if self.rank[root_x] > self.rank[root_y] {
    self.parent[root_y] = root_x
    // weight(root_y) relative to root_x:
    // weight(y) - weight(x) = -w
    // (weight(root_y) + wy) - (weight(root_x) + wx) = -w
    // weight(root_y) = -w + wx - wy (since weight(root_x) = 0)
    self.weight[root_y] = -w + wx - wy
  } else {
    self.parent[root_y] = root_x
    self.weight[root_y] = -w + wx - wy
    self.rank[root_x] = self.rank[root_x] + 1
  }
  true
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "union find basic" {
  let uf = UnionFind(5)
  debug_inspect(uf.count_sets(), content="5")
  let _ = uf.union(0, 1)
  debug_inspect(uf.count_sets(), content="4")
  debug_inspect(uf.connected(0, 1), content="true")
  debug_inspect(uf.connected(0, 2), content="false")
}

///|
test "union find transitivity" {
  let uf = UnionFind(5)
  let _ = uf.union(0, 1)
  let _ = uf.union(1, 2)
  let _ = uf.union(3, 4)
  debug_inspect(uf.connected(0, 2), content="true") // Transitive
  debug_inspect(uf.connected(0, 3), content="false")
  let _ = uf.union(2, 3)
  debug_inspect(uf.connected(0, 4), content="true") // All connected
  debug_inspect(uf.count_sets(), content="1")
}

///|
test "union find same set" {
  let uf = UnionFind(3)
  let _ = uf.union(0, 1)
  debug_inspect(uf.union(0, 1), content="false") // Already same set
  debug_inspect(uf.count_sets(), content="2")
}

///|
test "union find find" {
  let uf = UnionFind(4)
  let _ = uf.union(0, 1)
  let _ = uf.union(2, 3)
  let _ = uf.union(0, 2)

  // All should have same root
  let root = uf.find(0)
  debug_inspect(uf.find(1) == root, content="true")
  debug_inspect(uf.find(2) == root, content="true")
  debug_inspect(uf.find(3) == root, content="true")
}

///|
test "union find set size" {
  let uf = UnionFind(5)
  let _ = uf.union(0, 1)
  let _ = uf.union(0, 2)
  debug_inspect(uf.set_size(0), content="3")
  debug_inspect(uf.set_size(3), content="1")
}

///|
test "union find invalid" {
  let uf = UnionFind(3)
  debug_inspect(uf.find(-1), content="-1")
  debug_inspect(uf.find(10), content="-1")
  debug_inspect(uf.union(-1, 0), content="false")
}

///|
test "weighted union find basic" {
  let wuf = WeightedUnionFind(3)

  // a - b = 5, b - c = 3
  let _ = wuf.union_with_weight(0, 1, 5L)
  let _ = wuf.union_with_weight(1, 2, 3L)

  // a - c should be 8
  debug_inspect(wuf.diff(0, 2), content="Some(8)")
  debug_inspect(wuf.diff(2, 0), content="Some(-8)")
}

///|
test "weighted union find consistency" {
  let wuf = WeightedUnionFind(3)
  let _ = wuf.union_with_weight(0, 1, 5L)
  let _ = wuf.union_with_weight(1, 2, 3L)

  // Adding consistent constraint
  debug_inspect(wuf.union_with_weight(0, 2, 8L), content="true")

  // Adding inconsistent constraint
  debug_inspect(wuf.union_with_weight(0, 2, 10L), content="false")
}

///|
test "weighted union find diff" {
  let wuf = WeightedUnionFind(4)
  let _ = wuf.union_with_weight(0, 1, 10L)
  debug_inspect(wuf.diff(0, 1), content="Some(10)")
  debug_inspect(wuf.diff(1, 0), content="Some(-10)")
  debug_inspect(wuf.diff(0, 2), content="None") // Different sets
}

///|
test "union find empty" {
  let uf = UnionFind(0)
  debug_inspect(uf.count_sets(), content="0")
}

///|
test "union find single" {
  let uf = UnionFind(1)
  debug_inspect(uf.count_sets(), content="1")
  debug_inspect(uf.find(0), content="0")
}

///|
test "union find path compression" {
  let uf = UnionFind(10)

  // Create a chain: 0 <- 1 <- 2 <- ... <- 9
  for i in 1..<10 {
    let _ = uf.union(i - 1, i)
  }

  // Find from deepest element
  let root = uf.find(9)

  // After find with path compression, all should point to root
  for i in 0..<10 {
    debug_inspect(uf.find(i) == root, content="true")
  }
}
