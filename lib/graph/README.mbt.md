# Graph Algorithms (Reference + Invariants)

## What This Package Is

This package is a **teaching collection** of classic graph algorithms with
extra correctness notes in the source. The code favors clarity and invariants
so you can see *why* an algorithm works, not just *how* it runs.

If you need production-ready APIs, use the dedicated packages (for example
`@dijkstra`, `@union_find`, `@max_flow`, `@scc`, etc.). This package is meant
as the readable reference and a place to study loop invariants.

## File Map (Read This First)

- `lib/graph/graph.mbt`: topological sort, Dijkstra, Union-Find,
  Bellman-Ford, Floyd-Warshall.
- `lib/graph/tarjan.mbt`: Tarjan SCC with explicit stack reasoning.
- `lib/graph/more_graph.mbt`: bipartite check, cycle detection, Kosaraju SCC,
  Prim MST, Kruskal MST, additional shortest-path variants.
- `lib/graph/network_flow.mbt`: Edmonds-Karp, Dinic, min-cost max-flow,
  bipartite matching, Hungarian algorithm for assignment.

## Graph Basics (Very Short, Very Practical)

We use 0-based vertex indices.

- Directed edge: `u -> v`
- Undirected edge: `u -- v` (implemented as two directed edges)
- Weighted edge: `(u, v, w)` with `w` as the weight/capacity

Adjacency list conventions:

```
Unweighted:
  graph[u] = [v1, v2, v3]

Weighted:
  graph[u] = [(v1, w1), (v2, w2)]
```

Example (undirected triangle 0-1-2-0):

```
graph[0] = [1, 2]
graph[1] = [0, 2]
graph[2] = [0, 1]
```

### Minimal adjacency list builder

```mbt check
///|
fn build_adj(n : Int, edges : ArrayView[(Int, Int)]) -> Array[Array[Int]] {
  let adj : Array[Array[Int]] = [ for _ in 0..<n => [] ]
  for edge in edges {
    let (u, v) = edge
    if u < 0 || u >= n || v < 0 || v >= n {
      continue
    }
    // Undirected graph: add both directions.
    adj[u].push(v)
    adj[v].push(u)
  }
  adj
}

///|
test "build adjacency list" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
  let adj = build_adj(3, edges[:])
  let a0 = adj[0].copy()
  let a1 = adj[1].copy()
  a0.sort()
  a1.sort()
  inspect(a0, content="[1, 2]")
  inspect(a1, content="[0, 2]")
}
```

### BFS vs DFS (when to use which)

- **BFS**: shortest path in *unweighted* graphs, level order traversal.
- **DFS**: exploring components, topological order, cycle detection.

BFS example (levels from node 0):

```
0 -- 1 -- 2
|    |
3 -- 4

levels from 0:
0: {0}
1: {1, 3}
2: {2, 4}
```

```mbt check
///|
fn bfs_levels(adj : Array[Array[Int]], source : Int) -> Array[Int] {
  let n = adj.length()
  let dist = Array::make(n, -1)
  dist[source] = 0
  let queue : Array[Int] = [source]
  let _ = for head = 0 {
    match queue.get(head) {
      None => break ()
      Some(u) => {
        for v in adj[u] {
          if dist[v] < 0 {
            dist[v] = dist[u] + 1
            queue.push(v)
          }
        }
        continue head + 1
      }
    }
  }
  dist
}

///|
test "bfs levels" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (0, 3), (1, 4), (3, 4)]
  let adj = build_adj(5, edges[:])
  let dist = bfs_levels(adj, 0)
  inspect(dist, content="[0, 1, 2, 1, 2]")
}
```

## How to Read the Invariants

Some loops have a `where` block with `invariant` and `reasoning`. Those are
Dafny-style loop specs written in plain language. Read them as:

- **Invariant**: What must stay true at each step
- **Reasoning**: Why the loop preserves that truth
- **Termination**: Why the loop finishes

Simple `for .. in` loops usually skip invariants to keep the code focused.

# Algorithms, Explained With Stories and Examples

## 1) Topological Sort (Kahn's Algorithm)

**Problem**: Order tasks so every dependency comes before the task that needs it.

**Idea**: Only tasks with no remaining prerequisites can be taken now.

Example DAG:

```
A -> B -> D
|    |
V    V
C -> E
```

**Step-by-step**:

