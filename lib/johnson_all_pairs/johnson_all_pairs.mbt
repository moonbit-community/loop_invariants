// ============================================================================
// JOHNSON'S ALGORITHM - All-Pairs Shortest Paths (Sparse Graphs)
// ============================================================================
//
// Johnson's algorithm handles graphs with negative weights (no negative cycles)
// by reweighting edges so that Dijkstra can be used from every source.
//
// STEPS:
// 1. Add a super-source s with 0-weight edges to every vertex.
// 2. Run Bellman-Ford from s to compute potentials h[v].
// 3. Reweight each edge: w'(u,v) = w(u,v) + h[u] - h[v] (non-negative).
// 4. Run Dijkstra from every vertex on the reweighted graph.
// 5. Recover original distances: dist(u,v) = dist'(u,v) - h[u] + h[v].
//
// INVARIANTS:
// 1. Bellman-Ford potentials satisfy h[v] <= h[u] + w(u,v) for all edges.
// 2. Reweighted edges are non-negative, so Dijkstra is valid.
// 3. Distance recovery preserves shortest paths in the original graph.
//
// TIME COMPLEXITY: O(V * E + V * (E log V))
// SPACE COMPLEXITY: O(V + E)

///|
/// Sentinel value representing "infinity" (no path exists).
///
/// Chosen to be the largest `Int64` value that can be added to itself without
/// overflowing: `INF64 + INF64` fits in `Int64`, so overflow guards in
/// relaxation code simply compare `dist + w > INF64` before adding.
///
/// Callers that receive a distance matrix from `johnson_all_pairs` will see
/// this value for any pair of vertices where no path exists.
const INF64 : Int64 = 4611686018427387903L

///|
/// A single entry stored inside `MinHeap`.
///
/// Fields:
/// - `dist`: the tentative shortest-path distance to `node` in the
///   reweighted graph.
/// - `node`: the vertex index this entry refers to.
///
/// Entries are ordered by `dist` (smaller is higher priority). Stale entries
/// (where `dist != current_dist[node]`) are discarded when popped.
priv struct HeapEntry {
  dist : Int64
  node : Int
}

///|
/// A binary min-heap of `HeapEntry` values used by Dijkstra.
///
/// The heap maintains the **min-heap property**: `data[i].dist <=
/// data[2*i+1].dist` and `data[i].dist <= data[2*i+2].dist` for every
/// internal node `i`.
///
/// Stale duplicate entries (arising because `dist[v]` can only decrease) are
/// left in the heap and discarded at pop time via the `d != dist[u]` guard in
/// `dijkstra`. This is the standard "lazy deletion" approach.
priv struct MinHeap {
  data : Array[HeapEntry]
}

///|
/// Create an empty `MinHeap`.
///
/// Returns a heap with no entries. Call `push` to add entries and `pop` to
/// remove the entry with the smallest `dist`.
///
/// Time complexity: O(1).
fn MinHeap::new() -> MinHeap {
  { data: [] }
}

///|
/// Insert `entry` into the heap, restoring the min-heap property.
///
/// The new entry is appended at the end of the backing array and then
/// sifted upward by repeatedly swapping with its parent while its `dist` is
/// smaller than the parent's `dist`.
///
/// Parameters:
/// - `entry`: the `HeapEntry` to insert.
///
/// Time complexity: O(log n) where n is the current heap size.
fn MinHeap::push(self : MinHeap, entry : HeapEntry) -> Unit {
  self.data.push(entry)
  let _ = for i = self.data.length() - 1 {
    if i <= 0 {
      break ()
    }
    let p = (i - 1) / 2
    if self.data[i].dist < self.data[p].dist {
      let tmp = self.data[i]
      self.data[i] = self.data[p]
      self.data[p] = tmp
      continue p
    } else {
      break ()
    }
  }
}

