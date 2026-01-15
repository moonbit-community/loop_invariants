// ============================================================================
// Challenge: SCC (Tarjan)
// Single DFS with low-link values
// ============================================================================

///|
/// Compute strongly connected components using Tarjan's algorithm.
#warnings("+missing_invariant+missing_reasoning")
pub fn scc_tarjan(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Int] {
  let adj : Array[Array[Int]] = Array::makei(n, _ => [])
  edges.each(fn(edge) {
    let (u, v) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      adj[u].push(v)
    }
  })
  let index = Array::make(n, -1)
  let low = Array::make(n, 0)
  let onstack = Array::make(n, false)
  let stack : Array[Int] = []
  let comp = Array::make(n, -1)
  let mut time = 0
  let mut comp_id = 0
  fn dfs(v : Int) -> Unit {
    index[v] = time
    low[v] = time
    time = time + 1
    stack.push(v)
    onstack[v] = true
    let neighbors = adj[v]
    for j = 0; j < neighbors.length(); j = j + 1 {
      let to = neighbors[j]
      if index[to] == -1 {
        dfs(to)
        if low[to] < low[v] {
          low[v] = low[to]
        }
      } else if onstack[to] {
        if index[to] < low[v] {
          low[v] = index[to]
        }
      }
    } where {
      invariant: j >= 0 && j <= neighbors.length(),
      reasoning: (
        #|INVARIANT (Tarjan DFS):
        #|low[v] reflects the smallest index reachable through neighbors[0..j).
        #|MAINTENANCE:
        #|Update low[v] from child low-link or back-edge index.
        #|TERMINATION:
        #|At j = deg(v), low[v] is finalized.
      ),
    }
    if low[v] == index[v] {
      for {
        let w = stack.pop().unwrap()
        onstack[w] = false
        comp[w] = comp_id
        if w == v {
          break
        }
      } where {
        invariant: stack.length() >= 0,
        reasoning: (
          #|INVARIANT (Pop SCC):
          #|All popped nodes belong to the current SCC rooted at v.
          #|MAINTENANCE:
          #|Remove nodes from the stack until v is removed.
          #|TERMINATION:
          #|When w == v, the SCC is fully assigned.
        ),
      }
      comp_id = comp_id + 1
    }
  }

  for i = 0; i < n; i = i + 1 {
    if index[i] == -1 {
      dfs(i)
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (DFS forest):
      #|All vertices < i have been assigned to some SCC.
      #|MAINTENANCE:
      #|Start DFS from each unvisited vertex.
      #|TERMINATION:
      #|At i = n, every vertex has a component id.
    ),
  }
  comp
}
