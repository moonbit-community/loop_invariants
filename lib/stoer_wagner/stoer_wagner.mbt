// ============================================================================
// STOER-WAGNER ALGORITHM - Global Minimum Cut
// ============================================================================
//
// Finds the minimum cut of an undirected weighted graph, i.e., the minimum
// total weight of edges to remove to disconnect the graph.
//
// KEY INSIGHT: In each phase, we grow a set S by repeatedly adding the
// vertex most tightly connected to S. The last two vertices added form
// a valid s-t cut whose weight equals the sum of edges from t to S.
//
// ALGORITHM:
// 1. Start with arbitrary vertex in S
// 2. Add vertex with maximum connectivity to S
// 3. Repeat until all vertices in S
// 4. The cut separating last vertex from rest is a candidate min-cut
// 5. Merge last two vertices and repeat
//
// INVARIANTS:
// 1. S grows by one vertex each iteration
// 2. Cut-of-the-phase is a valid s-t cut for last two vertices
// 3. Minimum of all cut-of-the-phase values is global minimum cut
//
// TIME COMPLEXITY: O(V³) or O(VE + V² log V) with better data structures
// SPACE COMPLEXITY: O(V²)

///|
priv struct StoerWagnerGraph {
  n : Int
  weights : Array[Array[Int]] // Adjacency matrix (mutable during algorithm)
  merged : Array[Bool] // Track merged vertices
}

///|
fn StoerWagnerGraph::new(n : Int) -> StoerWagnerGraph {
  let weights = Array::make(n, [])
  let merged = Array::make(n, false)
  for i = 0; i < n; i = i + 1 {
    weights[i] = Array::make(n, 0)
  }
  { n, weights, merged }
}

///|
fn StoerWagnerGraph::add_edge(self : StoerWagnerGraph, u : Int, v : Int, w : Int) -> Unit {
  self.weights[u][v] = self.weights[u][v] + w
  self.weights[v][u] = self.weights[v][u] + w
}

///|
/// Minimum cut phase: returns (cut_weight, last_vertex, second_last_vertex)
fn StoerWagnerGraph::min_cut_phase(self : StoerWagnerGraph) -> (Int, Int, Int) {
  let n = self.n
  let in_set = Array::make(n, false)
  let conn = Array::make(n, 0) // Connection weight to current set

  // Find first non-merged vertex
  let mut start = -1
  for i = 0; i < n; i = i + 1 {
    if not(self.merged[i]) {
      start = i
      break
    }
  }

  in_set[start] = true
  let mut prev = start
  let mut last = start

  // Update connectivity from start vertex
  for i = 0; i < n; i = i + 1 {
    if not(self.merged[i]) && not(in_set[i]) {
      conn[i] = self.weights[start][i]
    }
  }

  // Add vertices one by one
  let mut added = 1
  let mut active_count = 0
  for i = 0; i < n; i = i + 1 {
    if not(self.merged[i]) {
      active_count = active_count + 1
    }
  }

  while added < active_count {
    // Find vertex with maximum connectivity
    let mut max_conn = -1
    let mut max_v = -1

    for i = 0; i < n; i = i + 1 {
      if not(self.merged[i]) && not(in_set[i]) {
        if conn[i] > max_conn {
          max_conn = conn[i]
          max_v = i
        }
      }
    }

    if max_v < 0 {
      break
    }

    in_set[max_v] = true
    prev = last
    last = max_v
    added = added + 1

    // Update connectivity
    for i = 0; i < n; i = i + 1 {
      if not(self.merged[i]) && not(in_set[i]) {
        conn[i] = conn[i] + self.weights[max_v][i]
      }
    }
  }

  // Cut weight is connectivity of last vertex when it was added
  (conn[last], last, prev)
}

///|
/// Merge two vertices
fn StoerWagnerGraph::merge_vertices(self : StoerWagnerGraph, s : Int, t : Int) -> Unit {
  let n = self.n

  // Merge t into s
  for i = 0; i < n; i = i + 1 {
    if i != s && i != t {
      self.weights[s][i] = self.weights[s][i] + self.weights[t][i]
      self.weights[i][s] = self.weights[i][s] + self.weights[i][t]
    }
  }

  self.merged[t] = true
}

