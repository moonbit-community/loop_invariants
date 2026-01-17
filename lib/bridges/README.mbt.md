# Bridges and Articulation Points

## Problem

Find:

- **Bridges**: edges whose removal disconnects the graph
- **Articulation points**: vertices whose removal disconnects the graph

## Simple Idea (DFS + Low-Link)

During DFS:

- `disc[u]` = discovery time
- `low[u]` = smallest discovery time reachable from u using at most one back edge

Then:

- Edge (u, v) is a **bridge** if `low[v] > disc[u]`
- Vertex u is an **articulation point** if a child v has `low[v] >= disc[u]`
  (with a special rule for the DFS root)

## Step-by-Step

1. Run DFS and compute `disc` and `low`
2. For each tree edge (u, v):
   - If `low[v] > disc[u]`, it is a bridge
   - If `low[v] >= disc[u]`, u may be an articulation point

## Example

```mbt check
///|
test "bridges example" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 3)]
  let bridges = @bridges.find_bridges(4, edges[:])
  inspect(bridges, content="[(1, 3)]")
  let cuts = @bridges.articulation_points(4, edges[:])
  inspect(cuts, content="[1]")
}
```

## Complexity

- Time: **O(V + E)**
- Space: **O(V + E)**

## When to Use

Use this when you need to identify critical links or critical nodes in a network.
