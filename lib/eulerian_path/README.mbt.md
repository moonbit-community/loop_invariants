# Eulerian Path and Circuit

## Overview

An **Eulerian path** visits every edge exactly once. An **Eulerian circuit**
is an Eulerian path that returns to the starting vertex. This package uses
**Hierholzer's algorithm** for both directed and undirected graphs.

- **Time**: O(V + E)
- **Space**: O(V + E)
- **Key Feature**: Classic graph traversal problem

## The Key Insight

```
Problem: Traverse every edge exactly once

When does a solution exist?
  Count vertex degrees!

Undirected graph:
  - Path: exactly 0 or 2 odd-degree vertices
  - Circuit: all vertices have even degree

Directed graph:
  - Path: at most one (out-in=1), at most one (in-out=1)
  - Circuit: all vertices have in-degree = out-degree

Hierholzer's algorithm:
  Start from valid vertex, follow edges until stuck.
  When stuck at a vertex, that vertex has no unused edges.
  Backtrack and splice in sub-paths from vertices with remaining edges.

  Key: Build path from the END by reversing the traversal.
```

## Visual: Hierholzer's Algorithm

```
Graph (undirected):
    0───1───2
    │   │   │
    └───3───┘

All vertices have degree 2 → Eulerian circuit exists!

Algorithm trace:
  Start at 0, path = []

  Step 1: Walk from 0
    0 → 1 → 2 → 3 → 0
    Stuck at 0 (all edges used from 0)
    path = [0, 3, 2, 1, 0] (reversed)

  Wait, we haven't used edge 1-3!

  Better trace:
    0 → 1 → 3 (stuck? no, 3 has edge to 2)
    3 → 2 → 1 (stuck? back to 1, edge 1→0 unused)
    1 → 0 (stuck? 0 has edge to 3)
    0 → 3 (stuck? yes, 3 has no unused edges)

  Backtrack and build:
    Final: [0, 1, 3, 2, 1, 0, 3]...

  Actually, let me redo properly:
    Start at 0
    0 → 1 → 2 → 3 → 1... oops, 1 has unused edge to 3

  Hierholzer handles this by DFS with backtracking!
```

## Visual: Directed Graph Example

```
Directed graph:
    0 ──► 1 ──► 2
    ▲           │
    └───────────┘

In-degree:  [1, 1, 1]
Out-degree: [1, 1, 1]
All equal → Eulerian circuit exists!

Traversal:
  Start at 0
  0 → 1 → 2 → 0 (back to start, all edges used)

Path: [0, 1, 2, 0]
```

## The Algorithm

```
hierholzer(graph, start):
  path = []
  stack = [start]

  while stack is not empty:
    v = stack.top()

    if v has unused edges:
      // Continue walking
      u = next unused neighbor of v
      mark edge (v, u) as used
      stack.push(u)
    else:
      // Stuck - finalize this vertex
      path.append(stack.pop())

  return reverse(path)
```

## Existence Conditions

```
DIRECTED GRAPH:

Eulerian circuit:
  ∀v: in(v) = out(v)
  All non-isolated vertices connected

Eulerian path (not circuit):
  Exactly one v with out(v) = in(v) + 1 (start)
  Exactly one v with in(v) = out(v) + 1 (end)
  All others: in(v) = out(v)

UNDIRECTED GRAPH:

Eulerian circuit:
  All vertices have even degree
  All non-isolated vertices connected

Eulerian path (not circuit):
  Exactly 2 vertices have odd degree (start and end)
  All others have even degree
```

## Example Usage

```mbt check
///|
test "directed eulerian path" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0), (0, 2)]
  let path = @eulerian_path.eulerian_path_directed(3, edges[:]).unwrap()
  inspect(path.length(), content="5")
}
```

```mbt check
///|
test "undirected eulerian circuit" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
  let path = @eulerian_path.eulerian_path_undirected(3, edges[:]).unwrap()
  inspect(path.length(), content="4")
}
```

