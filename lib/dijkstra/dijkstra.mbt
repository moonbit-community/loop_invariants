// ============================================================================
// DIJKSTRA'S ALGORITHM - Single Source Shortest Paths
// ============================================================================
//
// Dijkstra's algorithm finds shortest paths from a source vertex to all
// other vertices in a weighted graph with non-negative edge weights.
//
// KEY INSIGHT: Greedily selecting the unvisited vertex with minimum distance
// guarantees optimal paths because edge weights are non-negative.
//
// WHY NON-NEGATIVE WEIGHTS?
// If we have negative edges, a "settled" vertex might later find a shorter
// path through a negative edge, violating our greedy assumption.
//
// ALGORITHM:
// 1. Initialize: dist[source] = 0, dist[others] = infinity
// 2. Use priority queue (min-heap) to select next vertex
// 3. For selected vertex u, relax all edges (u, v):
//    if dist[u] + weight(u,v) < dist[v], update dist[v]
// 4. Repeat until all reachable vertices are processed
//
// RELAXATION INVARIANT:
// After processing vertex u, dist[u] is the true shortest path distance
// from source to u. This is because:
// - We always pick the unvisited vertex with minimum tentative distance
// - Any other path to u would go through an unvisited vertex with larger distance
//
// LOOP INVARIANT:
// For all settled vertices v, dist[v] = shortest path distance from source
//
// TIME COMPLEXITY: O((V + E) log V) with binary heap
// SPACE COMPLEXITY: O(V + E)

// ============================================================================
// PRIORITY QUEUE (Min-Heap for Dijkstra)
// ============================================================================

///|
/// Entry in the priority queue: (distance, vertex)
priv struct HeapEntry {
  dist : Int64
  vertex : Int
}

///|
/// Min-heap priority queue for Dijkstra's algorithm
priv struct MinHeap {
  data : Array[HeapEntry]
}

///|
fn MinHeap::new() -> MinHeap {
  { data: [] }
}

///|
fn MinHeap::push(self : MinHeap, entry : HeapEntry) -> Unit {
  self.data.push(entry)
  // Bubble up
  let mut i = self.data.length() - 1
  while i > 0 {
    let parent = (i - 1) / 2
    if self.data[i].dist < self.data[parent].dist {
      let temp = self.data[i]
      self.data[i] = self.data[parent]
      self.data[parent] = temp
      i = parent
    } else {
      break
    }
  }
}

///|
fn MinHeap::pop(self : MinHeap) -> HeapEntry? {
  let n = self.data.length()
  if n == 0 {
    return None
  }
  let result = self.data[0]
  let last = self.data[n - 1]
  let _ = self.data.pop()
  if self.data.length() > 0 {
    self.data[0] = last
    // Bubble down
    let mut i = 0
    let len = self.data.length()
    for {
      let left = 2 * i + 1
      let right = 2 * i + 2
      let mut smallest = i
      if left < len && self.data[left].dist < self.data[smallest].dist {
        smallest = left
      }
      if right < len && self.data[right].dist < self.data[smallest].dist {
        smallest = right
      }
      if smallest == i {
        break
      }
      let temp = self.data[i]
      self.data[i] = self.data[smallest]
      self.data[smallest] = temp
      i = smallest
    } where {
      invariant: i >= 0 && i < len,
      reasoning: (
        #|INVARIANT (heapify down):
        #|All indices outside the path from the root to i satisfy the heap
        #|property; i is the current candidate position for the swapped element.
        #|MAINTENANCE:
        #|Swap with the smaller child when needed to restore the min-heap order.
        #|TERMINATION:
        #|When smallest == i, the heap property holds for the entire heap.
      ),
    }
  }
  Some(result)
}

///|
fn MinHeap::is_empty(self : MinHeap) -> Bool {
  self.data.length() == 0
}

// ============================================================================
// GRAPH REPRESENTATION
// ============================================================================

