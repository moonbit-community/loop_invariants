// ============================================================================
// EDMONDS' ARBORESCENCE - Main Algorithm (Chu-Liu/Edmonds)
// ============================================================================
//
// The Chu-Liu/Edmonds algorithm finds a minimum-cost arborescence (directed
// spanning tree) rooted at a specified vertex. Every vertex except root must
// have exactly one incoming edge, and all vertices must be reachable from root.
//
// ALGORITHM OVERVIEW:
// ```
//   1. GREEDY SELECTION:
//      For each vertex v ≠ root, pick the cheapest incoming edge.
//
//   2. CYCLE CHECK:
//      If selected edges form no cycle → done! This is optimal.
//
//   3. CYCLE CONTRACTION (the clever part):
//      - Contract each cycle into a single supernode
//      - Adjust weights: w'(u→v) = w(u→v) - in_cost[v] for v in cycle
//      - This "pre-pays" the cycle cost and charges only the extra cost
//        to break the cycle
//
//   4. RECURSE:
//      Solve on contracted graph
//
//   5. EXPAND:
//      Map solution back to original graph
// ```
//
// WHY CONTRACTION PRESERVES OPTIMALITY:
// ```
//   When a cycle forms, we MUST use all but one edge of the cycle.
//   Say the cycle has edges with costs c1, c2, c3.
//
//   If we use external edge e entering at position 2:
//     Total cycle contribution = c1 + c3 (not c2)
//     = (c1 + c2 + c3) - c2
//     = cycle_cost - in_cost[2]
//
//   By subtracting in_cost[v] from edges entering v, we normalize:
//     Choosing edge e gives extra cost = w(e) - in_cost[dest(e)]
//   This extra cost is what the contracted graph optimizes.
// ```
//
// TIME COMPLEXITY: O(V × E) - each recursion level processes all edges,
//                  and there are at most V levels (each contracts ≥1 vertex)
// SPACE COMPLEXITY: O(V + E) for graph representation

