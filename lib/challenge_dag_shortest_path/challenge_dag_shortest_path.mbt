// ============================================================================
// Challenge: DAG Shortest Paths (Topological DP)
// ============================================================================

///|
const INF : Int = 0x3fffffff

///|
/// Return shortest paths in a DAG, or None if a cycle exists.
pub fn dag_shortest_paths(
  n : Int,
  edges : ArrayView[(Int, Int, Int)],
  src : Int,
) -> Array[Int]? {
  let adj : Array[Array[(Int, Int)]] = Array::makei(n, _ => [])
  let indeg : Array[Int] = Array::make(n, 0)
  for edge in edges {
    let (u, v, w) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      adj[u].push((v, w))
      indeg[v] = indeg[v] + 1
    }
  }
  let queue : Array[Int] = []
  for i in 0..<n {
    if indeg[i] == 0 {
      queue.push(i)
    }
  }
  let order : Array[Int] = []
  for head = 0; head < queue.length(); head = head + 1 {
    let u = queue[head]
    order.push(u)
    let neighbors = adj[u]
    for edge in neighbors {
      let (v, _w) = edge
      indeg[v] = indeg[v] - 1
      if indeg[v] == 0 {
        queue.push(v)
      }
    }
  } where {
    invariant: head >= 0 && head <= queue.length(),
    reasoning: (
      #|INVARIANT (Topo order):
      #|order is a valid topological prefix of processed nodes.
      #|MAINTENANCE:
      #|Processing u reveals new zero-indegree nodes.
      #|TERMINATION:
      #|When head reaches queue length, all reachable nodes are processed.
    ),
  }
  if order.length() != n {
    return None
  }
  let dist = Array::make(n, INF)
  if src >= 0 && src < n {
    dist[src] = 0
  }
  for u in order {
    if dist[u] != INF {
      let neighbors = adj[u]
      for edge in neighbors {
        let (v, w) = edge
        let cand = dist[u] + w
        if cand < dist[v] {
          dist[v] = cand
        }
      }
    }
  }
  Some(dist)
}
