///|
/// More Graph Algorithms
///
/// This file demonstrates additional graph algorithms with loop invariants,
/// including shortest path algorithms and cycle detection variants.

///|
/// Bellman-Ford Algorithm - Single Source Shortest Path with negative edges
///
/// MATHEMATICAL FOUNDATION:
/// Unlike Dijkstra, Bellman-Ford can handle negative edge weights.
/// After k iterations, dist[v] is the shortest path using at most k edges.
///
/// INVARIANT: After iteration i, dist[v] <= shortest path to v using at most i edges.
fn bellman_ford_with_neg_cycle(
  n : Int,
  edges : ArrayView[(Int, Int, Int)], // (from, to, weight)
  source : Int,
) -> (Array[Int], Bool) {
  // Bool indicates if negative cycle exists
  let inf = 2147483647
  let dist = Array::make(n, inf)
  dist[source] = 0

  // Relax all edges n-1 times
  for i = 0; i < n - 1; i = i + 1 {
    let mut changed = false
    for e = 0; e < edges.length(); e = e + 1 {
      let (u, v, w) = edges[e]
      if dist[u] != inf && dist[u] + w < dist[v] {
        dist[v] = dist[u] + w
        changed = true
      }
    } where {
      invariant: e >= 0 && e <= edges.length(),
      reasoning: (
        #|INVARIANT (Relaxation scan):
        #|After processing edges[0..e), dist reflects the shortest distances
        #|obtainable using at most i+1 edges whose last edge appears in this
        #|prefix. Any improvement sets changed = true for early termination.
      ),
    }
    // Early termination if no changes
    if not(changed) {
      break
    }
  } where {
    invariant: i >= 0 && i <= n - 1,
    reasoning: (
      #|LOOP INVARIANT: dist[v] <= shortest path to v using at most i+1 edges
      #|
      #|BASE CASE (i = 0): dist[source] = 0, others = inf
      #|  After first iteration, dist[v] = weight of direct edge from source (if exists)
      #|
      #|INDUCTIVE STEP:
      #|  If shortest path to u uses k edges, and (u,v,w) is an edge,
      #|  then path to v via u uses k+1 edges.
      #|  Relaxation ensures we find this path in iteration k+1.
      #|
      #|TERMINATION: Any shortest path uses at most n-1 edges (no cycles),
      #|  so n-1 iterations suffice.
    ),
  }

  // Check for negative cycles - one more iteration
  let mut has_negative_cycle = false
  for e = 0; e < edges.length(); e = e + 1 {
    let (u, v, w) = edges[e]
    if dist[u] != inf && dist[u] + w < dist[v] {
      has_negative_cycle = true
      break
    }
  } where {
    invariant: e >= 0 && e <= edges.length(),
    reasoning: (
      #|INVARIANT (Negative-cycle check):
      #|After scanning edges[0..e), no edge in this prefix can further relax
      #|dist. If any relaxable edge exists after n-1 passes, then some path
      #|can be improved indefinitely, implying a reachable negative cycle.
    ),
  }
  (dist, has_negative_cycle)
}

///|
test "bellman ford" {
  // Graph: 0 -> 1 (4), 0 -> 2 (5), 1 -> 2 (-3), 2 -> 3 (4)
  let edges = [(0, 1, 4), (0, 2, 5), (1, 2, -3), (2, 3, 4)]
  let (dist, has_neg) = bellman_ford_with_neg_cycle(4, edges[:], 0)
  assert_eq(has_neg, false)
  assert_eq(dist[0], 0)
  assert_eq(dist[1], 4)
  assert_eq(dist[2], 1) // 0 -> 1 -> 2 = 4 + (-3) = 1
  assert_eq(dist[3], 5) // 0 -> 1 -> 2 -> 3 = 1 + 4 = 5
}

