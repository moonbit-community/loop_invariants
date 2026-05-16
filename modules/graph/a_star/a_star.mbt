// ============================================================================
// A* SEARCH  -  Hart, Nilsson, Raphael (1968)
// ============================================================================
//
// PROBLEM
//
// Given a weighted directed graph with non-negative edge costs and a
// **heuristic** function `h(v)` that estimates the remaining cost from
// `v` to the goal, find the shortest path from a source `s` to a target
// `t` while expanding as few vertices as possible.
//
// A* generalises Dijkstra by ordering the priority queue on
// `f(v) = g(v) + h(v)`, where `g(v)` is the best known cost from `s`
// to `v`. When `h` is **admissible** (never overestimates) **and
// consistent** (`h(u) <= w(u, v) + h(v)` for every edge), A* finds
// the optimal path and is also "optimally efficient": no algorithm
// using the same heuristic can expand fewer vertices.
//
// Setting `h ≡ 0` recovers Dijkstra; the more accurately `h` estimates
// the true remaining cost, the closer A* gets to expanding only the
// vertices on the optimal path.
//
// COMPLEXITY
//
// With a consistent heuristic, every vertex is settled at most once, so
//
//   Time : O((V + E) log V) with a binary heap, same as Dijkstra,
//          but the constant is *much* smaller because the heap is
//          driven by f rather than g.
//   Space: O(V) for distances and predecessors.
//
// THE INVARIANT
//
//   "When a vertex u is popped from the open-set with g(u) = d,
//    d equals the true shortest-path cost from s to u."
//
// This is the standard Dijkstra invariant. Consistency of `h` plus
// non-negative edges keeps the popped `f` values monotonically
// non-decreasing, which is exactly what makes the argument go through.

///|
/// A directed weighted edge `u -> v` with non-negative cost `w`.
pub(all) struct Edge {
  to : Int
  w : Int64
}

///|
priv struct HeapEntry {
  f : Int64 // priority = g + h
  g : Int64 // distance from source so far
  v : Int
}

///|
priv struct MinHeap {
  data : Array[HeapEntry]
}

///|
fn MinHeap::new() -> MinHeap {
  { data: [] }
}

///|
fn MinHeap::push(self : MinHeap, e : HeapEntry) -> Unit {
  self.data.push(e)
  let mut i = self.data.length() - 1
  while i > 0 {
    let p = (i - 1) / 2
    if self.data[i].f < self.data[p].f {
      let t = self.data[i]
      self.data[i] = self.data[p]
      self.data[p] = t
      i = p
    } else {
      break
    }
  }
}

///|
fn MinHeap::pop(self : MinHeap) -> HeapEntry? {
  let n = self.data.length()
  if n == 0 {
    return None
  }
  let top = self.data[0]
  let last = self.data[n - 1]
  self.data.pop() |> ignore
  if n > 1 {
    self.data[0] = last
    let m = self.data.length()
    let mut i = 0
    while true {
      let l = 2 * i + 1
      let r = 2 * i + 2
      let mut best = i
      if l < m && self.data[l].f < self.data[best].f {
        best = l
      }
      if r < m && self.data[r].f < self.data[best].f {
        best = r
      }
      if best == i {
        break
      }
      let t = self.data[i]
      self.data[i] = self.data[best]
      self.data[best] = t
      i = best
    }
  }
  Some(top)
}

///|
/// Result of an A* search.
///
/// - `dist`     : `Some(d)` if the target was reached with cost `d`,
///                `None`    if no path exists.
/// - `path`     : the actual vertex sequence from `source` to `target`,
///                or `[]` when `dist` is `None`.
/// - `expanded` : how many vertices were finalised (popped); useful
///                for comparing heuristics empirically.
pub(all) struct AStarResult {
  dist : Int64?
  path : Array[Int]
  expanded : Int
}