```
In-degrees:
A:0 B:1 C:1 D:1 E:2

Queue starts with [A]
Pop A -> output [A], decrement B and C
Queue now [B, C]
Pop B -> output [A, B], decrement D and E
Queue now [C, D]
Pop C -> output [A, B, C], decrement E
Queue now [D, E]
Pop D -> output [A, B, C, D]
Pop E -> output [A, B, C, D, E]
```

If the queue becomes empty before all vertices are output, there is a cycle.

## 2) Single-Source Shortest Paths

### 2.1 Dijkstra (Non-Negative Weights)

**Problem**: Fast shortest paths when all edges have `w >= 0`.

**Idea**: Once a node is the smallest tentative distance, it can never improve.

Example:

```
0 --1--> 1 --2--> 3
|         |
4         1
|         |
V         V
2 --1-->  3
```

**Walkthrough (dist table)**:

```
Start: dist[0]=0, others=inf
Pick 0: relax 1 -> 1, relax 2 -> 4
Pick 1: relax 3 -> 3 (via 1)
Pick 2: relax 3 -> min(3, 5) = 3
Done
```

**Pitfall**: Dijkstra fails with negative weights.

### 2.2 Bellman-Ford (Negative Weights, Detects Cycles)

**Idea**: After k full edge scans, all shortest paths using <= k edges are known.

Example:

```
0 --1--> 1 --(-2)--> 2

Shortest to 2 is -1
```

**Negative cycle check**:
If you can still relax an edge after `n-1` rounds, a negative cycle exists.

Example negative cycle:

```
0 -> 1 (1)
1 -> 2 (1)
2 -> 0 (-3)

Cycle total = -1, distances can shrink forever.
```

### 2.3 Floyd-Warshall (All Pairs)

**Idea**: Allow more and more intermediate vertices in paths.

Matrix update:

```
for k in 0..n-1:
  for i in 0..n-1:
    for j in 0..n-1:
      dist[i][j] = min(dist[i][j], dist[i][k] + dist[k][j])
```

Tiny example (n=3):

```
Initial dist:
  0  5  9
  5  0  2
  9  2  0

Allow k=1 as intermediate:
  dist[0][2] = min(9, dist[0][1] + dist[1][2]) = min(9, 5+2) = 7
```

**Use when**: `n` is small (O(n^3)), but you need every pair.

## 3) Union-Find (Disjoint Set Union)

**Problem**: Keep track of connected components under unions.

```
Start: {0}, {1}, {2}, {3}, {4}
union(0,1) -> {0,1}
union(2,3) -> {2,3}
union(1,2) -> {0,1,2,3}
```

Path compression + union by rank gives near O(1) per operation.

Visual intuition:

```
Before compression:
0 <- 1 <- 2 <- 3

After find(3):
0 <- 1
0 <- 2
0 <- 3
```

## 4) Strongly Connected Components (SCC)

A **SCC** is a maximal group where every vertex can reach every other.

### 4.1 Tarjan (One DFS + Stack)

Key intuition:

- `disc[v]`: when `v` was first visited
- `low[v]`: earliest discovery reachable from `v` while staying on the stack

```
When disc[v] == low[v], v is the root of an SCC.
Pop stack until v to get the SCC.
```

Example:

```
0 -> 1 -> 2 -> 0
2 -> 3 -> 4 -> 3

SCCs: {0,1,2} and {3,4}
```

Condensation graph (SCC DAG):

```
{0,1,2} -> {3,4}
```

### 4.2 Kosaraju (Two DFS Passes)

1) DFS on original graph, record finish order
2) DFS on reversed graph in reverse finish order

This cleanly finds SCCs in topological order of the SCC DAG.

## 5) Bipartite Check and Cycle Detection

### 5.1 Bipartite Check (BFS Coloring)

**Rule**: adjacent vertices must have opposite colors.

```
Square 0-1-2-3-0 is bipartite:
Colors alternate 0/1 on BFS layers.
```

If you ever see an edge between same-colored vertices, there is an odd cycle.

### 5.2 Directed Cycle Detection (DFS States)

Use three states:

- WHITE (unvisited)
- GRAY (in recursion stack)
- BLACK (finished)

Encountering a GRAY neighbor means a back edge -> cycle.

## 6) Minimum Spanning Tree (MST)

### 6.1 Prim (Grow a Tree)

