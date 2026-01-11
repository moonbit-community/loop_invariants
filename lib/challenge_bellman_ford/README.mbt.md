# Challenge: Bellman-Ford

Shortest paths with negative edges and cycle detection.

## Example

```mbt check
///|
test "bellman-ford example" {
  let edges : Array[(Int, Int, Int)] = [
    (0, 1, 1),
    (1, 2, 2),
    (0, 2, 5),
    (2, 3, 1),
  ]
  let (dist, neg) = @challenge_bellman_ford.bellman_ford(4, edges[:], 0)
  inspect(dist, content="[0, 1, 3, 4]")
  inspect(neg, content="false")
}
```
