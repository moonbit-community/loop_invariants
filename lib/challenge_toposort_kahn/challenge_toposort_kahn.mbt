// ============================================================================
// Challenge: Topological Sort (Kahn's Algorithm)
// ============================================================================

///|
/// Return a topological ordering, or None if the graph has a cycle.
#warnings("+missing_invariant+missing_reasoning")
pub fn topo_sort(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Int]? {
  let adj : Array[Array[Int]] = Array::makei(n, _ => [])
  let indeg : Array[Int] = Array::make(n, 0)
  edges.each(fn(edge) {
    let (u, v) = edge
    if u >= 0 && u < n && v >= 0 && v < n {
      adj[u].push(v)
      indeg[v] = indeg[v] + 1
    }
  })
  let queue : Array[Int] = []
  for i = 0; i < n; i = i + 1 {
    if indeg[i] == 0 {
      queue.push(i)
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (Queue init):
      #|queue contains exactly the nodes with indegree 0 in [0..i).
      #|MAINTENANCE:
      #|Append i when its indegree is zero.
      #|TERMINATION:
      #|At i = n, all zero-indegree nodes are queued.
    ),
  }
  let order : Array[Int] = []
  for head = 0; head < queue.length(); head = head + 1 {
    let u = queue[head]
    order.push(u)
    let neighbors = adj[u]
    for j = 0; j < neighbors.length(); j = j + 1 {
      let v = neighbors[j]
      indeg[v] = indeg[v] - 1
      if indeg[v] == 0 {
        queue.push(v)
      }
    } where {
      invariant: j >= 0 && j <= neighbors.length(),
      reasoning: (
        #|INVARIANT (Relax outgoing):
        #|All edges neighbors[0..j) have been removed from the DAG.
        #|MAINTENANCE:
        #|Decrease indegree and enqueue when it becomes zero.
        #|TERMINATION:
        #|At j = degree(u), all outgoing edges from u are processed.
      ),
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
  for i = 0; i < n; i = i + 1 {
    let v = order[i]
    if v < 0 || v >= n || pos[v] != -1 {
      return false
    }
    pos[v] = i
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (Order positions):
      #|pos contains indices for order[0..i) with no duplicates.
      #|MAINTENANCE:
      #|Record order[i] and reject out-of-range or repeated vertices.
      #|TERMINATION:
      #|At i = n, pos maps each vertex to its position.
    ),
  }
  let m = edges.length()
  for i = 0; i < m; i = i + 1 {
    let (u, v) = edges[i]
    if u < 0 || u >= n || v < 0 || v >= n {
      continue
    }
    if pos[u] >= pos[v] {
      return false
    }
  } where {
    invariant: i >= 0 && i <= m,
    reasoning: (
      #|INVARIANT (Edge order check):
      #|All edges in edges[0..i) satisfy pos[u] < pos[v].
      #|MAINTENANCE:
      #|Verify each edge respects the topological ordering.
      #|TERMINATION:
      #|At i = m, the ordering is valid if no violation was found.
    ),
  }
  true
}
