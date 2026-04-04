// ============================================================================
// SUURBALLE'S ALGORITHM - Two Edge-Disjoint Shortest Paths
// ============================================================================
//
// Suurballe finds two edge-disjoint shortest paths from source to sink in a
// directed graph with non-negative edge weights.
//
// Outline:
// 1) Run Dijkstra from source to get shortest path distances and a shortest
//    path tree (one shortest path to sink).
// 2) Reweight edges: w'(u,v) = w(u,v) + dist[u] - dist[v] (non-negative).
// 3) Reverse edges along the shortest path to sink and set their weight to 0.
// 4) Run Dijkstra again on the modified graph.
// 5) Combine the two paths and cancel reversed edges to obtain two
//    edge-disjoint paths.
//
// TIME COMPLEXITY: O(E log V)
// SPACE COMPLEXITY: O(V + E)

/// Sentinel value representing an unreachable distance (effectively infinity).
/// Chosen as `Int64::max_value / 2` to avoid overflow when adding edge weights.
///|
const SD_INF : Int64 = 4611686018427387903L

// ============================================================================
// MIN-HEAP FOR DIJKSTRA
// ============================================================================

/// A single entry in the priority queue used by Dijkstra's algorithm.
/// Holds the tentative distance to a vertex so the heap can order by distance.
///|
priv struct HeapEntry {
  dist : Int64
  vertex : Int
}

/// A binary min-heap over `HeapEntry` values, ordered by `dist`.
/// Used as the priority queue in both Dijkstra passes.
///|
priv struct MinHeap {
  data : Array[HeapEntry]
}

/// Creates a new, empty `MinHeap`.
///|
fn MinHeap::new() -> MinHeap {
  { data: [] }
}

/// Inserts `entry` into the heap and restores the heap property by sifting up.
///|
fn MinHeap::push(self : MinHeap, entry : HeapEntry) -> Unit {
  self.data.push(entry)
  for i = self.data.length() - 1; i > 0; {
    let parent = (i - 1) / 2
    if self.data[i].dist < self.data[parent].dist {
      let tmp = self.data[i]
      self.data[i] = self.data[parent]
      self.data[parent] = tmp
      continue parent
    } else {
      break
    }
  }
}

/// Removes and returns the entry with the smallest `dist`, or `None` when the
/// heap is empty.  Restores the heap property by sifting the last element down
/// from the root.
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
    let len = self.data.length()
    for i = 0; i < len; {
      let left = 2 * i + 1
      let right = 2 * i + 2
      let smallest = if left < len && self.data[left].dist < self.data[i].dist {
        left
      } else {
        i
      }
      let smallest = if right < len &&
        self.data[right].dist < self.data[smallest].dist {
        right
      } else {
        smallest
      }
      if smallest == i {
        break
      }
      let tmp = self.data[i]
      self.data[i] = self.data[smallest]
      self.data[smallest] = tmp
      continue smallest
    } where {
      proof_invariant: i >= 0 && i < len,
      proof_reasoning: (
        #|INVARIANT (heapify down):
        #|All nodes except the path from root to i satisfy the heap order.
        #|MAINTENANCE:
        #|Swap with the smallest child to restore the heap property on the path.
        #|TERMINATION:
        #|When smallest == i, the heap property holds globally.
      ),
    }
  }
  Some(result)
}

// ============================================================================
// DIJKSTRA HELPERS
// ============================================================================

/// Runs Dijkstra on the original graph from `source` to `sink`.
///
/// Parameters:
/// - `n`      : number of vertices (vertices are `0..n-1`).
/// - `adj`    : adjacency list; `adj[u]` contains edge ids leaving `u`.
/// - `to`     : `to[e]` is the head vertex of edge `e`.
/// - `weight` : `weight[e]` is the non-negative weight of edge `e`.
/// - `source` : start vertex.
/// - `sink`   : target vertex.
///
/// Returns `Some((dist, prev_edge))` where:
/// - `dist[v]` is the shortest distance from `source` to `v`.
/// - `prev_edge[v]` is the id of the last edge on the shortest path to `v`,
///   or `-1` if `v` was not reached.
///
/// Returns `None` when `sink` is unreachable from `source`.
///|
fn dijkstra_original(
  n : Int,
  adj : Array[Array[Int]],
  to : Array[Int],
  weight : Array[Int64],
  source : Int,
  sink : Int,
) -> (Array[Int64], Array[Int])? {
  let dist = Array::make(n, SD_INF)
  let prev_edge = Array::make(n, -1)
  dist[source] = 0L
  let heap = MinHeap::new()
  heap.push({ dist: 0L, vertex: source })
  let _ = for popped = heap.pop() {
    match popped {
      None => break ()
      Some(entry) => {
        let u = entry.vertex
        if entry.dist != dist[u] {
          continue heap.pop()
        }
        if u == sink {
          break ()
        }
        for i in 0..<adj[u].length() {
          let edge_id = adj[u][i]
          let v = to[edge_id]
          let nd = dist[u] + weight[edge_id]
          if nd < dist[v] {
            dist[v] = nd
            prev_edge[v] = edge_id
            heap.push({ dist: nd, vertex: v })
          }
        } where {
          proof_invariant: i >= 0 && i <= adj[u].length(),
          proof_reasoning: (
            #|INVARIANT (relax edges):
            #|Edges adj[u][0..i) have been considered for relaxation.
            #|MAINTENANCE:
            #|Relax edge i if it improves the shortest known distance.
            #|TERMINATION:
            #|At i = deg(u), all outgoing edges are processed.
          ),
        }
        continue heap.pop()
      }
    }
  }
  if dist[sink] >= SD_INF {
    None
  } else {
    Some((dist, prev_edge))
  }
}

