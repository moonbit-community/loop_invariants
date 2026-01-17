// ============================================================================
// Challenge: SCC (Kosaraju)
// Two-pass DFS using reverse graph order
// ============================================================================

///|
/// Compute strongly connected components using Kosaraju's algorithm.
#warnings("+missing_invariant+missing_reasoning")
pub fn scc_kosaraju(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Int] {
  let adj : Array[Array[Int]] = Array::makei(n, _ => [])
  let rev : Array[Array[Int]] = Array::makei(n, _ => [])
  for edge in edges {
    let (u, v) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      adj[u].push(v)
      rev[v].push(u)
    }
  }
  let visited = Array::make(n, false)
  let order : Array[Int] = []
  fn dfs1(v : Int) -> Unit {
    visited[v] = true
    let neighbors = adj[v]
    for to in neighbors {
      if !visited[to] {
        dfs1(to)
      }
    }
    order.push(v)
  }

  for i in 0..<n {
    if !visited[i] {
      dfs1(i)
    }
  }
  let comp = Array::make(n, -1)
  let mut cid = 0
  fn dfs2(v : Int, id : Int) -> Unit {
    comp[v] = id
    let neighbors = rev[v]
    for to in neighbors {
      if comp[to] == -1 {
        dfs2(to, id)
      }
    }
  }

  for idx in order.length() >.. 0 {
    let v = order[idx]
    if comp[v] == -1 {
      dfs2(v, cid)
      cid = cid + 1
    }
  }
  comp
}
