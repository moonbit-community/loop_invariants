// ============================================================================
// DOMINATOR TREE - Type Definitions
// ============================================================================
//
// Data structures for the Lengauer-Tarjan dominator tree algorithm.
//
// TERMINOLOGY:
//   - Dominator: u dominates v if every path from root to v goes through u
//   - Immediate dominator (idom): closest strict dominator
//   - Semi-dominator (sdom): auxiliary concept for efficient computation
//
// The algorithm works in "DFS index space" where vertices are numbered 1..n
// by their DFS discovery order. Index 0 is unused/sentinel.

///|
/// Mutable counter for DFS timestamp assignment.
priv struct Counter {
  mut val : Int
}

///|
/// Build n separate empty lists for adjacency representation.
fn build_adj_lists(n : Int) -> Array[Array[Int]] {
  let adj = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    adj[i] = []
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (adj init):
      #|adj[0..i) contains distinct empty arrays.
      #|MAINTENANCE:
      #|Assign a fresh array at adj[i].
      #|TERMINATION:
      #|At i = n, all adjacency lists are initialized.
    ),
  }
  adj
}

///|
/// Working data structures for Lengauer-Tarjan algorithm.
///
/// FIELDS (all indexed by DFS number except adj which uses vertex IDs):
///   - n: number of vertices
///   - adj: forward adjacency list (vertex → vertex)
///   - pred: predecessor list by DFS index
///   - arr: vertex → DFS index (0 = unreachable)
///   - rev: DFS index → vertex (inverse of arr)
///   - parent: DFS tree parent by index
///   - sdom: semi-dominator by index
///   - idom: immediate dominator by index
///   - dsu: union-find parent
///   - label: union-find label for path compression
///   - bucket: vertices grouped by semi-dominator
///   - time: DFS timestamp counter
priv struct DominatorWork {
  n : Int
  adj : Array[Array[Int]]
  pred : Array[Array[Int]]
  arr : Array[Int]
  rev : Array[Int]
  parent : Array[Int]
  sdom : Array[Int]
  idom : Array[Int]
  dsu : Array[Int]
  label : Array[Int]
  bucket : Array[Array[Int]]
  time : Counter
}

///|
/// Create working structures for dominator tree computation.
fn DominatorWork::new(n : Int) -> DominatorWork {
  let adj = build_adj_lists(n)
  let pred = build_adj_lists(n + 1)
  {
    n,
    adj,
    pred,
    arr: Array::make(n, 0),
    rev: Array::make(n + 1, 0),
    parent: Array::make(n + 1, 0),
    sdom: Array::make(n + 1, 0),
    idom: Array::make(n + 1, 0),
    dsu: Array::make(n + 1, 0),
    label: Array::make(n + 1, 0),
    bucket: build_adj_lists(n + 1),
    time: { val: 0 },
  }
}

///|
/// Add directed edge u → v to the graph.
fn DominatorWork::add_edge(self : DominatorWork, u : Int, v : Int) -> Unit {
  self.adj[u].push(v)
}

///|
/// Final dominator tree result.
///
/// FIELDS:
///   - root: the root vertex
///   - idom: immediate dominator for each vertex (-1 if unreachable)
///   - tree: children of each vertex in dominator tree
///
/// PROPERTIES:
///   - idom[root] = root (root dominates itself)
///   - For reachable v ≠ root: idom[v] strictly dominates v
///   - tree[u] contains all v where idom[v] = u
pub(all) struct DominatorTree {
  root : Int
  idom : Array[Int]
  tree : Array[Array[Int]]
} derive(Show)
