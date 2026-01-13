# Push-Relabel Max Flow

## Overview

Push-relabel maintains a **preflow** and a **height label** on each vertex.
Excess flow is pushed along admissible edges (where `height[u] = height[v] + 1`).
If no admissible edge exists, the vertex is relabeled to create one. When no
active vertices remain, the preflow is a maximum flow.

- **Time**: O(V^2 E) worst-case
- **Space**: O(V + E)

## Example

```mbt check
///|
test "push-relabel example" {
  let pr = @push_relabel_max_flow.PushRelabel::new(6)
  pr.add_edge(0, 1, 16L)
  pr.add_edge(0, 2, 13L)
  pr.add_edge(1, 2, 10L)
  pr.add_edge(2, 1, 4L)
  pr.add_edge(1, 3, 12L)
  pr.add_edge(2, 4, 14L)
  pr.add_edge(3, 2, 9L)
  pr.add_edge(4, 3, 7L)
  pr.add_edge(3, 5, 20L)
  pr.add_edge(4, 5, 4L)
  let flow = pr.max_flow(0, 5)
  inspect(flow, content="23")
}
```
