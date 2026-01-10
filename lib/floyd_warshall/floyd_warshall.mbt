// ============================================================================
// FLOYD-WARSHALL - All Pairs Shortest Paths
// ============================================================================
//
// Floyd-Warshall computes shortest paths between all pairs of vertices in O(V³).
// Works with negative edge weights (but not negative cycles).
//
// KEY INSIGHT: Dynamic programming where dist[i][j][k] = shortest path from i to j
// using only vertices {0, 1, ..., k} as intermediate nodes.
//
// RECURRENCE:
// dist[i][j][k] = min(dist[i][j][k-1], dist[i][k][k-1] + dist[k][j][k-1])
// Either we don't use vertex k, or we go through it.
//
// SPACE OPTIMIZATION: Can use 2D array since we only need previous k.
//
// INVARIANTS:
// 1. After phase k: dist[i][j] = shortest path using vertices {0..k-1} as intermediates
// 2. dist[i][i] = 0 for all i (no negative cycles)
// 3. Triangle inequality: dist[i][j] <= dist[i][k] + dist[k][j]
//
// TIME COMPLEXITY: O(V³)
// SPACE COMPLEXITY: O(V²)

///|
const FW_INF : Int64 = 4611686018427387903L

///|
priv struct FloydWarshall {
  n : Int
  dist : Array[Array[Int64]]
  next : Array[Array[Int]] // For path reconstruction
}

///|
fn FloydWarshall::new(n : Int) -> FloydWarshall {
  let dist = Array::make(n, [])
  let next = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    dist[i] = Array::make(n, FW_INF)
    next[i] = Array::make(n, -1)
    dist[i][i] = 0L
  }
  { n, dist, next }
}

///|
/// Add directed edge from u to v with weight w
fn FloydWarshall::add_edge(self : FloydWarshall, u : Int, v : Int, w : Int64) -> Unit {
  if w < self.dist[u][v] {
    self.dist[u][v] = w
    self.next[u][v] = v
  }
}

///|
/// Add undirected edge between u and v with weight w
fn FloydWarshall::add_undirected_edge(
  self : FloydWarshall,
  u : Int,
  v : Int,
  w : Int64
) -> Unit {
  self.add_edge(u, v, w)
  self.add_edge(v, u, w)
}

///|
/// Run Floyd-Warshall algorithm
fn FloydWarshall::compute(self : FloydWarshall) -> Unit {
  let n = self.n

  // Main DP: try each vertex as intermediate
  for k = 0; k < n; k = k + 1 {
    for i = 0; i < n; i = i + 1 {
      for j = 0; j < n; j = j + 1 {
        if self.dist[i][k] < FW_INF && self.dist[k][j] < FW_INF {
          let through_k = self.dist[i][k] + self.dist[k][j]
          if through_k < self.dist[i][j] {
            self.dist[i][j] = through_k
            self.next[i][j] = self.next[i][k]
          }
        }
      }
    }
  }
}

///|
/// Get shortest distance from u to v
fn FloydWarshall::get_dist(self : FloydWarshall, u : Int, v : Int) -> Int64 {
  self.dist[u][v]
}

///|
/// Check if path exists from u to v
fn FloydWarshall::has_path(self : FloydWarshall, u : Int, v : Int) -> Bool {
  self.dist[u][v] < FW_INF
}

///|
/// Reconstruct path from u to v
fn FloydWarshall::get_path(self : FloydWarshall, u : Int, v : Int) -> Array[Int] {
  if self.next[u][v] < 0 {
    return []
  }

  let path : Array[Int] = [u]
  let mut cur = u
  while cur != v {
    cur = self.next[cur][v]
    path.push(cur)
  }
  path
}

///|
/// Check for negative cycle (any dist[i][i] < 0)
fn FloydWarshall::has_negative_cycle(self : FloydWarshall) -> Bool {
  for i = 0; i < self.n; i = i + 1 {
    if self.dist[i][i] < 0L {
      return true
    }
  }
  false
}

///|
/// Get diameter of graph (longest shortest path)
fn FloydWarshall::diameter(self : FloydWarshall) -> Int64 {
  let mut max_dist = 0L
  for i = 0; i < self.n; i = i + 1 {
    for j = 0; j < self.n; j = j + 1 {
      if self.dist[i][j] < FW_INF && self.dist[i][j] > max_dist {
        max_dist = self.dist[i][j]
      }
    }
  }
  max_dist
}

// ============================================================================
// TRANSITIVE CLOSURE
// ============================================================================

///|
/// Compute transitive closure using Floyd-Warshall variant
fn transitive_closure(adj : Array[Array[Bool]]) -> Array[Array[Bool]] {
  let n = adj.length()
  let reach = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    reach[i] = Array::make(n, false)
    for j = 0; j < n; j = j + 1 {
      reach[i][j] = adj[i][j] || i == j
    }
  }

  for k = 0; k < n; k = k + 1 {
    for i = 0; i < n; i = i + 1 {
      for j = 0; j < n; j = j + 1 {
        reach[i][j] = reach[i][j] || (reach[i][k] && reach[k][j])
      }
    }
  }

  reach
}

