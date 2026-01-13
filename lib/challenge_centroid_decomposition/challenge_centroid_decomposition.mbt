// ============================================================================
// Challenge: Centroid Decomposition
// ============================================================================

///|
fn build_adj(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Array[Int]] {
  let adj = Array::makei(n, fn(_) { [] })
  for i = 0; i < edges.length(); i = i + 1 {
    let (u, v) = edges[i]
    adj[u].push(v)
    adj[v].push(u)
  } where {
    invariant: i >= 0 && i <= edges.length(),
    reasoning: (
      #|INVARIANT (adjacency build):
      #|All edges in edges[0..i) are added to adj.
      #|MAINTENANCE:
      #|Insert both directions for the next edge.
      #|TERMINATION:
      #|At i = edges.length(), the adjacency list is complete.
    ),
  }
  adj
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn dfs_size(
  u : Int,
  p : Int,
  adj : Array[Array[Int]],
  removed : Array[Bool],
  sub : Array[Int],
) -> Int {
  let mut size = 1
  for i = 0; i < adj[u].length(); i = i + 1 {
    let v = adj[u][i]
    if v != p && !removed[v] {
      size = size + dfs_size(v, u, adj, removed, sub)
    }
  } where {
    invariant: i >= 0 && i <= adj[u].length(),
    reasoning: (
      #|INVARIANT (subtree size):
      #|size equals 1 plus the sizes of processed child subtrees of u.
      #|MAINTENANCE:
      #|For each eligible neighbor, add its subtree size.
      #|TERMINATION:
      #|At i = adj[u].length(), size is the full subtree size of u.
    ),
  }
  sub[u] = size
  size
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn find_centroid(
  u : Int,
  p : Int,
  total : Int,
  adj : Array[Array[Int]],
  removed : Array[Bool],
  sub : Array[Int],
) -> Int {
  for i = 0; i < adj[u].length(); i = i + 1 {
    let v = adj[u][i]
    if v != p && !removed[v] && sub[v] > total / 2 {
      return find_centroid(v, u, total, adj, removed, sub)
    }
  } where {
    invariant: i >= 0 && i <= adj[u].length(),
    reasoning: (
      #|INVARIANT (centroid search):
      #|Among processed neighbors, none has subtree size > total/2, so the
      #|centroid cannot lie there.
      #|MAINTENANCE:
      #|If a heavy child is found, recurse into it immediately.
      #|TERMINATION:
      #|If no heavy child exists, u is the centroid.
    ),
  }
  u
}

///|
#warnings("+missing_invariant+missing_reasoning")
fn decompose(
  u : Int,
  p : Int,
  depth : Int,
  adj : Array[Array[Int]],
  removed : Array[Bool],
  sub : Array[Int],
  parent : Array[Int],
  level : Array[Int],
) -> Unit {
  let total = dfs_size(u, -1, adj, removed, sub)
  let c = find_centroid(u, -1, total, adj, removed, sub)
  parent[c] = p
  level[c] = depth
  removed[c] = true
  for i = 0; i < adj[c].length(); i = i + 1 {
    let v = adj[c][i]
    if !removed[v] {
      decompose(v, c, depth + 1, adj, removed, sub, parent, level)
    }
  } where {
    invariant: i >= 0 && i <= adj[c].length(),
    reasoning: (
      #|INVARIANT (centroid children):
      #|Neighbors processed so far have been decomposed with c as their centroid
      #|parent.
      #|MAINTENANCE:
      #|Recurse into each remaining component after removing c.
      #|TERMINATION:
      #|At i = adj[c].length(), all components are decomposed.
    ),
  }
}

///|
pub struct CentroidDecomp {
  parent : Array[Int]
  level : Array[Int]
}

///|
/// Build centroid decomposition and return parent/level arrays.
#warnings("+missing_invariant+missing_reasoning")
pub fn build_centroid(n : Int, edges : ArrayView[(Int, Int)]) -> CentroidDecomp {
  let adj = build_adj(n, edges)
  let removed = Array::make(n, false)
  let sub = Array::make(n, 0)
  let parent = Array::make(n, -1)
  let level = Array::make(n, 0)
  if n > 0 {
    decompose(0, -1, 0, adj, removed, sub, parent, level)
  }
  { parent, level }
}
