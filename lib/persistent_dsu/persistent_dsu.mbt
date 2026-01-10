// ============================================================================
// PERSISTENT DSU - Disjoint Set Union with Rollback
// ============================================================================
//
// A Union-Find data structure that supports undoing operations.
// Useful for divide-and-conquer on trees, dynamic connectivity queries,
// and problems requiring "what if" union-find operations.
//
// KEY INSIGHT: Maintain a history stack of modifications. Each union
// operation is recorded so it can be reversed exactly.
//
// IMPLEMENTATION CHOICES:
// 1. Path compression is NOT used (would break rollback)
// 2. Union by rank/size IS used (maintains near-optimal height)
// 3. Each union records exactly what changed
//
// INVARIANTS:
// 1. After rollback, state is exactly as before corresponding union
// 2. Rank is always an upper bound on tree height
// 3. Connected components are correct at all times
//
// TIME COMPLEXITY:
// - find: O(log n) without path compression
// - union: O(log n)
// - rollback: O(1) per rollback operation
//
// SPACE COMPLEXITY: O(n + history_size)

///|
priv struct PersistentDSU {
  parent : Array[Int]
  rank : Array[Int]
  history : Array[(Int, Int, Int)] // (vertex, old_parent, old_rank)
  mut components : Int
}

///|
fn PersistentDSU::new(n : Int) -> PersistentDSU {
  let parent = Array::make(n, 0)
  let rank = Array::make(n, 0)
  for i = 0; i < n; i = i + 1 {
    parent[i] = i
    rank[i] = 0
  }
  { parent, rank, history: [], components: n }
}

///|
/// Find without path compression (required for rollback)
fn PersistentDSU::find(self : PersistentDSU, x : Int) -> Int {
  let mut curr = x
  while self.parent[curr] != curr {
    curr = self.parent[curr]
  }
  curr
}

///|
/// Check if two elements are in the same set
fn PersistentDSU::same(self : PersistentDSU, x : Int, y : Int) -> Bool {
  self.find(x) == self.find(y)
}

///|
/// Union two sets, returns true if they were different
fn PersistentDSU::union(self : PersistentDSU, x : Int, y : Int) -> Bool {
  let rx = self.find(x)
  let ry = self.find(y)

  if rx == ry {
    return false
  }

  // Union by rank
  if self.rank[rx] < self.rank[ry] {
    // Record change to rx
    self.history.push((rx, self.parent[rx], self.rank[rx]))
    self.parent[rx] = ry
  } else if self.rank[rx] > self.rank[ry] {
    // Record change to ry
    self.history.push((ry, self.parent[ry], self.rank[ry]))
    self.parent[ry] = rx
  } else {
    // Equal ranks, ry becomes child of rx, rx rank increases
    // Record both changes (ry's parent and rx's rank)
    self.history.push((ry, self.parent[ry], self.rank[ry]))
    self.history.push((rx, self.parent[rx], self.rank[rx]))
    self.parent[ry] = rx
    self.rank[rx] = self.rank[rx] + 1
  }

  self.components = self.components - 1
  true
}

///|
/// Get current history size (checkpoint for rollback)
fn PersistentDSU::checkpoint(self : PersistentDSU) -> Int {
  self.history.length()
}

///|
/// Rollback to a previous checkpoint
fn PersistentDSU::rollback(self : PersistentDSU, target : Int) -> Unit {
  while self.history.length() > target {
    let (v, old_parent, old_rank) = self.history.pop().unwrap_or((0, 0, 0))
    // If parent changed, this was a merge
    if self.parent[v] != old_parent {
      self.components = self.components + 1
    }
    self.parent[v] = old_parent
    self.rank[v] = old_rank
  }
}

///|
/// Get number of connected components
fn PersistentDSU::num_components(self : PersistentDSU) -> Int {
  self.components
}

///|
/// Get size of component containing x
fn PersistentDSU::size(self : PersistentDSU, x : Int) -> Int {
  let root = self.find(x)
  let mut count = 0
  for i = 0; i < self.parent.length(); i = i + 1 {
    if self.find(i) == root {
      count = count + 1
    }
  }
  count
}

// ============================================================================
// PERSISTENT DSU WITH SIZE (alternative implementation)
// ============================================================================

///|
priv struct SizedPersistentDSU {
  parent : Array[Int]
  size : Array[Int]
  history : Array[(Int, Int, Int, Int)] // (v1, old_parent1, v2, old_size2) or marker
  mut components : Int
}

///|
fn SizedPersistentDSU::new(n : Int) -> SizedPersistentDSU {
  let parent = Array::make(n, 0)
  let size = Array::make(n, 1)
  for i = 0; i < n; i = i + 1 {
    parent[i] = i
  }
  { parent, size, history: [], components: n }
}

///|
fn SizedPersistentDSU::find(self : SizedPersistentDSU, x : Int) -> Int {
  let mut curr = x
  while self.parent[curr] != curr {
    curr = self.parent[curr]
  }
  curr
}

///|
fn SizedPersistentDSU::same(self : SizedPersistentDSU, x : Int, y : Int) -> Bool {
  self.find(x) == self.find(y)
}

///|
fn SizedPersistentDSU::union(self : SizedPersistentDSU, x : Int, y : Int) -> Bool {
  let rx = self.find(x)
  let ry = self.find(y)

  if rx == ry {
    return false
  }

  // Union by size (larger becomes root)
  let (small, large) = if self.size[rx] < self.size[ry] {
    (rx, ry)
  } else {
    (ry, rx)
  }

  // Record: (small, old_parent_of_small, large, old_size_of_large)
  self.history.push((small, self.parent[small], large, self.size[large]))
  self.parent[small] = large
  self.size[large] = self.size[large] + self.size[small]

  self.components = self.components - 1
  true
}