/// An edge in the Suurballe-modified graph used for the second Dijkstra pass.
///
/// - `to`       : head vertex of this edge.
/// - `weight`   : reduced weight (`w'`) after applying Johnson potentials; `0`
///                for edges that were reversed from the first shortest path.
/// - `orig_id`  : index of the corresponding edge in the original edge list.
/// - `reversed` : `true` when this edge is a reversal of a first-path edge.
///                Traversing a reversed edge during path reconstruction cancels
///                the original directed edge in the combined graph.
///|
priv struct Edge2 {
  to : Int
  weight : Int64
  orig_id : Int
  reversed : Bool
}

/// Runs Dijkstra on the Suurballe-modified graph for the second path.
///
/// The modified graph has:
/// - Original edges reweighted by Johnson potentials (all non-negative).
/// - First-path edges replaced by their zero-cost reversal (`Edge2.reversed`).
///
/// Parameters:
/// - `n`      : number of vertices.
/// - `adj`    : adjacency list of `Edge2` records in the modified graph.
/// - `source` : start vertex.
/// - `sink`   : target vertex.
///
/// Returns `Some((dist, prev_v, prev_e))` where:
/// - `dist[v]`   is the reduced-cost shortest distance from `source` to `v`.
/// - `prev_v[v]` is the predecessor vertex on the shortest path to `v`.
/// - `prev_e[v]` is the index into `adj[prev_v[v]]` of the edge used.
///
/// Returns `None` when `sink` is unreachable.
///|
fn dijkstra_modified(
  n : Int,
  adj : Array[Array[Edge2]],
  source : Int,
  sink : Int,
) -> (Array[Int64], Array[Int], Array[Int])? {
  let dist = Array::make(n, SD_INF)
  let prev_v = Array::make(n, -1)
  let prev_e = Array::make(n, -1)
  dist[source] = 0L
  let heap = MinHeap::new()
  heap.push({ dist: 0L, vertex: source })
  let _ = for popped = heap.pop() {
    match popped {
      None => break ()
      Some(entry) => {
        let u = entry.vertex
        if entry.dist != dist[u] {
          continue heap.pop()
        }
        if u == sink {
          break ()
        }
        for i in 0..<adj[u].length() {
          let e = adj[u][i]
          let nd = dist[u] + e.weight
          if nd < dist[e.to] {
            dist[e.to] = nd
            prev_v[e.to] = u
            prev_e[e.to] = i
            heap.push({ dist: nd, vertex: e.to })
          }
        } where {
          proof_invariant: i >= 0 && i <= adj[u].length(),
          proof_reasoning: (
            #|INVARIANT (relax modified edges):
            #|Edges adj[u][0..i) have been relaxed under reduced weights.
            #|MAINTENANCE:
            #|Relax edge i if it improves the tentative distance.
            #|TERMINATION:
            #|At i = deg(u), all modified edges are processed.
          ),
        }
        continue heap.pop()
      }
    }
  }
  if dist[sink] >= SD_INF {
    None
  } else {
    Some((dist, prev_v, prev_e))
  }
}

// ============================================================================
// PATH EXTRACTION HELPERS
// ============================================================================

