// ============================================================================
// DOMINATOR TREE - Union-Find with Path Compression
// ============================================================================
//
// A specialized union-find structure that tracks the minimum semi-dominator
// on the path from a vertex to its set representative.
//
// KEY OPERATIONS:
//   - link(u, v): Make u the parent of v in the forest
//   - eval(v): Return the vertex with minimum sdom on path from v to root
//
// INSIGHT:
//   When computing sdom[v], we need min(sdom[u]) over all u that can reach v
//   via tree edges. Union-find tracks this efficiently as we process vertices
//   in reverse DFS order.
//
// INVARIANT:
//   label[v] holds the vertex with minimum sdom[label[v]] on the path
//   from v to the root of its set (before full path compression).

///|
/// Path compression with label update.
///
/// ALGORITHM:
///   Compress path from v to its set root.
///   Along the way, update label[v] to track minimum sdom.
///
/// THE TRICKY PART:
/// ```
///   Before compression: v → parent → grandparent → ... → root
///   After compression:  v → root
///
///   But we need to preserve:
///     label[v] = argmin { sdom[label[x]] : x on path v → root }
/// ```
///
/// HOW IT WORKS:
///   1. Recursively compress parent's path
///   2. If parent's label has smaller sdom, adopt it
///   3. Point directly to grandparent (path compression)
///
/// PARAMETERS:
///   - self: working data structures
///   - v: vertex to compress (by DFS index)
fn DominatorWork::compress(self : DominatorWork, v : Int) -> Unit {
  // Base case: v is root of its set (dsu[v] = v)
  guard self.dsu[self.dsu[v]] != self.dsu[v] else { return }

  // Recursively compress parent's path first
  self.compress(self.dsu[v])

  // Update label if parent's path has better (smaller) sdom
  if self.sdom[self.label[self.dsu[v]]] < self.sdom[self.label[v]] {
    self.label[v] = self.label[self.dsu[v]]
  }

  // Path compression: point directly to grandparent
  self.dsu[v] = self.dsu[self.dsu[v]]
}

///|
/// Evaluate: find vertex with minimum sdom on path to set root.
///
/// ALGORITHM:
///   If v is its own root, return v.
///   Otherwise, compress path and return label[v].
///
/// RETURN VALUE:
///   A vertex u such that sdom[u] is minimum among all vertices
///   on the path from v to its set root.
///
/// WHY THIS IS USEFUL:
///   When computing sdom[w], we look at predecessors p of w.
///   If p is higher in DFS order (tree descendant), we need
///   min sdom along the path from p to the already-processed region.
///   eval(p) gives us exactly this.
///
/// TIME: O(α(n)) amortized with path compression
///
/// PARAMETERS:
///   - self: working data structures
///   - v: query vertex (by DFS index)
///
/// RETURNS:
///   Vertex with minimum semi-dominator on path to root
fn DominatorWork::eval(self : DominatorWork, v : Int) -> Int {
  if self.dsu[v] == v {
    // v is root of its set
    v
  } else {
    // Compress path and return best label
    self.compress(v)
    self.label[v]
  }
}

///|
/// Link two vertices in the union-find forest.
///
/// SEMANTICS:
///   Make u the parent of v.
///   After this, v's set root becomes u's set root.
///
/// WHEN USED:
///   After processing vertex i in reverse order, we link parent[i] → i.
///   This "activates" vertex i for future eval() queries.
///
/// NOTE:
///   This is a simplified link without union-by-rank.
///   The algorithm still achieves good complexity because we process
///   in DFS reverse order, creating balanced-enough trees.
///
/// PARAMETERS:
///   - self: working data structures
///   - u: the new parent (by DFS index)
///   - v: the child to attach (by DFS index)
fn DominatorWork::link(self : DominatorWork, u : Int, v : Int) -> Unit {
  self.dsu[v] = u
}

///|
fn min(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}
