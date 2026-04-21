// ============================================================================
// Challenge: Union-Find with Rollback
// ============================================================================

///|
pub struct RollbackDSU {
  parent : Array[Int]
  size : Array[Int]
  history : Array[(Int, Int)] // (child, parent_size_before)
}

///|
/// Create a rollback-capable DSU with n singleton sets.
pub fn RollbackDSU::RollbackDSU(n : Int) -> RollbackDSU {
  let parent : Array[Int] = Array::make(n, 0)
  let size : Array[Int] = Array::make(n, 1)
  for i in 0..<n {
    parent[i] = i
  }
  { parent, size, history: [] }
}

///|
/// Find the representative of x (no path compression).
pub fn RollbackDSU::find(self : RollbackDSU, x : Int) -> Int {
  for cur = x {
    if self.parent[cur] == cur {
      break cur
    } else {
      continue self.parent[cur]
    }
  }
}

///|
/// Union the sets of a and b; returns true if merged.
pub fn RollbackDSU::union(self : RollbackDSU, a : Int, b : Int) -> Bool {
  let ra0 = self.find(a)
  let rb0 = self.find(b)
  let (ra, rb) = if self.size[ra0] < self.size[rb0] {
    (rb0, ra0)
  } else {
    (ra0, rb0)
  }
  if ra == rb {
    self.history.push((-1, 0))
    return false
  }
  self.history.push((rb, self.size[ra]))
  self.parent[rb] = ra
  self.size[ra] = self.size[ra] + self.size[rb]
  true
}

///|
/// Capture the current history size for later rollback.
pub fn RollbackDSU::snapshot(self : RollbackDSU) -> Int {
  self.history.length()
}

///|
/// Roll back all unions after the given snapshot.
pub fn RollbackDSU::rollback(self : RollbackDSU, snap : Int) -> Unit {
  for rollback_next = self.history.length() > snap {
    if !rollback_next {
      break
    } else {
      match self.history.pop() {
        Some((child, parent_size)) =>
          if child >= 0 {
            let root = self.parent[child]
            self.size[root] = parent_size
            self.parent[child] = child
          }
        None => ()
      }
      continue self.history.length() > snap
    }
  }
}

///|
/// Check whether a and b are currently in the same set.
pub fn RollbackDSU::same(self : RollbackDSU, a : Int, b : Int) -> Bool {
  self.find(a) == self.find(b)
}

///|
test "rollback_dsu" {
  let dsu = RollbackDSU(4)
  let _ = dsu.union(0, 1)
  let _ = dsu.union(2, 3)
  let snap = dsu.snapshot()
  let _ = dsu.union(1, 2)
  assert_true(dsu.same(0, 3))
  dsu.rollback(snap)
  assert_true(!dsu.same(0, 3))
  assert_true(dsu.same(0, 1))
  assert_true(dsu.same(2, 3))
}
