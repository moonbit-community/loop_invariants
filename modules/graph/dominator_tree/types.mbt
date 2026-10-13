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
  mut val : Int32
}

///|
/// Build n separate empty lists for adjacency representation.
fn build_adj_lists(n : Int32) -> Array[Array[Int32]] {
  [
    for _ in 0..<n => []
  ]
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
  n : Int32
  adj : Array[Array[Int32]]
  pred : Array[Array[Int32]]
  arr : Array[Int32]
  rev : Array[Int32]
  parent : Array[Int32]
  sdom : Array[Int32]
  idom : Array[Int32]
  dsu : Array[Int32]
  label : Array[Int32]
  bucket : Array[Array[Int32]]
  time : Counter
}

///|
/// Create working structures for dominator tree computation.
fn DominatorWork::DominatorWork(n : Int32) -> DominatorWork {
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
    time: { val: 0, },
  }
}

///|
/// Add directed edge u → v to the graph.
fn DominatorWork::add_edge(self : DominatorWork, u : Int32, v : Int32) -> Unit {
  self.adj[u].push(v)
}

///|
/// The result of running the Lengauer-Tarjan dominator tree algorithm on a
/// directed graph.
///
/// A vertex u **dominates** v when every path from the root to v must pass
/// through u. The **immediate dominator** (idom) of v is the unique closest
/// strict dominator. Together, the idom relation forms a tree rooted at the
/// start vertex.
///
/// Fields:
/// - `root` -- the root (start) vertex used when building the tree.
/// - `idom` -- `idom[v]` is the immediate dominator of vertex v.
///   * `idom[root] == root` (the root dominates itself).
///   * `idom[v] == -1` for any vertex v that is unreachable from root.
/// - `tree` -- adjacency list of the dominator tree.
///   `tree[u]` contains every vertex v for which `idom[v] == u`.
///
/// The struct is derived `Debug` for inspection during development.
///
/// To query dominance between two arbitrary vertices use `dominates`.
/// To build a dominator tree use `build_dominator_tree`.
pub(all) struct DominatorTree {
  root : Int32
  idom : Array[Int32]
  tree : Array[Array[Int32]]
} derive(Debug)
