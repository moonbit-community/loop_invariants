# Suurballe's Disjoint Paths

## Overview

Suurballe's algorithm finds **two edge-disjoint shortest paths** between a
source and a sink in a directed graph with non-negative weights. It runs two
Dijkstra passes with a clever edge reweighting and path reversal step.

- **Time**: O(E log V)
- **Space**: O(V + E)

## Core Idea

- Run Dijkstra once, then **reweight edges** with the shortest-path potentials.
- Reverse edges on the first shortest path to allow an alternate disjoint path.
- A second Dijkstra yields two **edge-disjoint shortest paths** combined.

## Example

```mbt check
///|
test "suurballe example" {
  let edges : Array[(Int, Int, Int64)] = [
    (0, 1, 1L),
    (1, 4, 1L),
    (0, 2, 1L),
    (2, 4, 1L),
    (0, 3, 2L),
    (3, 4, 0L),
  ]
  let result = @suurballe_disjoint_paths.suurballe_disjoint_paths(
    5,
    edges[:],
    0,
    4,
  )
  match result {
    None => fail("expected two disjoint paths")
    Some((p1, p2)) => {
      assert_eq(p1[0], 0)
      assert_eq(p1[p1.length() - 1], 4)
      assert_eq(p2[0], 0)
      assert_eq(p2[p2.length() - 1], 4)
      assert_true(p1.length() == 3)
      assert_true(p2.length() == 3)
    }
  }
}
```
