// ============================================================================
// SCC - Tests
// ============================================================================

///|
/// Test single cycle (one SCC).
///
/// GRAPH:
/// ```
///   0 → 1 → 2 → 0
/// ```
test "scc single cycle" {
  let adj : Array[Array[Int]] = [[1], [2], [0]]
  let result = find_sccs(3, adj)
  inspect(result.num_sccs, content="1")
  inspect(result.component[0] == result.component[1], content="true")
  inspect(result.component[1] == result.component[2], content="true")
}

///|
/// Test disconnected edges (each vertex is own SCC).
///
/// GRAPH:
/// ```
///   0 → 1    2 → 3
///   (no cycles, 4 SCCs)
/// ```
test "scc two components" {
  let adj : Array[Array[Int]] = [[1], [], [3], []]
  let result = find_sccs(4, adj)
  inspect(result.num_sccs, content="4")
}

///|
/// Test cycle with outgoing edge to DAG.
///
/// GRAPH:
/// ```
///   0 → 1 → 2 → 0, 2 → 3
///   SCCs: {0,1,2}, {3}
/// ```
test "scc with dag" {
  let adj : Array[Array[Int]] = [[1], [2], [0, 3], []]
  let result = find_sccs(4, adj)
  inspect(result.num_sccs, content="2")
  // {0,1,2} same SCC
  inspect(result.component[0] == result.component[1], content="true")
  inspect(result.component[1] == result.component[2], content="true")
  // {3} different SCC
  inspect(result.component[2] != result.component[3], content="true")
}

///|
/// Test that Kosaraju produces same result as Tarjan.
test "scc kosaraju same result" {
  let adj : Array[Array[Int]] = [[1], [2], [0, 3], []]
  let tarjan = find_sccs(4, adj)
  let kosaraju = find_sccs_kosaraju(4, adj)
  inspect(tarjan.num_sccs == kosaraju.num_sccs, content="true")
}

///|
/// Test condensation graph has correct edges.
test "scc condensation graph" {
  let adj : Array[Array[Int]] = [[1], [2], [0, 3], []]
  let result = find_sccs(4, adj)

  // Should have edge from {0,1,2}'s SCC to {3}'s SCC
  let scc_012 = result.component[0]
  let scc_3 = result.component[3]
  let has_edge = for i in 0..<result.scc_adj[scc_012].length(); has_edge = false {
    let has_edge = has_edge || result.scc_adj[scc_012][i] == scc_3
    continue has_edge
  } nobreak {
    has_edge
  }
  inspect(has_edge, content="true")
}

///|
/// Test empty graph.
test "scc empty" {
  let adj : Array[Array[Int]] = []
  let result = find_sccs(0, adj)
  inspect(result.num_sccs, content="0")
}

///|
/// Test single vertex.
test "scc single vertex" {
  let adj : Array[Array[Int]] = [[]]
  let result = find_sccs(1, adj)
  inspect(result.num_sccs, content="1")
  inspect(result.component[0], content="0")
}

///|
/// Test self-loop (still single SCC).
test "scc self loop" {
  let adj : Array[Array[Int]] = [[0]]
  let result = find_sccs(1, adj)
  inspect(result.num_sccs, content="1")
}

///|
/// Test 2-SAT satisfiable formula.
///
/// FORMULA:
/// ```
///   (x₀ OR x₁) AND (NOT x₀ OR x₁) AND (x₀ OR NOT x₁)
///
///   Solution: x₀ = true, x₁ = true
/// ```
test "two sat satisfiable" {
  let sat = TwoSAT::new(2)
  sat.add_clause(0, false, 1, false) // x₀ OR x₁
  sat.add_clause(0, true, 1, false) // NOT x₀ OR x₁
  sat.add_clause(0, false, 1, true) // x₀ OR NOT x₁
  match sat.solve() {
    Some(assignment) => inspect(assignment.length(), content="2")
    None => fail("Should be satisfiable")
  }
}

///|
/// Test 2-SAT unsatisfiable formula.
///
/// FORMULA:
/// ```
///   (x₀ OR x₀) AND (NOT x₀ OR NOT x₀) = x₀ AND NOT x₀
///   Contradiction!
/// ```
test "two sat unsatisfiable" {
  let sat = TwoSAT::new(1)
  sat.add_clause(0, false, 0, false) // x₀ OR x₀ = x₀
  sat.add_clause(0, true, 0, true) // NOT x₀ OR NOT x₀ = NOT x₀
  match sat.solve() {
    Some(_) => fail("Should be unsatisfiable")
    None => ()
  }
}

///|
/// Test SCC sizes sum to n.
test "scc sizes" {
  let adj : Array[Array[Int]] = [[1], [2], [0, 3], []]
  let result = find_sccs(4, adj)
  let total = for i = 0, total = 0; i < result.scc_sizes.length(); {
    continue i + 1, total + result.scc_sizes[i]
  } nobreak {
    total
  } where {
    proof_invariant: i >= 0 && i <= result.scc_sizes.length(),
    reasoning: (
      #|INVARIANT (sum sizes):
      #|  total = sum of scc_sizes[0..i)
      #|
      #|MAINTENANCE:
      #|  Add next size.
      #|
      #|TERMINATION:
      #|  At i = length, total = n.
    ),
  }
  inspect(total, content="4")
}

///|
/// Test two separate cycles.
///
/// GRAPH:
/// ```
///   0 ↔ 1    2 ↔ 3    1 → 2
///   SCCs: {0,1}, {2,3}
/// ```
test "scc complex" {
  let adj : Array[Array[Int]] = [[1], [0, 2], [3], [2]]
  let result = find_sccs(4, adj)
  inspect(result.num_sccs, content="2")
  // {0,1} same SCC
  inspect(result.component[0] == result.component[1], content="true")
  // {2,3} same SCC
  inspect(result.component[2] == result.component[3], content="true")
}
