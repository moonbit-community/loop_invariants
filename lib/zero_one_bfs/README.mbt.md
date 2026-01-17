# 0-1 BFS (Beginner-Friendly Guide)

0-1 BFS computes **shortest paths** when every edge weight is **0 or 1**.
It is faster than Dijkstra in this special case:

- Time: **O(V + E)**
- Space: **O(V + E)**

This package provides:

```
@zero_one_bfs.zero_one_bfs(graph, source) -> Array[Int]
@zero_one_bfs.Graph::new(n)
@zero_one_bfs.Graph::add_edge(u, v, weight)
@zero_one_bfs.Graph::add_undirected_edge(u, v, weight)
```

Unreachable vertices keep a large constant distance (`ZERO_ONE_INF` in code).

---

## 1) Why 0-1 BFS works

Dijkstra uses a priority queue to always pick the smallest distance next.
With weights only 0 or 1, we can do this with a **deque**:

```
weight 0 -> push to front (same distance)
weight 1 -> push to back  (distance + 1)
```

So the deque always keeps nodes in **non-decreasing distance order**.

---

## 2) Deque invariant (picture)

```
front -> [dist=2, dist=2, dist=3, dist=3, dist=4] -> back

If we relax a 0-edge, the new node has the SAME distance,
so it goes to the front.

If we relax a 1-edge, the new node is +1 distance,
so it goes to the back.
```

---

## 3) Step-by-step example

Graph:

```
0 --0--> 1 --1--> 3
|         |
1         1
v         v
2 --0--> 4 --0--> 3
```

Start at 0:

```
dist = [0, inf, inf, inf, inf]
deque = [0]

pop 0:
  0->1 (0): dist[1]=0, push_front(1)
  0->2 (1): dist[2]=1, push_back(2)
deque = [1, 2]

pop 1:
  1->3 (1): dist[3]=1, push_back(3)
  1->4 (1): dist[4]=1, push_back(4)
deque = [2, 3, 4]

pop 2:
  2->4 (0): dist[4] stays 1

pop 3, pop 4:
  no improvements

final dist = [0, 0, 1, 1, 1]
```

---

## 4) Example usage (directed)

```mbt check
///|
test "0-1 bfs example" {
  let g = @zero_one_bfs.Graph::new(5)
  g.add_edge(0, 1, 0)
  g.add_edge(1, 2, 1)
  g.add_edge(0, 2, 1)
  g.add_edge(2, 3, 0)
  g.add_edge(1, 3, 1)
  g.add_edge(3, 4, 1)
  let dist = @zero_one_bfs.zero_one_bfs(g, 0)
  inspect(dist, content="[0, 0, 1, 1, 2]")
}
```

---

## 5) Example usage (undirected)

```mbt check
///|
test "0-1 bfs undirected" {
  let g = @zero_one_bfs.Graph::new(4)
  g.add_undirected_edge(0, 1, 0)
  g.add_undirected_edge(1, 2, 1)
  g.add_undirected_edge(2, 3, 0)
  let dist = @zero_one_bfs.zero_one_bfs(g, 0)
  inspect(dist, content="[0, 0, 1, 1]")
}
```

---

## 6) Unreachable nodes

If a node is unreachable, its distance stays large.

```mbt check
///|
test "0-1 bfs unreachable" {
  let g = @zero_one_bfs.Graph::new(3)
  g.add_edge(0, 1, 1)
  let dist = @zero_one_bfs.zero_one_bfs(g, 0)
  inspect(dist[0], content="0")
  inspect(dist[1], content="1")
  // dist[2] is a large constant (unreachable)
  inspect(dist[2] > 1000000, content="true")
}
```

---

## 7) Common applications

```
Grid problems with 0/1 costs
Teleport edges (0 cost) + normal edges (1 cost)
Minimum obstacle removals (0 for empty, 1 for wall)
Graph problems where weights are only 0 or 1
```

---

## 8) 0-1 BFS vs others

```
BFS:        all edges weight 1
0-1 BFS:    weights in {0,1}
Dijkstra:   any non-negative weights
Bellman:    negative weights allowed
```

---

## 9) Common pitfalls

- Using it when weights are not 0 or 1.
- Forgetting that it is still **directed** unless you add both directions.
- Off-by-one errors when building the graph (0-indexed nodes).
