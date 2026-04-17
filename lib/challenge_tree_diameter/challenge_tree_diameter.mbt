// ============================================================================
// Challenge: Tree Diameter (Two BFS)
// ============================================================================

///|
fn build_adj(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Array[Int]] {
  let adj = [ for _ in 0..<n => [] ]
  for edge in edges {
    let (u, v) = edge
    adj[u].push(v)
    adj[v].push(u)
  }
  adj
}

///|
fn bfs(adj : Array[Array[Int]], start : Int) -> (Int, Array[Int]) {
  let n = adj.length()
  let dist = Array::make(n, -1)
  let queue : Array[Int] = []
  dist[start] = 0
  queue.push(start)
  for head = 0 {
    if head >= queue.length() {
      break
    } else {
      let u = queue[head]
      for v in adj[u] {
        if dist[v] == -1 {
          dist[v] = dist[u] + 1
          queue.push(v)
        }
      }
      continue head + 1
    }
  } where {
    proof_invariant: head >= 0 && head <= queue.length(),
    proof_reasoning: (
      #|INVARIANT (BFS queue):
      #|All nodes in queue[0..head) have finalized distances. The queue holds
      #|the frontier of discovered nodes.
      #|MAINTENANCE:
      #|Process queue[head], enqueue undiscovered neighbors with distance +1.
      #|TERMINATION:
      #|At head = queue.length(), all reachable nodes are processed.
    ),
  }
  let (best_node, _) = for
    i in 0..<n
    best_node = start, best_dist = dist[start] {
    if dist[i] > best_dist {
      continue i, dist[i]
    } else {
      continue best_node, best_dist
    }
  } nobreak {
    (best_node, best_dist)
  }
  (best_node, dist)
}

///|
/// Return the length of the tree diameter.
pub fn tree_diameter(n : Int, edges : ArrayView[(Int, Int)]) -> Int {
  if n == 0 {
    return 0
  }
  let adj = build_adj(n, edges)
  let (a, _) = bfs(adj, 0)
  let (b, dist) = bfs(adj, a)
  dist[b]
}