///|
/// Weighted edge
pub(all) struct Edge {
  to : Int
  weight : Int64
} derive(Show)

///|
/// Graph as adjacency list
pub(all) struct Graph {
  n : Int // Number of vertices
  adj : Array[Array[Edge]] // adj[u] = edges from u
}

///|
/// Create a new graph with n vertices
pub fn Graph::new(n : Int) -> Graph {
  let adj : Array[Array[Edge]] = Array::makei(n, _ => [])
  { n, adj }
}

///|
/// Add a directed edge from u to v with given weight
pub fn Graph::add_edge(
  self : Graph,
  from : Int,
  to : Int,
  weight : Int64,
) -> Unit {
  if from >= 0 && from < self.n && to >= 0 && to < self.n {
    self.adj[from].push({ to, weight })
  }
}

///|
/// Add an undirected edge between u and v
pub fn Graph::add_undirected_edge(
  self : Graph,
  u : Int,
  v : Int,
  weight : Int64,
) -> Unit {
  self.add_edge(u, v, weight)
  self.add_edge(v, u, weight)
}

// ============================================================================
// DIJKSTRA'S ALGORITHM
// ============================================================================

///|
const INF : Int64 = 4611686018427387903L // Large value for infinity

///|
const DIJK_INF_INT : Int = 0x3fffffff

///|
/// Result of Dijkstra's algorithm
pub(all) struct DijkstraResult {
  dist : Array[Int64] // dist[v] = shortest distance from source to v
  parent : Array[Int] // parent[v] = previous vertex on shortest path (-1 if none)
}

///|
/// Run Dijkstra's algorithm from source vertex
/// Returns distances and parent pointers for path reconstruction
///
/// ALGORITHM INVARIANT:
/// After each iteration, for all visited vertices v:
/// dist[v] = shortest path distance from source to v
pub fn dijkstra(graph : Graph, source : Int) -> DijkstraResult {
  let n = graph.n
  let dist = Array::make(n, INF)
  let parent = Array::make(n, -1)
  let visited = Array::make(n, false)
  if source < 0 || source >= n {
    return { dist, parent }
  }
  dist[source] = 0L
  let pq = MinHeap::new()
  pq.push({ dist: 0L, vertex: source })

  // Main Dijkstra loop - process vertices in order of increasing distance
  for {
    match pq.pop() {
      None => break
      Some(entry) => {
        let u = entry.vertex

        // Skip if already visited (we might have stale entries in PQ)
        if visited[u] {
          continue
        }
        visited[u] = true

        // Relax all outgoing edges
        for i = 0; i < graph.adj[u].length(); i = i + 1 {
          let edge = graph.adj[u][i]
          let v = edge.to
          let new_dist = dist[u] + edge.weight
          if new_dist < dist[v] {
            dist[v] = new_dist
            parent[v] = u
            pq.push({ dist: new_dist, vertex: v })
          }
        } where {
          invariant: i >= 0 && i <= graph.adj[u].length(),
          reasoning: (
            #|INVARIANT (relax edges):
            #|dist[u] is finalized (u has the smallest tentative distance among
            #|unvisited vertices), so any improvement to neighbors must go through u.
            #|MAINTENANCE:
            #|For each edge (u, v), relax dist[v] using dist[u] + weight.
            #|Non-negative weights guarantee this is safe and preserves optimality.
            #|TERMINATION:
            #|After all outgoing edges are processed, neighbors' distances are
            #|the best known via u.
          ),
        }
      }
    }
  } where {
    invariant: dist.length() == n &&
    parent.length() == n &&
    visited.length() == n,
    reasoning: (
      #|INVARIANT (Dijkstra):
      #|All visited vertices have their final shortest distances from source.
      #|For any unvisited vertex v, dist[v] is the shortest path length that
      #|uses only visited vertices as internal nodes (a valid upper bound).
      #|The priority queue may contain stale entries, but its minimum key
      #|corresponds to the smallest current dist among unvisited vertices.
      #|MAINTENANCE:
      #|Extract the unvisited vertex u with minimum dist[u], mark it visited,
      #|and relax its outgoing edges. Non-negative weights ensure dist[u] is
      #|optimal (no shorter path can go through unvisited vertices).
      #|TERMINATION:
      #|When the priority queue is empty, all reachable vertices are finalized.
    ),
  }
  { dist, parent }
}

