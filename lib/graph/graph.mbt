// ============================================================================
// Graph Algorithm Examples
// Deep invariant reasoning for fundamental graph algorithms
// ============================================================================

// ============================================================================
// Example G1: Topological Sort (Kahn's Algorithm)
// Order vertices so that all edges go from earlier to later vertices
// ============================================================================

///|
/// Compute in-degrees for all vertices.
fn compute_in_degrees(graph : Array[Array[Int]]) -> Array[Int] {
  let n = graph.length()
  let in_degree : Array[Int] = Array::make(n, 0)
  for u in 0..<n {
    for neighbor in graph[u] {
      in_degree[neighbor] = in_degree[neighbor] + 1
    }
  }
  in_degree
}

///|
/// Topological sort using Kahn's algorithm (BFS-based).
/// Returns Some(ordering) if graph is DAG, None if cycle exists.
#warnings("+missing_invariant+missing_reasoning")
fn topological_sort(graph : Array[Array[Int]]) -> Array[Int]? {
  let n = graph.length()
  let in_degree = compute_in_degrees(graph)
  let result : Array[Int] = []

  // Initialize queue with all vertices having in-degree 0
  let queue : Array[Int] = [ for v in 0..<n if in_degree[v] == 0 => v ]

  // Process vertices in topological order
  for head = 0 {
    if head >= queue.length() {
      break
    } else {
      let u = queue[head]
      result.push(u)

      // "Remove" u by decrementing in-degrees of its neighbors
      for neighbor in graph[u] {
        in_degree[neighbor] = in_degree[neighbor] - 1
        if in_degree[neighbor] == 0 {
          queue.push(neighbor)
        }
      }
      continue head + 1
    }
  } where {
    proof_invariant: head >= 0 && head <= queue.length(),
    proof_reasoning: (
      #|INVARIANT 1 (Queue processing):
      #|head points at the next vertex to process. All vertices in queue[0..head)
      #|have been removed and appended to result, while queue[head..] contains
      #|vertices discovered with in-degree 0 but not yet processed.
      #|MAINTENANCE:
      #|We process queue[head], append it to result, and enqueue any neighbor
      #|whose in-degree drops to 0. Incrementing head preserves the split
      #|between processed and discovered-but-unprocessed vertices.
      #|TERMINATION:
      #|When head reaches queue.length(), every discovered zero-in-degree
      #|vertex has been processed and no further work remains.
    ),
    proof_invariant: result.length() == head,
    proof_reasoning: (
      #|INVARIANT 2 (Progress):
      #|result mirrors the processed prefix of the queue, so result.length()
      #|tracks how many vertices have been popped and fixed in order.
      #|MAINTENANCE:
      #|Each iteration appends exactly one vertex (queue[head]) and then
      #|increments head, preserving result.length() == head.
      #|TERMINATION:
      #|At loop exit, result length equals the number of processed vertices.
    ),
    proof_invariant: head >= 0,
    proof_reasoning: (
      #|INVARIANT 3 (Topological property):
      #|For all u in result[0..head), all edges u→v have been "removed"
      #|(v's in-degree decremented). Moreover, result is a valid partial
      #|topological ordering of the vertices processed so far.
      #|
      #|MAINTENANCE:
      #|KEY INSIGHT (Kahn's Algorithm):
      #|A vertex can be added to the topological order iff its in-degree is 0,
      #|meaning all its predecessors have already been processed.
      #|
      #|Base: Initially, vertices with in-degree 0 have no predecessors,
      #|so they can appear first in any topological order. ✓
      #|
      #|Inductive: When we process vertex u:
      #|  - All u's predecessors have in-degree 0 at some earlier point
      #|  - Thus all predecessors are already in result
      #|  - Adding u maintains topological order ✓
      #|
      #|  After processing u, we decrement in-degrees of u's successors.
      #|  Any successor v whose in-degree becomes 0 has had ALL its
      #|  predecessors processed, so v can now be added to queue.
      #|
      #|TERMINATION:
      #|CYCLE DETECTION:
      #|If a cycle exists, vertices in the cycle never reach in-degree 0.
      #|They're waiting for predecessors that are also waiting for them.
      #|At termination, result.length() < n indicates a cycle.
      #|
      #|CORRECTNESS:
      #|result is a topological order iff every edge u→v has u before v.
      #|Since we only add v to queue after u is processed and decrements
      #|v's in-degree, u appears in result before v. ✓
    ),
  }
  if result.length() == n {
    Some(result)
  } else {
    None // Cycle detected
  }
}

