# Challenge: MST (Prim)

Prim's algorithm (O(n^2)) over an adjacency list.

## Example

```mbt check
///|
test "mst prim example" {
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 1),
    (1, 2, 2),
    (2, 3, 3),
    (0, 3, 10),
  ]
  let adj = @challenge_mst_prim.build_adj(4, edges[:])
  let total = @challenge_mst_prim.mst_weight(adj)
  inspect(total, content="Some(6)")
}
```
