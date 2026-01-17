// ============================================================================
// VIRTUAL TREE - Build minimal tree connecting a subset of nodes
// ============================================================================
//
// Given a rooted tree and a set of important nodes, the virtual tree is the
// minimal tree that connects them, obtained by inserting necessary LCAs.
// Nodes are connected by ancestor relations, and all edges follow the
// original tree structure.
//
// TIME COMPLEXITY: O(k log n) where k is number of important nodes
// SPACE COMPLEXITY: O(n + k)

///|
const NO_PARENT : Int = -1

///|
fn make_adj(n : Int) -> Array[Array[Int]] {
  Array::makei(n, _ => [])
}

///|
fn build_lca(
  adj : Array[Array[Int]],
  root : Int,
) -> (Array[Array[Int]], Array[Int], Array[Int], Array[Int]) {
  let n = adj.length()
  let mut log = 1
  let mut pow = 1
  for ; pow < n; {
    pow = pow * 2
    log = log + 1
  } where {
    invariant: pow >= 1 && log >= 1 && pow == 1 << (log - 1),
    reasoning: (
      #|INVARIANT (log growth):
      #|pow tracks 2^(log-1). Each iteration doubles pow and increments log,
      #|so pow remains the smallest power of two >= 2^(log-1).
      #|TERMINATION:
      #|When pow >= n, log is large enough for binary lifting.
    ),
  }
  let up : Array[Array[Int]] = Array::makei(log, _ => Array::make(n, root))
  let depth = Array::make(n, 0)
  let tin = Array::make(n, 0)
  let tout = Array::make(n, 0)
  fn dfs(
    adj : Array[Array[Int]],
    up : Array[Array[Int]],
    depth : Array[Int],
    tin : Array[Int],
    tout : Array[Int],
    u : Int,
    p : Int,
    timer : Int,
  ) -> Int {
    up[0][u] = if p == NO_PARENT { u } else { p }
    depth[u] = if p == NO_PARENT { 0 } else { depth[p] + 1 }
    tin[u] = timer
    let mut t = timer + 1
    for v in adj[u] {
      if v == p {
        continue
      }
      t = dfs(adj, up, depth, tin, tout, v, u, t)
    }
    tout[u] = t
    t
  }

  let _ = dfs(adj, up, depth, tin, tout, root, NO_PARENT, 0)
  for k in 1..<log {
    for v in 0..<n {
      let mid = up[k - 1][v]
      up[k][v] = up[k - 1][mid]
    }
  }
  (up, depth, tin, tout)
}

///|
fn lca(up : Array[Array[Int]], depth : Array[Int], a0 : Int, b0 : Int) -> Int {
  let log = up.length()
  let mut a = a0
  let mut b = b0
  if depth[a] < depth[b] {
    let tmp = a
    a = b
    b = tmp
  }
  let target_depth = depth[b]
  let mut diff = depth[a] - target_depth
  for k in log >.. 0 {
    let step = 1 << k
    if diff >= step {
      a = up[k][a]
      diff = diff - step
    }
  }
  if a == b {
    return a
  }
  for k in log >.. 0 {
    if up[k][a] != up[k][b] {
      a = up[k][a]
      b = up[k][b]
    }
  }
  up[0][a]
}

///|
pub struct VirtualTree {
  nodes : Array[Int]
  adj : Array[Array[Int]]
}

///|
/// Build the virtual tree for the given important nodes.
/// The returned adjacency uses original node ids, with edges only among
/// nodes in the virtual tree.
pub fn build_virtual_tree(
  adj : Array[Array[Int]],
  important : Array[Int],
  root? : Int = 0,
) -> VirtualTree {
  let n = adj.length()
  let vt_adj = make_adj(n)
  if important.length() == 0 {
    return { nodes: [], adj: vt_adj }
  }
  let (up, depth, tin, _tout) = build_lca(adj, root)
  let ordered = important.copy()
  ordered.sort_by((a, b) => tin[a] - tin[b])
  let nodes = ordered.copy()
  for i in 0..<(ordered.length() - 1) {
    nodes.push(lca(up, depth, ordered[i], ordered[i + 1]))
  }
  nodes.sort_by((a, b) => tin[a] - tin[b])
  let uniq : Array[Int] = []
  for v in nodes {
    if uniq.length() == 0 || uniq[uniq.length() - 1] != v {
      uniq.push(v)
    }
  }
  let stack : Array[Int] = []
  stack.push(uniq[0])
  for i in 1..<uniq.length() {
    let v = uniq[i]
    let l = lca(up, depth, v, stack[stack.length() - 1])
    for ; stack.length() >= 2 && depth[stack[stack.length() - 2]] >= depth[l]; {
      let child = stack[stack.length() - 1]
      let _ = stack.pop()
      let parent = stack[stack.length() - 1]
      vt_adj[parent].push(child)
      vt_adj[child].push(parent)
    } where {
      invariant: stack.length() >= 1,
      reasoning: (
        #|INVARIANT (virtual stack):
        #|stack forms a root-to-leaf path in the virtual tree, ordered by depth.
        #|While the second-to-top node is deeper than l, the top edge is final
        #|and can be emitted safely.
        #|TERMINATION:
        #|Loop ends when l is above the path tail or stack has only one node.
      ),
    }
    if stack[stack.length() - 1] != l {
      let child = stack[stack.length() - 1]
      let _ = stack.pop()
      vt_adj[l].push(child)
      vt_adj[child].push(l)
      stack.push(l)
    }
    stack.push(v)
  }
  for ; stack.length() > 1; {
    let child = stack[stack.length() - 1]
    let _ = stack.pop()
    let parent = stack[stack.length() - 1]
    vt_adj[parent].push(child)
    vt_adj[child].push(parent)
  } where {
    invariant: stack.length() >= 1,
    reasoning: (
      #|INVARIANT (final chain):
      #|stack represents a single remaining path in the virtual tree whose
      #|edges are not yet emitted. Each iteration adds one edge and shortens
      #|the path.
      #|TERMINATION:
      #|When one node remains, all edges have been emitted.
    ),
  }
  { nodes: uniq, adj: vt_adj }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "virtual tree basic" {
  let adj = make_adj(6)
  adj[0].push(1)
  adj[1].push(0)
  adj[0].push(2)
  adj[2].push(0)
  adj[1].push(3)
  adj[3].push(1)
  adj[1].push(4)
  adj[4].push(1)
  adj[2].push(5)
  adj[5].push(2)
  let vt = build_virtual_tree(adj, [3, 4, 5])
  inspect(vt.nodes, content="[0, 1, 3, 4, 5]")
  let adj0 = vt.adj[0].copy()
  adj0.sort()
  inspect(adj0, content="[1, 5]")
  let adj1 = vt.adj[1].copy()
  adj1.sort()
  inspect(adj1, content="[0, 3, 4]")
}

///|
test "virtual tree single node" {
  let adj = make_adj(3)
  adj[0].push(1)
  adj[1].push(0)
  adj[1].push(2)
  adj[2].push(1)
  let vt = build_virtual_tree(adj, [2])
  inspect(vt.nodes, content="[2]")
  inspect(vt.adj[2].length(), content="0")
}