///|
test "topological_sort" {
  // DAG: 0 → 1 → 2, 0 → 2
  let dag : Array[Array[Int]] = [
    [1, 2], // 0's neighbors
    [2], // 1's neighbors
    [],
  ] // 2's neighbors
  match topological_sort(dag) {
    Some(order) => {
      assert_eq(order.length(), 3)
      // 0 must come before 1 and 2, 1 must come before 2
      let pos : Array[Int] = Array::make(3, 0)
      for i, v in order {
        pos[v] = i
      }
      assert_true(pos[0] < pos[1])
      assert_true(pos[0] < pos[2])
      assert_true(pos[1] < pos[2])
    }
    None => assert_true(false)
  }

  // Graph with cycle: 0 → 1 → 2 → 0
  let cyclic : Array[Array[Int]] = [[1], [2], [0]]
  assert_eq(topological_sort(cyclic), None)
}

// ============================================================================
// Example G2: Dijkstra's Algorithm (Single-Source Shortest Paths)
// Find shortest paths from source to all vertices in weighted graph
// ============================================================================

///|
/// Dijkstra's algorithm with simple array-based priority "queue".
/// graph[u] = list of (neighbor, weight) pairs
/// Returns array of shortest distances from source to each vertex.
#warnings("+missing_invariant+missing_reasoning")
fn dijkstra(graph : Array[Array[(Int, Int)]], source : Int) -> Array[Int] {
  let n = graph.length()
  let inf = 0x7FFFFFFF
  let dist : Array[Int] = Array::make(n, inf)
  let visited : Array[Bool] = Array::make(n, false)
  dist[source] = 0

  // Process n vertices
  for count = 0 {
    if count >= n {
      break dist
    } else {
      // Find unvisited vertex with minimum distance
      let u = for i = 0, min_dist = inf, min_vertex = -1 {
        if i >= n {
          break min_vertex
        } else if !visited[i] && dist[i] < min_dist {
          continue i + 1, dist[i], i
        } else {
          continue i + 1, min_dist, min_vertex
        }
      } where {
        proof_invariant: i >= 0 && i <= n,
        proof_reasoning: (
          #|INVARIANT (Min scan):
          #|After scanning indices [0..i), min_vertex is the unvisited vertex
          #|with the smallest dist among those scanned, and min_dist is its
          #|distance. When i reaches n, we have the global minimum among all
          #|unvisited vertices.
          #|MAINTENANCE:
          #|At index i, if the vertex is unvisited and has a smaller distance,
          #|we update (min_dist, min_vertex); otherwise we keep the current
          #|minimum. This preserves the minimum over the scanned prefix.
          #|TERMINATION:
          #|When i == n, min_vertex is the minimum-distance unvisited vertex,
          #|or -1 if none remain.
        ),
      }
      if u == -1 {
        // All remaining vertices are unreachable
        break dist
      }
      visited[u] = true

      // Relax all edges from u
      for edge in graph[u] {
        let (v, weight) = edge
        if dist[u] + weight < dist[v] {
          dist[v] = dist[u] + weight
        }
      }
      continue count + 1
    }
  } where {
    proof_invariant: count >= 0 && count <= n,
    proof_reasoning: (
      #|INVARIANT 1 (Progress):
      #|Each iteration selects one new unvisited vertex u and marks it visited,
      #|so count equals the number of finalized vertices. If no such u exists,
      #|all remaining vertices are unreachable and the loop terminates.
      #|MAINTENANCE:
      #|Selecting the minimum unvisited u and marking it visited increments
      #|count by one, preserving the correspondence between count and visited.
      #|TERMINATION:
      #|The loop stops when count == n or when no reachable unvisited vertex
      #|remains (u == -1).
    ),
    proof_invariant: count >= 0,
    proof_reasoning: (
      #|INVARIANT 2 (Dijkstra's correctness):
      #|For all visited vertices u: dist[u] = shortest path from source to u.
      #|
      #|This is the fundamental invariant that makes Dijkstra's work.
      #|
      #|MAINTENANCE:
      #|PROOF BY INDUCTION:
      #|
      #|Base: source is the first visited vertex, dist[source] = 0. ✓
      #|
      #|Inductive step: Suppose invariant holds for all visited vertices.
      #|Let u be the unvisited vertex with minimum dist[u].
      #|
      #|Claim: dist[u] = shortest path to u.
      #|
      #|Proof by contradiction:
      #|Suppose there's a shorter path P from source to u.
      #|Let v be the first unvisited vertex on P.
      #|Let P₁ be the subpath from source to v's predecessor w.
      #|Since w is visited, dist[w] = shortest(source, w) by induction.
      #|When w was visited, we relaxed edge w→v, so:
      #|  dist[v] ≤ dist[w] + weight(w,v) = length(P₁) + weight(w,v)
      #|
      #|But P goes through v to reach u, so:
      #|  length(P) ≥ length(P₁) + weight(w,v) + weight(v...u)
      #|           ≥ dist[v] + weight(v...u)
      #|           ≥ dist[v]  (assuming non-negative weights)
      #|
      #|Since u has minimum dist among unvisited: dist[u] ≤ dist[v].
      #|So length(P) ≥ dist[v] ≥ dist[u].
      #|
      #|But we assumed P is shorter than dist[u]. Contradiction! ✓
      #|
      #|REQUIREMENT: All edge weights must be non-negative.
      #|With negative weights, a shorter path could be found later
      #|through a vertex with higher initial distance.
      #|TERMINATION:
      #|When the loop ends, all visited (and therefore reachable) vertices
      #|have their shortest distances finalized.
    ),
  }
}

