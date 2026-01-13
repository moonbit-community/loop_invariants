# Min-Cost Max-Flow (Potentials)

## Overview

This implementation uses **successive shortest augmenting paths** with
**Johnson potentials**. Potentials reweight residual edges so all reduced costs
are non-negative, allowing Dijkstra to be used in every augmentation step.

- **Time**: O(F · E log V)
- **Space**: O(V + E)

## Example

```mbt check
///|
test "min-cost flow with potentials" {
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
```
