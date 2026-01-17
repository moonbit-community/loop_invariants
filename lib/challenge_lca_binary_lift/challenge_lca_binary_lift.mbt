// ============================================================================
// Challenge: LCA (Binary Lifting)
// ============================================================================

///|
fn highest_bit(x : Int) -> Int {
  for v = x, k = 0 {
    if v <= 1 {
      break k
    } else {
      continue v >> 1, k + 1
    }
  } where {
    invariant: v >= 1,
    reasoning: (
      #|INVARIANT (highest bit):
      #|v equals x >> k, so k counts shifts so far.
      #|MAINTENANCE:
      #|Shift v right by 1 and increment k.
      #|TERMINATION:
      #|When v <= 1, k is floor(log2(x)).
    ),
  }
}

///|
fn build_adj(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Array[Int]] {
  let adj = Array::makei(n, _ => [])
  for edge in edges {
    let (u, v) = edge
    adj[u].push(v)
    adj[v].push(u)
  }
  adj
}

///|
pub struct Lca {
  up : Array[Array[Int]]
  depth : Array[Int]
}

///|
/// Precompute binary lifting tables for LCA queries.
#warnings("+missing_invariant+missing_reasoning")
pub fn build_lca(n : Int, edges : ArrayView[(Int, Int)], root : Int) -> Lca {
  if n == 0 {
    return { up: [], depth: [] }
  }
  let log = highest_bit(n) + 1
  let up = Array::makei(log, _ => Array::make(n, -1))
  let depth = Array::make(n, 0)
  let adj = build_adj(n, edges)
  let queue : Array[Int] = []
  queue.push(root)
  up[0][root] = -1
  depth[root] = 0
  for head = 0; head < queue.length(); head = head + 1 {
    let u = queue[head]
    for v in adj[u] {
      if v != up[0][u] {
        up[0][v] = u
        depth[v] = depth[u] + 1
        queue.push(v)
      }
    }
  } where {
    invariant: head >= 0 && head <= queue.length(),
    reasoning: (
      #|INVARIANT (BFS tree):
      #|Nodes in queue[0..head) have fixed depth and parent up[0]. The queue
      #|stores discovered but not yet processed nodes.
      #|MAINTENANCE:
      #|Process u, assign parent/depth for unseen neighbors, enqueue them.
      #|TERMINATION:
      #|At head = queue.length(), all nodes have depth and immediate parent.
    ),
  }
  for k in 1..<log {
    for v in 0..<n {
      let mid = up[k - 1][v]
      up[k][v] = if mid >= 0 { up[k - 1][mid] } else { -1 }
    }
  }
  { up, depth }
}

///|
/// Return the lowest common ancestor of u and v.
#warnings("+missing_invariant+missing_reasoning")
pub fn lca(tree : Lca, u : Int, v : Int) -> Int {
  let log = tree.up.length()
  let mut a = u
  let mut b = v
  if tree.depth[a] < tree.depth[b] {
    let tmp = a
    a = b
    b = tmp
  }
  let diff = tree.depth[a] - tree.depth[b]
  for k in 0..<log {
    if ((diff >> k) & 1) == 1 {
      a = tree.up[k][a]
    }
  }
  if a == b {
    return a
  }
  for k in log >.. 0 {
    let upa = tree.up[k][a]
    let upb = tree.up[k][b]
    if upa != upb {
      a = upa
      b = upb
    }
  }
  tree.up[0][a]
}