///|
test "dijkstra" {
  //     1
  //  0 ──→ 1
  //  │     │
  // 4│     │2
  //  ↓     ↓
  //  2 ──→ 3
  //     1
  let graph : Array[Array[(Int, Int)]] = [
    [(1, 1), (2, 4)], // 0 → 1 (weight 1), 0 → 2 (weight 4)
    [(3, 2)], // 1 → 3 (weight 2)
    [(3, 1)], // 2 → 3 (weight 1)
    [], // 3 has no outgoing edges
  ]
  let dist = dijkstra(graph, 0)
  assert_eq(dist[0], 0) // source
  assert_eq(dist[1], 1) // 0 → 1
  assert_eq(dist[2], 4) // 0 → 2
  assert_eq(dist[3], 3) // 0 → 1 → 3
}

// ============================================================================
// Example G3: Union-Find with Path Compression and Union by Rank
// Disjoint set data structure with near-constant amortized operations
// ============================================================================

///|
/// Union-Find structure: parent[i] = parent of i, rank[i] = upper bound on height
priv struct UnionFind {
  parent : Array[Int]
  rank : Array[Int]
}

///|
fn make_union_find(n : Int) -> UnionFind {
  let parent : Array[Int] = [ for i in 0..<n => i ]
  { parent, rank: Array::make(n, 0) }
}

///|
/// Find with path compression: makes all nodes on path point to root.
fn uf_find(uf : UnionFind, x : Int) -> Int {
  if uf.parent[x] == x {
    x
  } else {
    // Path compression: make x point directly to root
    let root = uf_find(uf, uf.parent[x])
    uf.parent[x] = root
    root
  }
}

///|
/// Union by rank: attach smaller tree under root of larger tree.
fn uf_union(uf : UnionFind, x : Int, y : Int) -> Unit {
  let root_x = uf_find(uf, x)
  let root_y = uf_find(uf, y)
  if root_x == root_y {
    return // Already in same set
  }

  // Union by rank: attach smaller tree under larger
  if uf.rank[root_x] < uf.rank[root_y] {
    uf.parent[root_x] = root_y
  } else if uf.rank[root_x] > uf.rank[root_y] {
    uf.parent[root_y] = root_x
  } else {
    // Same rank: arbitrarily choose, increment rank
    uf.parent[root_y] = root_x
    uf.rank[root_x] = uf.rank[root_x] + 1
  }
}

///|
test "union_find" {
  let uf = make_union_find(5)

  // Initially, each element is its own set
  assert_eq(uf_find(uf, 0), 0)
  assert_eq(uf_find(uf, 1), 1)

  // Union 0 and 1
  uf_union(uf, 0, 1)
  assert_eq(uf_find(uf, 0), uf_find(uf, 1))

  // Union 2 and 3
  uf_union(uf, 2, 3)
  assert_eq(uf_find(uf, 2), uf_find(uf, 3))

  // Different sets
  assert_true(uf_find(uf, 0) != uf_find(uf, 2))

  // Union the two sets
  uf_union(uf, 1, 3)
  assert_eq(uf_find(uf, 0), uf_find(uf, 3))
}