///|
/// Array-based Dijkstra for small or dense graphs (O(n^2)).
pub fn dijkstra_dense(adj : Array[Array[(Int, Int)]], src : Int) -> Array[Int] {
  let n = adj.length()
  let dist = Array::make(n, DIJK_INF_INT)
  let used = Array::make(n, false)
  if src < 0 || src >= n {
    return dist
  }
  dist[src] = 0
  for iter = 0; iter < n; iter = iter + 1 {
    let mut u = -1
    let mut best = DIJK_INF_INT
    for i = 0; i < n; i = i + 1 {
      if not(used[i]) && dist[i] < best {
        u = i
        best = dist[i]
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (min scan):
        #|best is the smallest dist among unvisited nodes in [0..i).
        #|MAINTENANCE:
        #|Update best when a smaller unvisited distance is found.
        #|TERMINATION:
        #|At i = n, u is the unvisited node with minimum dist (if any).
      ),
    }
    if u < 0 {
      break
    }
    used[u] = true
    let neighbors = adj[u]
    for j = 0; j < neighbors.length(); j = j + 1 {
      let (v, w) = neighbors[j]
      let cand = dist[u] + w
      if not(used[v]) && cand < dist[v] {
        dist[v] = cand
      }
    } where {
      invariant: j >= 0 && j <= neighbors.length(),
      reasoning: (
        #|INVARIANT (relaxation scan):
        #|All edges neighbors[0..j) have been relaxed from u.
        #|MAINTENANCE:
        #|Relax edge (u -> v) and update dist[v] if a shorter path is found.
        #|TERMINATION:
        #|After the loop, all outgoing edges from u are processed.
      ),
    }
  } where {
    invariant: iter >= 0 && iter <= n,
    invariant: dist.length() == n && used.length() == n,
    reasoning: (
      #|INVARIANT (dense Dijkstra frontier):
      #|All used nodes have final shortest distances from src.
      #|For unused nodes, dist is the shortest path using only used nodes
      #|as intermediate vertices.
      #|MAINTENANCE:
      #|Select the unused node with minimum tentative distance and relax edges.
      #|TERMINATION:
      #|After n iterations or when no reachable nodes remain, dist is correct.
    ),
  }
  dist
}

///|
/// Reconstruct path from source to target using parent pointers
pub fn reconstruct_path(result : DijkstraResult, target : Int) -> Array[Int] {
  let path : Array[Int] = []
  if target < 0 || target >= result.parent.length() {
    return path
  }
  if result.dist[target] == INF {
    return path // No path exists
  }

  // Build path from target to source
  let mut current = target
  while current != -1 {
    path.push(current)
    current = result.parent[current]
  }

  // Reverse to get source to target
  path.rev_in_place()
  path
}

///|
/// Get shortest distance from source to target
pub fn shortest_distance(graph : Graph, source : Int, target : Int) -> Int64? {
  if target < 0 || target >= graph.n {
    return None
  }
  let result = dijkstra(graph, source)
  if result.dist[target] == INF {
    None
  } else {
    Some(result.dist[target])
  }
}

// ============================================================================
// BIDIRECTIONAL DIJKSTRA (Optional Optimization)
// ============================================================================

