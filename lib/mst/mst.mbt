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
priv struct Edge {
  u : Int
  v : Int
  weight : Int64
}

///|
priv struct MST {
  n : Int
  edges : Array[Edge]
}

///|
fn MST::new(n : Int) -> MST {
  { n, edges: [] }
}

///|
fn MST::add_edge(self : MST, u : Int, v : Int, weight : Int64) -> Unit {
  self.edges.push({ u, v, weight })
}

///|
/// Union-Find for cycle detection
priv struct UF {
  parent : Array[Int]
  rank : Array[Int]
}

///|
fn UF::new(n : Int) -> UF {
  let parent = Array::make(n, 0)
  let rank = Array::make(n, 0)
  for i = 0; i < n; i = i + 1 {
    parent[i] = i
  } where {
    invariant: i >= 0 && i <= n && parent.length() == n && rank.length() == n,
    reasoning: (
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
fn UF::find(self : UF, x : Int) -> Int {
  if self.parent[x] != x {
    self.parent[x] = self.find(self.parent[x])
  }
  self.parent[x]
}

///|
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
/// Kruskal's algorithm
fn MST::kruskal(self : MST) -> (Array[Edge], Int64) {
  if self.n <= 1 {
    return ([], 0L)
  }

  // Sort edges by weight
  let sorted_edges = self.edges.copy()
  sorted_edges.sort_by(fn(a, b) {
    if a.weight < b.weight {
      -1
    } else if a.weight > b.weight {
      1
    } else {
      0
    }
  })
  let uf = UF::new(self.n)
  let mst_edges : Array[Edge] = []
  let mut total_weight = 0L
  for edge in sorted_edges {
    if mst_edges.length() == self.n - 1 {
      break
    }
    if uf.union(edge.u, edge.v) {
      mst_edges.push(edge)
      total_weight = total_weight + edge.weight
    }
  }
  (mst_edges, total_weight)
}

///|
/// Check if graph is connected
fn MST::is_connected(self : MST) -> Bool {
  if self.n <= 1 {
    return true
  }
  let (edges, _) = self.kruskal()
  edges.length() == self.n - 1
}

///|
/// Get MST weight
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
priv struct PrimMST {
  n : Int
  adj : Array[Array[(Int, Int64)]] // (neighbor, weight)
}

///|
fn PrimMST::new(n : Int) -> PrimMST {
  let adj = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    adj[i] = []
  } where {
    invariant: i >= 0 && i <= n && adj.length() == n,
    reasoning: (
      #|INVARIANT (adj init):
      #|Adjacency lists for vertices in [0, i) are initialized and independent.
      #|MAINTENANCE:
      #|Assign a fresh empty list to adj[i].
      #|TERMINATION:
      #|At i = n, all adjacency lists are initialized.
    ),
  }
  { n, adj }
}

///|
fn PrimMST::add_edge(self : PrimMST, u : Int, v : Int, weight : Int64) -> Unit {
  self.adj[u].push((v, weight))
  self.adj[v].push((u, weight))
}

///|
const PRIM_INF : Int64 = 9223372036854775807L

///|
fn PrimMST::compute(self : PrimMST) -> Int64? {
  if self.n <= 1 {
    return Some(0L)
  }
  let in_mst = Array::make(self.n, false)
  let min_edge = Array::make(self.n, PRIM_INF)
  min_edge[0] = 0L
  let mut total_weight = 0L
  let mut edges_added = 0
  for iter = 0; iter < self.n; iter = iter + 1 {
    // Find minimum edge to non-MST vertex
    let mut u = -1
    let mut min_w = PRIM_INF
    for i = 0; i < self.n; i = i + 1 {
      if not(in_mst[i]) && min_edge[i] < min_w {
        min_w = min_edge[i]
        u = i
      }
    } where {
      invariant: i >= 0 &&
      i <= self.n &&
      min_edge.length() == self.n &&
      in_mst.length() == self.n,
      reasoning: (
        #|INVARIANT (select min):
        #|min_w/u track the smallest min_edge among vertices in [0, i) not in MST.
        #|MAINTENANCE:
        #|If a better candidate is found, update min_w and u.
        #|TERMINATION:
        #|At i = n, u is the argmin among all non-MST vertices (or -1 if none).
      ),
    }
    if u < 0 || min_w == PRIM_INF {
      break // No more reachable vertices
    }
    in_mst[u] = true
    total_weight = total_weight + min_w
    if iter > 0 {
      edges_added = edges_added + 1
    }

    // Update min_edge for neighbors
    for neighbor in self.adj[u] {
      let (v, w) = neighbor
      if not(in_mst[v]) && w < min_edge[v] {
        min_edge[v] = w
      }
    }
  } where {
    invariant: iter >= 0 && iter <= self.n && in_mst.length() == self.n,
    reasoning: (
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
  let mst = MST::new(4)
  mst.add_edge(0, 1, 1L)
  mst.add_edge(1, 2, 2L)
  mst.add_edge(2, 3, 3L)
  mst.add_edge(0, 3, 4L)
  mst.add_edge(1, 3, 5L)
  let (edges, weight) = mst.kruskal()
  inspect(edges.length(), content="3")
  inspect(weight, content="6") // 1 + 2 + 3
}

///|
test "mst kruskal triangle" {
  let mst = MST::new(3)
  mst.add_edge(0, 1, 1L)
  mst.add_edge(1, 2, 2L)
  mst.add_edge(0, 2, 3L)
  inspect(mst.get_mst_weight(), content="Some(3)") // 1 + 2
}

///|
test "mst disconnected" {
  let mst = MST::new(4)
  mst.add_edge(0, 1, 1L)
  mst.add_edge(2, 3, 2L)
  inspect(mst.is_connected(), content="false")
  inspect(mst.get_mst_weight(), content="None")
}

///|
test "mst single vertex" {
  let mst = MST::new(1)
  inspect(mst.get_mst_weight(), content="Some(0)")
}

///|
test "prim basic" {
  let prim = PrimMST::new(4)
  prim.add_edge(0, 1, 1L)
  prim.add_edge(1, 2, 2L)
  prim.add_edge(2, 3, 3L)
  prim.add_edge(0, 3, 4L)
  inspect(prim.compute(), content="Some(6)")
}

///|
test "mst same weights" {
  let mst = MST::new(3)
  mst.add_edge(0, 1, 1L)
  mst.add_edge(1, 2, 1L)
  mst.add_edge(0, 2, 1L)
  inspect(mst.get_mst_weight(), content="Some(2)")
}