///|
test "bellman ford negative cycle" {
  // Graph with negative cycle: 0 -> 1 (1), 1 -> 2 (1), 2 -> 0 (-3)
  let edges = [(0, 1, 1), (1, 2, 1), (2, 0, -3)]
  let (_, has_neg) = bellman_ford_with_neg_cycle(3, edges[:], 0)
  assert_eq(has_neg, true)
}

///|
/// Floyd-Warshall Algorithm - All Pairs Shortest Path
///
/// MATHEMATICAL FOUNDATION:
/// dp[k][i][j] = shortest path from i to j using only vertices {0, ..., k-1} as intermediates
///
/// Recurrence: dp[k][i][j] = min(dp[k-1][i][j], dp[k-1][i][k] + dp[k-1][k][j])
///
/// INVARIANT: After processing vertex k, dist[i][j] is the shortest path
/// using only vertices {0, ..., k} as intermediate nodes.
fn floyd_warshall_all_pairs(adj : Array[Array[Int]]) -> Array[Array[Int]] {
  let n = adj.length()
  let inf = 2147483647 / 2 // Avoid overflow

  // Initialize distance matrix
  let dist : Array[Array[Int]] = []
  for i = 0; i < n; i = i + 1 {
    let row = Array::make(n, inf)
    row[i] = 0
    for j = 0; j < n; j = j + 1 {
      if adj[i][j] != 0 || i == j {
        row[j] = adj[i][j]
      }
    } where {
      invariant: j >= 0 && j <= n,
      reasoning: (
        #|INVARIANT (init row):
        #|row[0..j) reflects direct edge weights from adj[i][0..j).
        #|MAINTENANCE:
        #|Copy adj[i][j] (or 0 for diagonal) into row[j].
        #|TERMINATION:
        #|At j = n, row i is fully initialized.
      ),
    }
    dist.push(row)
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (init dist):
      #|dist[0..i) contains direct-edge distances for rows already built.
      #|MAINTENANCE:
      #|Create and push the initialized row for index i.
      #|TERMINATION:
      #|At i = n, all rows are initialized.
    ),
  }

  // Main algorithm: consider each vertex as intermediate
  for k = 0; k < n; k = k + 1 {
    for i = 0; i < n; i = i + 1 {
      for j = 0; j < n; j = j + 1 {
        if dist[i][k] + dist[k][j] < dist[i][j] {
          dist[i][j] = dist[i][k] + dist[k][j]
        }
      } where {
        invariant: j >= 0 && j <= n,
        reasoning: (
          #|INVARIANT (Inner update):
          #|After processing columns [0..j), dist[i][t] is the shortest path
          #|from i to t using intermediate vertices from {0..k}. Each step
          #|applies the transition dist[i][t] = min(dist[i][t], dist[i][k] +
          #|dist[k][t]) for the current t.
        ),
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (Row completion):
        #|After processing rows [0..i), dist[x][*] is correct using
        #|intermediates from {0..k} for all x < i.
      ),
    }
  } where {
    invariant: k >= 0 && k <= n,
    reasoning: (
      #|LOOP INVARIANT: dist[i][j] = shortest path from i to j using
      #|only vertices {0, ..., k-1} as intermediate nodes.
      #|
      #|BASE CASE (k = 0): dist[i][j] = direct edge weight (or inf)
      #|
      #|INDUCTIVE STEP:
      #|  For intermediate vertex k, either:
      #|  1. Shortest path doesn't use k: dist remains same
      #|  2. Shortest path uses k: dist[i][j] = dist[i][k] + dist[k][j]
      #|  We take the minimum.
      #|
      #|TERMINATION: After all vertices, dist[i][j] = true shortest path.
    ),
  }
  dist
}

