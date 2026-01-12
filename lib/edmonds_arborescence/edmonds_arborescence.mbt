// ============================================================================
// EDMONDS' ARBORESCENCE (Chu–Liu/Edmonds) - Directed MST
// ============================================================================
//
// Finds a minimum-cost arborescence rooted at r in a directed graph.
// Each vertex (except root) has exactly one incoming edge in the solution.
// If some vertex is unreachable from root, no arborescence exists.
//
// ALGORITHM (Chu–Liu/Edmonds):
// 1. For each vertex v != r, pick the cheapest incoming edge (u -> v).
// 2. If these edges form no cycle, they are the optimum.
// 3. Otherwise, contract each cycle into a supernode and adjust edge weights:
//    w'(u -> v) = w(u -> v) - in_cost[v] when v is inside the cycle.
// 4. Recurse on the contracted graph, then expand cycles to recover the solution.
//
// INVARIANTS:
// 1. For each vertex v != r, in_cost[v] is the minimum weight among edges into v.
// 2. If there is a cycle, the chosen in-edges are optimal inside the cycle up
//    to a constant; contraction preserves global optimality.
// 3. After contraction, all edges entering the cycle are reweighted so that
//    selecting one edge corresponds to selecting exactly one edge to break the cycle.
//
// TIME COMPLEXITY: O(V * E) in this straightforward implementation.
// SPACE COMPLEXITY: O(V + E)

///|
const INF64 : Int64 = 4611686018427387903L

///|
/// Directed edge with weight.
pub(all) struct Edge {
  from : Int
  to : Int
  weight : Int64
}

///|
/// Result of minimum arborescence.
pub(all) struct Arborescence {
  cost : Int64
  parent : Array[Int] // parent[v] = chosen predecessor, parent[root] = -1
}

///|
fn find_cycle(n : Int, root : Int, parent : Array[Int]) -> Array[Int] {
  let seen = Array::make(n, -1)
  for v = 0; v < n; v = v + 1 {
    if v == root || parent[v] == -1 {
      continue
    }
    let mut cur = v
    while cur != -1 && cur != root && seen[cur] == -1 {
      seen[cur] = v
      cur = parent[cur]
    }
    if cur != -1 && cur != root && seen[cur] == v {
      // Extract cycle
      let cycle : Array[Int] = []
      let start = cur
      cycle.push(start)
      let mut x = parent[start]
      while x != start {
        cycle.push(x)
        x = parent[x]
      }
      return cycle
    }
  } where {
    invariant: v >= 0 && v <= n,
    reasoning: (
      #|INVARIANT (cycle scan):
      #|Vertices in [0..v) are checked for cycles in the parent graph.
      #|MAINTENANCE:
      #|Follow parent pointers; a repeated vertex in the same traversal
      #|indicates a directed cycle.
      #|TERMINATION:
      #|At v = n, either a cycle is returned or none exists.
    ),
  }
  []
}

///|
fn build_reachable(n : Int, edges : Array[Edge], root : Int) -> Array[Bool] {
  let adj : Array[Array[Int]] = Array::make(n, [])
  for i = 0; i < edges.length(); i = i + 1 {
    let e = edges[i]
    adj[e.from].push(e.to)
  } where {
    invariant: i >= 0 && i <= edges.length(),
    reasoning: (
      #|INVARIANT (adj build):
      #|Edges[0..i) are added to the adjacency list.
      #|MAINTENANCE:
      #|Insert the next edge.
      #|TERMINATION:
      #|At i = edges.length(), adjacency is complete.
    ),
  }
  let seen = Array::make(n, false)
  let stack : Array[Int] = [root]
  seen[root] = true
  for idx = 0; idx < stack.length(); idx = idx + 1 {
    let u = stack[idx]
    for v in adj[u] {
      if not(seen[v]) {
        seen[v] = true
        stack.push(v)
      }
    }
  } where {
    invariant: idx >= 0 && idx <= stack.length(),
    reasoning: (
      #|INVARIANT (reachability):
      #|Vertices in stack[0..idx) are processed; seen marks all reachable nodes.
      #|MAINTENANCE:
      #|Expand stack[idx] and enqueue unseen neighbors.
      #|TERMINATION:
      #|At idx = stack.length(), all reachable vertices are marked.
    ),
  }
  seen
}

///|
fn cycle_cost(in_cost : Array[Int64], cycle : Array[Int]) -> Int64 {
  let mut total = 0L
  for i = 0; i < cycle.length(); i = i + 1 {
    total = total + in_cost[cycle[i]]
  } where {
    invariant: i >= 0 && i <= cycle.length(),
    reasoning: (
      #|INVARIANT (cycle sum):
      #|total equals the sum of in_cost for cycle[0..i).\n      #|MAINTENANCE:
      #|Add in_cost[cycle[i]] to the running total.\n      #|TERMINATION:
      #|At i = cycle.length(), total is the full cycle incoming cost sum.
    ),
  }
  total
}