/// Removes the first occurrence of vertex `v` from `adj[u]`.
///
/// Returns `true` if the edge was found and removed, `false` otherwise.
/// Used during edge cancellation to eliminate opposite-direction edges between
/// the combined first and second paths.
///|
fn remove_edge(adj : Array[Array[Int]], u : Int, v : Int) -> Bool {
  for i in 0..<adj[u].length() {
    if adj[u][i] == v {
      let _ = adj[u].remove(i)
      return true
    }
  } where {
    proof_invariant: i >= 0 && i <= adj[u].length(),
    proof_reasoning: (
      #|INVARIANT (edge removal):
      #|Edges adj[u][0..i) have been checked for the target v.
      #|MAINTENANCE:
      #|If adj[u][i] matches v, remove it and stop.
      #|TERMINATION:
      #|If the loop ends, the edge was not present.
    ),
  }
  false
}

/// Extracts one complete path from `source` to `sink` by consuming edges from
/// `adj` (each outgoing edge list is treated as a stack).
///
/// The function mutates `adj`: each edge consumed by this call is permanently
/// removed, so calling it a second time extracts a different (disjoint) path
/// from the same combined graph.
///
/// Returns `Some(path)` where `path` is a vertex list starting at `source` and
/// ending at `sink`, or `None` if no path can be completed.
///|
fn extract_path(
  adj : Array[Array[Int]],
  source : Int,
  sink : Int,
) -> Array[Int]? {
  let path : Array[Int] = []
  for steps = 0, cur = source; cur != sink; {
    path.push(cur)
    let next = adj[cur].pop()
    guard next is Some(v) else { return None }
    continue steps + 1, v
  } where {
    proof_invariant: steps >= 0 && path.length() == steps,
    proof_reasoning: (
      #|INVARIANT (path extraction):
      #|path contains the prefix from source to cur using edges already removed
      #|from the combined graph.
      #|MAINTENANCE:
      #|Pop one outgoing edge and advance cur along it.
      #|TERMINATION:
      #|When cur == sink, a full s-t path is extracted.
    ),
  }
  path.push(sink)
  Some(path)
}

// ============================================================================
// PUBLIC API
// ============================================================================