///|
test "floyd warshall" {
  // Graph: 0 -> 1 (3), 0 -> 3 (7), 1 -> 0 (8), 1 -> 2 (2)
  //        2 -> 0 (5), 2 -> 3 (1), 3 -> 0 (2)
  let inf = 2147483647 / 2
  let adj = [[0, 3, inf, 7], [8, 0, 2, inf], [5, inf, 0, 1], [2, inf, inf, 0]]
  let dist = floyd_warshall_all_pairs(adj)
  assert_eq(dist[0][0], 0)
  assert_eq(dist[0][1], 3)
  assert_eq(dist[0][2], 5) // 0 -> 1 -> 2
  assert_eq(dist[0][3], 6) // 0 -> 1 -> 2 -> 3
  assert_eq(dist[3][1], 5) // 3 -> 0 -> 1
}

///|
/// Kahn's Algorithm for Topological Sort (BFS-based)
///
/// INVARIANT: Vertices with in-degree 0 have no remaining predecessors,
/// so they can be safely added to the topological order.
fn topological_sort_kahn(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Int]? {
  // Calculate in-degrees
  let in_degree = Array::make(n, 0)
  let adj : Array[Array[Int]] = []
  for _ in 0..<n {
    adj.push([])
  }
  for e = 0; e < edges.length(); e = e + 1 {
    let (u, v) = edges[e]
    adj[u].push(v)
    in_degree[v] = in_degree[v] + 1
  } where {
    invariant: e >= 0 && e <= edges.length(),
    reasoning: (
      #|INVARIANT (Edge ingestion):
      #|After processing edges[0..e), adj contains exactly those edges,
      #|and in_degree[v] equals the number of incoming edges to v from
      #|that prefix. This initializes the dependency counts for Kahn's queue.
    ),
  }

  // Queue of vertices with in-degree 0
  let queue : Array[Int] = []
  for i in 0..<n {
    if in_degree[i] == 0 {
      queue.push(i)
    }
  }
  let result : Array[Int] = []
  for front = 0; front < queue.length(); {
    let u = queue[front]
    result.push(u)

    // Reduce in-degree of neighbors
    for i = 0; i < adj[u].length(); i = i + 1 {
      let v = adj[u][i]
      in_degree[v] = in_degree[v] - 1
      if in_degree[v] == 0 {
        queue.push(v)
      }
    } where {
      invariant: i >= 0 && i <= adj[u].length(),
      reasoning: (
        #|INVARIANT (Neighbor updates):
        #|After processing adj[u][0..i), all edges u→v in this prefix have been
        #|"removed" by decrementing in_degree[v]. Any v that drops to 0 is now
        #|ready to be processed and is enqueued.
      ),
    }
    continue front + 1
  } else {
    if result.length() == n {
      Some(result)
    } else {
      None
    }
  } where {
    invariant: front >= 0 && front <= queue.length(),
    reasoning: (
      #|LOOP INVARIANT:
      #|  - result contains vertices in valid topological order
      #|  - All vertices in result have been "removed" from the graph
      #|  - in_degree[v] = remaining predecessors not yet in result
      #|  - queue contains vertices with in_degree = 0
      #|
      #|When a vertex enters the queue, all its predecessors are in result,
      #|so it can safely be next in the topological order.
      #|
      #|TERMINATION: If result.length() < n, there's a cycle.
    ),
  }
}

///|
test "topological sort kahn" {
  // DAG: 0 -> 1, 0 -> 2, 1 -> 3, 2 -> 3
  let edges = [(0, 1), (0, 2), (1, 3), (2, 3)]
  let result = topological_sort_kahn(4, edges[:])
  assert_true(result is Some(_))
}

