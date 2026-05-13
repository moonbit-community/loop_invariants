// ============================================================================
// MINIMUM SPANNING TREE - Kruskal's and Prim's Algorithms
// ============================================================================
//
// A Minimum Spanning Tree (MST) connects all vertices with minimum total edge
// weight. For a graph with n vertices, MST has exactly n-1 edges.
//
// KRUSKAL'S ALGORITHM:
// 1. Sort edges by weight
// 2. For each edge in order, add to MST if it doesn't create a cycle
// 3. Use Union-Find to detect cycles efficiently
//
// PRIM'S ALGORITHM:
// 1. Start from any vertex, grow MST one vertex at a time
// 2. Always add the minimum weight edge connecting MST to non-MST vertex
// 3. Use priority queue for efficiency
//
// KEY INSIGHT (Cut Property):
// For any cut of the graph, the minimum weight edge crossing the cut
// is in some MST. Both algorithms exploit this property.
//
// INVARIANTS:
// 1. Selected edges form a forest (no cycles)
// 2. At each step, edges selected are part of some MST
// 3. After n-1 edges, we have a spanning tree
//
// TIME COMPLEXITY: O(E log E) for both algorithms
// SPACE COMPLEXITY: O(V + E)

///|
/// An undirected weighted edge between two vertices.
///
/// Both `u` and `v` are 0-based vertex indices. `weight` is the cost
/// assigned to this edge and may be any `Int64` value, including zero.
priv struct Edge {
  u : Int
  v : Int
  weight : Int64
}

///|
/// A weighted undirected graph used by Kruskal's algorithm.
///
/// `n` is the number of vertices (indexed `0..n-1`). Edges are stored in
/// an unsorted flat array and sorted lazily when `kruskal` is called.
priv struct MST {
  n : Int
  edges : Array[Edge]
}

///|
/// Create a new empty graph with `n` vertices and no edges.
///
/// # Parameters
/// - `n`: Number of vertices. Vertices are labelled `0` to `n-1`.
///
/// # Example
/// ```moonbit nocheck
/// let g = MST(5)
/// ```
fn MST::MST(n : Int) -> MST {
  { n, edges: [] }
}

///|
/// Add an undirected edge between vertices `u` and `v` with the given `weight`.
///
/// The edge is stored once and is treated as bidirectional by Kruskal's
/// algorithm: it can connect component `u` to component `v` or vice versa.
///
/// # Parameters
/// - `u`, `v`: Endpoint vertex indices (0-based).
/// - `weight`: Edge cost (`Int64`).
fn MST::add_edge(self : MST, u : Int, v : Int, weight : Int64) -> Unit {
  self.edges.push({ u, v, weight })
}

///|
/// Union-Find (Disjoint Set Union) data structure for cycle detection.
///
/// Uses path compression in `find` and union by rank in `union` so that
/// both operations run in nearly O(1) amortised time.
priv struct UF {
  parent : Array[Int]
  rank : Array[Int]
}

///|
/// Create a new Union-Find structure with `n` singleton sets.
///
/// After construction, `find(i) == i` for every vertex `i`.
///
/// # Parameters
/// - `n`: Number of elements (vertices). Each starts in its own set.
fn UF::UF(n : Int) -> UF {
  let parent = Array::make(n, 0)
  let rank = Array::make(n, 0)
  for i in 0..<n {
    parent[i] = i
  } where {
    proof_invariant: i >= 0 &&
    i <= n &&
    parent.length() == n &&
    rank.length() == n,
    proof_reasoning: (
      #|INVARIANT (UF init):
      #|parent[j] = j for all j in [0, i); each vertex is its own set.
      #|MAINTENANCE:
      #|Assign parent[i] = i.
      #|TERMINATION:
      #|At i = n, all vertices are separate sets.
    ),
  }
  { parent, rank }
}

///|
/// Return the representative (root) of the set containing `x`.
///
/// Applies **path compression**: after the call, `parent[x]` points
/// directly to the root, flattening the tree for future queries.
///
/// # Parameters
/// - `x`: A vertex index in `[0, n)`.
fn UF::find(self : UF, x : Int) -> Int {
  if self.parent[x] != x {
    self.parent[x] = self.find(self.parent[x])
  }
  self.parent[x]
}

///|
/// Merge the sets containing `x` and `y`.
///
/// Returns `true` if `x` and `y` were in different sets (the edge is
/// safe to add to the MST), or `false` if they were already connected
/// (adding the edge would create a cycle).
///
/// Uses **union by rank**: the root of the smaller-rank tree is attached
/// to the root of the larger-rank tree to keep trees shallow.
///
/// # Parameters
/// - `x`, `y`: Vertex indices whose sets are to be merged.
fn UF::union(self : UF, x : Int, y : Int) -> Bool {
  let rx = self.find(x)
  let ry = self.find(y)
  if rx == ry {
    return false
  }
  if self.rank[rx] < self.rank[ry] {
    self.parent[rx] = ry
  } else if self.rank[rx] > self.rank[ry] {
    self.parent[ry] = rx
  } else {
    self.parent[ry] = rx
    self.rank[rx] = self.rank[rx] + 1
  }
  true
}

