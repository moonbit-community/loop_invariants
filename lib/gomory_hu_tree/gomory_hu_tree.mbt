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
/// Sentinel infinity value used as the initial minimum during path traversal.
/// Equal to `Int64::max_value / 2` to avoid overflow when compared.
const GH_INF : Int64 = 4611686018427387903L

///|
/// A Gomory-Hu tree for an undirected capacitated graph.
///
/// The tree has exactly `n` vertices and `n-1` edges.  For any two distinct
/// vertices `u` and `v`, the minimum edge weight on the unique path between
/// them in this tree equals the minimum s-t cut value in the original graph.
///
/// Fields:
/// - `n`      : number of vertices in the original graph.
/// - `parent` : `parent[i]` is the parent of vertex `i` in the rooted tree
///              (vertex 0 is the root and has `parent[0] == -1`).
/// - `value`  : `value[i]` is the weight of the tree edge connecting `i` to
///              `parent[i]`, which equals the min-cut between `i` and
///              `parent[i]` in the original graph.
/// - `adj`    : adjacency list of the tree, stored as `(neighbour, weight)`
///              pairs, used for BFS path queries.
pub struct GomoryHuTree {
  n : Int
  parent : Array[Int]
  value : Array[Int64]
  adj : Array[Array[(Int, Int64)]]
}

///|
/// Build a Gomory-Hu tree for an undirected capacitated graph.
///
/// Parameters:
/// - `n`     : number of vertices (vertices are labeled `0..n-1`).
/// - `edges` : undirected edges given as `(u, v, capacity)` triples.
///             Parallel edges and loops are handled gracefully (loops and
///             non-positive capacities are ignored; parallel edges accumulate).
///
/// Returns a `GomoryHuTree` whose `min_cut` method answers all-pairs minimum
/// cut queries in O(n) time per query.
///
/// The algorithm runs exactly `n-1` max-flow computations (one per non-root
/// vertex).  Each flow is computed on the full graph (not a contracted one),
/// which simplifies the implementation at the cost of a small constant factor.
///
/// Time complexity : O(n * T_maxflow) where T_maxflow is the cost of a single
///                   s-t max-flow on the input graph.
/// Space complexity: O(n + m).
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
  for edge in edges {
    let (u, v, cap) = edge
    if u >= 0 && u < n && v >= 0 && v < n && u != v && cap > 0L {
      directed.push((u, v, cap))
      directed.push((v, u, cap))
    }
  }
  for i in 1..<n {
    let p = parent[i]
    let result = @min_cut_st.min_cut_st(n, directed[:], i, p).unwrap()
    value[i] = result.value
    let in_side = Array::make(n, false)
    for v in result.source_side {
      in_side[v] = true
    }
    for j in (i + 1)..<n {
      if parent[j] == p && in_side[j] {
        parent[j] = i
      }
    }
    if in_side[p] {
      let pp = parent[p]
      parent[p] = i
      parent[i] = pp
      let tmp = value[i]
      value[i] = value[p]
      value[p] = tmp
    }
  }
  let adj : Array[Array[(Int, Int64)]] = [ for _ in 0..<n => [] ]
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
/// Query the minimum cut value between vertices `u` and `v`.
///
/// By the Gomory-Hu theorem, this equals the minimum edge weight on the unique
/// path between `u` and `v` in the tree.  The method finds this path with a
/// BFS from `u` to `v` over the tree adjacency list, then walks the path back
/// while tracking the running minimum weight.
///
/// Special cases:
/// - Returns `0` when `u == v`.
/// - Returns `0` when `u` and `v` are in different connected components of the
///   original graph (their tree subtrees are disconnected).
///
/// Time complexity: O(n).
pub fn GomoryHuTree::min_cut(self : GomoryHuTree, u : Int, v : Int) -> Int64 {
  if u == v {
    return 0L
  }
  let parent = Array::make(self.n, -1)
  let parent_w = Array::make(self.n, 0L)
  let queue : Array[Int] = [u]
  parent[u] = u
  let found = for front = 0 {
    match queue.get(front) {
      None => break false
      Some(x) => {
        if x == v {
          break true
        }
        for edge in self.adj[x] {
          let (to, w) = edge
          if parent[to] == -1 {
            parent[to] = x
            parent_w[to] = w
            queue.push(to)
          }
        }
        continue front + 1
      }
    }
  }
  if !found || parent[v] == -1 {
    return 0L
  }
  for cur = v, min_w = GH_INF {
    if cur == u {
      break min_w
    } else {
      let w = parent_w[cur]
      let next = parent[cur]
      let new_min = if w < min_w { w } else { min_w }
      continue next, new_min
    }
  }
}