///|
/// Bipartite Check using BFS Coloring
///
/// INVARIANT: Vertices at even BFS levels get color 0, odd levels get color 1.
/// Graph is bipartite iff no edge connects same-colored vertices.
fn is_bipartite(n : Int, adj : Array[Array[Int]]) -> Bool {
  let color = Array::make(n, -1) // -1 = unvisited

  // Check each component
  for start = 0; start < n; start = start + 1 {
    if color[start] == -1 {
      // BFS from this vertex
      let queue : Array[Int] = [start]
      color[start] = 0
      for front = 0; front < queue.length(); {
        let u = queue[front]
        for i = 0; i < adj[u].length(); i = i + 1 {
          let v = adj[u][i]
          if color[v] == -1 {
            color[v] = 1 - color[u]
            queue.push(v)
          } else if color[v] == color[u] {
            return false // Same color = odd cycle = not bipartite
          }
        } where {
          invariant: i >= 0 && i <= adj[u].length(),
          reasoning: (
            #|INVARIANT (Coloring):
            #|After processing adj[u][0..i), every neighbor examined either
            #|receives the opposite color (if unvisited) or is confirmed to
            #|have a compatible color. Any same-color edge immediately
            #|detects an odd cycle and returns false.
          ),
        }
        continue front + 1
      } where {
        invariant: front >= 0 && front <= queue.length(),
        reasoning: (
          #|INVARIANT (BFS levels):
          #|Vertices in queue[0..front) have been expanded, and their neighbors
          #|are colored with the opposite color. This enforces a 2-coloring
          #|consistent with BFS levels; any violation implies an odd cycle.
        ),
      }
    }
  } where {
    invariant: start >= 0 && start <= n,
    reasoning: (
      #|INVARIANT (Component scan):
      #|All vertices in [0, start) belong to components already checked and
      #|found bipartite. Each new start launches BFS for an unvisited component.
    ),
  }
  true
}

///|
test "bipartite" {
  // Bipartite graph: 0 -- 1, 0 -- 3, 1 -- 2, 2 -- 3
  let adj = [[1, 3], [0, 2], [1, 3], [0, 2]]
  assert_eq(is_bipartite(4, adj), true)

  // Non-bipartite: triangle 0 -- 1 -- 2 -- 0
  let adj2 = [[1, 2], [0, 2], [0, 1]]
  assert_eq(is_bipartite(3, adj2), false)
}

///|
/// Cycle Detection in Directed Graph using DFS
///
/// Uses three states: WHITE (unvisited), GRAY (in current path), BLACK (finished)
/// A cycle exists iff we encounter a GRAY vertex during DFS.
fn has_cycle_directed(n : Int, adj : Array[Array[Int]]) -> Bool {
  let white = 0
  let gray = 1
  let black = 2
  let state = Array::make(n, white)
  for start = 0; start < n; start = start + 1 {
    if state[start] == white {
      if dfs_has_cycle(adj, state, start, gray, black) {
        return true
      }
    }
  } where {
    invariant: start >= 0 && start <= n,
    reasoning: (
      #|INVARIANT (DFS forest):
      #|All vertices in [0, start) have been considered; any BLACK vertex is
      #|fully explored with no back edges found. If a cycle exists in those
      #|components, we would have returned true already.
    ),
  }
  false
}

///|
fn dfs_has_cycle(
  adj : Array[Array[Int]],
  state : Array[Int],
  u : Int,
  gray : Int,
  black : Int,
) -> Bool {
  state[u] = gray // Mark as in-progress
  for i = 0; i < adj[u].length(); i = i + 1 {
    let v = adj[u][i]
    if state[v] == gray {
      return true // Back edge = cycle
    }
    if state[v] == 0 && dfs_has_cycle(adj, state, v, gray, black) {
      return true
    }
  } where {
    invariant: i >= 0 && i <= adj[u].length(),
    reasoning: (
      #|INVARIANT (DFS edge scan):
      #|After processing neighbors[0..i), all DFS tree edges in this prefix
      #|have been explored. Encountering a GRAY vertex indicates a back edge
      #|to the current recursion stack, which is exactly a directed cycle.
    ),
  }
  state[u] = black // Mark as finished
  false
}

