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
/// Union-Find (Disjoint Set Union) data structure
pub struct UnionFind {
  parent : Array[Int]
  rank : Array[Int]
  mut num_sets : Int
}

///|
/// Create a new Union-Find structure with n elements (0 to n-1)
/// Initially, each element is in its own set
pub fn UnionFind::new(n : Int) -> UnionFind {
  // Each element is its own parent (self-loop = root)
  let parent = Array::makei(n, fn(i) { i })
  let rank = Array::make(n, 0)
  { parent, rank, num_sets: n }
}

///|
/// Find the root (representative) of element x's set
/// Uses path compression for efficiency
///
/// INVARIANT: Following parent pointers leads to root
/// PATH COMPRESSION: Makes all nodes on path point directly to root
pub fn UnionFind::find(self : UnionFind, x : Int) -> Int {
  if x < 0 || x >= self.parent.length() {
    return -1
  }

  // Find root with path compression
  // We first find the root, then make all nodes point to it
  let mut root = x
  while self.parent[root] != root {
    root = self.parent[root]
  }

  // Path compression: make all nodes on path point to root
  let mut curr = x
  while curr != root {
    let next = self.parent[curr]
    self.parent[curr] = root
    curr = next
  }
  root
}

///|
/// Union the sets containing x and y
/// Uses union by rank for efficiency
/// Returns true if sets were different (union performed)
///
/// INVARIANT: Smaller rank tree goes under larger rank tree
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
/// Check if x and y are in the same set
pub fn UnionFind::connected(self : UnionFind, x : Int, y : Int) -> Bool {
  let root_x = self.find(x)
  let root_y = self.find(y)
  root_x >= 0 && root_x == root_y
}

///|
/// Get the number of disjoint sets
pub fn UnionFind::count_sets(self : UnionFind) -> Int {
  self.num_sets
}

///|
/// Get the size of the set containing x
pub fn UnionFind::set_size(self : UnionFind, x : Int) -> Int {
  let root = self.find(x)
  if root < 0 {
    return 0
  }
  self.parent.foldi(init=0, fn(i, acc, _) {
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
/// Weighted Union-Find where each element has a weight relative to its parent
/// Useful for problems like "A is X units heavier than B"
priv struct WeightedUnionFind {
  parent : Array[Int]
  rank : Array[Int]
  weight : Array[Int64] // weight[x] = weight of x relative to parent[x]
}

///|
fn WeightedUnionFind::new(n : Int) -> WeightedUnionFind {
  let parent = Array::makei(n, fn(i) { i })
  let rank = Array::make(n, 0)
  let weight = Array::make(n, 0L)
  { parent, rank, weight }
}

///|
/// Find root and return (root, weight_to_root)
/// weight_to_root = total weight from x to root
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
/// Get difference: weight(x) - weight(y) if in same set, None otherwise
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
/// Union with constraint: weight(x) - weight(y) = w
/// Returns true if union performed or constraint consistent
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
  let uf = UnionFind::new(5)
  inspect(uf.count_sets(), content="5")
  let _ = uf.union(0, 1)
  inspect(uf.count_sets(), content="4")
  inspect(uf.connected(0, 1), content="true")
  inspect(uf.connected(0, 2), content="false")
}

///|
test "union find transitivity" {
  let uf = UnionFind::new(5)
  let _ = uf.union(0, 1)
  let _ = uf.union(1, 2)
  let _ = uf.union(3, 4)
  inspect(uf.connected(0, 2), content="true") // Transitive
  inspect(uf.connected(0, 3), content="false")
  let _ = uf.union(2, 3)
  inspect(uf.connected(0, 4), content="true") // All connected
  inspect(uf.count_sets(), content="1")
}

///|
test "union find same set" {
  let uf = UnionFind::new(3)
  let _ = uf.union(0, 1)
  inspect(uf.union(0, 1), content="false") // Already same set
  inspect(uf.count_sets(), content="2")
}

///|
test "union find find" {
  let uf = UnionFind::new(4)
  let _ = uf.union(0, 1)
  let _ = uf.union(2, 3)
  let _ = uf.union(0, 2)

  // All should have same root
  let root = uf.find(0)
  inspect(uf.find(1) == root, content="true")
  inspect(uf.find(2) == root, content="true")
  inspect(uf.find(3) == root, content="true")
}

///|
test "union find set size" {
  let uf = UnionFind::new(5)
  let _ = uf.union(0, 1)
  let _ = uf.union(0, 2)
  inspect(uf.set_size(0), content="3")
  inspect(uf.set_size(3), content="1")
}

///|
test "union find invalid" {
  let uf = UnionFind::new(3)
  inspect(uf.find(-1), content="-1")
  inspect(uf.find(10), content="-1")
  inspect(uf.union(-1, 0), content="false")
}

///|
test "weighted union find basic" {
  let wuf = WeightedUnionFind::new(3)

  // a - b = 5, b - c = 3
  let _ = wuf.union_with_weight(0, 1, 5L)
  let _ = wuf.union_with_weight(1, 2, 3L)

  // a - c should be 8
  inspect(wuf.diff(0, 2), content="Some(8)")
  inspect(wuf.diff(2, 0), content="Some(-8)")
}

///|
test "weighted union find consistency" {
  let wuf = WeightedUnionFind::new(3)
  let _ = wuf.union_with_weight(0, 1, 5L)
  let _ = wuf.union_with_weight(1, 2, 3L)

  // Adding consistent constraint
  inspect(wuf.union_with_weight(0, 2, 8L), content="true")

  // Adding inconsistent constraint
  inspect(wuf.union_with_weight(0, 2, 10L), content="false")
}

///|
test "weighted union find diff" {
  let wuf = WeightedUnionFind::new(4)
  let _ = wuf.union_with_weight(0, 1, 10L)
  inspect(wuf.diff(0, 1), content="Some(10)")
  inspect(wuf.diff(1, 0), content="Some(-10)")
  inspect(wuf.diff(0, 2), content="None") // Different sets
}

///|
test "union find empty" {
  let uf = UnionFind::new(0)
  inspect(uf.count_sets(), content="0")
}

///|
test "union find single" {
  let uf = UnionFind::new(1)
  inspect(uf.count_sets(), content="1")
  inspect(uf.find(0), content="0")
}

///|
test "union find path compression" {
  let uf = UnionFind::new(10)

  // Create a chain: 0 <- 1 <- 2 <- ... <- 9
  for i in 1..<10 {
    let _ = uf.union(i - 1, i)

  }

  // Find from deepest element
  let root = uf.find(9)

  // After find with path compression, all should point to root
  for i in 0..<10 {
    inspect(uf.find(i) == root, content="true")
  }
}