///|
/// Bidirectional Dijkstra for single-pair shortest path
/// Faster for point-to-point queries on large graphs
///
/// IDEA: Search from both source and target simultaneously
/// Stop when searches meet in the middle
pub fn bidirectional_dijkstra(
  graph : Graph,
  reverse_graph : Graph,
  source : Int,
  target : Int,
) -> Int64? {
  if source < 0 || source >= graph.n || target < 0 || target >= graph.n {
    return None
  }
  if source == target {
    return Some(0L)
  }
  let n = graph.n
  let dist_forward = Array::make(n, INF)
  let dist_backward = Array::make(n, INF)
  let visited_forward = Array::make(n, false)
  let visited_backward = Array::make(n, false)
  dist_forward[source] = 0L
  dist_backward[target] = 0L
  let pq_forward = MinHeap::new()
  let pq_backward = MinHeap::new()
  pq_forward.push({ dist: 0L, vertex: source })
  pq_backward.push({ dist: 0L, vertex: target })
  let mut best_dist = INF

  // INVARIANT: best_dist is the shortest known path through a vertex
  // visited by both searches
  for {
    // Alternate between forward and backward search
    let forward_done = pq_forward.is_empty()
    let backward_done = pq_backward.is_empty()
    if forward_done && backward_done {
      break
    }

    // Forward step
    if not(forward_done) {
      match pq_forward.pop() {
        Some(entry) => {
          let u = entry.vertex
          if not(visited_forward[u]) {
            visited_forward[u] = true

            // Check if we met backward search
            if visited_backward[u] {
              let candidate = dist_forward[u] + dist_backward[u]
              if candidate < best_dist {
                best_dist = candidate
              }
            }

            // Early termination
            if dist_forward[u] >= best_dist {
              // Skip
            } else {
              // Relax edges
              for i = 0; i < graph.adj[u].length(); i = i + 1 {
                let edge = graph.adj[u][i]
                let v = edge.to
                let new_dist = dist_forward[u] + edge.weight
                if new_dist < dist_forward[v] {
                  dist_forward[v] = new_dist
                  pq_forward.push({ dist: new_dist, vertex: v })
                }
              } where {
                invariant: i >= 0 && i <= graph.adj[u].length(),
                reasoning: (
                  #|INVARIANT (forward relax):
                  #|All outgoing edges in adj[u][0..i) have been relaxed for
                  #|the forward search.
                  #|MAINTENANCE:
                  #|Relax edge i and update dist_forward/pq_forward as needed.
                  #|TERMINATION:
                  #|At i = deg(u), forward relaxations from u are complete.
                ),
              }
            }
          }
        }
        None => ()
      }
    }

    // Backward step
    if not(backward_done) {
      match pq_backward.pop() {
        Some(entry) => {
          let u = entry.vertex
          if not(visited_backward[u]) {
            visited_backward[u] = true

            // Check if we met forward search
            if visited_forward[u] {
              let candidate = dist_forward[u] + dist_backward[u]
              if candidate < best_dist {
                best_dist = candidate
              }
            }

            // Early termination
            if dist_backward[u] >= best_dist {
              // Skip
            } else {
              // Relax edges (using reverse graph)
              for i = 0; i < reverse_graph.adj[u].length(); i = i + 1 {
                let edge = reverse_graph.adj[u][i]
                let v = edge.to
                let new_dist = dist_backward[u] + edge.weight
                if new_dist < dist_backward[v] {
                  dist_backward[v] = new_dist
                  pq_backward.push({ dist: new_dist, vertex: v })
                }
              } where {
                invariant: i >= 0 && i <= reverse_graph.adj[u].length(),
                reasoning: (
                  #|INVARIANT (backward relax):
                  #|All outgoing edges in reverse_graph.adj[u][0..i) have been
                  #|relaxed for the backward search.
                  #|MAINTENANCE:
                  #|Relax edge i and update dist_backward/pq_backward as needed.
                  #|TERMINATION:
                  #|At i = deg(u), backward relaxations from u are complete.
                ),
              }
            }
          }
        }
        None => ()
      }
    }
  } where {
    invariant: best_dist >= 0L,
    reasoning: (
      #|INVARIANT (bidirectional search):
      #|best_dist is the shortest path length found so far from any meeting node.
      #|MAINTENANCE:
      #|Alternate forward and backward expansions, updating best_dist when the
      #|frontiers meet; early termination is safe when a frontier's distance
      #|exceeds best_dist.
      #|TERMINATION:
      #|When both queues are exhausted, no shorter path exists.
    ),
  }
  if best_dist == INF {
    None
  } else {
    Some(best_dist)
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "dijkstra basic" {
  let g = Graph::new(5)
  // Simple graph: 0 -> 1 -> 2 -> 3 -> 4
  g.add_edge(0, 1, 1L)
  g.add_edge(1, 2, 2L)
  g.add_edge(2, 3, 3L)
  g.add_edge(3, 4, 4L)
  let result = dijkstra(g, 0)
  inspect(result.dist[0], content="0")
  inspect(result.dist[1], content="1")
  inspect(result.dist[2], content="3")
  inspect(result.dist[3], content="6")
  inspect(result.dist[4], content="10")
}

///|
test "dijkstra dense basic" {
  let adj : Array[Array[(Int, Int)]] = [
    [(1, 2), (2, 5)],
    [(2, 1), (3, 2)],
    [(3, 3)],
    [(4, 1)],
    [],
  ]
  let dist = dijkstra_dense(adj, 0)
  inspect(dist, content="[0, 2, 3, 4, 5]")
  let dist2 = dijkstra_dense(adj, 4)
  inspect(dist2[0] == DIJK_INF_INT, content="true")
}

///|
test "dijkstra with shortcuts" {
  let g = Graph::new(4)
  g.add_edge(0, 1, 1L)
  g.add_edge(1, 2, 1L)
  g.add_edge(2, 3, 1L)
  g.add_edge(0, 3, 10L) // Long direct path
  let result = dijkstra(g, 0)
  // Should take 0->1->2->3 (cost 3) not 0->3 (cost 10)
  inspect(result.dist[3], content="3")
}

///|
test "dijkstra unreachable" {
  let g = Graph::new(3)
  g.add_edge(0, 1, 1L)
  // Vertex 2 is unreachable

  let result = dijkstra(g, 0)
  inspect(result.dist[0], content="0")
  inspect(result.dist[1], content="1")
  inspect(result.dist[2] == INF, content="true")
}

///|
test "dijkstra undirected" {
  let g = Graph::new(4)
  g.add_undirected_edge(0, 1, 1L)
  g.add_undirected_edge(1, 2, 2L)
  g.add_undirected_edge(2, 3, 3L)
  g.add_undirected_edge(0, 3, 10L)
  let result = dijkstra(g, 0)
  inspect(result.dist[3], content="6") // 0->1->2->3
}

///|
test "path reconstruction" {
  let g = Graph::new(5)
  g.add_edge(0, 1, 1L)
  g.add_edge(1, 2, 1L)
  g.add_edge(2, 3, 1L)
  g.add_edge(0, 4, 1L)
  g.add_edge(4, 3, 1L) // Alternative path
  let result = dijkstra(g, 0)
  let path = reconstruct_path(result, 3)

  // Should be length 3: either 0->1->2->3 or 0->4->3
  inspect(path.length(), content="3")
  inspect(path[0], content="0")
  inspect(path[path.length() - 1], content="3")
}

///|
test "shortest distance helper" {
  let g = Graph::new(3)
  g.add_edge(0, 1, 5L)
  g.add_edge(1, 2, 3L)
  inspect(shortest_distance(g, 0, 2), content="Some(8)")
  inspect(shortest_distance(g, 0, 0), content="Some(0)")
}

///|
test "dijkstra single vertex" {
  let g = Graph::new(1)
  let result = dijkstra(g, 0)
  inspect(result.dist[0], content="0")
}

///|
test "dijkstra complex graph" {
  // Create a more complex graph
  let g = Graph::new(6)
  g.add_edge(0, 1, 7L)
  g.add_edge(0, 2, 9L)
  g.add_edge(0, 5, 14L)
  g.add_edge(1, 2, 10L)
  g.add_edge(1, 3, 15L)
  g.add_edge(2, 3, 11L)
  g.add_edge(2, 5, 2L)
  g.add_edge(3, 4, 6L)
  g.add_edge(4, 5, 9L)
  let result = dijkstra(g, 0)
  inspect(result.dist[0], content="0")
  inspect(result.dist[1], content="7")
  inspect(result.dist[2], content="9")
  inspect(result.dist[3], content="20")
  inspect(result.dist[4], content="26")
  inspect(result.dist[5], content="11")
}

///|
test "min heap basic" {
  let heap = MinHeap::new()
  heap.push({ dist: 5L, vertex: 0 })
  heap.push({ dist: 2L, vertex: 1 })
  heap.push({ dist: 8L, vertex: 2 })
  heap.push({ dist: 1L, vertex: 3 })

  // Should come out in order: 1, 2, 5, 8
  match heap.pop() {
    Some(e) => inspect(e.dist, content="1")
    None => fail("Expected element")
  }
  match heap.pop() {
    Some(e) => inspect(e.dist, content="2")
    None => fail("Expected element")
  }
  match heap.pop() {
    Some(e) => inspect(e.dist, content="5")
    None => fail("Expected element")
  }
  match heap.pop() {
    Some(e) => inspect(e.dist, content="8")
    None => fail("Expected element")
  }
  inspect(heap.is_empty(), content="true")
}

///|
test "dijkstra invalid source" {
  let g = Graph::new(3)
  let result = dijkstra(g, -1)
  inspect(result.dist[0] == INF, content="true")
  let result2 = dijkstra(g, 10)
  inspect(result2.dist[0] == INF, content="true")
}

///|
test "bidirectional dijkstra basic" {
  let g = Graph::new(4)
  let rev_g = Graph::new(4)

  // Forward graph
  g.add_edge(0, 1, 1L)
  g.add_edge(1, 2, 2L)
  g.add_edge(2, 3, 3L)

  // Reverse graph
  rev_g.add_edge(1, 0, 1L)
  rev_g.add_edge(2, 1, 2L)
  rev_g.add_edge(3, 2, 3L)
  let dist = bidirectional_dijkstra(g, rev_g, 0, 3)
  inspect(dist, content="Some(6)")
}

///|
test "bidirectional dijkstra same vertex" {
  let g = Graph::new(3)
  let rev_g = Graph::new(3)
  let dist = bidirectional_dijkstra(g, rev_g, 1, 1)
  inspect(dist, content="Some(0)")
}

///|
test "path reconstruction unreachable" {
  let g = Graph::new(3)
  let result = dijkstra(g, 0)
  let path = reconstruct_path(result, 2)
  inspect(path.length(), content="0")
}

///|
test "dijkstra zero weight edge" {
  let g = Graph::new(3)
  g.add_edge(0, 1, 0L)
  g.add_edge(1, 2, 0L)
  let result = dijkstra(g, 0)
  inspect(result.dist[2], content="0")
}

///|
test "dijkstra multiple paths same length" {
  let g = Graph::new(4)
  g.add_edge(0, 1, 1L)
  g.add_edge(0, 2, 1L)
  g.add_edge(1, 3, 1L)
  g.add_edge(2, 3, 1L)
  let result = dijkstra(g, 0)
  inspect(result.dist[3], content="2") // Either path works
}

///|
test "graph creation" {
  let g = Graph::new(5)
  inspect(g.n, content="5")
  inspect(g.adj.length(), content="5")
  g.add_edge(0, 1, 10L)
  inspect(g.adj[0].length(), content="1")
  inspect(g.adj[0][0].to, content="1")
  inspect(g.adj[0][0].weight, content="10")
}