///|
/// Remove and return the entry with the smallest `dist`, restoring the
/// min-heap property.
///
/// Returns `None` if the heap is empty. Otherwise the last element is moved
/// to the root position and sifted downward by swapping with the smaller of
/// its two children until the heap property is restored.
///
/// Time complexity: O(log n) where n is the current heap size.
fn MinHeap::pop(self : MinHeap) -> HeapEntry? {
  let n = self.data.length()
  if n == 0 {
    return None
  }
  let result = self.data[0]
  let last = match self.data.pop() {
    Some(v) => v
    None => return Some(result)
  }
  if self.data.length() > 0 {
    self.data[0] = last
    let len = self.data.length()
    let _ = for i = 0 {
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
        break ()
      } else {
        let tmp = self.data[i]
        self.data[i] = self.data[smallest]
        self.data[smallest] = tmp
        continue smallest
      }
    }
  }
  Some(result)
}

///|
/// Construct an adjacency list for a graph with `n` vertices and no edges.
///
/// Returns an array of `n` empty edge-lists. Each element `adj[u]` is an
/// array of `(v, w)` pairs representing directed edges `u -> v` with weight
/// `w` in the reweighted graph.
///
/// Parameters:
/// - `n`: number of vertices.
///
/// Time complexity: O(n).
fn build_adj(n : Int) -> Array[Array[(Int, Int64)]] {
  [
    for _ in 0..<n => []
  ]
}

///|
/// Run Dijkstra's algorithm on the reweighted graph from `src`.
///
/// The input graph is assumed to have **all non-negative edge weights** (the
/// caller is responsible for ensuring this via Johnson reweighting). Stale
/// heap entries are discarded via the `d != dist[u]` guard (lazy deletion).
///
/// Overflow is prevented by skipping relaxation whenever `d > INF64 - w`,
/// which would cause the sum to wrap around. Unreachable vertices keep their
/// initial distance of `INF64`.
///
/// Parameters:
/// - `n`: number of vertices; indices must be in `0..<n`.
/// - `adj`: adjacency list of the reweighted graph; `adj[u]` contains
///   `(v, w')` pairs where `w' >= 0`.
/// - `src`: source vertex index (`0 <= src < n`).
///
/// Returns an array of length `n` where entry `v` holds the shortest
/// reweighted distance from `src` to `v`, or `INF64` if `v` is unreachable.
///
/// Time complexity: O((E + V) log V) with binary heap.
/// Space complexity: O(V + E).
fn dijkstra(
  n : Int,
  adj : Array[Array[(Int, Int64)]],
  src : Int,
) -> Array[Int64] {
  let dist = Array::make(n, INF64)
  dist[src] = 0L
  let heap = MinHeap::new()
  heap.push({ dist: 0L, node: src })
  for ;; {
    match heap.pop() {
      None => break
      Some(entry) => {
        let d = entry.dist
        let u = entry.node
        if d != dist[u] {
          continue
        }
        for edge in adj[u] {
          let (v, w) = edge
          if d > INF64 - w {
            continue
          }
          let nd = d + w
          if nd < dist[v] {
            dist[v] = nd
            heap.push({ dist: nd, node: v })
          }
        }
      }
    }
  } where {
    proof_invariant: dist.length() == n,
    proof_reasoning: (
      #|INVARIANT (Dijkstra):
      #|For every node already finalized (popped with d == dist[u]), dist[u] is
      #|its true shortest distance in the reweighted graph. For all others,
      #|dist is the best known upper bound. The heap may contain stale entries,
      #|but the minimum valid entry matches the smallest current dist.
      #|MAINTENANCE:
      #|Relaxing outgoing edges preserves shortest-path upper bounds.
      #|TERMINATION:
      #|When the heap is empty, all reachable distances are finalized.
    ),
  }
  dist
}

