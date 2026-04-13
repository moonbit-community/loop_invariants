// ============================================================================
// Challenge: SCC (Tarjan)
// Single DFS with low-link values
// ============================================================================

///|
/// Compute strongly connected components using Tarjan's algorithm.
pub fn scc_tarjan(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Int] {
  let adj : Array[Array[Int]] = [| for _ in 0..<n => [] |]
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
  fn pop_component(root : Int, id : Int) -> Unit {
    match stack.pop() {
      Some(w) => {
        onstack[w] = false
        comp[w] = id
        if w != root {
          pop_component(root, id)
        }
      }
      None => ()
    }
  }

  fn dfs(v : Int, time : Int, comp_id : Int) -> (Int, Int) {
    index[v] = time
    low[v] = time
    stack.push(v)
    onstack[v] = true
    let (time, comp_id) = for to in adj[v]; time = time + 1, comp_id = comp_id {
      if index[to] == -1 {
        let (time1, comp1) = dfs(to, time, comp_id)
        if low[to] < low[v] {
          low[v] = low[to]
        }
        continue time1, comp1
      } else if onstack[to] {
        if index[to] < low[v] {
          low[v] = index[to]
        }
        continue time, comp_id
      } else {
        continue time, comp_id
      }
    } nobreak {
      (time, comp_id)
    }
    if low[v] == index[v] {
      pop_component(v, comp_id)
      (time, comp_id + 1)
    } else {
      (time, comp_id)
    }
  }

  let _ = for i in 0..<n; time = 0, comp_id = 0 {
    if index[i] == -1 {
      let (time1, comp1) = dfs(i, time, comp_id)
      continue time1, comp1
    } else {
      continue time, comp_id
    }
  } nobreak {
    (time, comp_id)
  }
  comp
}
