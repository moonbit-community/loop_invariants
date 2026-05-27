// ============================================================================
// BIDIRECTIONAL DIJKSTRA
// ============================================================================
//
// PROBLEM
//
// Shortest path from a single source `s` to a single target `t` in a
// directed weighted graph with non-negative edges. Plain Dijkstra
// expands every vertex closer to `s` than `t` is; **bidirectional**
// Dijkstra runs *two* searches -- forward from `s` on the original
// graph, backward from `t` on the reverse graph -- and stops when the
// two frontiers meet.
//
// Expected number of expanded vertices: roughly the square root of the
// number Dijkstra would expand, since each search reaches a ball of
// half the radius.
//
// TERMINATION RULE
//
// Maintain
//
//   mu = best so far of (dist_fwd[u] + w(u, v) + dist_bwd[v]) seen on
//   any edge u -> v
//
// Stop once `top_fwd + top_bwd >= mu`, where `top_fwd` and `top_bwd`
// are the heap-tops. No further expansion can beat `mu`.
//
// COMPLEXITY
//
//   Worst case  : O((V + E) log V), same as Dijkstra.
//   Typical     : ~sqrt(V_expanded) on random graphs.
//
// THE INVARIANT
//
//   "After each step, mu is the length of the shortest path from s to
//    t that has been **fully witnessed** (its forward portion
//    finalised, its backward portion finalised). When the heaps' tops
//    sum >= mu, no shorter path exists."

///|
pub(all) struct Edge {
  to : Int
  w : Int64
}

