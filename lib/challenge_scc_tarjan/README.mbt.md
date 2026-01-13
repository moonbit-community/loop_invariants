# Challenge: SCC (Tarjan)

Single-pass SCC decomposition using low-link values.

## Core Idea

Each node gets:
- `index`: DFS visit order
- `lowlink`: smallest index reachable through DFS edges

When `lowlink[v] == index[v]`, v is the root of an SCC; pop the stack
until v to form one component.

## Example

```mbt check
///|
test "scc tarjan example" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4)]
  let comp = @challenge_scc_tarjan.scc_tarjan(5, edges[:])
  inspect(comp[0] == comp[1] && comp[1] == comp[2], content="true")
}
```

## Another Example

```mbt check
///|
test "scc tarjan isolated" {
  let edges : Array[(Int, Int)] = []
  let comp = @challenge_scc_tarjan.scc_tarjan(2, edges[:])
  inspect(comp[0] != comp[1], content="true")
}
```

## Notes

- Runs in O(n + m).
- Component ids are arbitrary but consistent.