///|
/// Run Kruskal's algorithm and return the MST edges together with the
/// total weight.
///
/// The algorithm sorts all edges by weight and greedily adds each edge
/// that would not create a cycle (detected via Union-Find). By the
/// **cut property**, every chosen edge is safe: at the moment it is
/// considered it is the lightest edge crossing some cut of the graph,
/// so it must belong to some MST.
///
/// # Returns
/// A tuple `(mst_edges, total_weight)` where `mst_edges` contains at
/// most `n - 1` edges. If the graph is connected, exactly `n - 1` edges
/// are returned and `total_weight` is the MST cost. If the graph is
/// disconnected, fewer than `n - 1` edges are returned (a minimum
/// spanning *forest*).
///
/// # Complexity
/// - Time: O(E log E) for sorting, plus near-linear Union-Find operations.
/// - Space: O(E) for the sorted edge copy plus O(V) for Union-Find.
fn MST::kruskal(self : MST) -> (Array[Edge], Int64) {
  if self.n <= 1 {
    return ([], 0L)
  }

  // Sort edges by weight
  let sorted_edges = self.edges.copy()
  sorted_edges.sort_by((a, b) => {
    if a.weight < b.weight {
      -1
    } else if a.weight > b.weight {
      1
    } else {
      0
    }
  })
  let uf = UF(self.n)
  let mst_edges : Array[Edge] = []
  let total_weight = for edge in sorted_edges; total_weight = 0L {
    if mst_edges.length() < self.n - 1 && uf.union(edge.u, edge.v) {
      mst_edges.push(edge)
      continue total_weight + edge.weight
    }
    continue total_weight
  } nobreak {
    total_weight
  }
  (mst_edges, total_weight)
}

///|
/// Return `true` when a spanning tree exists, i.e. the graph is connected.
///
/// A graph on `n` vertices is connected if and only if Kruskal's algorithm
/// finds exactly `n - 1` MST edges. A graph with a single vertex is
/// trivially connected.
fn MST::is_connected(self : MST) -> Bool {
  if self.n <= 1 {
    return true
  }
  let (edges, _) = self.kruskal()
  edges.length() == self.n - 1
}

///|
/// Return the total weight of a minimum spanning tree, or `None` if the
/// graph is disconnected.
///
/// - Returns `Some(0)` for a graph with a single vertex.
/// - Returns `Some(weight)` when all vertices can be spanned.
/// - Returns `None` when the graph has isolated components.
fn MST::get_mst_weight(self : MST) -> Int64? {
  if self.n <= 1 {
    return Some(0L)
  }
  let (edges, weight) = self.kruskal()
  if edges.length() == self.n - 1 {
    Some(weight)
  } else {
    None
  }
}

// ============================================================================
// PRIM'S ALGORITHM (using simple O(V^2) approach)
// ============================================================================

///|
/// A weighted undirected graph stored as an adjacency list, used by
/// Prim's O(V^2) algorithm.
///
/// `n` is the number of vertices. `adj[u]` holds a list of
/// `(neighbor, weight)` pairs for every edge incident to vertex `u`.
priv struct PrimMST {
  n : Int
  adj : Array[Array[(Int, Int64)]] // (neighbor, weight)
}

///|
/// Create a new empty adjacency-list graph with `n` vertices.
///
/// # Parameters
/// - `n`: Number of vertices. Vertices are labelled `0` to `n-1`.
fn PrimMST::PrimMST(n : Int) -> PrimMST {
  let adj : Array[Array[(Int, Int64)]] = [ for _ in 0..<n => [] ]
  { n, adj }
}

///|
/// Add an undirected edge between vertices `u` and `v` with the given
/// `weight`. Both endpoints' adjacency lists are updated.
///
/// # Parameters
/// - `u`, `v`: Endpoint vertex indices (0-based).
/// - `weight`: Edge cost (`Int64`).
fn PrimMST::add_edge(self : PrimMST, u : Int, v : Int, weight : Int64) -> Unit {
  self.adj[u].push((v, weight))
  self.adj[v].push((u, weight))
}

///|
/// Sentinel value representing "no edge known yet" in Prim's algorithm.
///
/// Set to `Int64::max_value` (9 223 372 036 854 775 807) so that any real
/// edge weight will compare as smaller.
const PRIM_INF : Int64 = 9223372036854775807L