// ============================================================================
// Example G4: Bellman-Ford Algorithm
// Single-source shortest paths with negative edges (detects negative cycles)
// ============================================================================

///|
/// Bellman-Ford algorithm for single-source shortest paths.
/// edges is array of (from, to, weight) tuples.
/// Works with negative edge weights, detects negative cycles.
/// Returns Some(distances) or None if negative cycle exists.
#warnings("+missing_invariant+missing_reasoning")
fn bellman_ford(
  n : Int,
  edges : ArrayView[(Int, Int, Int)],
  source : Int,
) -> Array[Int]? {
  let inf = 0x7FFFFFFF
  let dist : Array[Int] = Array::make(n, inf)
  dist[source] = 0

  // Relax all edges n-1 times
  for i in 0..<(n - 1) {
    let _ = i
    let changed = for edge in edges; changed = false {
      let (u, v, w) = edge
      if dist[u] != inf && dist[u] + w < dist[v] {
        dist[v] = dist[u] + w
        continue true
      }
      continue changed
    } nobreak {
      changed
    }
    if !changed {
      break // Early termination if no changes
    }
  } where {
    proof_invariant: i >= 0 && i <= n - 1,
    proof_reasoning: (
      #|INVARIANT (Bellman-Ford correctness):
      #|After i iterations, dist[v] ≤ shortest path using ≤ i edges.
      #|
      #|MAINTENANCE:
      #|PROOF:
      #|Base (i=0): dist[source] = 0, others = ∞.
      #|  The only 0-edge path is source→source with length 0. ✓
      #|
      #|Inductive: Suppose invariant holds after i iterations.
      #|Consider shortest path P from source to v using ≤ i+1 edges.
      #|Let u be the predecessor of v on P.
      #|Then P = P' + (u→v) where P' uses ≤ i edges.
      #|
      #|By induction: dist[u] ≤ length(P') after i iterations.
      #|When we relax edge (u,v), we set:
      #|  dist[v] = min(dist[v], dist[u] + w(u,v))
      #|          ≤ length(P') + w(u,v)
      #|          = length(P). ✓
      #|
      #|After n-1 iterations:
      #|dist[v] ≤ shortest path using ≤ n-1 edges.
      #|In a graph with n vertices, any simple path has ≤ n-1 edges.
      #|So dist[v] = shortest simple path (if no negative cycles).
      #|
      #|NEGATIVE CYCLE DETECTION:
      #|If a negative cycle is reachable from source, we can always
      #|find a shorter path by going around the cycle again.
      #|After n-1 iterations, if another relaxation succeeds,
      #|a negative cycle exists.
      #|TERMINATION:
      #|The loop stops after n-1 iterations or earlier if no changes occur;
      #|at that point all shortest paths without negative cycles are found.
    ),
  }

  // Check for negative cycles: if any edge can still be relaxed
  for edge in edges {
    let (u, v, w) = edge
    if dist[u] != inf && dist[u] + w < dist[v] {
      return None // Negative cycle detected
    }
  }
  Some(dist)
}

///|
test "bellman_ford" {
  // Graph with negative edge (no cycle):
  // 0 --1--> 1 --(-2)--> 2
  let edges : Array[(Int, Int, Int)] = [(0, 1, 1), (1, 2, -2)]
  match bellman_ford(3, edges, 0) {
    Some(dist) => {
      assert_eq(dist[0], 0)
      assert_eq(dist[1], 1)
      assert_eq(dist[2], -1) // 1 + (-2) = -1
    }
    None => assert_true(false)
  }

  // Graph with negative cycle: 0 → 1 → 2 → 0 with total weight -1
  let edges_cycle : Array[(Int, Int, Int)] = [(0, 1, 1), (1, 2, 1), (2, 0, -3)]
  assert_eq(bellman_ford(3, edges_cycle, 0), None)
}

// ============================================================================
// Example G5: Floyd-Warshall All-Pairs Shortest Paths
// Find shortest paths between all pairs of vertices
// ============================================================================