///|
test "cycle detection directed" {
  // Acyclic: 0 -> 1 -> 2
  let adj = [[1], [2], []]
  assert_eq(has_cycle_directed(3, adj), false)

  // Cyclic: 0 -> 1 -> 2 -> 0
  let adj2 = [[1], [2], [0]]
  assert_eq(has_cycle_directed(3, adj2), true)
}

///|
/// Strongly Connected Components Count using Kosaraju's
///
/// Two DFS passes:
/// 1. First DFS on original graph to get finish order
/// 2. Second DFS on reverse graph in reverse finish order
fn count_sccs(n : Int, adj : Array[Array[Int]]) -> Int {
  // First pass: get finish order
  let visited = Array::make(n, false)
  let order : Array[Int] = []
  for i = 0; i < n; i = i + 1 {
    if not(visited[i]) {
      dfs_order(adj, visited, order, i)
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (Finish order):
      #|All vertices in [0..i) have been considered as DFS roots. Any vertex
      #|reachable from those roots is marked visited, and appears in order
      #|after all of its descendants (post-order).
    ),
  }

  // Build reverse graph
  let rev_adj : Array[Array[Int]] = []
  for _ in 0..<n {
    rev_adj.push([])
  }
  for u = 0; u < n; u = u + 1 {
    for i = 0; i < adj[u].length(); i = i + 1 {
      rev_adj[adj[u][i]].push(u)
    } where {
      invariant: i >= 0 && i <= adj[u].length(),
      reasoning: (
        #|INVARIANT (Edge reversal):
        #|After processing adj[u][0..i), all edges u→v in this prefix have been
        #|reversed into rev_adj[v], so rev_adj holds the transpose graph.
      ),
    }
  } where {
    invariant: u >= 0 && u <= n,
    reasoning: (
      #|INVARIANT (Transpose build):
      #|After processing vertices [0..u), all outgoing edges from those vertices
      #|have been reversed into rev_adj.
    ),
  }

  // Second pass: count SCCs
  let visited2 = Array::make(n, false)
  let mut scc_count = 0
  for i = n - 1; i >= 0; i = i - 1 {
    let v = order[i]
    if not(visited2[v]) {
      dfs_mark(rev_adj, visited2, v)
      scc_count = scc_count + 1
    }
  } where {
    invariant: i >= -1 && i < n,
    reasoning: (
      #|INVARIANT (Reverse finish order):
      #|Vertices in order[i+1..] have already been assigned to exactly one SCC.
      #|Processing order[i] in the reversed graph discovers precisely its SCC,
      #|because any edge to a different SCC would go to a vertex already marked.
    ),
  }
  scc_count
}

///|
fn dfs_order(
  adj : Array[Array[Int]],
  visited : Array[Bool],
  order : Array[Int],
  u : Int,
) -> Unit {
  visited[u] = true
  for i = 0; i < adj[u].length(); i = i + 1 {
    let v = adj[u][i]
    if not(visited[v]) {
      dfs_order(adj, visited, order, v)
    }
  } where {
    invariant: i >= 0 && i <= adj[u].length(),
    reasoning: (
      #|INVARIANT (DFS1):
      #|After processing neighbors[0..i), all vertices reachable from u through
      #|those neighbors are visited and appended to order after their descendants.
    ),
  }
  order.push(u)
}

///|
fn dfs_mark(adj : Array[Array[Int]], visited : Array[Bool], u : Int) -> Unit {
  visited[u] = true
  for i = 0; i < adj[u].length(); i = i + 1 {
    let v = adj[u][i]
    if not(visited[v]) {
      dfs_mark(adj, visited, v)
    }
  } where {
    invariant: i >= 0 && i <= adj[u].length(),
    reasoning: (
      #|INVARIANT (DFS2):
      #|After processing neighbors[0..i), all vertices reachable from u via
      #|those edges are marked visited and belong to the same SCC.
    ),
  }
}