///|
/// Run Prim's O(V^2) algorithm and return the total MST weight.
///
/// Starting from vertex 0, the algorithm repeatedly selects the cheapest
/// edge that crosses the frontier between the current tree and the
/// remaining vertices. By the **cut property**, each chosen edge is safe.
///
/// The inner scan over all vertices to find the minimum is O(V), giving
/// an overall O(V^2) runtime. This is competitive with the heap-based
/// O((V+E) log V) variant on dense graphs where E is close to V^2.
///
/// # Returns
/// - `Some(total_weight)` when the graph is connected and a spanning
///   tree covering all `n` vertices is found.
/// - `None` when the graph is disconnected (fewer than `n - 1` edges
///   were added before no reachable vertex remained).
/// - `Some(0)` for a single-vertex graph.
///
/// # Complexity
/// - Time: O(V^2). Suitable for dense graphs or when V is small.
/// - Space: O(V) for the `in_mst` and `min_edge` arrays.
fn PrimMST::compute(self : PrimMST) -> Int64? {
  if self.n <= 1 {
    return Some(0L)
  }
  let in_mst = Array::make(self.n, false)
  let min_edge = Array::make(self.n, PRIM_INF)
  min_edge[0] = 0L
  let (total_weight, edges_added) = for iter = 0, total_weight = 0L, edges_added = 0; iter <
                                       self.n; {
    // Find minimum edge to non-MST vertex
    let (u, min_w) = for i in 0..<self.n; u = -1, min_w = PRIM_INF {
      if !in_mst[i] && min_edge[i] < min_w {
        continue i, min_edge[i]
      }
      continue u, min_w
    } nobreak {
      (u, min_w)
    } where {
      proof_invariant: i >= 0 &&
      i <= self.n &&
      min_edge.length() == self.n &&
      in_mst.length() == self.n,
      proof_reasoning: (
        #|INVARIANT (select min):
        #|min_w/u track the smallest min_edge among vertices in [0, i) not in MST.
        #|MAINTENANCE:
        #|If a better candidate is found, update min_w and u.
        #|TERMINATION:
        #|At i = n, u is the argmin among all non-MST vertices (or -1 if none).
      ),
    }
    if u < 0 || min_w == PRIM_INF {
      break (total_weight, edges_added) // No more reachable vertices
    }
    in_mst[u] = true
    let total_weight = total_weight + min_w
    let edges_added = if iter > 0 { edges_added + 1 } else { edges_added }

    // Update min_edge for neighbors
    for neighbor in self.adj[u] {
      let (v, w) = neighbor
      if !in_mst[v] && w < min_edge[v] {
        min_edge[v] = w
      }
    }
    continue iter + 1, total_weight, edges_added
  } nobreak {
    (total_weight, edges_added)
  } where {
    proof_invariant: iter >= 0 && iter <= self.n && in_mst.length() == self.n,
    proof_reasoning: (
      #|INVARIANT (Prim):
      #|The set in_mst forms a tree, and min_edge holds the cheapest crossing
      #|edge for each vertex not yet in the tree.
      #|MAINTENANCE:
      #|Select the minimum min_edge vertex, add it, and relax its neighbors.
      #|By the cut property, the chosen edge is safe.
      #|TERMINATION:
      #|After n iterations or when no reachable vertex remains, MST is complete
      #|for the connected component.
    ),
  }
  if edges_added == self.n - 1 {
    Some(total_weight)
  } else {
    None
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "mst kruskal basic" {
  let mst = MST(4)
  mst.add_edge(0, 1, 1L)
  mst.add_edge(1, 2, 2L)
  mst.add_edge(2, 3, 3L)
  mst.add_edge(0, 3, 4L)
  mst.add_edge(1, 3, 5L)
  let (edges, weight) = mst.kruskal()
  debug_inspect(edges.length(), content="3")
  debug_inspect(weight, content="6") // 1 + 2 + 3
}

///|
test "mst kruskal triangle" {
  let mst = MST(3)
  mst.add_edge(0, 1, 1L)
  mst.add_edge(1, 2, 2L)
  mst.add_edge(0, 2, 3L)
  debug_inspect(mst.get_mst_weight(), content="Some(3)") // 1 + 2
}

///|
test "mst disconnected" {
  let mst = MST(4)
  mst.add_edge(0, 1, 1L)
  mst.add_edge(2, 3, 2L)
  debug_inspect(mst.is_connected(), content="false")
  debug_inspect(mst.get_mst_weight(), content="None")
}

///|
test "mst single vertex" {
  let mst = MST(1)
  debug_inspect(mst.get_mst_weight(), content="Some(0)")
}

///|
test "prim basic" {
  let prim = PrimMST(4)
  prim.add_edge(0, 1, 1L)
  prim.add_edge(1, 2, 2L)
  prim.add_edge(2, 3, 3L)
  prim.add_edge(0, 3, 4L)
  debug_inspect(prim.compute(), content="Some(6)")
}

///|
test "mst same weights" {
  let mst = MST(3)
  mst.add_edge(0, 1, 1L)
  mst.add_edge(1, 2, 1L)
  mst.add_edge(0, 2, 1L)
  debug_inspect(mst.get_mst_weight(), content="Some(2)")
}
