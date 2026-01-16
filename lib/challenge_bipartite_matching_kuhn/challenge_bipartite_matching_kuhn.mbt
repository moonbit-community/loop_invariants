// ============================================================================
// Challenge: Bipartite Matching (Kuhn DFS)
// ============================================================================

///|
/// Build adjacency from left to right (u in [0,left_n), v in [0,right_n)).
#warnings("+missing_invariant+missing_reasoning")
pub fn build_adj(
  left_n : Int,
  right_n : Int,
  edges : ArrayView[(Int, Int)],
) -> Array[Array[Int]] {
  let adj : Array[Array[Int]] = Array::makei(left_n, _ => [])
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
  u : Int,
  adj : Array[Array[Int]],
  seen : Array[Bool],
  match_r : Array[Int],
) -> Bool {
  let neighbors = adj[u]
  let right_n = match_r.length()
  for i = 0; i < neighbors.length(); i = i + 1 {
    let v = neighbors[i]
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
  } where {
    invariant: i >= 0 && i <= neighbors.length(),
    reasoning: (
      #|INVARIANT (Augmenting DFS):
      #|All neighbors[0..i) have been tried for an augmenting path from u.
      #|MAINTENANCE:
      #|Explore unmatched or re-routed matches via recursion.
      #|TERMINATION:
      #|If a path is found, return true; otherwise all options are exhausted.
    ),
  }
  false
}

///|
/// Maximum bipartite matching size.
#warnings("+missing_invariant+missing_reasoning")
pub fn max_matching(adj : Array[Array[Int]], right_n : Int) -> Int {
  let left_n = adj.length()
  let match_r = Array::make(right_n, -1)
  for u = 0, matched = 0; u < left_n; {
    let seen = Array::make(right_n, false)
    let new_matched = if try_kuhn(u, adj, seen, match_r) {
      matched + 1
    } else {
      matched
    }
    continue u + 1, new_matched
  } else {
    matched
  } where {
    invariant: u >= 0 && u <= left_n,
    reasoning: (
      #|INVARIANT (Kuhn outer loop):
      #|matched equals the size of the matching after processing nodes < u.
      #|MAINTENANCE:
      #|Find an augmenting path from u and update matching if possible.
      #|TERMINATION:
      #|At u = left_n, matched is the maximum matching size.
    ),
  }
}