/// Computes two edge-disjoint shortest paths from `source` to `sink` in a
/// directed graph with non-negative edge weights using Suurballe's algorithm.
///
/// Parameters:
/// - `n`      : total number of vertices; vertices are labelled `0..n-1`.
/// - `edges`  : slice of `(u, v, w)` triples, where `u` and `v` are vertex
///              indices and `w >= 0` is the edge weight.
/// - `source` : start vertex (`0 <= source < n`, `source != sink`).
/// - `sink`   : target vertex (`0 <= sink < n`).
///
/// Returns `Some((path1, path2))` where each path is a vertex list
/// `[source, ..., sink]` and the two paths share no directed edge.
/// The combined weight of both paths is minimal over all edge-disjoint pairs.
///
/// Returns `None` when:
/// - no pair of edge-disjoint paths exists between `source` and `sink`, or
/// - any input constraint is violated: `n <= 0`, vertex indices out of range,
///   negative edge weight, or `source == sink`.
///
/// Time complexity:  `O(E log V)`
/// Space complexity: `O(V + E)`
///|
pub fn suurballe_disjoint_paths(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
  source : Int,
  sink : Int,
) -> (Array[Int], Array[Int])? {
  if n <= 0 ||
    source < 0 ||
    source >= n ||
    sink < 0 ||
    sink >= n ||
    source == sink {
    return None
  }
  let m = edges.length()
  let from = Array::make(m, 0)
  let to = Array::make(m, 0)
  let weight = Array::make(m, 0L)
  let adj = Array::makei(n, _ => [])
  for i in 0..<m {
    let (u, v, w) = edges[i]
    if u < 0 || u >= n || v < 0 || v >= n || w < 0L {
      return None
    }
    from[i] = u
    to[i] = v
    weight[i] = w
    adj[u].push(i)
  } where {
    proof_invariant: i >= 0 && i <= m,
    proof_reasoning: (
      #|INVARIANT (edge load):
      #|Edges in edges[0..i) are loaded into from/to/weight and adj.
      #|MAINTENANCE:
      #|Store edge i and append its id to adj[u].
      #|TERMINATION:
      #|At i = m, all edges are loaded.
    ),
  }
  let (dist, prev_edge) = match
    dijkstra_original(n, adj, to, weight, source, sink) {
    None => return None
    Some(result) => result
  }
  let path_edges : Array[Int] = []
  for steps = 0, v = sink; v != source; {
    let e = prev_edge[v]
    if e < 0 {
      return None
    }
    path_edges.push(e)
    continue steps + 1, from[e]
  } where {
    proof_invariant: steps >= 0 && path_edges.length() == steps,
    proof_reasoning: (
      #|INVARIANT (shortest path reconstruction):
      #|path_edges holds the suffix of the shortest path from v to sink in
      #|reverse order.
      #|MAINTENANCE:
      #|Append the predecessor edge and move v to its tail.
      #|TERMINATION:
      #|When v == source, the entire shortest path is recorded.
    ),
  }
  path_edges.rev_in_place()
  let on_path = Array::make(m, false)
  for idx in 0..<path_edges.length() {
    let e = path_edges[idx]
    on_path[e] = true
  } where {
    proof_invariant: idx >= 0 && idx <= path_edges.length(),
    proof_reasoning: (
      #|INVARIANT (mark path edges):
      #|Edges in path_edges[0..idx) are marked as belonging to the first
      #|shortest path.
      #|MAINTENANCE:
      #|Mark the next edge in the shortest path.
      #|TERMINATION:
      #|At idx = len, all path edges are marked.
    ),
  }
  let reduced = Array::make(m, 0L)
  for i in 0..<m {
    reduced[i] = weight[i] + dist[from[i]] - dist[to[i]]
  } where {
    proof_invariant: i >= 0 && i <= m,
    proof_reasoning: (
      #|INVARIANT (reduced costs):
      #|Reduced weights for edges[0..i) are computed using dist.
      #|MAINTENANCE:
      #|Set reduced[i] = w + dist[u] - dist[v], which is non-negative by
      #|triangle inequality.
      #|TERMINATION:
      #|At i = m, all reduced costs are ready.
    ),
  }
  let adj2 = Array::makei(n, _ => [])
  for i in 0..<m {
    let u = from[i]
    let v2 = to[i]
    if on_path[i] {
      adj2[v2].push({ to: u, weight: 0L, orig_id: i, reversed: true })
    } else {
      adj2[u].push({ to: v2, weight: reduced[i], orig_id: i, reversed: false })
    }
  } where {
    proof_invariant: i >= 0 && i <= m,
    proof_reasoning: (
      #|INVARIANT (modified graph):
      #|Edges in [0..i) are added to adj2 with path edges reversed and assigned
      #|weight 0, others reweighted by reduced cost.
      #|MAINTENANCE:
      #|Insert the modified version of edge i.
      #|TERMINATION:
      #|At i = m, adj2 represents the Suurballe-modified graph.
    ),
  }
  let (_, prev_v, prev_e) = match dijkstra_modified(n, adj2, source, sink) {
    None => return None
    Some(result) => result
  }
  let path2 : Array[(Int, Edge2)] = []
  for steps = 0, v = sink; v != source; {
    let u = prev_v[v]
    let idx = prev_e[v]
    if u < 0 || idx < 0 {
      return None
    }
    let e = adj2[u][idx]
    path2.push((u, e))
    continue steps + 1, u
  } where {
    proof_invariant: steps >= 0 && path2.length() == steps,
    proof_reasoning: (
      #|INVARIANT (second path reconstruction):
      #|path2 holds the suffix of the second path from v to sink in reverse
      #|order, including reversed edges.
      #|MAINTENANCE:
      #|Append the predecessor edge and move v to its tail.
      #|TERMINATION:
      #|When v == source, the second path is fully recorded.
    ),
  }
  path2.rev_in_place()
  let combined_adj = Array::makei(n, _ => [])
  for idx in 0..<path_edges.length() {
    let e = path_edges[idx]
    combined_adj[from[e]].push(to[e])
  } where {
    proof_invariant: idx >= 0 && idx <= path_edges.length(),
    proof_reasoning: (
      #|INVARIANT (combine path1):
      #|combined_adj contains the first idx edges of the original shortest path.
      #|MAINTENANCE:
      #|Add the next edge to the combined graph.
      #|TERMINATION:
      #|At idx = len, all path1 edges are included.
    ),
  }
  for idx in 0..<path2.length() {
    let (u, e) = path2[idx]
    if e.reversed {
      let orig_u = from[e.orig_id]
      let orig_v = to[e.orig_id]
      let _ = remove_edge(combined_adj, orig_u, orig_v)
    } else {
      combined_adj[u].push(e.to)
    }
  } where {
    proof_invariant: idx >= 0 && idx <= path2.length(),
    proof_reasoning: (
      #|INVARIANT (combine path2):
      #|The combined graph contains all non-cancelled edges from path2[0..idx).
      #|Reversed edges cancel their counterparts in path1.
      #|MAINTENANCE:
      #|Remove a cancelled edge or add a new edge from path2.
      #|TERMINATION:
      #|At idx = len, combined_adj encodes two edge-disjoint paths.
    ),
  }
  let path1 = extract_path(combined_adj, source, sink)
  guard path1 is Some(p1) else { return None }
  let path2b = extract_path(combined_adj, source, sink)
  guard path2b is Some(p2) else { return None }
  Some((p1, p2))
}