///|
/// Floyd-Warshall algorithm for all-pairs shortest paths.
/// dist[i][j] = shortest path from i to j (0x7FFFFFFF = no path).
#warnings("+missing_invariant+missing_reasoning")
fn floyd_warshall(
  n : Int,
  edges : ArrayView[(Int, Int, Int)],
) -> Array[Array[Int]] {
  let inf = 0x7FFFFFFF
  let dist : Array[Array[Int]] = [
    for i in 0..<n => {
      let row = Array::make(n, inf)
      row[i] = 0
      row
    }
  ]

  // Initialize with direct edges
  for edge in edges {
    let (u, v, w) = edge
    if w < dist[u][v] {
      dist[u][v] = w
    }
  }

  // Main DP: consider each vertex k as intermediate
  for k = 0 {
    if k >= n {
      break dist
    } else {
      for i in 0..<n {
        for j in 0..<n {
          if dist[i][k] != inf && dist[k][j] != inf {
            let through_k = dist[i][k] + dist[k][j]
            if through_k < dist[i][j] {
              dist[i][j] = through_k
            }
          }
        } where {
          proof_invariant: j >= 0 && j <= n,
          proof_reasoning: (
            #|INVARIANT (Column update):
            #|After processing columns [0..j), dist[i][c] is the shortest path
            #|from i to c using intermediates from {0..k} for all c < j.
            #|MAINTENANCE:
            #|Updating column j considers paths through k for (i, j), so the
            #|property extends to [0..j+1).
            #|TERMINATION:
            #|When j == n, row i has been fully updated for intermediate k.
          ),
        }
      } where {
        proof_invariant: i >= 0 && i <= n,
        proof_reasoning: (
          #|INVARIANT (Row update):
          #|After processing rows [0..i), every dist[r][*] with r < i has been
          #|updated to allow intermediate vertex k.
          #|MAINTENANCE:
          #|For each row i, the inner loop applies the k-based relaxation for
          #|all columns, so the processed prefix gains k as an allowed intermediate.
          #|TERMINATION:
          #|At i == n, all rows have been updated for this k.
        ),
      }
      continue k + 1
    }
  } where {
    proof_invariant: k >= 0 && k <= n,
    proof_reasoning: (
      #|INVARIANT (Floyd-Warshall DP):
      #|After processing vertices 0, 1, ..., k-1 as intermediates:
      #|dist[i][j] = shortest path from i to j using only vertices
      #|            {0, 1, ..., k-1} as intermediate nodes.
      #|
      #|MAINTENANCE:
      #|PROOF:
      #|Base (k=0): dist[i][j] = direct edge weight (or ∞).
      #|  The only path using no intermediates is a direct edge. ✓
      #|
      #|Inductive: Consider shortest path P from i to j using
      #|intermediates from {0, ..., k}.
      #|
      #|Case 1: P doesn't use vertex k.
      #|  Then P uses only {0, ..., k-1}, so by induction,
      #|  dist[i][j] (before update) already captures this. ✓
      #|
      #|Case 2: P uses vertex k.
      #|  P = P₁ + P₂ where P₁ goes i→k and P₂ goes k→j.
      #|  Neither P₁ nor P₂ uses k as intermediate (k is endpoint).
      #|  So P₁ uses only {0,...,k-1} and P₂ uses only {0,...,k-1}.
      #|  By induction: length(P₁) = dist[i][k], length(P₂) = dist[k][j].
      #|  We update: dist[i][j] = min(dist[i][j], dist[i][k] + dist[k][j]). ✓
      #|
      #|TIME: O(V³)
      #|SPACE: O(V²)
      #|
      #|ELEGANT INSIGHT:
      #|This is DP over the STRUCTURE of paths, not their length.
      #|The intermediate vertices form the subproblem decomposition.
      #|TERMINATION:
      #|When k == n, all vertices are allowed as intermediates, so dist holds
      #|the true all-pairs shortest paths.
    ),
  }
}

///|
test "floyd_warshall" {
  // Triangle: 0 --1--> 1 --2--> 2, with shortcut 0 --4--> 2
  let edges : Array[(Int, Int, Int)] = [(0, 1, 1), (1, 2, 2), (0, 2, 4)]
  let dist = floyd_warshall(3, edges)
  assert_eq(dist[0][0], 0)
  assert_eq(dist[0][1], 1)
  assert_eq(dist[0][2], 3) // 0 → 1 → 2 is shorter than 0 → 2
  assert_eq(dist[1][2], 2)
}

// ============================================================================
// Example G6: Kruskal's Minimum Spanning Tree
// Find MST using Union-Find and sorted edges
// ============================================================================

