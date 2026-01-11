# Challenge: MST (Kruskal)

Minimum spanning tree via edge sorting and DSU.

## Example

```mbt check
///|
test "mst kruskal example" {
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 1),
    (1, 2, 2),
    (2, 3, 3),
    (0, 3, 10),
  ]
  let total = @challenge_mst_kruskal.mst_weight(4, edges[:])
  inspect(total, content="Some(6)")
}
```