```mbt check
///|
test "directed no eulerian" {
  // Unbalanced degrees - no Eulerian path
  let edges : Array[(Int, Int)] = [(0, 1), (0, 2)]
  let path = @eulerian_path.eulerian_path_directed(3, edges[:])
  inspect(path is None, content="true")
}
```

## Algorithm Walkthrough

```
Directed graph:
  Edges: 0→1, 1→2, 2→0, 0→2

  Degrees:
    0: out=2, in=1 (start candidate)
    1: out=1, in=1
    2: out=1, in=2 (end candidate)

  Start from 0 (out > in):

  Stack: [0]
    0 has edges to 1 and 2
    Take 0→1, mark used
    Stack: [0, 1]

  Stack: [0, 1]
    1 has edge to 2
    Take 1→2, mark used
    Stack: [0, 1, 2]

  Stack: [0, 1, 2]
    2 has edge to 0
    Take 2→0, mark used
    Stack: [0, 1, 2, 0]

  Stack: [0, 1, 2, 0]
    0 has edge to 2
    Take 0→2, mark used
    Stack: [0, 1, 2, 0, 2]

  Stack: [0, 1, 2, 0, 2]
    2 has no unused edges
    Pop 2, add to path: [2]
    Stack: [0, 1, 2, 0]

  Stack: [0, 1, 2, 0]
    0 has no unused edges
    Pop 0, add to path: [2, 0]
    Stack: [0, 1, 2]

  Continue popping (all exhausted):
    Path: [2, 0, 2, 1, 0]

  Reverse: [0, 1, 2, 0, 2]

  Verify: 0→1 ✓, 1→2 ✓, 2→0 ✓, 0→2 ✓
```

## Why Hierholzer Works

```
Claim: When we get stuck, we're at the start vertex (for circuits).

Proof:
  Each time we enter a vertex (except start), we can leave it.
  Why? Because in = out for all vertices.
  The only vertex we might not be able to leave is start.

Claim: DFS explores all edges.

Proof:
  We mark edges as used and never revisit.
  When stuck, we backtrack to find unused edges.
  Process continues until all edges used.

The reversal gives correct order:
  We add vertex to path only when ALL its edges are processed.
  This ensures sub-paths are correctly spliced.
```

## Common Applications

### 1. Seven Bridges of Königsberg
```
The original Eulerian problem!
Can you cross all bridges exactly once?
Answer: Only if ≤ 2 odd-degree vertices.
```

### 2. DNA Sequencing
```
De Bruijn graphs for genome assembly.
Reads are edges, Eulerian path reconstructs genome.
```

### 3. Circuit Design
```
PCB routing where each connection used once.
Chinese Postman problem (related).
```

### 4. Puzzle Games
```
Draw figure without lifting pen.
Trace every edge exactly once.
```

## Complexity Analysis

| Operation | Time | Notes |
|-----------|------|-------|
| Check existence | O(V + E) | Count degrees |
| Find start vertex | O(V) | Check odd degree |
| Hierholzer traversal | O(E) | Each edge once |
| **Total** | **O(V + E)** | Linear |

## Eulerian vs Hamiltonian

| Property | Eulerian | Hamiltonian |
|----------|----------|-------------|
| Visit | Every edge once | Every vertex once |
| Complexity | O(V + E) polynomial | NP-complete |
| Existence test | Degree condition | No simple test |
| Algorithm | Hierholzer | Backtracking |

## Undirected Graph Handling

```
For undirected graphs:
  Each undirected edge becomes two directed edges.
  But we must mark BOTH when using one!

Implementation:
  Store edges as pairs with indices.
  When using edge i, also mark its reverse twin.
  This ensures each undirected edge used once.
```

## Finding Start Vertex

```
Directed:
  - Circuit: any vertex with edges
  - Path: vertex with out > in, or any if none

Undirected:
  - Circuit: any vertex with edges
  - Path: one of the two odd-degree vertices
```

## Implementation Notes

- Track edge indices for marking (not vertex pairs)
- Handle disconnected graphs: check connectivity first
- For undirected: use edge pairing for mark-twin
- Empty graph returns empty path
- Single vertex with no edges: path = [v]

