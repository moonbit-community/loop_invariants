# Push‑Relabel Max Flow (Preflow‑Push)

This package computes maximum flow using **push‑relabel** (also called
preflow‑push). It is a fast, local algorithm that often performs very well on
dense graphs.

---

## 1. The problem (quick recap)

We have a directed graph with capacities on edges.

We want the **maximum total flow** from source `s` to sink `t` while respecting:

- **capacity**: flow ≤ capacity on each edge
- **conservation**: for every vertex except s and t, incoming flow = outgoing flow

---

## 2. Push‑relabel idea in one picture

Instead of finding global augmenting paths, push‑relabel works **locally**:

```
Each node stores:
  excess(v)  = flow_in - flow_out
  height(v)  = "level" used to guide pushes

Only push from higher to lower:
  h(u) = h(v) + 1   (admissible edge)
```

If a node has excess but no admissible edge, we **relabel** it higher.

---

## 3. Preflow vs flow

Push‑relabel temporarily allows **excess** at nodes:

```
Flow:    in(v) == out(v)   (for all v except s, t)
Preflow: in(v) >= out(v)   (excess is allowed)
```

The algorithm’s job is to move all excess to the sink (or back to the source).

---

## 4. The two operations

### Push

If we have an admissible edge (u → v) with remaining capacity:

```
delta = min(excess[u], residual(u,v))
push delta from u to v
```

### Relabel

If u has excess but no admissible edge, raise its height:

```
h(u) = 1 + min{ h(v) | residual(u,v) > 0 }
```

This creates a new admissible edge.

---

## 5. Visual intuition (tiny diagram)

```
Heights:
  h(s) = n
  h(t) = 0

Example:
  u (h=3, excess=5)
   \
    v (h=2)

Edge u->v is admissible because h(u) = h(v) + 1.
So we push from u down to v.
```

---

## 6. Step‑by‑step mini example

Graph:

```
0 --(3)--> 1 --(2)--> 3
 \         |         ^
  \(2)     |(1)      |
    \      v         |
      --> 2 --(4)----+

s = 0, t = 3
```

Capacities:

```
0->1:3, 0->2:2, 1->2:1, 1->3:2, 2->3:4
```

Initialize:

```
height[0]=4 (n), others 0
push all from source:
  excess[1]=3, excess[2]=2
```

Now process node 1:

```
h(1)=0, no admissible edge
relabel h(1)=1
push 2 to node 3 (capacity 2)
excess[1]=1, excess[3]=2
```

Process node 2:

```
h(2)=0 -> relabel to 1
push 2 to node 3 (capacity 4)
excess[2]=0, excess[3]=4
```

Node 1 still has excess 1:

```
push 1 to node 2 (edge 1->2)
then node 2 pushes to 3
```

Total flow = 5 (max).

---

## 7. Example usage (public API)

```mbt check
///|
test "push-relabel example" {
  let pr = @push_relabel_max_flow.PushRelabel::new(6)
  pr.add_edge(0, 1, 16L)
  pr.add_edge(0, 2, 13L)
  pr.add_edge(1, 2, 10L)
  pr.add_edge(2, 1, 4L)
  pr.add_edge(1, 3, 12L)
  pr.add_edge(2, 4, 14L)
  pr.add_edge(3, 2, 9L)
  pr.add_edge(4, 3, 7L)
  pr.add_edge(3, 5, 20L)
  pr.add_edge(4, 5, 4L)
  let flow = pr.max_flow(0, 5)
  inspect(flow, content="23")
}
```

---

## 8. Why it works (invariants)

Push‑relabel maintains:

1. **Capacity**: 0 ≤ flow ≤ capacity
2. **Preflow**: excess(v) ≥ 0 for v ≠ s
3. **Height rule**: for residual edge (u,v), h(u) ≤ h(v) + 1

These guarantee the algorithm terminates and produces a max flow.

---

## 9. Complexity (rule of thumb)

```
Worst case: O(V^2 E)
```

But with heuristics (highest label, gap, global relabel), it is very fast in
practice, especially on dense graphs.

---

## 10. Common applications

1. **Max flow / min cut**
2. **Bipartite matching**
3. **Image segmentation** (graph cuts)
4. **Network design**

---

## 11. Beginner tips

1. Push‑relabel is **local**: no augmenting path search.
2. Excess is allowed (preflow), so intermediate states may look “invalid.”
3. Heights only increase.
4. Always keep residual edges (for backflow).

---

## 12. Summary

Push‑relabel solves max flow by pushing local excess downhill and relabeling
when stuck. It is simple, powerful, and one of the best practical choices for
large or dense networks.
