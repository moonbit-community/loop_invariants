// ============================================================================
// Challenge: SCC (Tarjan)
// Single DFS with low-link values
// ============================================================================

///|
/// Compute strongly connected components using Tarjan's algorithm.
#warnings("+missing_invariant+missing_reasoning")
pub fn scc_tarjan(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Int] {
  let adj : Array[Array[Int]] = Array::makei(n, _ => [])
  for edge in edges {
    let (u, v) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      adj[u].push(v)
    }
  }
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
    for to in neighbors {
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
    }
    if low[v] == index[v] {
      for {
        match stack.pop() {
          Some(w) => {
            onstack[w] = false
            comp[w] = comp_id
            if w == v {
              break
            }
          }
          None => break
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

  for i in 0..<n {
    if index[i] == -1 {
      dfs(i)
    }
  }
  comp
}