Maintain the cheapest edge that connects the current tree to any new vertex.

```
Start at 0
Always pick smallest crossing edge
```

### 6.2 Kruskal (Sort Edges)

Sort edges by weight and add if they do not create a cycle.

```
Use Union-Find to test if two endpoints are already connected.
```

Mini example:

```
Edges (weight):
0-1 (1), 1-2 (4), 0-2 (2)

Pick 0-1 (1), then 0-2 (2)
Skip 1-2 (4) because it would create a cycle.
```

## 7) Network Flow and Matching

### 7.1 Max Flow (Edmonds-Karp)

**Idea**: Repeatedly find an augmenting path in the residual graph.

Example:

```
source ->(10)-> A ->(10)-> sink
source ->(10)-> B ->(10)-> sink

Max flow = 20
```

Augmenting path view:

```
Residual path: source -> A -> sink
Send 10, capacities drop to 0 on that path.
Then use: source -> B -> sink
Send 10, total = 20.
```
Edmonds-Karp uses BFS to find shortest augmenting paths.

### 7.2 Dinic (Faster Max Flow)

- Build level graph with BFS
- Send blocking flows with DFS
- Repeat until sink is unreachable

### 7.3 Min-Cost Max-Flow

Each edge has a cost; find the cheapest way to push as much flow as possible.
This implementation uses SPFA for shortest augmenting paths in the residual
network.

### 7.4 Bipartite Matching via Flow

Left side -> Right side edges become capacity-1 edges.
Max flow equals maximum matching.

Bipartite to flow sketch:

```
source -> L0, L1, L2 (cap 1)
L nodes -> R nodes (cap 1)
R0, R1, R2 -> sink (cap 1)
```

### 7.5 Assignment Problem (Hungarian Algorithm)

Given a cost matrix, pick one column per row with minimum total cost.
Hungarian runs in O(n^3) and is optimal for dense assignment problems.

Small example (rows are workers, columns are jobs):

```
cost =
  [4, 1, 3]
  [2, 0, 5]
  [3, 2, 2]

Optimal assignment:
  row0 -> col1 (1)
  row1 -> col0 (2)
  row2 -> col2 (2)
Total cost = 5
```

# Algorithm Selection Guide

| Problem | Use | Constraints |
|--------|-----|-------------|
| Task ordering | Topological sort | DAG only |
| Shortest path (non-negative) | Dijkstra | w >= 0 |
| Shortest path (negative) | Bellman-Ford | no neg cycle |
| All-pairs shortest | Floyd-Warshall | small n |
| Connectivity | Union-Find | unions + finds |
| SCCs | Tarjan or Kosaraju | directed graphs |
| MST | Prim (dense), Kruskal (sparse) | undirected |
| Max flow | Edmonds-Karp or Dinic | capacities >= 0 |
| Min-cost flow | SPFA MCMF | capacities + costs |
| Matching | Flow or Hungarian | bipartite |

# Common Pitfalls

- Dijkstra fails with negative edges.
- Floyd-Warshall needs a safe INF to avoid overflow.
- Topological sort returns fewer than n nodes if a cycle exists.
- In flow algorithms, do not forget the reverse edges in the residual graph.
- In SCC problems, do not mix up directed and undirected edges.

# Complexity Cheat Sheet

| Algorithm | Time | Notes |
|----------|------|-------|
| Kahn topological sort | O(V + E) | DAG only |
| Dijkstra (binary heap) | O((V + E) log V) | non-negative weights |
| Bellman-Ford | O(VE) | negative edges ok |
| Floyd-Warshall | O(V^3) | all pairs |
| Union-Find | ~O(1) | inverse Ackermann |
| Tarjan SCC | O(V + E) | one DFS |
| Kosaraju SCC | O(V + E) | two DFS |
| Prim MST | O(V^2) or O(E log V) | depends on PQ |
| Kruskal MST | O(E log E) | sort edges |
| Edmonds-Karp | O(VE^2) | BFS augmenting paths |
| Dinic | O(V^2 E) | faster in practice |
| Min-cost max-flow | varies | depends on shortest path |
| Hungarian | O(n^3) | assignment |

# Where to Go Next

- Read the annotated source files in this package for invariant details.
- For reusable APIs, see the specialized packages mentioned above.
- For performance-critical code, check the dedicated implementations in `lib/`.