///|
/// Simple edge sorting (insertion sort for demonstration).
fn sort_edge_tuples(edges : Array[(Int, Int, Int)]) -> Unit {
  for i in 1..<edges.length() {
    let key = edges[i]
    let (_, _, key_weight) = key
    let insert_pos = for j = i - 1 {
      if j < 0 {
        break 0
      }
      let (_, _, j_weight) = edges[j]
      if j_weight > key_weight {
        edges[j + 1] = edges[j]
        continue j - 1
      } else {
        break j + 1
      }
    } where {
      proof_invariant: j >= -1 && j < i,
      proof_reasoning: (
        #|INVARIANT (Insertion scan):
        #|The subarray edges[j+1..i] contains elements from the original
        #|edges[0..i) that are strictly heavier than key_weight, shifted
        #|one position to the right. Elements in edges[0..j] remain sorted
        #|and have weight <= key_weight.
        #|MAINTENANCE:
        #|If edges[j] is heavier than key_weight, we shift it right and
        #|decrement j, preserving the partition and sorted prefix. If not,
        #|we stop because key belongs after j.
        #|TERMINATION:
        #|j decreases on each shift; the loop ends when j < 0 or
        #|edges[j] <= key_weight, so placing key at the break position keeps
        #|edges[0..i] sorted.
      ),
    }
    edges[insert_pos] = key
  } where {
    proof_invariant: i >= 1 && i <= edges.length(),
    proof_reasoning: (
      #|INVARIANT (Insertion sort):
      #|edges[0..i) is sorted by weight, and edges[i] is inserted into its
      #|correct position by shifting larger elements one step to the right.
      #|MAINTENANCE:
      #|The inner while loop finds the insertion position for edges[i] and
      #|shifts heavier elements, preserving sorted order of edges[0..i+1).
      #|TERMINATION:
      #|At i == edges.length(), the entire array is sorted.
    ),
  }
}

///|
/// Kruskal's algorithm for Minimum Spanning Tree.
/// Returns list of edges in MST and total weight.
#warnings("+missing_invariant+missing_reasoning")
fn kruskal(
  n : Int,
  edges : Array[(Int, Int, Int)],
) -> (Array[(Int, Int, Int)], Int) {
  sort_edge_tuples(edges)
  let uf = make_union_find(n)
  let mst : Array[(Int, Int, Int)] = []
  let total_weight = for i = 0, total_weight = 0 {
    if i >= edges.length() || mst.length() >= n - 1 {
      break total_weight
    } else {
      let edge = edges[i]
      let (u, v, w) = edge

      // Only add edge if it connects different components
      if uf_find(uf, u) != uf_find(uf, v) {
        uf_union(uf, u, v)
        mst.push(edge)
        continue i + 1, total_weight + w
      }
      continue i + 1, total_weight
    }
  } where {
    proof_invariant: i >= 0 && i <= edges.length() && mst.length() <= n - 1,
    proof_reasoning: (
      #|INVARIANT (Kruskal's cut property):
      #|At each step, mst contains a subset of some MST.
      #|
      #|MAINTENANCE:
      #|PROOF (Cut Property):
      #|For any cut (S, V-S) of the graph, the minimum weight edge
      #|crossing the cut is in some MST.
      #|
      #|When we add edge (u,v):
      #|  - u and v are in different components (different trees)
      #|  - (u,v) is the minimum weight edge connecting these components
      #|    (because we process edges in sorted order)
      #|  - By cut property, (u,v) is safe to add to MST
      #|
      #|CORRECTNESS:
      #|Union-Find ensures we never create a cycle:
      #|  - We only add (u,v) if find(u) ≠ find(v)
      #|  - After adding, we union them
      #|  - Future edges within same component are rejected
      #|
      #|TIME: O(E log E) for sorting + O(E α(V)) for union-find operations
      #|      ≈ O(E log E) since α(V) is nearly constant
      #|TERMINATION:
      #|The loop stops when mst has n-1 edges or edges are exhausted.
    ),
  }
  (mst, total_weight)
}

///|
test "kruskal" {
  // Graph:
  //   0 --1-- 1
  //   |       |
  //   3       2
  //   |       |
  //   2 --4-- 3
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 1),
    (1, 3, 2),
    (0, 2, 3),
    (2, 3, 4),
  ]
  let (mst, weight) = kruskal(4, edges)
  assert_eq(mst.length(), 3)
  assert_eq(weight, 6) // 1 + 2 + 3 = 6
}
