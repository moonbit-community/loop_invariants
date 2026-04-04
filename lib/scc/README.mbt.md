# Strongly Connected Components (SCC)

This package finds **strongly connected components** in a directed graph.
It implements:

- **Tarjan** (one DFS pass, low-link values)
- **Kosaraju** (two DFS passes, transpose graph)

It also includes a **2-SAT solver** built on SCCs.

---

## 1. What is an SCC?

An SCC is a **maximal set of vertices** where every vertex can reach every
other vertex via directed paths.

If you compress each SCC into one node, the graph becomes a **DAG**
(directed acyclic graph), called the **condensation**.

---

## 2. Directed graph with multiple SCCs

The graph below has five vertices grouped into three SCCs:

```
   +-------+       +-------+       +-------+
   |  0    |       |  1    |       |  2    |
   |       | ----> |       | ----> |       |
   |  (A)  | <---  |  (A)  |       |  (B)  | <---+
   +-------+       +-------+       +-------+     |
                       |                         |
                       v           +-------+     |
                               +-> |  3    |-----+
                                   |  (B)  |
                                   +-------+
                                       |
                                       v
                                   +-------+
                                   |  4    |
                                   |  (C)  |
                                   +-------+
```

Edges:

```
0 <-> 1         (bidirectional: SCC A = {0, 1})
1  -> 3         (exit from A)
2 <-> 3         (bidirectional: SCC B = {2, 3})
3  -> 4         (exit from B)
                (SCC C = {4}, no outgoing edges)
```

SCCs:

```
  A = {0, 1}
  B = {2, 3}
  C = {4}
```

Condensation DAG (contracting each SCC to a single node):

```
  [A: 0,1]  -->  [B: 2,3]  -->  [C: 4]
```

---

## 3. Why SCCs matter

SCCs let you:

- detect cycles in directed graphs,
- topologically sort components (via condensation),
- solve 2-SAT,
- simplify reachability by compressing the graph.

---

## 4. Tarjan's algorithm (one-pass DFS)

Tarjan uses two per-vertex arrays assigned during DFS:

```
disc[v]  = discovery time (when v was first visited)
low[v]   = lowest disc[] reachable from v's subtree
           via back edges still on the DFS stack
```

A vertex `v` is the **root** of its SCC when:

```
disc[v] == low[v]
```

At that point, all vertices on the stack from `v` upward form one SCC.

---

## 5. Tarjan step-by-step

Graph:

```
  0 --> 1 --> 2 --> 0
              |
              v
              3
```

Edges: `0->1`, `1->2`, `2->0`, `2->3`

DFS trace (timer starts at 0):

```
Step 1  visit 0 : disc[0]=0  low[0]=0   stack=[0]
Step 2  visit 1 : disc[1]=1  low[1]=1   stack=[0,1]
Step 3  visit 2 : disc[2]=2  low[2]=2   stack=[0,1,2]
          edge 2->0 : 0 is on stack
          -> low[2] = min(low[2], disc[0]) = min(2,0) = 0
Step 4  visit 3 : disc[3]=3  low[3]=3   stack=[0,1,2,3]
          no back edges
          disc[3]==low[3] -> root found
          pop stack until 3: pop {3}  -> SCC_0 = {3}
          stack=[0,1,2]
Step 5  return to 2 : disc[2]=2  low[2]=0
          disc[2] != low[2] -> not a root
Step 6  return to 1 : low[1] = min(low[1], low[2]) = min(1,0) = 0
          disc[1] != low[1] -> not a root
Step 7  return to 0 : low[0] = min(low[0], low[1]) = min(0,0) = 0
          disc[0]==low[0] -> root found
          pop stack until 0: pop {2,1,0}  -> SCC_1 = {0,1,2}
          stack=[]
```

Result:

```
  SCC_0 = {3}       (sink, no outgoing edges)
  SCC_1 = {0,1,2}   (the cycle)

  Condensation: SCC_1 --> SCC_0
```

Note: Tarjan numbers SCCs in reverse topological order (sink SCCs get
lower numbers).

---

## 5b. Kosaraju's two-pass algorithm

Kosaraju uses two full DFS passes:

**Pass 1** — run DFS on the original graph and record vertices in
post-order (finish order):

```
Graph: 0->1->2->0, 2->3

DFS from 0 (one possible traversal):
  enter 0 -> enter 1 -> enter 2
    enter 3, finish 3
    (back edge 2->0 skipped, 0 already visited)
  finish 2, finish 1, finish 0

Post-order (finish list): [3, 2, 1, 0]
```

**Transpose** — reverse every edge:

```
Original  : 0->1, 1->2, 2->0, 2->3
Transposed: 1->0, 2->1, 0->2, 3->2
```