///|
/// A* shortest path.
///
/// - `n`        : number of vertices, labelled `0 ..< n`.
/// - `adj[u]`   : outgoing edges from `u`. Costs must be non-negative.
/// - `source`   : starting vertex.
/// - `target`   : goal vertex.
/// - `heuristic`: `h(v)` -- estimate of remaining cost from `v` to
///                `target`. Must be admissible (`<=` true remaining
///                cost) for optimality; **consistent** for optimal
///                efficiency.
///
/// Returns dist/path/expanded. When `heuristic = fn _ { 0L }`, A*
/// reduces to Dijkstra.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let edges = [[{ to: 1, w: 1L }, { to: 2, w: 4L }], [{ to: 2, w: 2L }], []]
///   let r = @a_star.a_star(3, edges, 0, 2, _ => 0L)
///   @debug.assert_eq(r.dist, Some(3L))
/// }
/// ```
pub fn a_star(
  n : Int,
  adj : Array[Array[Edge]],
  source : Int,
  target : Int,
  heuristic : (Int) -> Int64,
) -> AStarResult {
  let inf : Int64 = 9223372036854775807L
  let g = Array::make(n, inf)
  let parent = Array::make(n, -1)
  let closed = Array::make(n, false)
  if source < 0 || source >= n || target < 0 || target >= n {
    return { dist: None, path: [], expanded: 0 }
  }
  g[source] = 0L
  let open_set = MinHeap::new()
  open_set.push({ f: heuristic(source), g: 0L, v: source })
  let mut expanded = 0
  while true {
    let top = open_set.pop()
    match top {
      None => break
      Some(e) =>
        if closed[e.v] {
          continue
        } else if e.g != g[e.v] {
          // Outdated entry.
          continue
        } else {
          closed[e.v] = true
          expanded = expanded + 1
          if e.v == target {
            break
          }
          for next in adj[e.v] {
            if next.to < 0 || next.to >= n {
              continue
            }
            let ng = e.g + next.w
            if ng < g[next.to] {
              g[next.to] = ng
              parent[next.to] = e.v
              open_set.push({ f: ng + heuristic(next.to), g: ng, v: next.to })
            }
          }
        }
    }
  }
  if not_reached(g[target], inf) {
    let path = reconstruct(parent, source, target)
    { dist: Some(g[target]), path, expanded }
  } else {
    { dist: None, path: [], expanded }
  }
}

///|
fn not_reached(d : Int64, inf : Int64) -> Bool {
  d != inf
}

///|
fn reconstruct(parent : Array[Int], source : Int, target : Int) -> Array[Int] {
  let path : Array[Int] = []
  let mut v = target
  while v != -1 && v != source {
    path.push(v)
    v = parent[v]
  }
  if v == source {
    path.push(source)
  } else {
    return []
  }
  // Reverse in place.
  let mut i = 0
  let mut j = path.length() - 1
  while i < j {
    let t = path[i]
    path[i] = path[j]
    path[j] = t
    i = i + 1
    j = j - 1
  }
  path
}

///|
test "a_star dijkstra equivalence on small graph" {
  // Triangle 0 -1 -2 with shortcut 0 -2.
  let adj : Array[Array[Edge]] = [
    [{ to: 1, w: 1L }, { to: 2, w: 4L }],
    [{ to: 2, w: 2L }],
    [],
  ]
  let r = a_star(3, adj, 0, 2, _ => 0L)
  @debug.assert_eq(r.dist, Some(3L))
  @debug.assert_eq(r.path, [0, 1, 2])
}

///|
test "a_star unreachable" {
  // 0 -> 1, but 2 is isolated.
  let adj : Array[Array[Edge]] = [[{ to: 1, w: 1L }], [], []]
  let r = a_star(3, adj, 0, 2, _ => 0L)
  @debug.assert_eq(r.dist, None)
  @debug.assert_eq(r.path, [])
}

///|
test "a_star source equals target" {
  let adj : Array[Array[Edge]] = [[]]
  let r = a_star(1, adj, 0, 0, _ => 0L)
  @debug.assert_eq(r.dist, Some(0L))
  @debug.assert_eq(r.path, [0])
}

