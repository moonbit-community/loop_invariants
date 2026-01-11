// ============================================================================
// Challenge: Minimum Spanning Tree (Prim, O(n^2))
// ============================================================================

///|
const INF : Int = 0x3fffffff

///|
/// Build an undirected adjacency list from edge list (u, v, w).
#warnings("+missing_invariant+missing_reasoning")
pub fn build_adj(
  n : Int,
  edges : ArrayView[(Int, Int, Int)],
) -> Array[Array[(Int, Int)]] {
  let adj : Array[Array[(Int, Int)]] = Array::make(n, [])
  let m = edges.length()
  for i = 0; i < m; i = i + 1 {
    let (u, v, w) = edges[i]
    if u >= 0 && u < n && v >= 0 && v < n {
      adj[u].push((v, w))
      adj[v].push((u, w))
    }
  } where {
    invariant: i >= 0 && i <= m,
    reasoning: (
      #|INVARIANT (Adjacency build):
      #|adj reflects all undirected edges in edges[0..i).
      #|MAINTENANCE:
      #|Insert (u, v) and (v, u) for each valid edge.
      #|TERMINATION:
      #|At i = m, all edges are inserted.
    ),
  }
  adj
}

///|
/// Return the MST total weight if connected; otherwise None.
#warnings("+missing_invariant+missing_reasoning")
pub fn mst_weight(adj : Array[Array[(Int, Int)]]) -> Int? {
  let n = adj.length()
  if n <= 1 {
    return Some(0)
  }
  let in_mst = Array::make(n, false)
  let min_edge = Array::make(n, INF)
  min_edge[0] = 0
  let mut total = 0
  let mut added = 0
  for iter = 0; iter < n; iter = iter + 1 {
    let mut v = -1
    let mut best = INF
    for i = 0; i < n; i = i + 1 {
      if !in_mst[i] && min_edge[i] < best {
        v = i
        best = min_edge[i]
      }
    } where {
      invariant: i >= 0 && i <= n,
      reasoning: (
        #|INVARIANT (Select next):
        #|best is the smallest edge weight among nodes not yet in the MST.
        #|MAINTENANCE:
        #|Update best when a smaller candidate is found.
        #|TERMINATION:
        #|At i = n, v is the best next node (if any).
      ),
    }
    if v < 0 || best == INF {
      break
    }
    in_mst[v] = true
    total = total + best
    added = added + 1
    let neighbors = adj[v]
    for j = 0; j < neighbors.length(); j = j + 1 {
      let (to, w) = neighbors[j]
      if !in_mst[to] && w < min_edge[to] {
        min_edge[to] = w
      }
    } where {
      invariant: j >= 0 && j <= neighbors.length(),
      reasoning: (
        #|INVARIANT (Update frontier):
        #|All edges neighbors[0..j) have been considered for min_edge.
        #|MAINTENANCE:
        #|Decrease min_edge[to] when a cheaper connection is found.
        #|TERMINATION:
        #|After the loop, frontier costs from v are updated.
      ),
    }
  } where {
    invariant: iter >= 0 && iter <= n,
    invariant: added >= 0 && added <= n,
    reasoning: (
      #|INVARIANT (Prim growth):
      #|The in_mst set is connected and total equals its MST weight so far.
      #|MAINTENANCE:
      #|Add the cheapest edge to a new node and update frontier costs.
      #|TERMINATION:
      #|If added == n, total is the MST weight; otherwise graph is disconnected.
    ),
  }
  if added == n {
    Some(total)
  } else {
    None
  }
}

///|
test "mst_prim_basic" {
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 1),
    (1, 2, 2),
    (2, 3, 3),
    (0, 3, 10),
  ]
  let adj = build_adj(4, edges[:])
  assert_eq(mst_weight(adj), Some(6))
}

///|
test "mst_prim_disconnected" {
  let edges : Array[(Int, Int, Int)] = [(0, 1, 1)]
  let adj = build_adj(3, edges[:])
  assert_eq(mst_weight(adj), None)
}
