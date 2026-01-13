# Challenge: Topological Sort (Kahn)

Kahn's algorithm for DAG ordering or cycle detection.

## Core Idea

Maintain in-degrees and a queue of zero in-degree nodes. Repeatedly pop a node,
append it to the order, and decrement its outgoing neighbors. If all nodes are
processed, the graph is a DAG; otherwise a cycle exists.

## Example

```mbt check
///|
test "toposort example" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
  let order = @challenge_toposort_kahn.topo_sort(4, edges[:])
  guard order is Some(ord) else { fail("expected order") }
  inspect(@challenge_toposort_kahn.is_topo(ord, 4, edges[:]), content="true")
}
```

## Another Example

```mbt check
///|
test "toposort cycle" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
  let order = @challenge_toposort_kahn.topo_sort(3, edges[:])
  inspect(order is None, content="true")
}
```

## Notes

- Runs in O(n + m).
- Returns `None` when a cycle exists.