**Pass 2** — process vertices in reverse finish order (`0,1,2,3`) on the
transposed graph. Each DFS tree is one SCC:

```
Process 0 (component=-1): DFS on transpose reaches {0,1,2} -> SCC_0
Process 1 (already in SCC_0): skip
Process 2 (already in SCC_0): skip
Process 3 (component=-1): DFS on transpose reaches {3}     -> SCC_1
```

Result: same two SCCs as Tarjan.

---

## 6. Condensation DAG

After finding SCCs, the package builds `scc_adj`: the condensation DAG
where each SCC becomes a node and edges between SCCs are preserved
(duplicates removed).

```
SCCResult fields:
  num_sccs  = number of SCCs
  component = component[v] gives the SCC index of vertex v
  scc_sizes = scc_sizes[i] gives the number of vertices in SCC i
  scc_adj   = condensation DAG adjacency list
```

Example for `0->1->2->0, 2->3`:

```
  component = [1, 1, 1, 0]     (vertices 0,1,2 in SCC 1; vertex 3 in SCC 0)
  scc_sizes = [1, 3]            (SCC 0 has 1 vertex, SCC 1 has 3 vertices)
  scc_adj   = [[],  [0]]        (SCC 1 has edge to SCC 0; SCC 0 has none)
  num_sccs  = 2
```

---

## 7. Example usage (public API)

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

---

## 8. Extra example: condensation DAG

```mbt check
///|
test "scc condensation dag" {
  let adj : Array[Array[Int]] = Array::makei(5, _ => [])
  // SCC A: 0 <-> 1
  adj[0].push(1)
  adj[1].push(0)
  // SCC B: 2 <-> 3
  adj[2].push(3)
  adj[3].push(2)
  // Edge A -> B, and B -> 4
  adj[1].push(2)
  adj[3].push(4)
  let res = @scc.find_sccs(5, adj)
  inspect(res.num_sccs, content="3")
  let c0 = res.component[0]
  let c2 = res.component[2]
  let c4 = res.component[4]
  inspect(c0 != c2 && c2 != c4, content="true")
}
```

---

## 9. 2-SAT with SCC

**2-SAT** is a boolean satisfiability problem where every clause contains
exactly two literals.

Each clause `(a OR b)` is encoded as two directed implications:

```
(a OR b)  ==  (NOT a => b)  AND  (NOT b => a)
```

Build an implication graph with `2n` vertices:

```
  vertex i     = variable xᵢ  (positive)
  vertex i + n = variable ¬xᵢ (negated)
```

Add edges for every implication, then run SCC:

```
  UNSATISFIABLE : xᵢ and ¬xᵢ are in the same SCC
                  (they imply each other => contradiction)

  SATISFIABLE   : for each i, choose the literal whose SCC
                  comes later in topological order
                  (higher SCC index in Tarjan's numbering)
```

Mini example — clause `(x OR y)`:

```
  Implication graph:
    ¬x --> y
    ¬y --> x

  If x and ¬x end up in the same SCC: impossible.
  Otherwise pick the assignment from topological SCC order.
```

---

## 10. Example: 2-SAT usage

```mbt check
///|
test "two sat example" {
  let ts = @scc.TwoSAT::new(2)

  // (x0 OR x1)
  ts.add_clause(0, true, 1, true)

  // (NOT x0 OR x1)
  ts.add_clause(0, false, 1, true)
  let ans = ts.solve()
  inspect(ans is Some(_), content="true")
}
```

---

## 11. Complexity

```
Tarjan:    O(V + E)  time,  O(V)     extra space
Kosaraju:  O(V + E)  time,  O(V + E) extra space (transpose)
2-SAT:     O(V + E)  time
```

---

## 12. Beginner checklist

1. SCC only applies to **directed** graphs.
2. SCCs partition the vertex set — each vertex belongs to exactly one SCC.
3. The condensation of any directed graph is always a DAG.
4. Tarjan finds SCCs in one DFS using `disc` and `low` arrays.
5. Kosaraju finds SCCs in two DFS passes using the transpose graph.
6. 2-SAT reduces directly to SCC in linear time.

---

## 13. Summary

SCCs reveal the cycle structure of a directed graph.

- **Tarjan** is one-pass and uses only `O(V)` extra space; it produces
  SCCs in reverse topological order.
- **Kosaraju** is two-pass and conceptually simpler, but needs `O(V + E)`
  extra space for the transpose graph.
- **2-SAT** encodes each clause as implications, then checks whether any
  variable and its negation fall in the same SCC.

Both SCC algorithms run in `O(V + E)` time and are essential tools for
graph analysis, compiler optimization, and constraint solving.
