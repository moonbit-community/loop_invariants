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
  let adj : Array[Array[(Int, Int)]] = [ for _ in 0..<n => [] ]
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
  let (total, added) = for _ in 0..<n; total = 0, added = 0 {
    let (v, best) = for i in 0..<n; v = -1, best = INF {
      if !in_mst[i] && min_edge[i] < best {
        continue i, min_edge[i]
      } else {
        continue v, best
      }
    } nobreak {
      (v, best)
    }
    if v < 0 || best == INF {
      break (total, added)
    }
    in_mst[v] = true
    let neighbors = adj[v]
    for edge in neighbors {
      let (to, w) = edge
      if !in_mst[to] && w < min_edge[to] {
        min_edge[to] = w
      }
    }
    continue total + best, added + 1
  } nobreak {
    (total, added)
  }
  if added == n {
    Some(total)
  } else {
    None
  }
}
