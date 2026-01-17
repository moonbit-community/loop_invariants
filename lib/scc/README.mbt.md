# Strongly Connected Components (SCC)

This package finds **strongly connected components** in a directed graph.
It implements:

- **Tarjan** (one DFS pass)
- **Kosaraju** (two DFS passes)

It also includes a **2‑SAT solver** built on SCCs.

---

## 1. What is an SCC?

An SCC is a **maximal set of vertices** where every vertex can reach every
other vertex.

If you compress each SCC into one node, the graph becomes a **DAG**.

---

## 2. Tiny visual example

```
Graph:
  0 → 1
  ↑   ↓
  2 ←─┘
  2 → 3

SCCs:
  {0,1,2}  (cycle)
  {3}
```

Condensation DAG:

```
 [0,1,2]  →  [3]
```

---

## 3. Why SCCs matter

SCCs let you:

- detect cycles,
- topologically sort components,
- solve 2‑SAT,
- simplify reachability problems by compressing the graph.

---

## 4. Tarjan’s algorithm (one‑pass DFS)

Tarjan uses two arrays:

```
disc[v] = discovery time
low[v]  = lowest discovery time reachable from v
```

A vertex `v` is the **root** of an SCC if:

```
disc[v] == low[v]
```

Then all vertices on the stack up to `v` form one SCC.

---

## 5. Tarjan step‑by‑step (small example)

Graph:

```
0 → 1 → 2 → 0
2 → 3
```

DFS order:

```
visit 0: disc=0, low=0
visit 1: disc=1, low=1
visit 2: disc=2, low=2
  edge 2→0 gives low[2]=0
visit 3: disc=3, low=3
  no back edge, so {3} is an SCC

backtrack:
low[1] = min(low[1], low[2]) = 0
low[0] = min(low[0], low[1]) = 0

disc[0] == low[0] -> pop {2,1,0} as SCC
```

Result: two SCCs {0,1,2} and {3}.

---

## 6. Kosaraju’s algorithm (two passes)

Steps:

1. DFS on original graph, record finish order.
2. Reverse all edges (transpose).
3. DFS in **reverse finish order** on the transpose.

Each DFS tree in pass 2 is one SCC.

Why it works:

- SCCs become nodes in a DAG.
- Finishing order puts sink SCCs last.
- Reversing edges lets us reach exactly one SCC at a time.

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

## 8. What `SCCResult` contains

```
num_sccs    = number of components
component   = component index for each vertex
scc_sizes   = size of each SCC
scc_adj     = DAG of SCCs (condensation graph)
```

---

## 9. 2‑SAT with SCC (friendly version)

Each clause `(a OR b)` becomes implications:

```
NOT a → b
NOT b → a
```

Then:

```
If x and NOT x are in the same SCC, the formula is unsatisfiable.
```

If it is satisfiable, the topological order of SCCs gives an assignment.

---

## 10. Example: 2‑SAT usage

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
Tarjan:    O(V + E)
Kosaraju:  O(V + E)
Space:     O(V + E)
```

---

## 12. Beginner checklist

1. SCC only applies to **directed** graphs.
2. SCCs form a **DAG** when compressed.
3. Tarjan uses low‑link values and a stack.
4. Kosaraju uses a second DFS on the transpose.
5. 2‑SAT reduces directly to SCC.

---

## 13. Summary

SCCs reveal the “cycle structure” of a directed graph.

Tarjan is one‑pass and fast; Kosaraju is conceptually simple.
Both are linear time and are essential for 2‑SAT and graph compression.
