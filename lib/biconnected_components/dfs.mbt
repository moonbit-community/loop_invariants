// ============================================================================
// BICONNECTED COMPONENTS - Tarjan's DFS Algorithm
// ============================================================================
//
// The core DFS-based algorithm for finding biconnected components.
//
// ALGORITHM OVERVIEW:
// ```
//   1. DFS the graph, computing disc[u] and low[u] for each vertex
//   2. Push edges onto a stack as we traverse
//   3. When low[v] >= disc[u] for tree edge (u,v):
//      - Pop edges from stack until (u,v) → one biconnected component
//      - Mark u as articulation point (with special case for root)
// ```
//
// ARTICULATION POINT DETECTION:
// ```
//   For non-root vertex u with tree child v:
//     If low[v] >= disc[u], then u is an articulation point.
//     Reason: v's subtree has no back edge going above u.
//
//   For root vertex:
//     Root is articulation point iff it has >= 2 DFS children.
//     Reason: root has no ancestor, so back edges don't help.
// ```
//
// COMPONENT EXTRACTION:
// ```
//   When we detect low[v] >= disc[u]:
//     All edges pushed after (u,v) belong to the same block.
//     Pop until we see (u,v) → that's one biconnected component.
//
//   Example DFS on triangle 0-1-2-0:
//     Push (0,1), push (1,2), see back edge (2,0) updates low
//     When returning to 0: low[1] = 0 < disc[0], no split
//     Continue... eventually extract {(0,1), (1,2), (2,0)}
// ```

///|
/// DFS from vertex u, computing disc/low and extracting components.
///
/// ALGORITHM:
/// ```
///   1. Assign discovery time disc[u] = timer++
///   2. Initialize low[u] = disc[u]
///   3. For each neighbor v:
///      - If unvisited (tree edge):
///        * Push (u,v) to stack
///        * Recurse on v
///        * Update low[u] = min(low[u], low[v])
///        * If low[v] >= disc[u]: extract component, mark articulation
///      - If visited and disc[v] < disc[u] (back edge):
///        * Push (u,v) to stack
///        * Update low[u] = min(low[u], disc[v])
///   4. Special root check: articulation if >= 2 children
/// ```
///
/// PARAMETERS:
///   - self: the finder state
///   - u: current vertex
///   - p_edge: parent edge ID (-1 for root)
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
  let children = for i = 0, children = 0; i < self.adj[u].length(); {
    let (v, eid) = self.adj[u][i]

    // Skip the parent edge (don't go back immediately)
    guard eid != p_edge else { continue i + 1, children }
    if self.disc[v] == -1 {
      // Case 1: Tree edge - v is unvisited
      self.edge_stack.push((u, v))
      self.dfs(v, eid)

      // Update low-link from child
      self.low[u] = min(self.low[u], self.low[v])

      // Articulation point check (non-root)
      // If v's subtree can't reach above u, u is critical
      if p_edge != -1 && self.low[v] >= self.disc[u] {
        self.articulation[u] = true
      }

      // Component extraction
      // When low[v] >= disc[u], edges from (u,v) to stack top form a block
      if self.low[v] >= self.disc[u] {
        let comp : Array[(Int, Int)] = []
        for {
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
          invariant: comp.length() + self.edge_stack.length() >= 0,
          reasoning: (
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
      continue i + 1, children + 1
    } else if self.disc[v] < self.disc[u] {
      // Case 2: Back edge - v is ancestor of u
      // Only process if disc[v] < disc[u] to avoid duplicate processing
      self.edge_stack.push((u, v))
      self.low[u] = min(self.low[u], self.disc[v])
      continue i + 1, children
    } else {
      continue i + 1, children
    }
  } else {
    children
  } where {
    invariant: i >= 0 && i <= self.adj[u].length(),
    reasoning: (
      #|INVARIANT (neighbor processing):
      #|  Neighbors adj[u][0..i) are fully processed.
      #|  low[u] reflects minimum reachable disc through those neighbors.
      #|  edge_stack contains edges not yet assigned to components.
      #|
      #|LOW-LINK UPDATE RULES:
      #|  - Tree edge (u,v): low[u] = min(low[u], low[v])
      #|    Because v's reachable ancestors are also u's.
      #|  - Back edge (u,w): low[u] = min(low[u], disc[w])
      #|    Because we can reach w directly.
      #|
      #|MAINTENANCE:
      #|  Process adj[u][i], updating low and extracting components.
      #|
      #|TERMINATION:
      #|  At i = deg(u), all neighbors processed.
    ),
  }

  // Root articulation check
  // Root is articulation iff it has >= 2 children in DFS tree
  if p_edge == -1 && children > 1 {
    self.articulation[u] = true
  }
}

///|
/// Run DFS on all connected components.
fn BiconnectedFinder::run(self : BiconnectedFinder) -> Unit {
  for v = 0; v < self.n; v = v + 1 {
    if self.disc[v] == -1 {
      self.dfs(v, -1)
    }
  } where {
    invariant: v >= 0 && v <= self.n,
    reasoning: (
      #|INVARIANT (component coverage):
      #|  Vertices [0..v) are fully processed.
      #|  All biconnected components involving only those vertices
      #|  have been extracted.
      #|
      #|MAINTENANCE:
      #|  If v is unvisited, start DFS to cover its connected component.
      #|
      #|TERMINATION:
      #|  At v = n, entire graph processed.
    ),
  }
}

///|
/// Collect all articulation points.
fn BiconnectedFinder::collect_articulation_points(
  self : BiconnectedFinder,
) -> Array[Int] {
  let result : Array[Int] = []
  for i = 0; i < self.n; i = i + 1 {
    if self.articulation[i] {
      result.push(i)
    }
  } where {
    invariant: i >= 0 && i <= self.n,
    reasoning: (
      #|INVARIANT (AP collection):
      #|  result contains articulation points from vertices [0..i).
      #|
      #|MAINTENANCE:
      #|  If articulation[i], append i.
      #|
      #|TERMINATION:
      #|  At i = n, all articulation points collected.
    ),
  }
  result
}
