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
  let m = edges.length()
  for i = 0; i < m; i = i + 1 {
    let (u, v) = edges[i]
    if u >= 0 && u < n && v >= 0 && v < n {
      adj[u].push(v)
      rev[v].push(u)
    }
  } where {
    invariant: i >= 0 && i <= m,
    reasoning: (
      #|INVARIANT (Build graphs):
      #|adj/rev include all edges in edges[0..i).
      #|MAINTENANCE:
      #|Insert edge (u -> v) into adj and (v -> u) into rev.
      #|TERMINATION:
      #|At i = m, both graphs are fully built.
    ),
  }
  let visited = Array::make(n, false)
  let order : Array[Int] = []
  fn dfs1(v : Int) -> Unit {
    visited[v] = true
    let neighbors = adj[v]
    for j = 0; j < neighbors.length(); j = j + 1 {
      let to = neighbors[j]
      if !visited[to] {
        dfs1(to)
      }
    } where {
      invariant: j >= 0 && j <= neighbors.length(),
      reasoning: (
        #|INVARIANT (DFS forward):
        #|All neighbors[0..j) have been fully explored from v.
        #|MAINTENANCE:
        #|Recurse into unvisited neighbors as they are discovered.
        #|TERMINATION:
        #|At j = deg(v), v's reachable subtree is visited.
      ),
    }
    order.push(v)
  }

  for i = 0; i < n; i = i + 1 {
    if !visited[i] {
      dfs1(i)
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (Finish order):
      #|All vertices < i are visited and added to order by finish time.
      #|MAINTENANCE:
      #|Start a new DFS when an unvisited vertex is found.
      #|TERMINATION:
      #|At i = n, order contains all vertices by decreasing finish time.
    ),
  }
  let comp = Array::make(n, -1)
  let mut cid = 0
  fn dfs2(v : Int, id : Int) -> Unit {
    comp[v] = id
    let neighbors = rev[v]
    for j = 0; j < neighbors.length(); j = j + 1 {
      let to = neighbors[j]
      if comp[to] == -1 {
        dfs2(to, id)
      }
    } where {
      invariant: j >= 0 && j <= neighbors.length(),
      reasoning: (
        #|INVARIANT (DFS reverse):
        #|All neighbors[0..j) in rev have been assigned to component id.
        #|MAINTENANCE:
        #|Recurse into unassigned reverse neighbors.
        #|TERMINATION:
        #|At j = deg(v), the whole SCC is labeled.
      ),
    }
  }

  for idx = order.length() - 1; idx >= 0; idx = idx - 1 {
    let v = order[idx]
    if comp[v] == -1 {
      dfs2(v, cid)
      cid = cid + 1
    }
  } where {
    invariant: idx >= -1 && idx < order.length(),
    reasoning: (
      #|INVARIANT (Second pass):
      #|All vertices with order index > idx are assigned to some component.
      #|MAINTENANCE:
      #|Run reverse DFS from the next unassigned vertex.
      #|TERMINATION:
      #|At idx = -1, all components are labeled.
    ),
  }
  comp
}
