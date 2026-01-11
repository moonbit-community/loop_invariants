# Strongly Connected Components (Tarjan/Kosaraju)

Find SCCs in a directed graph. SCCs are maximal sets of vertices where every
vertex can reach every other vertex. This package offers Tarjan (single DFS)
and Kosaraju (two-pass) implementations.

## What it includes

- `find_sccs` (Tarjan)
- `find_sccs_kosaraju` (Kosaraju)
- Condensation graph construction in the returned `SCCResult`

## Example

```mbt check
///|
test "scc example" {
  let adj : Array[Array[Int]] = Array::makei(4, fn(_) { [] })
  adj[0].push(1)
  adj[1].push(2)
  adj[2].push(0)
  adj[2].push(3)
  let res = @scc.find_sccs(4, adj)
  inspect(res.num_sccs, content="2")
  inspect(
    res.component[0] == res.component[1] && res.component[1] == res.component[2],
    content="true",
  )
  inspect(res.component[3] != res.component[0], content="true")
}
```

## Notes

- Time complexity: `O(V + E)`.
- The condensation graph is a DAG, useful for DP on components.