///|
priv struct HeapEntry {
  d : Int64
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
    if self.data[i].d < self.data[p].d {
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
      if l < m && self.data[l].d < self.data[best].d {
        best = l
      }
      if r < m && self.data[r].d < self.data[best].d {
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
fn MinHeap::top_priority(self : MinHeap) -> Int64? {
  if self.data.length() == 0 {
    None
  } else {
    Some(self.data[0].d)
  }
}

///|
/// Sentinel for "unreached". Safe under one addition.
pub const INF : Int64 = 4611686018427387903L

///|
/// Build the reverse-edge adjacency list given a forward `adj`.
fn reverse_adj(n : Int, adj : Array[Array[Edge]]) -> Array[Array[Edge]] {
  let rev = Array::makei(n, _ => ([] : Array[Edge]))
  for u in 0..<n {
    for e in adj[u] {
      if e.to >= 0 && e.to < n {
        rev[e.to].push({ to: u, w: e.w })
      }
    }
  }
  rev
}

///|
/// Single-pair shortest path via bidirectional Dijkstra. Returns the
/// shortest distance, or `INF` if `target` is unreachable from `source`.
///
/// `n` is the vertex count (vertices `0..n`). Edge weights must be
/// non-negative.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let adj : Array[Array[@bidirectional_dijkstra.Edge]] = [
///     [{ to: 1, w: 1L }, { to: 2, w: 4L }],
///     [{ to: 2, w: 2L }],
///     [],
///   ]
///   @debug.assert_eq(@bidirectional_dijkstra.shortest_path(3, adj, 0, 2), 3L)
/// }
/// ```
pub fn shortest_path(
  n : Int,
  adj : Array[Array[Edge]],
  source : Int,
  target : Int,
) -> Int64 {
  if source < 0 || source >= n || target < 0 || target >= n {
    return INF
  }
  if source == target {
    return 0L
  }
  let rev = reverse_adj(n, adj)
  let dist_fwd = Array::make(n, INF)
  let dist_bwd = Array::make(n, INF)
  let done_fwd = Array::make(n, false)
  let done_bwd = Array::make(n, false)
  dist_fwd[source] = 0L
  dist_bwd[target] = 0L
  let hf = MinHeap::new()
  let hb = MinHeap::new()
  hf.push({ d: 0L, v: source })
  hb.push({ d: 0L, v: target })
  let mut mu = INF
  while true {
    let tf = hf.top_priority()
    let tb = hb.top_priority()
    let f_val = match tf {
      None => INF
      Some(x) => x
    }
    let b_val = match tb {
      None => INF
      Some(x) => x
    }
    if f_val >= INF && b_val >= INF {
      break
    }
    if f_val + b_val >= mu {
      break
    }
    // Expand the smaller side.
    if f_val <= b_val {
      let top = hf.pop()
      match top {
        None => break
        Some(e) =>
          if !done_fwd[e.v] && e.d == dist_fwd[e.v] {
            done_fwd[e.v] = true
            for ed in adj[e.v] {
              if ed.to < 0 || ed.to >= n {
                continue
              }
              let nd = e.d + ed.w
              if nd < dist_fwd[ed.to] {
                dist_fwd[ed.to] = nd
                hf.push({ d: nd, v: ed.to })
              }
              if dist_bwd[ed.to] < INF {
                let total = nd + dist_bwd[ed.to]
                if total < mu {
                  mu = total
                }
              }
            }
          }
      }
    } else {
      let top = hb.pop()
      match top {
        None => break
        Some(e) =>
          if !done_bwd[e.v] && e.d == dist_bwd[e.v] {
            done_bwd[e.v] = true
            for ed in rev[e.v] {
              if ed.to < 0 || ed.to >= n {
                continue
              }
              let nd = e.d + ed.w
              if nd < dist_bwd[ed.to] {
                dist_bwd[ed.to] = nd
                hb.push({ d: nd, v: ed.to })
              }
              if dist_fwd[ed.to] < INF {
                let total = nd + dist_fwd[ed.to]
                if total < mu {
                  mu = total
                }
              }
            }
          }
      }
    }
  }
  mu
}

///|
test "bidir small graph" {
  let adj : Array[Array[Edge]] = [
    [{ to: 1, w: 1L }, { to: 2, w: 4L }],
    [{ to: 2, w: 2L }],
    [],
  ]
  @debug.assert_eq(shortest_path(3, adj, 0, 2), 3L)
}

///|
test "bidir self-source" {
  let adj : Array[Array[Edge]] = [[]]
  @debug.assert_eq(shortest_path(1, adj, 0, 0), 0L)
}

///|
test "bidir unreachable" {
  let adj : Array[Array[Edge]] = [[{ to: 1, w: 1L }], [], []]
  @debug.assert_eq(shortest_path(3, adj, 0, 2), INF)
}

///|
test "bidir invalid endpoints" {
  let adj : Array[Array[Edge]] = [[]]
  @debug.assert_eq(shortest_path(1, adj, -1, 0), INF)
  @debug.assert_eq(shortest_path(1, adj, 0, 5), INF)
}

///|
test "bidir agrees with Dijkstra" {
  // Compare with a naive Dijkstra on a slightly bigger graph.
  fn dijkstra(
    n : Int,
    adj : Array[Array[Edge]],
    s : Int,
    t : Int,
  ) -> Int64 {
    let dist = Array::make(n, INF)
    dist[s] = 0L
    let heap = MinHeap::new()
    heap.push({ d: 0L, v: s })
    while true {
      let top = heap.pop()
      match top {
        None => break
        Some(e) => {
          if e.d > dist[e.v] {
            continue
          }
          if e.v == t {
            return dist[t]
          }
          for ed in adj[e.v] {
            let nd = e.d + ed.w
            if nd < dist[ed.to] {
              dist[ed.to] = nd
              heap.push({ d: nd, v: ed.to })
            }
          }
        }
      }
    }
    dist[t]
  }

  let adj : Array[Array[Edge]] = [
    [{ to: 1, w: 7L }, { to: 2, w: 9L }, { to: 5, w: 14L }],
    [{ to: 0, w: 7L }, { to: 2, w: 10L }, { to: 3, w: 15L }],
    [
      { to: 0, w: 9L },
      { to: 1, w: 10L },
      { to: 3, w: 11L },
      { to: 5, w: 2L },
    ],
    [{ to: 1, w: 15L }, { to: 2, w: 11L }, { to: 4, w: 6L }],
    [{ to: 3, w: 6L }, { to: 5, w: 9L }],
    [{ to: 0, w: 14L }, { to: 2, w: 2L }, { to: 4, w: 9L }],
  ]
  for s in 0..<6 {
    for t in 0..<6 {
      @debug.assert_eq(shortest_path(6, adj, s, t), dijkstra(6, adj, s, t))
    }
  }
}