///|
test "count sccs" {
  // Graph with 3 SCCs: {0,1,2}, {3}, {4}
  // 0 <-> 1, 1 -> 2, 2 -> 0, 2 -> 3, 3 -> 4
  let adj = [[1], [0, 2], [0, 3], [4], []]
  assert_eq(count_sccs(5, adj), 3)
}

///|
/// Minimum Spanning Tree - Prim's Algorithm
///
/// INVARIANT: At each step, we add the minimum-weight edge connecting
/// the MST to a non-MST vertex.
fn prim_mst(n : Int, adj : Array[Array[(Int, Int)]]) -> Int {
  // adj[u] contains (v, weight) pairs
  if n == 0 {
    return 0
  }
  let inf = 2147483647
  let in_mst = Array::make(n, false)
  let key = Array::make(n, inf) // Minimum edge weight to connect to MST
  key[0] = 0
  let mut total_weight = 0
  for count = 0; count < n; count = count + 1 {
    // Find minimum key vertex not in MST
    let mut min_key = inf
    let mut u = -1
    for v = 0; v < n; v = v + 1 {
      if not(in_mst[v]) && key[v] < min_key {
        min_key = key[v]
        u = v
      }
    } where {
      invariant: v >= 0 && v <= n,
      reasoning: (
        #|INVARIANT (Extract-min):
        #|After scanning vertices [0..v), min_key/u holds the smallest key
        #|among those not yet in the MST. This selects the safest next vertex
        #|by the cut property.
      ),
    }
    if u == -1 {
      break // Disconnected graph
    }
    in_mst[u] = true
    total_weight = total_weight + key[u]

    // Update keys of adjacent vertices
    for i = 0; i < adj[u].length(); i = i + 1 {
      let (v, weight) = adj[u][i]
      if not(in_mst[v]) && weight < key[v] {
        key[v] = weight
      }
    } where {
      invariant: i >= 0 && i <= adj[u].length(),
      reasoning: (
        #|INVARIANT (Key updates):
        #|After processing adj[u][0..i), key[v] stores the minimum edge weight
        #|connecting v to the current MST for every neighbor seen so far.
      ),
    }
  } where {
    invariant: count >= 0 && count <= n,
    reasoning: (
      #|LOOP INVARIANT:
      #|  - in_mst marks vertices in current MST
      #|  - key[v] = minimum edge weight connecting v to MST (for v not in MST)
      #|  - total_weight = sum of MST edges so far
      #|
      #|CORRECTNESS: Always adding the minimum safe edge ensures MST property.
      #|This is the cut property: minimum edge crossing any cut is in some MST.
    ),
  }
  total_weight
}

///|
test "prim mst" {
  // Graph: 0 -- 1 (4), 0 -- 7 (8), 1 -- 2 (8), 1 -- 7 (11)
  //        2 -- 3 (7), 2 -- 8 (2), 2 -- 5 (4), 3 -- 4 (9)
  //        3 -- 5 (14), 4 -- 5 (10), 5 -- 6 (2), 6 -- 7 (1)
  //        6 -- 8 (6), 7 -- 8 (7)
  let adj : Array[Array[(Int, Int)]] = [
    [(1, 4), (7, 8)], // 0
    [(0, 4), (2, 8), (7, 11)], // 1
    [(1, 8), (3, 7), (5, 4), (8, 2)], // 2
    [(2, 7), (4, 9), (5, 14)], // 3
    [(3, 9), (5, 10)], // 4
    [(2, 4), (3, 14), (4, 10), (6, 2)], // 5
    [(5, 2), (7, 1), (8, 6)], // 6
    [(0, 8), (1, 11), (6, 1), (8, 7)], // 7
    [(2, 2), (6, 6), (7, 7)], // 8
  ]
  // MST weight = 4 + 8 + 2 + 4 + 2 + 1 + 7 + 9 = 37
  assert_eq(prim_mst(9, adj), 37)
}

