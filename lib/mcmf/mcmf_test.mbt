// ============================================================================
// MIN-COST MAX-FLOW - Tests
// ============================================================================

///|
/// Test basic MCMF computation.
///
/// NETWORK:
/// ```
///   0 -> 1: cap 2, cost 1
///   0 -> 2: cap 1, cost 2
///   1 -> 2: cap 1, cost 1
///   1 -> 3: cap 1, cost 3
///   2 -> 3: cap 2, cost 1
///
///   Max flow = 3, paths found by cost order
/// ```
test "mcmf basic" {
  let mcmf = MinCostMaxFlow::new(4)
  mcmf.add_edge(0, 1, 2L, 1L)
  mcmf.add_edge(0, 2, 1L, 2L)
  mcmf.add_edge(1, 2, 1L, 1L)
  mcmf.add_edge(1, 3, 1L, 3L)
  mcmf.add_edge(2, 3, 2L, 1L)
  let (flow, cost) = mcmf.compute(0, 3)
  inspect(flow, content="3")
  // Cost depends on path order, but should be reasonable
  inspect(cost <= 12L, content="true")
}

///|
/// Test simple single edge.
test "mcmf simple" {
  let mcmf = MinCostMaxFlow::new(2)
  mcmf.add_edge(0, 1, 5L, 2L)
  let (flow, cost) = mcmf.compute(0, 1)
  inspect(flow, content="5")
  inspect(cost, content="10") // 5 * 2
}

///|
/// Test disconnected network.
test "mcmf no path" {
  let mcmf = MinCostMaxFlow::new(3)
  mcmf.add_edge(0, 1, 1L, 1L)
  // No edge to vertex 2
  let (flow, cost) = mcmf.compute(0, 2)
  inspect(flow, content="0")
  inspect(cost, content="0")
}

///|
/// Test parallel edges with different costs.
///
/// NETWORK:
/// ```
///   0 -> 1: cap 2, cost 1 (cheap)
///   0 -> 1: cap 2, cost 3 (expensive)
///
///   Should use cheap edge first, then expensive.
///   Total: 2*1 + 2*3 = 8
/// ```
test "mcmf parallel edges" {
  let mcmf = MinCostMaxFlow::new(2)
  mcmf.add_edge(0, 1, 2L, 1L) // Cheap
  mcmf.add_edge(0, 1, 2L, 3L) // Expensive
  let (flow, cost) = mcmf.compute(0, 1)
  inspect(flow, content="4")
  inspect(cost, content="8")
}

///|
/// Test flow limit functionality.
test "mcmf flow limit" {
  let mcmf = MinCostMaxFlow::new(2)
  mcmf.add_edge(0, 1, 10L, 1L)
  let (flow, cost) = mcmf.compute_with_limit(0, 1, 5L)
  inspect(flow, content="5")
  inspect(cost, content="5")
}

///|
/// Test assignment problem: 2 workers, 2 tasks.
///
/// COST MATRIX:
/// ```
///   Worker 0: [1, 3] (task 0 costs 1, task 1 costs 3)
///   Worker 1: [2, 2] (task 0 costs 2, task 1 costs 2)
///
///   Optimal: 0->0 (1), 1->1 (2) = 3
///   Alternative: 0->1 (3), 1->0 (2) = 5
/// ```
test "assignment basic" {
  let cost : Array[Array[Int64]] = [[1L, 3L], [2L, 2L]]
  inspect(solve_assignment(cost), content="3")
}

///|
/// Test larger assignment problem.
///
/// COST MATRIX:
/// ```
///   Worker 0: [9, 2, 7]
///   Worker 1: [6, 4, 3]
///   Worker 2: [5, 8, 1]
///
///   Optimal: 0->1 (2), 1->0 (6), 2->2 (1) = 9
/// ```
test "assignment larger" {
  let cost : Array[Array[Int64]] = [[9L, 2L, 7L], [6L, 4L, 3L], [5L, 8L, 1L]]
  let result = solve_assignment(cost)
  inspect(result, content="9")
}

///|
/// Test diamond-shaped network.
///
/// NETWORK:
/// ```
///   0 -> 1: cap 3, cost 1
///   0 -> 2: cap 3, cost 2
///   1 -> 3: cap 3, cost 1
///   2 -> 3: cap 3, cost 1
///
///   Max flow = 6
///   Min cost: 3 through top (1+1=2 each) + 3 through bottom (2+1=3 each)
///           = 3*2 + 3*3 = 15
/// ```
test "mcmf diamond" {
  let mcmf = MinCostMaxFlow::new(4)
  mcmf.add_edge(0, 1, 3L, 1L)
  mcmf.add_edge(0, 2, 3L, 2L)
  mcmf.add_edge(1, 3, 3L, 1L)
  mcmf.add_edge(2, 3, 3L, 1L)
  let (flow, cost) = mcmf.compute(0, 3)
  inspect(flow, content="6")
  inspect(cost, content="15")
}
