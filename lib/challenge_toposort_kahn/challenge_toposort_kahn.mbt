// ============================================================================
// Challenge: Topological Sort (Kahn's Algorithm)
// ============================================================================

///|
/// Return a topological ordering, or None if the graph has a cycle.
#warnings("+missing_invariant+missing_reasoning")
pub fn topo_sort(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Int]? {
  let adj : Array[Array[Int]] = Array::makei(n, _ => [])
  let indeg : Array[Int] = Array::make(n, 0)
  for edge in edges {
    let (u, v) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      adj[u].push(v)
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
    for v in neighbors {
      indeg[v] = indeg[v] - 1
      if indeg[v] == 0 {
        queue.push(v)
      }
    }
  } where {
    invariant: head >= 0 && head <= queue.length(),
    reasoning: (
      #|INVARIANT (Kahn frontier):
      #|order contains a valid topological prefix of processed nodes.
      #|MAINTENANCE:
      #|Removing u exposes new zero-indegree nodes that are appended to queue.
      #|TERMINATION:
      #|When head reaches queue.length(), all reachable nodes are processed.
    ),
  }
  if order.length() == n {
    Some(order)
  } else {
    None
  }
}

///|
/// Check whether `order` is a valid topological ordering for the graph.
#warnings("+missing_invariant+missing_reasoning")
pub fn is_topo(
  order : Array[Int],
  n : Int,
  edges : ArrayView[(Int, Int)],
) -> Bool {
  if order.length() != n {
    return false
  }
  let pos = Array::make(n, -1)
  for i, v in order {
    if v < 0 || v >= n || pos[v] != -1 {
      return false
    }
    pos[v] = i
  }
  for edge in edges {
    let (u, v) = edge
    if u < 0 || u >= n || v < 0 || v >= n {
      continue
    }
    if pos[u] >= pos[v] {
      return false
    }
  }
  true
}
