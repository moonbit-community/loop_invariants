# Challenge: SCC (Kosaraju)

Two-pass DFS to compute strongly connected components.

## Core Idea

1. Run DFS on the original graph to compute a finishing order.
2. Reverse all edges.
3. Run DFS in reverse finishing order to extract SCCs.

Each DFS tree in step 3 is one strongly connected component.

## Example

```mbt check
///|
test "scc kosaraju example" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4)]
  let comp = @challenge_scc_kosaraju.scc_kosaraju(5, edges[:])
  inspect(comp[0] == comp[1] && comp[1] == comp[2], content="true")
}
```

## Another Example

```mbt check
///|
test "scc kosaraju isolated" {
  let edges : Array[(Int, Int)] = []
  let comp = @challenge_scc_kosaraju.scc_kosaraju(3, edges[:])
  inspect(comp[0] != comp[1] && comp[1] != comp[2], content="true")
}
```

## Notes

- Runs in O(n + m).
- Component ids are arbitrary but consistent.
