// ============================================================================
// DSU ON TREE (SMALL-TO-LARGE) - Subtree mode sum
// ============================================================================
//
// For each node, compute the sum of colors that achieve the maximum
// frequency inside its subtree.
//
// The algorithm keeps a global frequency structure. For each node u:
// - process all light children with keep=false (their data is discarded)
// - process heavy child with keep=true (its data is kept)
// - add all light subtrees and u itself into the current structure
// - record the answer for u
// - if keep=false, clear the structure (it contains exactly subtree u)
//
// TIME COMPLEXITY: O(n log n) with Map-based counts
// SPACE COMPLEXITY: O(n)

///|
const NO_CHILD : Int = -1

///|
/// Compute subtree sizes, heavy child, and Euler tour ranges.
fn dfs_sizes(
  adj : Array[Array[Int]],
  u : Int,
  p : Int,
  parent : Array[Int],
  size : Array[Int],
  heavy : Array[Int],
  tin : Array[Int],
  tout : Array[Int],
  euler : Array[Int],
  timer : Int,
) -> Int {
  parent[u] = p
  tin[u] = timer
  euler[timer] = u
  let mut t = timer + 1
  size[u] = 1
  let mut best_size = 0
  for v in adj[u] {
    if v == p {
      continue
    }
    t = dfs_sizes(adj, v, u, parent, size, heavy, tin, tout, euler, t)
    size[u] = size[u] + size[v]
    if size[v] > best_size {
      best_size = size[v]
      heavy[u] = v
    }
  }
  tout[u] = t
  t
}

///|
/// Return the sum of colors that appear most frequently in each subtree.
/// Root can be overridden with `root` (default 0).
pub fn subtree_color_mode_sum(
  adj : Array[Array[Int]],
  colors : Array[Int],
  root? : Int = 0,
) -> Array[Int64] {
  let n = adj.length()
  if n == 0 {
    return []
  }
  let parent = Array::make(n, -1)
  let size = Array::make(n, 0)
  let heavy = Array::make(n, NO_CHILD)
  let tin = Array::make(n, 0)
  let tout = Array::make(n, 0)
  let euler = Array::make(n, 0)
  let _ = dfs_sizes(
    adj,
    root,
    NO_CHILD,
    parent,
    size,
    heavy,
    tin,
    tout,
    euler,
    0,
  )
  let counts : Map[Int, Int] = Map::new()
  let max_freq : Ref[Int] = { val: 0 }
  let sum_ref : Ref[Int64] = { val: 0L }
  let result : Array[Int64] = Array::make(n, 0L)
  fn add_color(
    counts : Map[Int, Int],
    max_freq : Ref[Int],
    sum_ref : Ref[Int64],
    color : Int,
  ) -> Unit {
    let prev = counts.get_or_default(color, 0)
    let next = prev + 1
    counts.set(color, next)
    if next > max_freq.val {
      max_freq.val = next
      sum_ref.val = color.to_int64()
    } else if next == max_freq.val {
      sum_ref.val = sum_ref.val + color.to_int64()
    }
  }

  fn add_subtree(
    counts : Map[Int, Int],
    max_freq : Ref[Int],
    sum_ref : Ref[Int64],
    colors : Array[Int],
    tin : Array[Int],
    tout : Array[Int],
    euler : Array[Int],
    u : Int,
  ) -> Unit {
    // Euler interval [tin[u], tout[u]) enumerates exactly the subtree of u.
    for idx in tin[u]..<tout[u] {
      let node = euler[idx]
      add_color(counts, max_freq, sum_ref, colors[node])
    }
  }

  fn dfs_dsu(
    adj : Array[Array[Int]],
    colors : Array[Int],
    heavy : Array[Int],
    tin : Array[Int],
    tout : Array[Int],
    euler : Array[Int],
    counts : Map[Int, Int],
    max_freq : Ref[Int],
    sum_ref : Ref[Int64],
    result : Array[Int64],
    u : Int,
    p : Int,
    keep : Bool,
  ) -> Unit {
    for v in adj[u] {
      if v == p || v == heavy[u] {
        continue
      }
      dfs_dsu(
        adj, colors, heavy, tin, tout, euler, counts, max_freq, sum_ref, result,
        v, u, false,
      )
    }
    // Keep the heavy subtree contributions to avoid repeated rebuild work.
    if heavy[u] != NO_CHILD {
      dfs_dsu(
        adj,
        colors,
        heavy,
        tin,
        tout,
        euler,
        counts,
        max_freq,
        sum_ref,
        result,
        heavy[u],
        u,
        true,
      )
    }
    for v in adj[u] {
      if v == p || v == heavy[u] {
        continue
      }
      add_subtree(counts, max_freq, sum_ref, colors, tin, tout, euler, v)
    }
    // Now counts represent exactly the subtree of u.
    add_color(counts, max_freq, sum_ref, colors[u])
    result[u] = sum_ref.val
    if not(keep) {
      counts.clear()
      max_freq.val = 0
      sum_ref.val = 0L
    }
  }

  dfs_dsu(
    adj,
    colors,
    heavy,
    tin,
    tout,
    euler,
    counts,
    max_freq,
    sum_ref,
    result,
    root,
    NO_CHILD,
    false,
  )
  result
}

// ============================================================================
// TESTS
// ============================================================================

///|
fn make_adj(n : Int) -> Array[Array[Int]] {
  Array::makei(n, _ => [])
}

///|
test "dsu on tree mode sum" {
  let adj = make_adj(5)
  adj[0].push(1)
  adj[1].push(0)
  adj[0].push(2)
  adj[2].push(0)
  adj[1].push(3)
  adj[3].push(1)
  adj[1].push(4)
  adj[4].push(1)
  let colors : Array[Int] = [1, 2, 1, 2, 3]
  let result = subtree_color_mode_sum(adj, colors)
  inspect(result, content="[3, 2, 1, 2, 3]")
}

///|
test "dsu on tree tie case" {
  let adj = make_adj(3)
  adj[0].push(1)
  adj[1].push(0)
  adj[1].push(2)
  adj[2].push(1)
  let colors : Array[Int] = [5, 5, 7]
  let result = subtree_color_mode_sum(adj, colors)
  inspect(result, content="[5, 12, 7]")
}