///|
/// Kruskal's MST Algorithm
///
/// Sort edges by weight, add each edge if it doesn't create a cycle.
/// Uses Union-Find for cycle detection.
fn kruskal_mst(n : Int, edges : Array[(Int, Int, Int)]) -> Int {
  // Sort edges by weight - use insertion sort for simplicity
  let sorted_edges = edges.copy()
  // Simple bubble sort since sort_by_key may not work with tuples
  for i = 0; i < sorted_edges.length(); i = i + 1 {
    for j = i + 1; j < sorted_edges.length(); j = j + 1 {
      let (_, _, w1) = sorted_edges[i]
      let (_, _, w2) = sorted_edges[j]
      if w2 < w1 {
        let temp = sorted_edges[i]
        sorted_edges[i] = sorted_edges[j]
        sorted_edges[j] = temp
      }
    } where {
      invariant: j >= i + 1 && j <= sorted_edges.length(),
      reasoning: (
        #|INVARIANT (Selection in bubble sort):
        #|After scanning indices [i+1..j), sorted_edges[i] holds the smallest
        #|weight edge among sorted_edges[i..j) seen so far.
      ),
    }
  } where {
    invariant: i >= 0 && i <= sorted_edges.length(),
    reasoning: (
      #|INVARIANT (Sorted prefix):
      #|After iteration i, sorted_edges[0..i) contains the i smallest edges in
      #|non-decreasing order. The remaining suffix is unsorted.
    ),
  }

  // Union-Find
  let parent = Array::make(n, 0)
  let rank = Array::make(n, 0)
  for i in 0..<n {
    parent[i] = i
  }
  let mut total_weight = 0
  let mut edges_added = 0
  for i = 0; i < sorted_edges.length() && edges_added < n - 1; {
    let (u, v, w) = sorted_edges[i]
    let root_u = find_root(parent, u)
    let root_v = find_root(parent, v)
    if root_u != root_v {
      // Union
      if rank[root_u] < rank[root_v] {
        parent[root_u] = root_v
      } else if rank[root_u] > rank[root_v] {
        parent[root_v] = root_u
      } else {
        parent[root_v] = root_u
        rank[root_u] = rank[root_u] + 1
      }
      total_weight = total_weight + w
      edges_added = edges_added + 1
      continue i + 1
    } else {
      continue i + 1
    }
  } else {
    total_weight
  } where {
    invariant: i >= 0 && edges_added >= 0 && edges_added <= n - 1,
    reasoning: (
      #|LOOP INVARIANT:
      #|  - Edges added form a forest (no cycles)
      #|  - total_weight = sum of edge weights in forest
      #|  - Edges are considered in sorted order
      #|
      #|CORRECTNESS: By cut property, minimum edge connecting two components
      #|is always safe to add. Since we process in sorted order, we always
      #|add the minimum safe edge.
    ),
  }
}

///|
fn find_root(parent : Array[Int], x : Int) -> Int {
  for p = x; parent[p] != p; {
    // Path compression
    parent[p] = parent[parent[p]]
    continue parent[p]
  } else {
    p
  } where {
    invariant: p >= 0 && p < parent.length(),
    reasoning: (
      #|INVARIANT (find root):
      #|p is always a valid index on the path from x to its root.
      #|MAINTENANCE:
      #|Compress by skipping a parent level, shortening the path.
      #|TERMINATION:
      #|When parent[p] == p, p is the root.
    ),
  }
}

///|
test "kruskal mst" {
  // Same graph as Prim test
  let edges = [
    (0, 1, 4),
    (0, 7, 8),
    (1, 2, 8),
    (1, 7, 11),
    (2, 3, 7),
    (2, 5, 4),
    (2, 8, 2),
    (3, 4, 9),
    (3, 5, 14),
    (4, 5, 10),
    (5, 6, 2),
    (6, 7, 1),
    (6, 8, 6),
    (7, 8, 7),
  ]
  assert_eq(kruskal_mst(9, edges), 37)
}
