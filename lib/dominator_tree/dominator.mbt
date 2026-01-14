// ============================================================================
// DOMINATOR TREE - Main Algorithm (Lengauer-Tarjan)
// ============================================================================
//
// This file contains the core dominator computation using the Lengauer-Tarjan
// algorithm. The algorithm computes immediate dominators in near-linear time.
//
// ALGORITHM OVERVIEW:
//   1. DFS from root, number vertices 1..n by discovery order
//   2. Process vertices in REVERSE DFS order (n down to 1)
//   3. For each vertex, compute semi-dominator using union-find
//   4. Use buckets to track vertices with same semi-dominator
//   5. Second pass to finalize immediate dominators
//
// KEY INSIGHT:
//   The semi-dominator sdom[v] is the minimum DFS number reachable from v
//   via a path that goes "up" tree edges then optionally one cross/back edge.
//   This gives us a candidate for the dominator.

///|
/// Compute immediate dominators for all vertices.
///
/// ALGORITHM:
/// ```
///   FOR i = n DOWNTO 1:
///     1. Compute sdom[i] = min { sdom[eval(p)] : p ∈ pred[i] }
///     2. Add i to bucket[sdom[i]]
///     3. Process bucket[parent[i]] to compute tentative idom
///     4. Link parent[i] → i in union-find
///
///   FOR i = 2 TO n:
///     5. Fix idom[i] if it differs from sdom[i]
/// ```
///
/// THE BUCKET TRICK:
/// ```
///   When processing vertex i, bucket[i] contains all vertices v where
///   sdom[v] = i. For each such v, we can compute idom[v] using:
///
///     u = eval(v)  // vertex with min sdom on path v → root
///     if sdom[u] == sdom[v]:
///       idom[v] = sdom[v]  // Semi-dominator IS the dominator
///     else:
///       idom[v] = u        // Need to fix later (idom[v] = idom[u])
/// ```
///
/// WHY REVERSE ORDER:
///   Processing children before parents ensures that when we process i,
///   all descendants are already linked. This makes eval() return the
///   correct minimum semi-dominator on any path.
///
/// PARAMETERS:
///   - self: working data structures (populated by DFS)
///   - root_idx: DFS index of the root vertex
fn DominatorWork::compute_idom(self : DominatorWork, root_idx : Int) -> Unit {
  let n = self.time.val

  // Phase 1: Process vertices in reverse DFS order
  // Compute semi-dominators and tentative immediate dominators
  for i = n; i >= 1; i = i - 1 {
    // Step 1: Compute semi-dominator
    // sdom[i] = min { sdom[eval(p)] : p is a predecessor of i }
    for p in self.pred[i] {
      let u = self.eval(p)
      self.sdom[i] = min(self.sdom[i], self.sdom[u])
    }

    // Step 2: Add to bucket (except for root)
    if i > 1 {
      self.bucket[self.sdom[i]].push(i)
    }

    // Step 3: Process bucket[i] - vertices whose semi-dominator is i
    // At this point, all descendants of i are linked, so eval() works correctly
    for v in self.bucket[i] {
      let u = self.eval(v)
      // If sdom[u] == sdom[v], then sdom[v] is the immediate dominator
      // Otherwise, we'll fix it in phase 2 (idom[v] = idom[u])
      if self.sdom[u] == self.sdom[v] {
        self.idom[v] = self.sdom[v]
      } else {
        self.idom[v] = u
      }
    }

    // Step 4: Link parent[i] → i (activate i for future eval queries)
    if i > 1 {
      self.link(self.parent[i], i)
    }
  } where {
    invariant: i >= 0 && i <= n,
    reasoning: (
      #|INVARIANT (reverse pass):
      #|  For all DFS indices j > i:
      #|    - sdom[j] is correctly computed
      #|    - j is linked to parent[j] in union-find
      #|    - bucket[j] has been processed
      #|    - idom[j] has a tentative value (correct or needs fix)
      #|
      #|MAINTENANCE:
      #|  1. Compute sdom[i] from predecessors (eval works because
      #|     all descendants are already linked)
      #|  2. Add i to appropriate bucket
      #|  3. Process bucket[i] to set tentative idom
      #|  4. Link i to its parent for future queries
      #|
      #|TERMINATION:
      #|  At i = 0 (loop ends at i = 1), all vertices have tentative
      #|  idom values set.
    ),
  }

  // Phase 2: Fix immediate dominators
  // Some idom values point to intermediate vertices; follow the chain
  for i = 2; i <= n; i = i + 1 {
    // If idom[i] was set to u (not sdom[i]), then idom[i] = idom[u]
    if self.idom[i] != self.sdom[i] {
      self.idom[i] = self.idom[self.idom[i]]
    }
  } where {
    invariant: i >= 2 && i <= n + 1,
    reasoning: (
      #|INVARIANT (idom fix):
      #|  For DFS indices in [2..i), idom[j] is the correct
      #|  immediate dominator.
      #|
      #|WHY THIS WORKS:
      #|  If idom[v] was set to u (where u ≠ sdom[v]), then
      #|  u is on the path from v to sdom[v] in the DFS tree,
      #|  and idom[v] = idom[u]. Since we process in increasing
      #|  order, idom[u] is already correct when we process v.
      #|
      #|MAINTENANCE:
      #|  Replace idom[i] with idom[idom[i]] when needed.
      #|
      #|TERMINATION:
      #|  At i = n+1, all idom values are finalized.
    ),
  }

  // Root dominates itself
  self.idom[root_idx] = root_idx
}