///|
/// Find global minimum cut
fn StoerWagnerGraph::min_cut(self : StoerWagnerGraph) -> Int {
  let n = self.n

  // Count active vertices
  let mut active = 0
  for i = 0; i < n; i = i + 1 {
    if not(self.merged[i]) {
      active = active + 1
    }
  }

  if active <= 1 {
    return 0
  }

  let mut min_cut_val = 2147483647

  // Run n-1 phases
  for phase = 0; phase < n - 1; phase = phase + 1 {
    let mut current_active = 0
    for i = 0; i < n; i = i + 1 {
      if not(self.merged[i]) {
        current_active = current_active + 1
      }
    }

    if current_active <= 1 {
      break
    }

    let (cut_weight, last, prev) = self.min_cut_phase()

    if cut_weight < min_cut_val {
      min_cut_val = cut_weight
    }

    self.merge_vertices(prev, last)
  }

  min_cut_val
}

///|
/// Find minimum cut of an edge list graph
fn stoer_wagner(n : Int, edges : Array[(Int, Int, Int)]) -> Int {
  let g = StoerWagnerGraph::new(n)
  for i = 0; i < edges.length(); i = i + 1 {
    let (u, v, w) = edges[i]
    g.add_edge(u, v, w)
  }
  g.min_cut()
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "stoer_wagner simple" {
  // Two vertices connected by edge weight 5
  let edges : Array[(Int, Int, Int)] = [(0, 1, 5)]
  inspect(stoer_wagner(2, edges), content="5")
}

///|
test "stoer_wagner triangle" {
  // Triangle with edges 1, 2, 3
  let edges : Array[(Int, Int, Int)] = [(0, 1, 1), (1, 2, 2), (0, 2, 3)]
  // Minimum cut separates one vertex
  // Cut {0} has weight 1 + 3 = 4
  // Cut {1} has weight 1 + 2 = 3
  // Cut {2} has weight 2 + 3 = 5
  inspect(stoer_wagner(3, edges), content="3")
}

///|
test "stoer_wagner path" {
  // Path: 0 --1-- 1 --2-- 2 --3-- 3
  let edges : Array[(Int, Int, Int)] = [(0, 1, 1), (1, 2, 2), (2, 3, 3)]
  // Minimum cut is the edge with weight 1
  inspect(stoer_wagner(4, edges), content="1")
}

///|
test "stoer_wagner square" {
  // Square with equal weights
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 1), (1, 2, 1), (2, 3, 1), (3, 0, 1)
  ]
  // Minimum cut needs 2 edges
  inspect(stoer_wagner(4, edges), content="2")
}

///|
test "stoer_wagner complex" {
  // More complex graph
  // 0 ---3--- 1
  // |         |
  // 2         4
  // |         |
  // 3 ---1--- 2
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 3), (0, 3, 2), (1, 2, 4), (2, 3, 1)
  ]
  // Various cuts possible
  let result = stoer_wagner(4, edges)
  inspect(result <= 3, content="true")
}

///|
test "stoer_wagner disconnected" {
  // Already disconnected graph
  let edges : Array[(Int, Int, Int)] = []
  inspect(stoer_wagner(2, edges), content="0")
}

///|
test "stoer_wagner single vertex" {
  let edges : Array[(Int, Int, Int)] = []
  inspect(stoer_wagner(1, edges), content="0")
}

///|
test "stoer_wagner complete4" {
  // K4 with unit weights
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 1), (0, 2, 1), (0, 3, 1),
    (1, 2, 1), (1, 3, 1), (2, 3, 1)
  ]
  // Each vertex has degree 3, so min cut is 3
  inspect(stoer_wagner(4, edges), content="3")
}

///|
test "stoer_wagner barbell" {
  // Two triangles connected by single edge
  // Triangle 0-1-2 and triangle 3-4-5
  // Connected by edge 2-3 with weight 1
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 10), (1, 2, 10), (0, 2, 10),
    (3, 4, 10), (4, 5, 10), (3, 5, 10),
    (2, 3, 1)
  ]
  // Minimum cut is the bridge edge
  inspect(stoer_wagner(6, edges), content="1")
}