///|
test "a_star out of range endpoints" {
  let adj : Array[Array[Edge]] = [[]]
  @debug.assert_eq(a_star(1, adj, -1, 0, _ => 0L).dist, None)
  @debug.assert_eq(a_star(1, adj, 0, 5, _ => 0L).dist, None)
}

///|
test "a_star grid with manhattan heuristic" {
  // 5x5 grid of nodes, each cell labelled (r, c) -> r*5 + c.
  // 4-neighbour edges with unit cost; some cells are walls.
  let cols = 5
  let n = 5 * cols
  let walls = [(1, 1), (1, 2), (1, 3), (2, 3), (3, 3)]
  let is_wall = Array::make(n, false)
  for w in walls {
    is_wall[w.0 * cols + w.1] = true
  }
  fn id(r : Int, c : Int) -> Int {
    r * cols + c
  }

  let adj : Array[Array[Edge]] = Array::make(n, [])
  for r in 0..<5 {
    for c in 0..<5 {
      if is_wall[id(r, c)] {
        continue
      }
      let edges : Array[Edge] = []
      let deltas = [(-1, 0), (1, 0), (0, -1), (0, 1)]
      for d in deltas {
        let nr = r + d.0
        let nc = c + d.1
        if nr >= 0 && nr < 5 && nc >= 0 && nc < cols && !is_wall[id(nr, nc)] {
          edges.push({ to: id(nr, nc), w: 1L })
        }
      }
      adj[id(r, c)] = edges
    }
  }
  let target = id(4, 4)
  fn h(v : Int) -> Int64 {
    let r = v / cols
    let c = v % cols
    let dr = if 4 > r { 4 - r } else { r - 4 }
    let dc = if 4 > c { 4 - c } else { c - 4 }
    (dr + dc).to_int64()
  }

  let with_h = a_star(n, adj, id(0, 0), target, h)
  let dijkstra_like = a_star(n, adj, id(0, 0), target, _ => 0L)
  @debug.assert_eq(with_h.dist, dijkstra_like.dist)
  // Manhattan heuristic should expand no more vertices than Dijkstra.
  @debug.assert_eq(with_h.expanded <= dijkstra_like.expanded, true)
}

///|
test "a_star agrees with Dijkstra on random graph" {
  // Build a small deterministic graph and confirm a_star (with h=0)
  // returns the same distance as a brute-force shortest path search.
  let adj : Array[Array[Edge]] = [
    [{ to: 1, w: 7L }, { to: 2, w: 9L }, { to: 5, w: 14L }],
    [{ to: 0, w: 7L }, { to: 2, w: 10L }, { to: 3, w: 15L }],
    [{ to: 0, w: 9L }, { to: 1, w: 10L }, { to: 3, w: 11L }, { to: 5, w: 2L }],
    [{ to: 1, w: 15L }, { to: 2, w: 11L }, { to: 4, w: 6L }],
    [{ to: 3, w: 6L }, { to: 5, w: 9L }],
    [{ to: 0, w: 14L }, { to: 2, w: 2L }, { to: 4, w: 9L }],
  ]
  let expected = [0L, 7L, 9L, 20L, 20L, 11L]
  for t in 0..<6 {
    let r = a_star(6, adj, 0, t, _ => 0L)
    @debug.assert_eq(r.dist, Some(expected[t]))
  }
}

///|
test "a_star returns valid path" {
  // The path is consecutive edges and the costs sum to the reported distance.
  let adj : Array[Array[Edge]] = [
    [{ to: 1, w: 1L }, { to: 2, w: 10L }],
    [{ to: 3, w: 2L }],
    [{ to: 3, w: 1L }],
    [],
  ]
  let r = a_star(4, adj, 0, 3, _ => 0L)
  @debug.assert_eq(r.dist, Some(3L))
  // Walk the path, summing edge weights.
  let mut total = 0L
  for i in 0..<(r.path.length() - 1) {
    let u = r.path[i]
    let v = r.path[i + 1]
    let mut w = -1L
    for e in adj[u] {
      if e.to == v {
        w = e.w
        break
      }
    }
    @debug.assert_eq(w >= 0L, true)
    total = total + w
  }
  @debug.assert_eq(total, 3L)
}
