// ============================================================================
// Challenge: Minimum Spanning Tree (Prim, O(n^2))
// ============================================================================

///|
const INF : Int = 0x3fffffff

///|
/// Build an undirected adjacency list from edge list (u, v, w).
pub fn build_adj(
  n : Int,
  edges : ArrayView[(Int, Int, Int)],
) -> Array[Array[(Int, Int)]] {
  let adj : Array[Array[(Int, Int)]] = Array::makei(n, _ => [])
  for edge in edges {
    let (u, v, w) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      adj[u].push((v, w))
      adj[v].push((u, w))
    }
  }
  adj
}

///|
/// Return the MST total weight if connected; otherwise None.
pub fn mst_weight(adj : Array[Array[(Int, Int)]]) -> Int? {
  let n = adj.length()
  if n <= 1 {
    return Some(0)
  }
  let in_mst = Array::make(n, false)
  let min_edge = Array::make(n, INF)
  min_edge[0] = 0
  let mut total = 0
  let mut added = 0
  for _ in 0..<n {
    let mut v = -1
    let mut best = INF
    for i in 0..<n {
      if !in_mst[i] && min_edge[i] < best {
        v = i
        best = min_edge[i]
      }
    }
    if v < 0 || best == INF {
      break
    }
    in_mst[v] = true
    total = total + best
    added = added + 1
    let neighbors = adj[v]
    for edge in neighbors {
      let (to, w) = edge
      if !in_mst[to] && w < min_edge[to] {
        min_edge[to] = w
      }
    }
  }
  if added == n {
    Some(total)
  } else {
    None
  }
}
