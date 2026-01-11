# Challenge: Dijkstra Shortest Paths

Array-based Dijkstra for non-negative edge weights.

## Example

```mbt check
///|
test "dijkstra example" {
  let adj : Array[Array[(Int, Int)]] = [
    [(1, 2), (2, 5)],
    [(2, 1), (3, 2)],
    [(3, 3)],
    [(4, 1)],
    [],
  ]
  let dist = @challenge_dijkstra.dijkstra(adj, 0)
  inspect(dist, content="[0, 2, 3, 4, 5]")
}
```