///|
/// Build a dominator tree from a directed graph.
///
/// ALGORITHM:
/// ```
///   1. Build adjacency lists from edges
///   2. Run DFS from root to number vertices
///   3. Build predecessor lists (reverse edges)
///   4. Compute immediate dominators (Lengauer-Tarjan)
///   5. Convert DFS-index results back to vertex IDs
///   6. Build dominator tree from idom relation
/// ```
///
/// PARAMETERS:
///   - n: number of vertices (labeled 0..n-1)
///   - edges: directed edges as (source, target) pairs
///   - root: the root vertex
///
/// RETURNS:
///   Some(tree) if root is valid, None otherwise.
///   Unreachable vertices have idom = -1.
///
/// TIME: O((V + E) × α(V)) where α is inverse Ackermann
/// SPACE: O(V + E)
///
/// EXAMPLE:
/// ```
///   edges = [(0,1), (1,2), (1,3), (2,3)]
///   tree = build_dominator_tree(4, edges, 0)
///
///   Result: idom = [0, 0, 1, 1]
///   Meaning: 0 dominates itself, 1's idom is 0, 2's idom is 1, 3's idom is 1
///
///   Dominator tree:
///       0
///       |
///       1
///      / \
///     2   3
/// ```
pub fn build_dominator_tree(
  n : Int,
  edges : ArrayView[(Int, Int)],
  root : Int,
) -> DominatorTree? {
  // Validate input
  if n <= 0 || root < 0 || root >= n {
    return None
  }

  // Step 1: Build graph
  let work = DominatorWork::new(n)
  for i = 0; i < edges.length(); i = i + 1 {
    let (u, v) = edges[i]
    guard u >= 0 && u < n && v >= 0 && v < n else { continue }
    work.add_edge(u, v)
  } where {
    invariant: i >= 0 && i <= edges.length(),
    reasoning: (
      #|INVARIANT (graph build):
      #|  edges[0..i) have been added to adjacency lists.
      #|
      #|MAINTENANCE:
      #|  Add edge (u, v) if both endpoints are in range.
      #|
      #|TERMINATION:
      #|  At i = edges.length(), the graph is complete.
    ),
  }

  // Step 2: DFS to number vertices
  work.dfs(root)
  let root_idx = work.arr[root]
  if root_idx == 0 {
    return None // Root unreachable (shouldn't happen)
  }

  // Step 3: Build predecessors in DFS-index space
  work.build_predecessors(edges)

  // Step 4: Compute immediate dominators
  work.compute_idom(root_idx)

  // Step 5: Convert from DFS indices back to vertex IDs
  let idom_vertex = Array::make(n, -1)
  for i = 1; i <= work.time.val; i = i + 1 {
    let v = work.rev[i] // vertex ID for DFS index i
    let id = work.idom[i] // idom in DFS index
    idom_vertex[v] = work.rev[id] // convert back to vertex ID
  } where {
    invariant: i >= 1 && i <= work.time.val + 1,
    reasoning: (
      #|INVARIANT (index conversion):
      #|  idom_vertex is filled for all vertices with DFS index < i.
      #|
      #|MAINTENANCE:
      #|  Map DFS index i to vertex v, then map idom[i] to vertex ID.
      #|
      #|TERMINATION:
      #|  At i = time+1, all reachable vertices have idom_vertex set.
    ),
  }

  // Step 6: Build dominator tree structure
  let tree = build_adj_lists(n)
  for v = 0; v < n; v = v + 1 {
    let p = idom_vertex[v]
    guard p >= 0 && v != root else { continue }
    tree[p].push(v) // Add edge idom[v] → v
  } where {
    invariant: v >= 0 && v <= n,
    reasoning: (
      #|INVARIANT (tree build):
      #|  Dominator tree edges are added for vertices [0..v).
      #|
      #|MAINTENANCE:
      #|  Add edge from idom[v] to v (except for root and unreachable).
      #|
      #|TERMINATION:
      #|  At v = n, dominator tree is complete.
    ),
  }
  Some({ root, idom: idom_vertex, tree })
}

///|
/// Check if vertex u dominates vertex v.
///
/// ALGORITHM:
///   Walk up from v following idom pointers until we reach u or the root.
///
/// TIME: O(depth of dominator tree)
///
/// PARAMETERS:
///   - self: the dominator tree
///   - u: potential dominator
///   - v: potentially dominated vertex
///
/// RETURNS:
///   true if every path from root to v passes through u
pub fn DominatorTree::dominates(self : DominatorTree, u : Int, v : Int) -> Bool {
  // Bounds check
  if u < 0 || v < 0 || u >= self.idom.length() || v >= self.idom.length() {
    return false
  }

  // Unreachable vertices are not dominated
  if self.idom[v] == -1 {
    return false
  }

  // Walk up the dominator tree from v
  for cur = v; ; {
    if cur == u {
      break true // Found u on the path
    }
    let p = self.idom[cur]
    if p == cur || p < 0 {
      break false // Reached root or unreachable
    }
    continue p
  } where {
    invariant: cur >= 0 && cur < self.idom.length(),
    reasoning: (
      #|INVARIANT (dominator walk):
      #|cur is on the path from v toward the root in the dominator tree.
      #|MAINTENANCE:
      #|Move to parent in dominator tree.
      #|TERMINATION:
      #|Either find u, or reach root (idom[root] == root) or unreachable.
    ),
  }
}
