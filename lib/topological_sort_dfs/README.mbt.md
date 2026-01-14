# Topological Sort (DFS)

## Overview

**Topological Sort** produces a linear ordering of vertices in a directed acyclic
graph (DAG) such that for every edge u → v, vertex u appears before v.

- **Time**: O(V + E)
- **Space**: O(V + E)
- **Key Feature**: Detects cycles while sorting

## The Key Insight

```
Problem: Order tasks so dependencies come first

Naive: Try all permutations → O(V!)

DFS insight:
  When DFS finishes a vertex, ALL its descendants are done.
  So finish order is REVERSE topological order!

  DFS on A→B→C:
    Enter A
      Enter B
        Enter C
        Exit C (finish: [C])
      Exit B (finish: [C, B])
    Exit A (finish: [C, B, A])

  Reverse: [A, B, C] ← topological order!

Cycle detection:
  Track vertex states: unvisited, visiting, done
  Edge to "visiting" vertex = back edge = CYCLE!
```

## Visual: DFS Finish Order

```
Graph:
    0 ─────► 1
    │        │
    │        ▼
    └──────► 2 ────► 3

DFS from 0:

  Stack trace:
    visit(0) →
      visit(1) →
        visit(2) →
          visit(3) →
            finish 3   [3]
          finish 2     [3, 2]
        finish 1       [3, 2, 1]
      visit(2) already done
    finish 0           [3, 2, 1, 0]

  Finish order: [3, 2, 1, 0]
  Reverse:      [0, 1, 2, 3] ← topological order ✓

Verify edges:
  0→1: 0 before 1 ✓
  0→2: 0 before 2 ✓
  1→2: 1 before 2 ✓
  2→3: 2 before 3 ✓
```

## The Algorithm

```
topological_sort(graph):
  state = [UNVISITED] * n
  result = []

  for each vertex v:
    if state[v] == UNVISITED:
      if not dfs(v):
        return None  // Cycle detected

  return reverse(result)

dfs(v):
  state[v] = VISITING

  for each neighbor u of v:
    if state[u] == VISITING:
      return false  // Back edge = cycle!
    if state[u] == UNVISITED:
      if not dfs(u):
        return false

  state[v] = DONE
  result.append(v)
  return true
```

## Example Usage

```mbt check
///|
test "topological sort example" {
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2), (1, 3), (2, 3)]
  let order = @topological_sort_dfs.topological_sort(4, edges[:]).unwrap()
  inspect(order.length(), content="4")
}
```

```mbt check
///|
test "topological sort with multiple sources" {
  let edges : Array[(Int, Int)] = [(0, 2), (1, 2), (2, 3)]
  let order = @topological_sort_dfs.topological_sort(4, edges[:]).unwrap()
  // Both [0, 1, 2, 3] and [1, 0, 2, 3] are valid
  inspect(order.length(), content="4")
}
```

## Algorithm Walkthrough

```
Graph: 4 nodes
Edges: 0→1, 0→2, 1→3, 2→3

    0
   / \
  ▼   ▼
  1   2
   \ /
    ▼
    3

DFS traversal starting from 0:

State: [U, U, U, U]  (U=Unvisited, V=Visiting, D=Done)

visit(0): state = [V, U, U, U]
  visit(1): state = [V, V, U, U]
    visit(3): state = [V, V, U, V]
      no neighbors
      finish 3: state = [V, V, U, D], result = [3]
    finish 1: state = [V, D, U, D], result = [3, 1]
  visit(2): state = [V, D, V, D]
    neighbor 3 is DONE, skip
    finish 2: state = [V, D, D, D], result = [3, 1, 2]
  finish 0: state = [D, D, D, D], result = [3, 1, 2, 0]

Reverse: [0, 2, 1, 3]

Verify:
  0→1: 0 at pos 0, 1 at pos 2 ✓
  0→2: 0 at pos 0, 2 at pos 1 ✓
  1→3: 1 at pos 2, 3 at pos 3 ✓
  2→3: 2 at pos 1, 3 at pos 3 ✓
```

## Cycle Detection

```
Graph with cycle:
  0 → 1 → 2 → 0

DFS from 0:
  visit(0): state[0] = VISITING
    visit(1): state[1] = VISITING
      visit(2): state[2] = VISITING
        neighbor 0 has state VISITING!
        Back edge detected → CYCLE!

Return None (no topological order exists)
```

## Why It Works

```
Claim: Reverse of DFS finish order is a valid topological order.

Proof:
  Consider any edge u → v in the DAG.

  Case 1: u is visited before v in DFS
    - DFS will visit v from u (directly or indirectly)
    - v finishes before u finishes
    - In reverse, u comes before v ✓

  Case 2: v is visited before u in DFS
    - Since there's no path v → u (would create cycle)
    - v finishes before u is even visited
    - In reverse, u comes before v ✓

The "visiting" state catches cycles:
  If edge u → v where v is "visiting",
  then v is an ancestor of u on the DFS stack,
  so there's a path v → u, and u → v creates a cycle!
```

## Common Applications

### 1. Build Systems
```
Compile source files in dependency order.
A depends on B means B must be compiled first.
```

### 2. Course Prerequisites
```
Schedule courses so prerequisites come first.
CS201 requires CS101 → CS101 before CS201.
```

### 3. Task Scheduling
```
Order tasks respecting dependencies.
"Deploy" after "Build" after "Test".
```

### 4. DAG Dynamic Programming
```
Process nodes in topological order.
Each node computed after its dependencies.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| Build adjacency list | O(E) | One pass over edges |
| DFS traversal | O(V + E) | Visit each vertex/edge once |
| Reverse result | O(V) | Linear in vertices |
| **Total** | **O(V + E)** | Optimal for graphs |

## DFS vs Kahn's Algorithm (BFS)

| Aspect | DFS | Kahn's (BFS) |
|--------|-----|--------------|
| Approach | Finish order | Remove zero in-degree |
| Cycle detection | Back edge | Remaining vertices |
| Memory | O(V) recursion | O(V) queue |
| Order found | One valid order | One valid order |

**Choose DFS when**: You're already doing DFS for other purposes.
**Choose Kahn's when**: You need to process in level order.

## Implementation Notes

- Track three states per vertex: unvisited, visiting, done
- "Visiting" state is key for cycle detection
- Can use iterative DFS with explicit stack to avoid recursion limits
- Multiple valid topological orders may exist for the same DAG

## Multiple Valid Orders

```
Graph:
  0 → 2
  1 → 2

Valid topological orders:
  [0, 1, 2]
  [1, 0, 2]

DFS order depends on which vertex we start with
and adjacency list ordering.
```

