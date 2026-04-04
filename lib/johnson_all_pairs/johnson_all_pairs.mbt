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
const INF64 : Int64 = 4611686018427387903L

///|
priv struct HeapEntry {
  dist : Int64
  node : Int
}

///|
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
fn build_adj(n : Int) -> Array[Array[(Int, Int64)]] {
  Array::makei(n, _ => [])
}

///|
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
    reasoning: (
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
/// All-pairs shortest paths using Johnson's algorithm.
/// Returns None if a negative cycle exists.
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
  let result : Array[Array[Int64]] = Array::make(n, [])
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
  let dist = johnson_all_pairs(4, edges[:]).unwrap()
  inspect(dist[0], content="[0, 1, -1, 1]")
  inspect(dist[1], content="[4611686018427387903, 0, -2, 0]")
}

///|
test "johnson negative cycle" {
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 1L), (1, 2, -2L), (2, 1, -2L)]
  inspect(johnson_all_pairs(3, edges[:]), content="None")
}

///|
test "johnson unreachable" {
  let edges : Array[(Int, Int, Int64)] = [(0, 1, 2L), (1, 2, 3L)]
  let dist = johnson_all_pairs(4, edges[:]).unwrap()
  inspect(dist[0][3], content="4611686018427387903")
}
