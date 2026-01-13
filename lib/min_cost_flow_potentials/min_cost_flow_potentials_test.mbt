///|
test "mcf potentials basic" {
  let mcf = @min_cost_flow_potentials.MinCostFlowPotentials::new(4)
  mcf.add_edge(0, 1, 2L, 1L)
  mcf.add_edge(0, 2, 1L, 2L)
  mcf.add_edge(1, 2, 1L, 1L)
  mcf.add_edge(1, 3, 1L, 3L)
  mcf.add_edge(2, 3, 2L, 1L)
  let (flow, cost) = mcf.compute(0, 3)
  inspect(flow, content="3")
  inspect(cost, content="10")
}

///|
test "mcf potentials flow limit" {
  let mcf = @min_cost_flow_potentials.MinCostFlowPotentials::new(2)
  mcf.add_edge(0, 1, 10L, 2L)
  let (flow, cost) = mcf.compute_with_limit(0, 1, 5L)
  inspect(flow, content="5")
  inspect(cost, content="10")
}

///|
test "mcf potentials no path" {
  let mcf = @min_cost_flow_potentials.MinCostFlowPotentials::new(3)
  mcf.add_edge(0, 1, 1L, 1L)
  let (flow, cost) = mcf.compute(0, 2)
  inspect(flow, content="0")
  inspect(cost, content="0")
}