// ============================================================================
// MINIMAX / MAXIMIN PATH
// ============================================================================

///|
/// Find path that minimizes maximum edge weight (widest path variant)
fn minimax_path(weights : Array[Array[Int64]]) -> Array[Array[Int64]] {
  let n = weights.length()
  let result = Array::make(n, [])
  for i = 0; i < n; i = i + 1 {
    result[i] = Array::make(n, FW_INF)
    for j = 0; j < n; j = j + 1 {
      result[i][j] = weights[i][j]
    }
    result[i][i] = 0L
  }

  for k = 0; k < n; k = k + 1 {
    for i = 0; i < n; i = i + 1 {
      for j = 0; j < n; j = j + 1 {
        // Max edge on path through k
        let through_k = if result[i][k] > result[k][j] {
          result[i][k]
        } else {
          result[k][j]
        }
        // Take path with smaller max edge
        if through_k < result[i][j] {
          result[i][j] = through_k
        }
      }
    }
  }

  result
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "floyd_warshall basic" {
  let fw = FloydWarshall::new(4)
  fw.add_edge(0, 1, 3L)
  fw.add_edge(0, 2, 6L)
  fw.add_edge(1, 2, 2L)
  fw.add_edge(2, 3, 1L)
  fw.add_edge(1, 3, 5L)

  fw.compute()

  inspect(fw.get_dist(0, 3), content="6") // 0->1->2->3 = 3+2+1
  inspect(fw.get_dist(0, 2), content="5") // 0->1->2 = 3+2
  inspect(fw.get_dist(1, 3), content="3") // 1->2->3 = 2+1
}

///|
test "floyd_warshall path reconstruction" {
  let fw = FloydWarshall::new(4)
  fw.add_edge(0, 1, 1L)
  fw.add_edge(1, 2, 1L)
  fw.add_edge(2, 3, 1L)

  fw.compute()

  let path = fw.get_path(0, 3)
  inspect(path.length(), content="4")
  inspect(path[0], content="0")
  inspect(path[1], content="1")
  inspect(path[2], content="2")
  inspect(path[3], content="3")
}

///|
test "floyd_warshall no path" {
  let fw = FloydWarshall::new(3)
  fw.add_edge(0, 1, 1L)
  // No edge to vertex 2

  fw.compute()

  inspect(fw.has_path(0, 2), content="false")
  inspect(fw.has_path(0, 1), content="true")
}

///|
test "floyd_warshall undirected" {
  let fw = FloydWarshall::new(3)
  fw.add_undirected_edge(0, 1, 2L)
  fw.add_undirected_edge(1, 2, 3L)

  fw.compute()

  inspect(fw.get_dist(0, 2), content="5")
  inspect(fw.get_dist(2, 0), content="5")
}

///|
test "floyd_warshall diameter" {
  let fw = FloydWarshall::new(4)
  fw.add_undirected_edge(0, 1, 1L)
  fw.add_undirected_edge(1, 2, 2L)
  fw.add_undirected_edge(2, 3, 3L)

  fw.compute()

  inspect(fw.diameter(), content="6") // 0 to 3
}

///|
test "transitive_closure" {
  let adj : Array[Array[Bool]] = [
    [false, true, false],
    [false, false, true],
    [false, false, false],
  ]
  let reach = transitive_closure(adj)

  inspect(reach[0][0], content="true") // Self
  inspect(reach[0][1], content="true") // Direct
  inspect(reach[0][2], content="true") // Through 1
  inspect(reach[2][0], content="false") // No path back
}

///|
test "minimax_path" {
  // Graph where direct path has high edge, but indirect has lower max
  let weights : Array[Array[Int64]] = [
    [0L, 10L, 2L],
    [10L, 0L, 3L],
    [2L, 3L, 0L],
  ]
  let result = minimax_path(weights)

  // 0->1 direct is 10, but 0->2->1 has max edge 3
  inspect(result[0][1], content="3")
}

///|
test "floyd_warshall negative weights" {
  let fw = FloydWarshall::new(3)
  fw.add_edge(0, 1, 4L)
  fw.add_edge(0, 2, 5L)
  fw.add_edge(1, 2, -3L) // Negative edge

  fw.compute()

  inspect(fw.get_dist(0, 2), content="1") // 0->1->2 = 4 + (-3) = 1
  inspect(fw.has_negative_cycle(), content="false")
}

///|
test "floyd_warshall self loop" {
  let fw = FloydWarshall::new(2)
  fw.add_edge(0, 1, 1L)
  fw.add_edge(1, 0, 1L)

  fw.compute()

  inspect(fw.get_dist(0, 0), content="0")
  inspect(fw.get_dist(0, 1), content="1")
  inspect(fw.get_dist(1, 0), content="1")
}
