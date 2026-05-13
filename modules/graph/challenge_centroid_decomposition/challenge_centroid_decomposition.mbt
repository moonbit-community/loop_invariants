// ============================================================================
// Challenge: Centroid Decomposition
// ============================================================================

///|
fn build_adj(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Array[Int]] {
  let adj = [ for _ in 0..<n => [] ]
  for edge in edges {
    let (u, v) = edge
    adj[u].push(v)
    adj[v].push(u)
  }
  adj
}

///|
fn dfs_size(
  u : Int,
  p : Int,
  adj : Array[Array[Int]],
  removed : Array[Bool],
  sub : Array[Int],
) -> Int {
  let size = adj[u].fold(init=1, (size, v) => {
    if v != p && !removed[v] {
      size + dfs_size(v, u, adj, removed, sub)
    } else {
      size
    }
  })
  sub[u] = size
  size
}

///|
fn find_centroid(
  u : Int,
  p : Int,
  total : Int,
  adj : Array[Array[Int]],
  removed : Array[Bool],
  sub : Array[Int],
) -> Int {
  for v in adj[u] {
    if v != p && !removed[v] && sub[v] > total / 2 {
      return find_centroid(v, u, total, adj, removed, sub)
    }
  }
  u
}

///|
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
  for v in adj[c] {
    if !removed[v] {
      decompose(v, c, depth + 1, adj, removed, sub, parent, level)
    }
  }
}

///|
/// The centroid decomposition of a tree.
///
/// The centroid decomposition repeatedly removes a centroid (a node whose
/// removal leaves every remaining component of size at most `n/2`) and
/// recurses on the resulting subtrees. The removed centroids form a new tree
/// of height `O(log n)`. The struct stores two parallel arrays:
///
/// - `parent[v]`: centroid-tree parent of `v` (or `-1` for the root).
/// - `level[v]`: depth of `v` in the centroid tree (root is `0`).
///
/// Construct it with `build_centroid(n, edges)`; the build cost is
/// `O(n log n)`.
///
/// Example:
/// ```moonbit nocheck
/// test {
///   let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4)]
///   let cd = build_centroid(5, edges[:])
///   @debug.assert_eq(cd.parent[2], -1)
///   @debug.assert_eq(cd.level[2], 0)
/// }
/// ```
pub struct CentroidDecomp {
  parent : Array[Int]
  level : Array[Int]
}

///|
/// Build centroid decomposition and return parent/level arrays.
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
