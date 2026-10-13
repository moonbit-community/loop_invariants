// ============================================================================
// Challenge: Bipartite Matching (Kuhn DFS)
// ============================================================================

///|
/// Build adjacency from left to right (u in [0,left_n), v in [0,right_n)).
pub fn build_adj(
  left_n : Int32,
  right_n : Int32,
  edges : ArrayView[(Int32, Int32)],
) -> Array[Array[Int32]] {
  let adj : Array[Array[Int32]] = [ for _ in 0..<left_n => [] ]
  for edge in edges {
    let (u, v) = edge
    if u >= 0 && u < left_n && v >= 0 && v < right_n {
      adj[u].push(v)
    }
  }
  adj
}

///|
fn try_kuhn(
  u : Int32,
  adj : Array[Array[Int32]],
  seen : Array[Bool],
  match_r : Array[Int32],
) -> Bool {
  let neighbors = adj[u]
  let right_n = match_r.length()
  for v in neighbors {
    if v < 0 || v >= right_n {
      continue
    }
    if !seen[v] {
      seen[v] = true
      let m = match_r[v]
      if m == -1 || try_kuhn(m, adj, seen, match_r) {
        match_r[v] = u
        return true
      }
    }
  }
  false
}

///|
/// Maximum bipartite matching size.
pub fn max_matching(adj : Array[Array[Int32]], right_n : Int32) -> Int32 {
  let left_n = adj.length()
  let match_r = Array::make(right_n, -1)
  for u in 0..<left_n; matched = 0 {
    let seen = Array::make(right_n, false)
    if try_kuhn(u, adj, seen, match_r) {
      continue matched + 1
    } else {
      continue matched
    }
  } nobreak {
    matched
  }
}

///|
test "max_matching" {
  let adj = build_adj(3, 3, [(0, 0), (0, 1), (1, 1), (1, 2), (2, 2)])
  @debug.assert_eq(max_matching(adj, 3), 3)
}
