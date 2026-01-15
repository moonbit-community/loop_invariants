// ============================================================================
// GOMORY-HU TREE - All-Pairs Min-Cut for Undirected Graphs
// ============================================================================
//
// A Gomory-Hu tree is a weighted tree where the minimum s-t cut value between
// any two vertices equals the minimum edge weight on their path in the tree.
//
// This implementation uses the classic O(n * maxflow) algorithm:
// - Maintain parent[] for each vertex (initially 0).
// - For i = 1..n-1, compute min-cut between i and parent[i].
// - Use the cut partition to update parents and possibly swap relationships.
//
// We use @min_cut_st to compute s-t min-cuts, adding both directions of each
// undirected edge.
//
// TIME COMPLEXITY: O(n * maxflow)
// SPACE COMPLEXITY: O(n + m)

///|
const GH_INF : Int64 = 4611686018427387903L

///|
/// Gomory-Hu tree representation.
pub struct GomoryHuTree {
  n : Int
  parent : Array[Int]
  value : Array[Int64]
  adj : Array[Array[(Int, Int64)]]
}

///|
/// Build a Gomory-Hu tree for an undirected capacitated graph.
pub fn gomory_hu_tree(
  n : Int,
  edges : ArrayView[(Int, Int, Int64)],
) -> GomoryHuTree {
  if n <= 0 {
    return { n: 0, parent: [], value: [], adj: [] }
  }
  let parent = Array::make(n, 0)
  parent[0] = -1
  let value = Array::make(n, 0L)

  // Build directed edge list for min_cut_st.
  let directed : Array[(Int, Int, Int64)] = []
  for idx = 0; idx < edges.length(); idx = idx + 1 {
    let (u, v, cap) = edges[idx]
    if u >= 0 && u < n && v >= 0 && v < n && u != v && cap > 0L {
      directed.push((u, v, cap))
      directed.push((v, u, cap))
    }
  } where {
    invariant: idx >= 0 && idx <= edges.length(),
    reasoning: (
      #|INVARIANT (directed expansion):
      #|Undirected edges in edges[0..idx) have been expanded into two directed
      #|edges (both directions) when valid.
      #|MAINTENANCE:
      #|Expand edge idx if it is within bounds and has positive capacity.
      #|TERMINATION:
      #|At idx = edges.length(), all valid edges are expanded.
    ),
  }
  for i = 1; i < n; i = i + 1 {
    let p = parent[i]
    let result = @min_cut_st.min_cut_st(n, directed[:], i, p).unwrap()
    value[i] = result.value
    let in_side = Array::make(n, false)
    for k = 0; k < result.source_side.length(); k = k + 1 {
      let v = result.source_side[k]
      in_side[v] = true
    } where {
      invariant: k >= 0 && k <= result.source_side.length(),
      reasoning: (
        #|INVARIANT (mark cut side):
        #|Vertices in result.source_side[0..k) are marked as belonging to i's
        #|cut side.
        #|MAINTENANCE:
        #|Mark the next vertex in the cut set.
        #|TERMINATION:
        #|At k = len, all vertices on the source side are marked.
      ),
    }
    for j = i + 1; j < n; j = j + 1 {
      if parent[j] == p && in_side[j] {
        parent[j] = i
      }
    } where {
      invariant: j >= i + 1 && j <= n,
      reasoning: (
        #|INVARIANT (parent reassignment):
        #|Among vertices in [i+1, j), any vertex previously attached to p and
        #|lying on i's cut side now has parent i.
        #|MAINTENANCE:
        #|Check vertex j and redirect its parent when it shares the cut side.
        #|TERMINATION:
        #|At j = n, all affected vertices have been reassigned.
      ),
    }
    if in_side[p] {
      let pp = parent[p]
      parent[p] = i
      parent[i] = pp
      let tmp = value[i]
      value[i] = value[p]
      value[p] = tmp
    }
  } where {
    invariant: i >= 1 && i <= n,
    reasoning: (
      #|INVARIANT (partial Gomory-Hu tree):
      #|For all vertices < i, parent/value encode correct min-cuts between each
      #|vertex and its parent. Vertices >= i still point to some ancestor in
      #|[0, i).
      #|MAINTENANCE:
      #|Compute the min-cut between i and its current parent, then reassign any
      #|vertices on i's side to preserve tree consistency. If the parent is on
      #|the same side, swap to keep the tree valid.
      #|TERMINATION:
      #|At i = n, parent/value define a full Gomory-Hu tree.
    ),
  }
  let adj : Array[Array[(Int, Int64)]] = Array::makei(n, fn(_) { [] })
  for i in 0..<n {
    let p = parent[i]
    if p >= 0 {
      let w = value[i]
      adj[i].push((p, w))
      adj[p].push((i, w))
    }
  }
  { n, parent, value, adj }
}

///|
/// Query min-cut value between u and v by taking the minimum edge on the path.
pub fn GomoryHuTree::min_cut(self : GomoryHuTree, u : Int, v : Int) -> Int64 {
  if u == v {
    return 0L
  }
  let parent = Array::make(self.n, -1)
  let parent_w = Array::make(self.n, 0L)
  let queue : Array[Int] = [u]
  parent[u] = u
  let mut front = 0
  while queue.get(front) is Some(x) {
    if x == v {
      break
    }
    for i = 0; i < self.adj[x].length(); i = i + 1 {
      let (to, w) = self.adj[x][i]
      if parent[to] == -1 {
        parent[to] = x
        parent_w[to] = w
        queue.push(to)
      }
    } where {
      invariant: i >= 0 && i <= self.adj[x].length(),
      reasoning: (
        #|INVARIANT (expand neighbors):
        #|Edges adj[x][0..i) have been checked; unvisited neighbors there have
        #|their parent recorded and are enqueued.
        #|MAINTENANCE:
        #|Inspect edge i and enqueue the neighbor when unseen.
        #|TERMINATION:
        #|At i = deg(x), all neighbors of x have been processed.
      ),
    }
    front = front + 1
  }
  if parent[v] == -1 {
    return 0L
  }
  let mut min_w = GH_INF
  let mut cur = v
  for steps = 0; cur != u; steps = steps + 1 {
    let w = parent_w[cur]
    if w < min_w {
      min_w = w
    }
    cur = parent[cur]
  } where {
    invariant: steps >= 0 && min_w >= 0L,
    reasoning: (
      #|INVARIANT (path minimum):
      #|min_w is the smallest edge weight seen so far on the path from v to cur.
      #|MAINTENANCE:
      #|Update min_w with the next parent edge and move upward.
      #|TERMINATION:
      #|At cur = u, min_w is the minimum edge weight on the u-v path.
    ),
  }
  min_w
}
