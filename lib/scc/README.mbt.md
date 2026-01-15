# Strongly Connected Components (SCC)

## Overview

A **Strongly Connected Component** is a maximal set of vertices where every
vertex can reach every other vertex. This package implements both **Tarjan's**
and **Kosaraju's** algorithms.

- **Time**: O(V + E)
- **Space**: O(V)

## Core Idea

- Use DFS to discover **cycles of mutual reachability**.
- Tarjan tracks **low-link** values to find SCC roots in one pass.
- Kosaraju uses **reverse finish order** on the transposed graph.

## Visual Example

```
Graph:                    SCCs:
    0 ──→ 1              ┌─────────┐    ┌───┐
    ↑     │              │ 0  1  2 │    │ 3 │
    │     ↓              │  (cycle)│    │   │
    └──── 2 ──→ 3        └─────────┘    └───┘
          ↑
          │              SCC 1: {0,1,2} - all can reach each other
          └──────────    SCC 2: {3} - no outgoing edges back
```

## Why SCCs Matter

When you contract each SCC to a single node, you get a **DAG** (Directed Acyclic Graph):

```
Original:                   Condensation DAG:
    0 → 1                       [0,1,2]
    ↑   ↓                          │
    └── 2 → 3                      ↓
                                  [3]

The DAG enables:
- Topological sorting of components
- DP on the component graph
- Identifying bottlenecks in connectivity
```

## Tarjan's Algorithm

Uses a single DFS with discovery times and low-link values.

### Key Concepts

```
disc[v] = Discovery time (when first visited)
low[v]  = Lowest discovery time reachable from v's subtree

A vertex v is the ROOT of its SCC when: disc[v] == low[v]
```

### Algorithm Walkthrough

```
Graph: 0 → 1 → 2 → 0, 2 → 3

DFS from 0:

Visit 0: disc[0]=0, low[0]=0, push 0
         Stack: [0]

Visit 1: disc[1]=1, low[1]=1, push 1
         Stack: [0, 1]

Visit 2: disc[2]=2, low[2]=2, push 2
         Stack: [0, 1, 2]

  Edge 2→0: 0 is on stack!
           low[2] = min(2, disc[0]) = 0

  Edge 2→3:
    Visit 3: disc[3]=3, low[3]=3, push 3
             Stack: [0, 1, 2, 3]

    No outgoing edges from 3
    disc[3] == low[3], so 3 is SCC root
    Pop until 3: SCC = {3}
    Stack: [0, 1, 2]

  Back to 2: low[2] = 0

Back to 1: low[1] = min(1, low[2]) = 0

Back to 0: low[0] = 0
          disc[0] == low[0], so 0 is SCC root
          Pop until 0: SCC = {2, 1, 0}

Result: 2 SCCs: {0,1,2} and {3}
```

### The Stack Invariant

```
Stack contains exactly:
1. Current DFS path (root to current node)
2. Nodes that can still reach back to the path

When disc[v] == low[v]:
- v cannot reach any earlier node
- All nodes above v in stack form v's SCC
- Pop them all and assign to same component
```

## Kosaraju's Algorithm

Uses two DFS passes with graph transposition.

```
Pass 1: DFS on original graph
        Record finish times in post-order

Pass 2: Transpose graph (reverse all edges)
        DFS in reverse finish order

Why it works:
- If u can reach v in original graph
- Then v can reach u in transposed graph
- Processing in reverse finish order ensures
  we start from "sink" SCCs first
```

## Example Usage

```mbt check
///|
test "scc example" {
  let adj : Array[Array[Int]] = Array::makei(4, _ => [])
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

## Common Applications

### 1. 2-SAT Problem

```
Variables: x₀, x₁, x₂, ...
Clauses: (x₀ OR x₁), (NOT x₁ OR x₂), ...

Build implication graph:
  (a OR b) becomes: NOT a → b, NOT b → a

Satisfiable iff: For all i, xᵢ and NOT xᵢ are in different SCCs

Assignment: xᵢ = true if xᵢ's SCC comes after NOT xᵢ's SCC
```

### 2. Condensation Graph

```
Contract each SCC to a single node.
Result is a DAG - enables:
- Topological sort
- Shortest/longest paths
- DP on components
```

### 3. Reachability Analysis

```
Within an SCC: Everyone can reach everyone
Between SCCs: Follow the DAG structure

Use case: Finding critical connections in networks
```

### 4. Compiler Optimization

```
Call graph analysis:
- Functions in same SCC are mutually recursive
- SCCs in DAG order = safe compilation order
```

## Algorithm Comparison

| Algorithm | Passes | Space | Best For |
|-----------|--------|-------|----------|
| **Tarjan** | 1 DFS | O(V) | Single pass, online |
| **Kosaraju** | 2 DFS | O(V+E)* | Conceptually simpler |

*Kosaraju needs space for transposed graph.

## Complexity Analysis

```
Tarjan's Algorithm:
- Each vertex pushed/popped once: O(V)
- Each edge examined once: O(E)
- Total: O(V + E)

Kosaraju's Algorithm:
- First DFS: O(V + E)
- Build transpose: O(V + E)
- Second DFS: O(V + E)
- Total: O(V + E)
```

## The SCCResult Structure

```
num_sccs:    Number of strongly connected components
component[v]: Which SCC vertex v belongs to
scc_sizes[i]: Size of SCC i
scc_adj:     Condensation graph (DAG of SCCs)
```

## Implementation Tips

- Tarjan: Use iterative version for very deep graphs
- Stack overflow: Consider explicit stack for large graphs
- 2-SAT: Component indices give topological order (reversed)
- Condensation: Remember to handle multi-edges
