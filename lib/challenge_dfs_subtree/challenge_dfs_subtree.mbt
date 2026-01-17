// ============================================================================
// Challenge: Subtree Sizes with Iterative DFS
// ============================================================================

///|
/// Compute subtree sizes rooted at 'root' for a tree graph.
#warnings("+missing_invariant+missing_reasoning")
pub fn subtree_sizes(adj : Array[Array[Int]], root : Int) -> Array[Int] {
  let n = adj.length()
  if n == 0 || root < 0 || root >= n {
    return []
  }
  let parent : Array[Int] = Array::make(n, -1)
  let order : Array[Int] = []
  let stack : Array[Int] = []
  parent[root] = root
  stack.push(root)
  for idx = 0; idx < stack.length(); idx = idx + 1 {
    let u = stack[idx]
    order.push(u)
    for v in adj[u] {
      if v != parent[u] && parent[v] == -1 {
        parent[v] = u
        stack.push(v)
      }
    }
  } where {
    invariant: idx >= 0 && idx <= stack.length(),
    reasoning: (
      #|INVARIANT (DFS discovery):
      #|All nodes in stack[0..idx) have been expanded, and order records them.
      #|MAINTENANCE:
      #|Expanding stack[idx] assigns parents to unvisited neighbors and
      #|appends them to the stack.
      #|TERMINATION:
      #|When idx reaches stack.length(), all reachable nodes are discovered.
    ),
  }
  let size : Array[Int] = Array::make(n, 0)
  for i in order.length() >.. 0 {
    let u = order[i]
    size[u] = 1
    for v in adj[u] {
      if parent[v] == u {
        size[u] = size[u] + size[v]
      }
    }
  }
  size
}

///|
test "subtree_sizes" {
  // Tree: 0-1, 0-2, 2-3
  let adj : Array[Array[Int]] = [[1, 2], [0], [0, 3], [2]]
  let size = subtree_sizes(adj, 0)
  assert_eq(size[0], 4)
  assert_eq(size[1], 1)
  assert_eq(size[2], 2)
  assert_eq(size[3], 1)
}