///|
/// Compute all-pairs shortest paths using Johnson's algorithm.
///
/// Johnson's algorithm handles directed graphs with **negative edge weights**
/// but **no negative cycles**. It works in two stages:
///
/// 1. **Reweighting** (Bellman-Ford phase): a virtual super-source `q` is
///    added with 0-weight edges to every vertex. Bellman-Ford is run from `q`
///    to obtain potential values `h[v]`. Each original edge `(u, v, w)` is
///    reweighted to `w' = w + h[u] - h[v]`, which is guaranteed to be >= 0
///    by the Bellman-Ford triangle inequality. If a negative cycle exists,
///    Bellman-Ford detects it and the function returns `None`.
///
/// 2. **Dijkstra phase**: Dijkstra is run from every vertex `s` on the
///    reweighted graph. The reweighted distances `d'[s][t]` are then converted
///    back to original distances via `dist[s][t] = d'[s][t] - h[s] + h[t]`.
///
/// The correction `- h[s] + h[t]` is exact because the reweighting shifts all
/// paths between `s` and `t` by the same constant `h[s] - h[t]`
/// (the internal potential terms telescope and cancel).
///
/// Parameters:
/// - `n`: number of vertices; vertices are labelled `0..<n`.
/// - `edges`: a slice of `(u, v, w)` triples representing directed edges
///   `u -> v` with `Int64` weight `w`. Edges with out-of-range indices
///   (`u < 0`, `u >= n`, `v < 0`, `v >= n`) are silently ignored.
///   Weights may be negative; parallel edges and self-loops are accepted.
///
/// Returns:
/// - `Some(dist)` where `dist` is an `n x n` array of `Int64` distances.
///   `dist[s][t]` is the shortest-path cost from `s` to `t` in the original
///   graph, or `INF64` (`4611686018427387903`) if `t` is unreachable from `s`.
/// - `None` if a negative cycle is detected.
/// - `Some([])` if `n <= 0`.
///
/// Example:
///
/// ```
/// let edges = [(0, 1, 1L), (0, 2, 4L), (1, 2, -2L), (2, 3, 2L), (1, 3, 5L)]
/// let dist = johnson_all_pairs(4, edges[:]).unwrap()
/// // dist[0] = [0, 1, -1, 1]
/// ```
///
/// Time complexity: O(V * E + V^2 * log V).
/// Space complexity: O(V + E) working space, O(V^2) for the output matrix.
pub fn johnson_all_pairs(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
) -> Array[Array[Int64]]? {
  if n <= 0 {
    return Some([])
  }

  // Build Bellman-Ford graph with super-source
  let super_source = n
  let bf = @bellman_ford.BellmanFord::new(n + 1)
  for edge in edges {
    let (u, v, w) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      bf.add_edge(u, v, w)
    }
  }
  for v in 0..<n {
    bf.add_edge(super_source, v, 0L)
  }
  let bf_result = bf.compute(super_source)
  if bf_result.has_negative_cycle() {
    return None
  }
  let h = bf_result.dist

  // Build reweighted adjacency list
  let adj = build_adj(n)
  for edge in edges {
    let (u, v, w) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      let w2 = w + h[u] - h[v]
      adj[u].push((v, w2))
    }
  }

  // Run Dijkstra from each vertex
  let result : Array[Array[Int64]] = [ for _ in 0..<n => [] ]
  for s in 0..<n {
    let dist = dijkstra(n, adj, s)
    let row = Array::make(n, INF64)
    for v in 0..<n {
      if dist[v] < INF64 {
        row[v] = dist[v] - h[s] + h[v]
      }
    }
    result[s] = row
  }
  Some(result)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "johnson basic" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (0, 2, 4L),
    (1, 2, -2L),
    (2, 3, 2L),
    (1, 3, 5L),
  ]
  let dist = johnson_all_pairs(4, edges).unwrap()
  inspect(dist[0], content="[0, 1, -1, 1]")
  inspect(dist[1], content="[4611686018427387903, 0, -2, 0]")
}

///|
test "johnson negative cycle" {
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 1L), (1, 2, -2L), (2, 1, -2L)]
  inspect(johnson_all_pairs(3, edges), content="None")
}

///|
test "johnson unreachable" {
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 2L), (1, 2, 3L)]
  let dist = johnson_all_pairs(4, edges).unwrap()
  inspect(dist[0][3], content="4611686018427387903")
}
