// ============================================================================
// DSU ON TREE (SMALL-TO-LARGE) - Subtree mode sum
// ============================================================================
//
// For each node u in a rooted tree, compute the sum of all color identifiers
// that achieve the maximum frequency inside subtree(u).
//
// Algorithm (post-order DFS, "keep heavy child"):
//   1. For each light child v of u: recurse with keep=false.
//      The data structure is cleared after the call returns.
//   2. For the heavy child h of u (if any): recurse with keep=true.
//      The data structure retains subtree(h)'s contribution.
//   3. Walk every light subtree and node u itself, inserting colors.
//      After this step the data structure represents exactly subtree(u).
//   4. Record result[u] from the current data-structure state.
//   5. If keep=false, clear the data structure.
//
// Correctness: Step 3 uses the Euler-tour range [tin[v], tout[v]) to iterate
// over subtree(v) without a second recursion, which keeps the code simple and
// makes the amortized cost analysis straightforward.
//
// Complexity:
//   TIME  O(n log n) — each node is inserted at most O(log n) times,
//                      once per light-edge ancestor on its root-to-node path.
//   SPACE O(n)       — the global Map plus the DFS call stack.

///|
/// Sentinel indicating "no child" in the heavy-child array.
const NO_CHILD : Int = -1

///|
/// Compute subtree sizes, heavy children, and Euler-tour entry/exit times in a
/// single post-order DFS.
///
/// After the call:
/// - `parent[u]` is the parent of u in the rooted DFS tree (`NO_CHILD` for
///   the root).
/// - `size[u]` is the number of nodes in subtree(u), including u itself.
/// - `heavy[u]` is the child of u with the largest subtree size, or `NO_CHILD`
///   if u is a leaf.  Ties are broken in favor of the child seen later in the
///   adjacency list.
/// - `tin[u]` is the DFS entry time of u (0-based pre-order index).
/// - `tout[u]` is the DFS exit time of u, exclusive: the open interval
///   `[tin[u], tout[u])` contains the DFS times of all nodes in subtree(u).
/// - `euler[t]` is the node whose DFS entry time is t (i.e. the pre-order
///   sequence).
///
/// Returns the next available timer value after finishing subtree(u).
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
  size[u] = 1
  let (t, _) = for v in adj[u]; t = timer + 1, best_size = 0 {
    if v == p {
      continue
    }
    let t = dfs_sizes(adj, v, u, parent, size, heavy, tin, tout, euler, t)
    size[u] = size[u] + size[v]
    let best_size = if size[v] > best_size {
      heavy[u] = v
      size[v]
    } else {
      best_size
    }
    continue t, best_size
  } nobreak {
    (t, best_size)
  }
  tout[u] = t
  t
}

///|
/// For each node in the tree, return the sum of all color identifiers that
/// appear with the maximum frequency in that node's subtree.
///
/// Parameters:
/// - `adj`    — undirected adjacency list; `adj[u]` lists all neighbors of u.
///              The tree must be connected with exactly n-1 edges.
/// - `colors` — `colors[u]` is the non-negative integer color of node u.
/// - `root`   — optional root node (default 0).  Any node is a valid root.
///
/// Returns an array `result` of length n where `result[u]` is the mode sum
/// for subtree(u) when the tree is rooted at `root`.
///
/// **Mode sum definition**: Let `freq` be the frequency map of colors in
/// subtree(u), and let `M = max(freq.values())`.  Then
///   `result[u] = sum of c for all c with freq[c] == M`.
///
/// If multiple colors tie for the maximum frequency, their identifiers are all
/// summed.  For a leaf node u the result is simply `colors[u]`.
///
/// **Complexity**: O(n log n) time, O(n) space.
///
/// Example — star graph with root 0, colors [1,2,1,2,3]:
/// ```
///       0(1)
///      /|\
///   1(2) 2(1) 3(2)   <- three light children
///    |
///   4(3)
/// ```
/// subtree(1) contains colors {2,1,2,3}: color 2 has freq 2, so result[1]=2.
/// subtree(0) contains all colors {1,2,1,2,3}: colors 1 and 2 both have
///   freq 2, so result[0] = 1+2 = 3.
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
  // Global data structure shared across the entire DSU-on-tree DFS.
  // counts   : color -> frequency in the current accumulated subtree
  // max_freq : maximum frequency seen so far
  // sum_ref  : sum of all colors achieving max_freq
  let counts : Map[Int, Int] = Map([])
  let max_freq : Ref[Int] = { val: 0 }
  let sum_ref : Ref[Int64] = { val: 0L }
  let result : Array[Int64] = Array::make(n, 0L)
  // Insert a single color into the global data structure, updating max_freq
  // and sum_ref as needed.
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
      // New maximum: only this color achieves it.
      max_freq.val = next
      sum_ref.val = color.to_int64()
    } else if next == max_freq.val {
      // Tied for maximum: add color to the running sum.
      sum_ref.val = sum_ref.val + color.to_int64()
    }
  }

  // Insert all nodes in subtree(u) into the global data structure using the
  // pre-computed Euler-tour range [tin[u], tout[u]).  This avoids a recursive
  // walk and keeps the cost proportional to subtree size.
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

  // Post-order DFS that implements the "keep heavy child" strategy.
  //
  // Invariant on entry: the global data structure is either empty (first call
  // or after a clear) or contains exactly the colors of subtree(heavy[parent])
  // when called for the heavy child.
  //
  // Invariant on exit (keep=true): the data structure contains exactly the
  // colors of subtree(u).
  //
  // Invariant on exit (keep=false): the data structure is empty.
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
    // Step 1: recurse into light children with keep=false so their data is
    // discarded before we start accumulating for this subtree.
    for v in adj[u] {
      if v == p || v == heavy[u] {
        continue
      }
      dfs_dsu(
        adj, colors, heavy, tin, tout, euler, counts, max_freq, sum_ref, result,
        v, u, false,
      )
    }
    // Step 2: recurse into the heavy child with keep=true so its accumulated
    // data remains in the global structure when we return.
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
    // Step 3: add light subtrees and node u into the global structure.
    // After this loop the structure contains exactly subtree(u).
    for v in adj[u] {
      if v == p || v == heavy[u] {
        continue
      }
      add_subtree(counts, max_freq, sum_ref, colors, tin, tout, euler, v)
    }
    // Now counts represent exactly the subtree of u.
    add_color(counts, max_freq, sum_ref, colors[u])
    // Step 4: record the answer for u.
    result[u] = sum_ref.val
    // Step 5: if the parent does not want to reuse our data, reset the global
    // structure to empty so the next sibling or parent starts clean.
    if !keep {
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
  [
    for _ in 0..<n => []
  ]
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

///|
test "dsu on tree keeps carried state when parent edge is skipped" {
  let adj = make_adj(4)
  adj[1].push(2)
  adj[2].push(1)
  adj[0].push(1)
  adj[1].push(0)
  adj[1].push(3)
  adj[3].push(1)
  let colors : Array[Int] = [1, 2, 2, 3]
  let result = subtree_color_mode_sum(adj, colors)
  inspect(result, content="[2, 2, 2, 3]")
}