///|
fn SizedPersistentDSU::checkpoint(self : SizedPersistentDSU) -> Int {
  self.history.length()
}

///|
fn SizedPersistentDSU::rollback(self : SizedPersistentDSU, target : Int) -> Unit {
  while self.history.length() > target {
    let (small, old_parent, large, old_size) = self.history.pop().unwrap_or((0, 0, 0, 0))
    self.parent[small] = old_parent
    self.size[large] = old_size
    self.components = self.components + 1
  }
}

///|
fn SizedPersistentDSU::component_size(self : SizedPersistentDSU, x : Int) -> Int {
  self.size[self.find(x)]
}

///|
fn SizedPersistentDSU::num_components(self : SizedPersistentDSU) -> Int {
  self.components
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "persistent dsu basic" {
  let dsu = PersistentDSU::new(5)

  inspect(dsu.same(0, 1), content="false")
  inspect(dsu.num_components(), content="5")

  let _ = dsu.union(0, 1)
  inspect(dsu.same(0, 1), content="true")
  inspect(dsu.num_components(), content="4")

  let _ = dsu.union(2, 3)
  inspect(dsu.num_components(), content="3")

  let _ = dsu.union(0, 2)
  inspect(dsu.same(1, 3), content="true")
  inspect(dsu.num_components(), content="2")
}

///|
test "persistent dsu rollback" {
  let dsu = PersistentDSU::new(4)

  let cp0 = dsu.checkpoint()
  let _ = dsu.union(0, 1)
  let cp1 = dsu.checkpoint()
  let _ = dsu.union(2, 3)
  let cp2 = dsu.checkpoint()
  let _ = dsu.union(0, 2)

  // All connected now
  inspect(dsu.same(0, 3), content="true")
  inspect(dsu.num_components(), content="1")

  // Rollback last union
  dsu.rollback(cp2)
  inspect(dsu.same(0, 3), content="false")
  inspect(dsu.same(0, 1), content="true")
  inspect(dsu.same(2, 3), content="true")
  inspect(dsu.num_components(), content="2")

  // Rollback to cp1
  dsu.rollback(cp1)
  inspect(dsu.same(2, 3), content="false")
  inspect(dsu.same(0, 1), content="true")
  inspect(dsu.num_components(), content="3")

  // Rollback to beginning
  dsu.rollback(cp0)
  inspect(dsu.same(0, 1), content="false")
  inspect(dsu.num_components(), content="4")
}

///|
test "persistent dsu size" {
  let dsu = PersistentDSU::new(5)

  let _ = dsu.union(0, 1)
  let _ = dsu.union(1, 2)
  inspect(dsu.size(0), content="3")
  inspect(dsu.size(3), content="1")
}

///|
test "sized dsu basic" {
  let dsu = SizedPersistentDSU::new(5)

  let _ = dsu.union(0, 1)
  let _ = dsu.union(1, 2)
  inspect(dsu.component_size(0), content="3")
  inspect(dsu.component_size(3), content="1")
}

///|
test "sized dsu rollback" {
  let dsu = SizedPersistentDSU::new(4)

  let cp = dsu.checkpoint()
  let _ = dsu.union(0, 1)
  let _ = dsu.union(2, 3)
  let _ = dsu.union(0, 2)

  inspect(dsu.component_size(0), content="4")
  inspect(dsu.num_components(), content="1")

  dsu.rollback(cp)
  inspect(dsu.component_size(0), content="1")
  inspect(dsu.num_components(), content="4")
}

///|
test "persistent dsu duplicate union" {
  let dsu = PersistentDSU::new(3)

  let result1 = dsu.union(0, 1)
  inspect(result1, content="true")

  let result2 = dsu.union(0, 1)
  inspect(result2, content="false")

  inspect(dsu.num_components(), content="2")
}

///|
test "persistent dsu chain rollback" {
  let dsu = PersistentDSU::new(6)

  // Create chain: 0-1-2-3-4-5
  let checkpoints : Array[Int] = []
  for i = 0; i < 5; i = i + 1 {
    checkpoints.push(dsu.checkpoint())
    let _ = dsu.union(i, i + 1)

  }

  // All connected
  inspect(dsu.same(0, 5), content="true")

  // Rollback step by step
  // checkpoint[i] was taken BEFORE union(i, i+1)
  // After rollback(checkpoint[i]): unions 0..i-1 done, so 0..i connected
  for i = 4; i >= 0; i = i - 1 {
    dsu.rollback(checkpoints[i])
    // After rollback to checkpoint[i], element i+1 should be disconnected from 0
    inspect(dsu.same(0, i + 1), content="false")
  }
}

///|
test "sized dsu larger" {
  let dsu = SizedPersistentDSU::new(10)

  // Create two groups
  for i = 0; i < 5; i = i + 1 {
    let _ = dsu.union(0, i)

  }
  for i = 5; i < 10; i = i + 1 {
    let _ = dsu.union(5, i)

  }

  inspect(dsu.num_components(), content="2")
  inspect(dsu.component_size(0), content="5")
  inspect(dsu.component_size(5), content="5")

  let cp = dsu.checkpoint()
  let _ = dsu.union(0, 5)
  inspect(dsu.component_size(0), content="10")

  dsu.rollback(cp)
  inspect(dsu.component_size(0), content="5")
}
