# Challenge: Topological Sort (Kahn)

Kahn's algorithm for DAG ordering or cycle detection.

## Example

```mbt check
///|
test "toposort example" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
  let order = @challenge_toposort_kahn.topo_sort(4, edges[:])
  guard order is Some(ord) else { fail("expected order") }
  inspect(ord.length(), content="4")
}
```
