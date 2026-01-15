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
  for k = 1; k < log; k = k + 1 {
    for v = 0; v < n; v = v + 1 {
      let mid = up[k - 1][v]
      up[k][v] = if mid >= 0 { up[k - 1][mid] } else { -1 }
    } where {
      invariant: v >= 0 && v <= n,
      reasoning: (
        #|INVARIANT (lift table):
        #|up[k][0..v) holds the 2^k ancestors for those nodes.
        #|MAINTENANCE:
        #|Use up[k-1] twice to jump 2^k.
        #|TERMINATION:
        #|At v = n, the k-th level is complete.
      ),
    }
  } where {
    invariant: k >= 1 && k <= log,
    reasoning: (
      #|INVARIANT (levels):
      #|Levels [0..k) of up are built, providing 2^j ancestors for j < k.
      #|MAINTENANCE:
      #|Compute level k from level k-1.
      #|TERMINATION:
      #|At k = log, all lifting levels are available.
    ),
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
  for k = 0; k < log; k = k + 1 {
    if ((diff >> k) & 1) == 1 {
      a = tree.up[k][a]
    }
  } where {
    invariant: k >= 0 && k <= log,
    reasoning: (
      #|INVARIANT (lift depth):
      #|a has been lifted to reduce the depth difference by the bits handled
      #|so far.
      #|MAINTENANCE:
      #|If the k-th bit is set, jump a up by 2^k.
      #|TERMINATION:
      #|At k = log, a and b are at the same depth.
    ),
  }
  if a == b {
    return a
  }
  for k = log - 1; k >= 0; k = k - 1 {
    let upa = tree.up[k][a]
    let upb = tree.up[k][b]
    if upa != upb {
      a = upa
      b = upb
    }
  } where {
    invariant: k >= 0 && k < log,
    reasoning: (
      #|INVARIANT (raise both):
      #|a and b are at the same depth and remain below their LCA.
      #|MAINTENANCE:
      #|Jump both up when their 2^k ancestors differ.
      #|TERMINATION:
      #|At k = -1, a and b are children of the LCA.
    ),
  }
  tree.up[0][a]
}
