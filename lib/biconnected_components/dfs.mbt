// ============================================================================
// BICONNECTED COMPONENTS - Tarjan's DFS Algorithm
// ============================================================================
//
// The core DFS-based algorithm for finding biconnected components.
//
// ALGORITHM OVERVIEW:
// ```
//   1. DFS the graph, computing disc[u] and low[u] for each vertex.
//   2. Push each traversed edge onto a stack.
//   3. When returning from a tree child v of u and low[v] >= disc[u]:
//      - Pop edges from the stack until edge (u,v) is popped.
//      - The popped edges form one biconnected component.
//      - Mark u as an articulation point (with a special case for the root).
// ```
//
// WHY THE EDGE STACK WORKS:
// ```
//   All edges pushed after (u,v) were discovered inside v's DFS subtree.
//   Because low[v] >= disc[u], none of those edges has a back edge that
//   escapes above u. They are therefore all confined to the same block.
//   Popping down to and including (u,v) collects exactly that block.
// ```
//
// ARTICULATION POINT DETECTION:
// ```
//   Non-root vertex u is an articulation point when it has at least one
//   tree child v satisfying low[v] >= disc[u].
//
//   Root vertex u is an articulation point only when it has >= 2 DFS
//   children. (The root has no ancestor, so back edges from its subtrees
//   cannot reconnect them through the root itself.)
// ```

///|
/// Perform a DFS from vertex `u`, computing low-link values and extracting
/// biconnected components as they are completed.
///
/// This implements the core of Tarjan's biconnected component algorithm.
/// The function is called once for every unvisited vertex by `run`, which
/// handles disconnected graphs by looping over all vertices.
///
/// Parameters:
/// - `self`: the shared mutable finder state (disc, low, stacks, etc.)
/// - `u`: the vertex to visit; must satisfy `self.disc[u] == -1` on entry
/// - `p_edge`: the edge ID used to arrive at `u` (`-1` for the DFS root);
///   edges with this ID are skipped to avoid immediately reversing the tree
///
/// Side effects (all stored in `self`):
/// - `disc[u]` and `low[u]` are set for every visited vertex.
/// - Edges are pushed to `self.edge_stack` during traversal and popped into
///   `self.components` when a block boundary is detected.
/// - `self.articulation[u]` is set to `true` when `u` qualifies as an
///   articulation point.
///
/// Low-link update rules applied inside this function:
/// ```
///   Tree edge (u -> v, unvisited v):
///     push (u,v); recurse; low[u] = min(low[u], low[v])
///     if low[v] >= disc[u]: extract block, maybe mark u as AP
///
///   Back edge (u -> w, already visited, disc[w] < disc[u]):
///     push (u,w); low[u] = min(low[u], disc[w])
///
///   Forward/cross edges (disc[w] > disc[u]): skip
///     (these are already-handled tree descendants; no update needed)
/// ```
fn BiconnectedFinder::dfs(
  self : BiconnectedFinder,
  u : Int,
  p_edge : Int,
) -> Unit {
  // Assign discovery time
  self.disc[u] = self.timer
  self.low[u] = self.timer
  self.timer = self.timer + 1
  self.parent_edge[u] = p_edge
  let children = for i in 0..<self.adj[u].length(); children = 0 {
    let (v, eid) = self.adj[u][i]

    // Skip the parent edge (don't go back immediately)
    guard eid != p_edge else { continue children }
    if self.disc[v] == -1 {
      // Case 1: Tree edge - v is unvisited
      self.edge_stack.push((u, v))
      self.dfs(v, eid)

      // Update low-link from child
      self.low[u] = min(self.low[u], self.low[v])

      // Articulation point check (non-root):
      // v's subtree cannot reach above u, so removing u disconnects v.
      if p_edge != -1 && self.low[v] >= self.disc[u] {
        self.articulation[u] = true
      }

      // Component extraction:
      // All edges pushed since (u,v) belong to one biconnected component.
      if self.low[v] >= self.disc[u] {
        let comp : Array[(Int, Int)] = []
        for ;; {
          match self.edge_stack.pop() {
            Some(e) => {
              comp.push(e)
              if e == (u, v) || e == (v, u) {
                break
              }
            }
            None => break
          }
        } where {
          proof_invariant: comp.length() + self.edge_stack.length() >= 0,
          proof_reasoning: (
            #|INVARIANT (component extraction):
            #|  comp contains edges popped from stack, which are exactly
            #|  the edges in the biconnected component bounded by (u,v).
            #|
            #|WHY THIS WORKS:
            #|  All edges pushed after (u,v) were discovered in v's subtree.
            #|  Since low[v] >= disc[u], these edges can't escape above u.
            #|  They form a maximal biconnected subgraph.
            #|
            #|MAINTENANCE:
            #|  Pop one edge per iteration.
            #|
            #|TERMINATION:
            #|  Stop when we pop (u,v), the boundary edge.
          ),
        }
        if comp.length() > 0 {
          self.components.push(comp)
        }
      }
      continue children + 1
    } else if self.disc[v] < self.disc[u] {
      // Case 2: Back edge - v is a proper ancestor of u.
      // Only process edges going strictly upward (disc[v] < disc[u]) to
      // avoid double-counting each undirected edge.
      self.edge_stack.push((u, v))
      self.low[u] = min(self.low[u], self.disc[v])
      continue children
    } else {
      continue children
    }
  } nobreak {
    children
  }

  // Root articulation check:
  // The DFS root is an articulation point iff it has >= 2 DFS children.
  // With one child, removing the root still leaves the rest connected.
  if p_edge == -1 && children > 1 {
    self.articulation[u] = true
  }
}

///|
/// Run the DFS on every connected component of the graph.
///
/// Iterates over all vertices and calls `dfs` for each unvisited vertex,
/// treating it as the root of its connected component. This ensures that
/// disconnected graphs are handled correctly: each connected component is
/// explored independently and contributes its own set of blocks.
fn BiconnectedFinder::run(self : BiconnectedFinder) -> Unit {
  for v in 0..<self.n {
    if self.disc[v] == -1 {
      self.dfs(v, -1)
    }
  }
}

///|
/// Collect and return all articulation points found during the DFS.
///
/// Scans the `articulation` boolean array and returns the indices of all
/// vertices marked as articulation points, in ascending vertex order.
/// The result array may be empty if the graph has no articulation points
/// (e.g., a single cycle or an empty graph).
fn BiconnectedFinder::collect_articulation_points(
  self : BiconnectedFinder,
) -> Array[Int] {
  let result : Array[Int] = [|
    for i in 0..<self.n if self.articulation[i] => i
  |]
  result
}
