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
/// Compute the minimum-cost arborescence rooted at `root`.
///
/// An **arborescence** is a directed spanning tree where every vertex except
/// the root has exactly one incoming edge and all vertices are reachable from
/// the root.  This function implements the Chu-Liu/Edmonds algorithm, which
/// repeatedly contracts directed cycles until the greedy in-edge selection
/// is cycle-free, then expands back to recover the solution.
///
/// ## Algorithm outline
///
/// ```
/// // Phase 1 — reachability guard
/// if any vertex is unreachable from root → return None
///
/// // Phase 2 — greedy in-edge selection
/// for each v ≠ root:
///   in_edge[v] = cheapest edge entering v
///
/// // Phase 3 — termination or contraction
/// if no cycle in in_edge:
///   return { cost: sum of in_edge weights, parent: in_edge sources }
/// else:
///   C = one cycle in in_edge
///   build contracted graph G':
///     - merge C into supernode 0
///     - for edges u→v with v in C: w'(u→v) = w(u→v) - in_cost[v]
///   recurse on G'
///   expand contracted solution back to original vertices
/// ```
///
/// ## Weight adjustment — the key insight
///
/// When an external edge `u → v` (with `v` in cycle `C`) is selected in the
/// contracted graph, it replaces the in-cycle edge entering `v`.  The adjusted
/// weight `w(u→v) - in_cost[v]` represents only the *extra* cost beyond what
/// the cycle already contributes, so adding `cycle_cost(C)` back during
/// expansion yields the true total.
///
/// ```
/// // Edge enters cycle at v, replacing the cycle's own in-edge to v:
/// //
/// //   True extra cost = w(u→v) - in_cost[v]
/// //                       ↑           ↑
/// //               external edge   saved cycle edge
/// ```
///
/// ## Parameters
///
/// - `n`     — Number of vertices (labeled `0` to `n-1`).
/// - `edges` — Directed edges with integer weights.  Parallel edges are
///             allowed and may all be needed during contraction.
/// - `root`  — Root vertex of the desired arborescence.
///
/// ## Returns
///
/// `Some(arborescence)` if a valid arborescence exists.
/// `None` if any vertex is unreachable from `root`, or if `n`, `root` are
/// out of range.
///
/// ## Example
///
/// ```
/// // Graph (root = 0):
/// //
/// //   0 →(1)→ 1 →(1)→ 2
/// //   |               |
/// //   └────(5)→ 2  (1)→ 3
/// //            1 →(2)→ 3
/// //
/// // Minimum arborescence:
/// //   0→1 (1) + 1→2 (1) + 2→3 (1) = 3
/// //
/// // Result: parent = [-1, 0, 1, 2], cost = 3
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
  let edge_list = edges.to_owned()

  // Step 0: Check reachability
  let reachable = build_reachable(n, edge_list, root)
  for v in 0..<n {
    if !reachable[v] {
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
    let total = for v = 0, total = 0L; v < n; {
      if v != root {
        continue v + 1, total + in_cost[v]
      }
      continue v + 1, total
    } nobreak {
      total
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
  let comp = Array::make(n, -1)
  let new_n = for v = 0, new_index = 1; v < n; {
    if cycle_id[v] == 0 {
      comp[v] = 0
      continue v + 1, new_index
    }
    comp[v] = new_index
    continue v + 1, new_index + 1
  } nobreak {
    new_index
  }

  // Step 4: Build contracted graph
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
  let sub = min_arborescence(new_n, contracted_edges, new_root)
  match sub {
    None => None
    Some(sub_tree) => {
      // Step 6: Expand solution back to original graph
      let final_parent = parent.copy()

      // Find which edge enters the cycle in contracted solution
      let enter_edge = for i in 0..<contracted_edges.length() {
        let e = contracted_edges[i]
        if e.to == 0 && sub_tree.parent[e.to] == e.from {
          break Some(e)
        }
      } nobreak {
        None
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
