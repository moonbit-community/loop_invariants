# Bipartite Matching

## Overview

**Bipartite Matching** finds the maximum set of edges in a bipartite graph
where no two edges share a vertex. This solves assignment problems optimally.

- **Hungarian Algorithm**: O(V × E)
- **Hopcroft-Karp**: O(E × √V)
- **Space**: O(V + E)

## The Problem

```
Bipartite graph:
  Left (workers)     Right (jobs)
      A ─────────────── 1
        ╲             ╱
         ╲           ╱
      B ───╲───────╱─── 2
            ╲     ╱
             ╲   ╱
      C ──────╲─╱────── 3

Edges: A-1, A-2, B-2, B-3, C-3

Maximum matching: {A-1, B-2, C-3} (size 3)
Each worker gets exactly one job, each job has one worker.
```

## The Key Insight: Augmenting Paths

```
Augmenting path: Alternates between unmatched and matched edges,
starting and ending at unmatched vertices.

Current matching: {A-2, B-3}
Unmatched: A(no), B(no), C(yes), 1(yes)

Find augmenting path from C:
  C → 3 (unmatched edge)
    → B (matched to 3)
    → 2 (unmatched edge for B)
    → A (matched to 2)
    → 1 (unmatched edge for A, 1 is unmatched!)

Path: C - 3 - B - 2 - A - 1

Flip the path:
  Before: {A-2, B-3}
  After:  {A-1, B-2, C-3}

Matching increased by 1!
```

## Hungarian Algorithm (Kuhn's)

```
For each unmatched left vertex, DFS to find augmenting path:

def find_augmenting(u):
    for v in neighbors(u):
        if not visited[v]:
            visited[v] = true
            if match[v] is None or find_augmenting(match[v]):
                match[v] = u
                return true
    return false

for u in left_vertices:
    reset visited
    if find_augmenting(u):
        matching_size++
```

## Hopcroft-Karp Algorithm

```
Faster by finding multiple augmenting paths at once:

1. BFS: Build level graph from unmatched left vertices
   - Level[v] = shortest distance to unmatched right vertex
   - Stop when reaching unmatched right vertices

2. DFS: Find vertex-disjoint augmenting paths
   - Only follow edges that decrease level by 1
   - Multiple paths found in parallel

3. Augment all found paths

4. Repeat until no augmenting path exists

Each phase finds paths of same (shortest) length.
At most O(√V) phases needed.
```

## Visual: Level Graph

```
BFS levels from unmatched left vertices:

Level 0    Level 1    Level 2    Level 3
(Left)     (Right)    (Left)     (Right)

  A* ──────── 1
                ╲
  B* ──────── 2 ─────── C ──────── 3*

* = unmatched

Shortest augmenting path: A → 1 (length 1)
Or: B → 2 → C → 3 (length 3)

Process shortest paths first for efficiency!
```

## Example Usage

```mbt check
///|
test "bipartite matching example" {
  let edges : Array[(Int, Int)] = [(0, 0), (0, 1), (1, 1)]
  let matching = @bipartite_matching.max_matching(2, 2, edges[:])
  inspect(matching, content="[(0, 0), (1, 1)]")
  inspect(matching.length(), content="2")
}
```

## Common Applications

### 1. Job Assignment
```
Workers (left) and jobs (right)
Edges: Worker can do job
Goal: Assign maximum jobs with one worker per job
```

### 2. Stable Marriage Problem
```
Men and women with preferences
Find stable pairing where no two people prefer each other
over their assigned partners
```

### 3. Course Scheduling
```
Students (left) and courses (right)
Edges: Student wants course
Goal: Maximize satisfied enrollments
```

### 4. Network Flow
```
Bipartite matching = Max flow in unit-capacity graph
Add source → all left, all right → sink
Maximum flow = maximum matching
```

## König's Theorem

```
In bipartite graphs:
  Maximum Matching = Minimum Vertex Cover

If matching has size k, then there exist k vertices
that cover all edges.

Use this to find minimum vertex cover from maximum matching!
```

## Complexity Analysis

| Algorithm | Time | Space |
|-----------|------|-------|
| Hungarian (Kuhn) | O(V × E) | O(V) |
| Hopcroft-Karp | O(E × √V) | O(V) |

## Matching Algorithms Comparison

| Algorithm | Time | Best For |
|-----------|------|----------|
| **Hungarian** | O(VE) | Simple implementation |
| **Hopcroft-Karp** | O(E√V) | Large sparse graphs |
| **Max Flow** | O(V²E) | General networks |
| **Push-Relabel** | O(V²√E) | Dense graphs |

**Choose Hopcroft-Karp when**: You need efficient bipartite matching.

## Hall's Theorem

```
Perfect matching exists (all left vertices matched) iff:
  For every subset S of left vertices,
  |neighbors(S)| ≥ |S|

"Marriage theorem": Every subset must have enough neighbors!
```

## Implementation Notes

- Use adjacency lists for sparse graphs
- Reset visited array between DFS calls in Hungarian
- In Hopcroft-Karp, BFS gives level assignment
- Track match_left and match_right arrays for O(1) lookup
- For weighted matching, use Hungarian algorithm for weighted assignment

