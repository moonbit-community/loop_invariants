# Biconnected Components (and Articulation Points)

## Problem

Find parts of an undirected graph that stay connected **even if one vertex is removed**.
Also find **articulation points** (vertices whose removal disconnects the graph).

## Simple Idea

Use DFS with discovery time and **low-link** values:

- `disc[u]` = time we first see u
- `low[u]` = lowest discovery time reachable from u (using at most one back edge)

A vertex `u` is an articulation point if a child `v` has `low[v] >= disc[u]`.
That means v’s subtree cannot reach above u.

## Step-by-Step

1. Run DFS from each unvisited node
2. Track `disc` and `low`
3. Push DFS edges onto a stack
4. When `low[v] >= disc[u]`, pop edges to form **one component**

## Complexity

- Time: **O(V + E)**
- Space: **O(V + E)**

## Example

```mbt check
///|
test "biconnected components example" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (1, 3)]
  let res = @biconnected_components.biconnected_components(4, edges[:])
  let sizes = res.components.map(c => c.length())
  sizes.sort_by((a, b) => a - b)
  inspect(sizes, content="[1, 3]")
  res.articulation_points.sort_by((a, b) => a - b)
  inspect(res.articulation_points, content="[1]")
}
```

## When to Use

Use this when you need:

- Critical vertices in a network
- 2-vertex-connected subgraphs
- Robustness analysis (single-point failures)