///|
/// Compute minimum arborescence rooted at root.
/// Returns None if some vertex is unreachable from root.
pub fn min_arborescence(
  n : Int,
  edges : ArrayView[Edge],
  root : Int,
) -> Arborescence? {
  if n <= 0 || root < 0 || root >= n {
    return None
  }
  let edge_list = edges.to_array()
  let reachable = build_reachable(n, edge_list, root)
  for v in 0..<n {
    if not(reachable[v]) {
      return None
    }
  }

  // Step 1: choose min incoming edge for each vertex
  let in_cost = Array::make(n, INF64)
  let parent = Array::make(n, -1)
  for i = 0; i < edge_list.length(); i = i + 1 {
    let e = edge_list[i]
    if e.to != root && e.weight < in_cost[e.to] {
      in_cost[e.to] = e.weight
      parent[e.to] = e.from
    }
  } where {
    invariant: i >= 0 && i <= edge_list.length(),
    reasoning: (
      #|INVARIANT (min incoming):
      #|For each vertex, in_cost is the minimum weight among edges scanned so far.
      #|MAINTENANCE:
      #|Update in_cost and parent if a cheaper edge is found.
      #|TERMINATION:
      #|At i = edges.length(), all min incoming edges are selected.
    ),
  }
  parent[root] = -1

  // Detect cycle in chosen edges
  let cycle = find_cycle(n, root, parent)
  if cycle.length() == 0 {
    let mut total = 0L
    for v = 0; v < n; v = v + 1 {
      if v != root {
        total = total + in_cost[v]
      }
    } where {
      invariant: v >= 0 && v <= n,
      reasoning: (
        #|INVARIANT (sum costs):
        #|total is the sum of in_cost for vertices in [0..v) excluding root.
        #|MAINTENANCE:
        #|Add in_cost[v] when v != root.
        #|TERMINATION:
        #|At v = n, total is the arborescence cost.
      ),
    }
    return Some({ cost: total, parent })
  }

  // Step 2: contract the cycle
  let cycle_id = Array::make(n, -1)
  for i = 0; i < cycle.length(); i = i + 1 {
    cycle_id[cycle[i]] = 0
  } where {
    invariant: i >= 0 && i <= cycle.length(),
    reasoning: (
      #|INVARIANT (cycle mark):
      #|Vertices in cycle[0..i) are marked with cycle_id = 0.
      #|MAINTENANCE:
      #|Mark cycle[i].
      #|TERMINATION:
      #|At i = cycle.length(), all cycle vertices are marked.
    ),
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
      #|INVARIANT (component map):
      #|comp assigns vertices in [0..v) to either the cycle (0) or a new index.
      #|MAINTENANCE:
      #|Assign the next index to non-cycle vertices.
      #|TERMINATION:
      #|At v = n, all vertices are mapped to contracted components.
    ),
  }
  let new_n = new_index
  let contracted_edges : Array[Edge] = []
  for i = 0; i < edge_list.length(); i = i + 1 {
    let e = edge_list[i]
    let a = comp[e.from]
    let b = comp[e.to]
    if a != b {
      let mut w = e.weight
      if b == 0 {
        w = w - in_cost[e.to]
      }
      contracted_edges.push({ from: a, to: b, weight: w })
    }
  } where {
    invariant: i >= 0 && i <= edge_list.length(),
    reasoning: (
      #|INVARIANT (contract edges):
      #|Edges[0..i) are transformed into contracted_edges with proper weights.
      #|MAINTENANCE:
      #|If edge crosses components, add it; subtract in_cost for edges entering
      #|the cycle component.
      #|TERMINATION:
      #|At i = edges.length(), all inter-component edges are processed.
    ),
  }
  let new_root = comp[root]
  let sub = min_arborescence(new_n, contracted_edges[:], new_root)
  match sub {
    None => None
    Some(sub_tree) => {
      // Expand: start with the chosen incoming edges
      let final_parent = parent.copy()
      // Determine which edge enters the cycle in the contracted solution
      let mut enter_edge : Edge? = None
      for e in contracted_edges {
        if e.to == 0 && sub_tree.parent[e.to] == e.from {
          enter_edge = Some(e)
          break
        }
      }
      // If an edge enters the cycle, we need to replace one cycle edge
      match enter_edge {
        None => {
          let total = sub_tree.cost + cycle_cost(in_cost, cycle)
          Some({ cost: total, parent: final_parent })
        }
        Some(edge_in) => {
          // Find original edge that corresponds to edge_in
          let mut enter_v = -1
          for e in edge_list {
            if comp[e.from] == edge_in.from && comp[e.to] == 0 {
              let adjusted = e.weight - in_cost[e.to]
              if adjusted == edge_in.weight {
                enter_v = e.to
                final_parent[enter_v] = e.from
                break
              }
            }
          }
          let _ = enter_v
          let total = sub_tree.cost + cycle_cost(in_cost, cycle)
          Some({ cost: total, parent: final_parent })
        }
      }
    }
  }
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "arborescence basic" {
  let edges : Array[Edge] = [
    { from: 0, to: 1, weight: 1L },
    { from: 0, to: 2, weight: 5L },
    { from: 1, to: 2, weight: 1L },
    { from: 1, to: 3, weight: 2L },
    { from: 2, to: 3, weight: 1L },
  ]
  let res = min_arborescence(4, edges[:], 0).unwrap()
  inspect(res.cost, content="3")
  inspect(res.parent[0], content="-1")
  inspect(res.parent[1], content="0")
  inspect(res.parent[2], content="1")
  inspect(res.parent[3], content="2")
}

///|
test "arborescence cycle" {
  let edges : Array[Edge] = [
    { from: 0, to: 1, weight: 1L },
    { from: 1, to: 2, weight: 1L },
    { from: 2, to: 1, weight: 1L },
    { from: 2, to: 3, weight: 1L },
    { from: 0, to: 3, weight: 5L },
  ]
  let res = min_arborescence(4, edges[:], 0).unwrap()
  inspect(res.cost, content="3")
}

///|
test "arborescence unreachable" {
  let edges : Array[Edge] = [
    { from: 0, to: 1, weight: 1L },
    { from: 2, to: 3, weight: 1L },
  ]
  let res = min_arborescence(4, edges[:], 0)
  inspect(res is None, content="true")
}