///|
/// Compute minimum arborescence rooted at the given root vertex.
///
/// ALGORITHM:
/// ```
///   1. Verify all vertices are reachable from root
///   2. For each vertex, select minimum incoming edge (greedy)
///   3. If no cycle, return the solution
///   4. Otherwise:
///      a. Contract cycle into supernode (component 0)
///      b. Map other vertices to components 1, 2, ...
///      c. Create contracted edges with adjusted weights
///      d. Recurse on contracted graph
///      e. Expand solution back to original vertices
/// ```
///
/// THE WEIGHT ADJUSTMENT (crucial insight):
/// ```
///   For an edge u→v where v is in a cycle:
///     new_weight = old_weight - in_cost[v]
///
///   This normalizes the cost of "breaking into" the cycle at vertex v.
///   If we select this edge, we remove the cycle edge entering v
///   and gain (old_weight - in_cost[v]) extra cost.
/// ```
///
/// PARAMETERS:
///   - n: number of vertices (labeled 0 to n-1)
///   - edges: directed edges with weights
///   - root: the root vertex of the desired arborescence
///
/// RETURNS:
///   Some(arborescence) if a valid arborescence exists,
///   None if some vertex is unreachable from root.
///
/// EXAMPLE:
/// ```
///   Graph:
///     0 →(1)→ 1 →(1)→ 2
///     0 →(5)→ 2
///     2 →(1)→ 3
///     1 →(2)→ 3
///
///   Minimum arborescence from root 0:
///     0→1 (cost 1)
///     1→2 (cost 1)
///     2→3 (cost 1)
///     Total: 3
///
///   Result: parent = [-1, 0, 1, 2], cost = 3
/// ```
pub fn min_arborescence(
  n : Int,
  edges : ArrayView[Edge],
  root : Int,
) -> Arborescence? {
  // Input validation
  if n <= 0 || root < 0 || root >= n {
    return None
  }
  let edge_list = edges.to_array()

  // Step 0: Check reachability
  let reachable = build_reachable(n, edge_list, root)
  for v in 0..<n {
    if not(reachable[v]) {
      return None // Arborescence impossible
    }
  }

  // Step 1: Select minimum incoming edge for each vertex
  let in_cost = Array::make(n, INF64)
  let parent = Array::make(n, -1)
  for e in edge_list {
    // Root has no incoming edge in arborescence
    guard e.to != root && e.weight < in_cost[e.to] else { continue }
    in_cost[e.to] = e.weight
    parent[e.to] = e.from
  }
  parent[root] = -1

  // Step 2: Check for cycles
  let cycle = find_cycle(n, root, parent)

  // Case A: No cycle - selected edges form valid arborescence
  if cycle.length() == 0 {
    let mut total = 0L
    for v = 0; v < n; v = v + 1 {
      if v != root {
        total = total + in_cost[v]
      }
    } where {
      invariant: v >= 0 && v <= n,
      reasoning: (
        #|INVARIANT (cost summation):
        #|  total = Σ in_cost[u] for u in [0..v) where u ≠ root
        #|
        #|MAINTENANCE:
        #|  Add in_cost[v] for non-root vertices.
        #|
        #|TERMINATION:
        #|  At v = n, total is complete arborescence cost.
      ),
    }
    return Some({ cost: total, parent })
  }

  // Case B: Cycle found - must contract and recurse

  // Step 3: Build component mapping
  // - Cycle vertices → component 0
  // - Other vertices → components 1, 2, ...
  let cycle_id = Array::make(n, -1)
  for v in cycle {
    cycle_id[v] = 0
  }
  let mut new_index = 1
  let comp = Array::make(n, -1)
  for v = 0; v < n; v = v + 1 {
    if cycle_id[v] == 0 {
      comp[v] = 0
    } else {
      comp[v] = new_index
      new_index = new_index + 1
    }
  } where {
    invariant: v >= 0 && v <= n,
    reasoning: (
      #|INVARIANT (component assignment):
      #|  Vertices [0..v) are assigned to components.
      #|  Cycle vertices → 0, others → sequential IDs.
      #|
      #|MAINTENANCE:
      #|  Assign component ID to vertex v.
      #|
      #|TERMINATION:
      #|  At v = n, all vertices have component assignments.
    ),
  }

  // Step 4: Build contracted graph
  let new_n = new_index
  let contracted_edges : Array[Edge] = []
  for e in edge_list {
    let a = comp[e.from]
    let b = comp[e.to]

    // Only keep edges between different components
    guard a != b else { continue }

    // Adjust weight for edges entering the cycle
    let w = if b == 0 {
      // Edge enters cycle component - subtract the in_cost
      // This normalizes: selecting this edge "replaces" cycle edge at e.to
      e.weight - in_cost[e.to]
    } else {
      e.weight
    }
    contracted_edges.push({ from: a, to: b, weight: w })
  }

  // Step 5: Recurse on contracted graph
  let new_root = comp[root]
  let sub = min_arborescence(new_n, contracted_edges[:], new_root)
  match sub {
    None => None
    Some(sub_tree) => {
      // Step 6: Expand solution back to original graph
      let final_parent = parent.copy()

      // Find which edge enters the cycle in contracted solution
      let mut enter_edge : Edge? = None
      for e in contracted_edges {
        if e.to == 0 && sub_tree.parent[e.to] == e.from {
          enter_edge = Some(e)
          break
        }
      }
      match enter_edge {
        None => {
          // No edge enters cycle in contracted solution
          // This can happen if cycle is entirely within the arborescence
          let total = sub_tree.cost + cycle_cost(in_cost, cycle)
          Some({ cost: total, parent: final_parent })
        }
        Some(edge_in) => {
          // Find original edge corresponding to contracted edge
          // Update parent to reflect the actual edge chosen
          for e in edge_list {
            if comp[e.from] == edge_in.from && comp[e.to] == 0 {
              let adjusted = e.weight - in_cost[e.to]
              if adjusted == edge_in.weight {
                // This is the edge - update parent
                final_parent[e.to] = e.from
                break
              }
            }
          }
          let total = sub_tree.cost + cycle_cost(in_cost, cycle)
          Some({ cost: total, parent: final_parent })
        }
      }
    }
  }
}
