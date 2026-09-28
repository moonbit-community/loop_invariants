// Property-based tests for the Dijkstra family. Every algorithm is compared
// against a Bellman-Ford reference written here, on small random directed
// multigraphs (self-loops and parallel edges included) with non-negative
// weights, a few of them large (~1e17, still far from the INF sentinel).

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// `true` when `f(i, xs[i])` holds for every index.
fn[T] all_i(xs : Array[T], f : (Int, T) -> Bool) -> Bool {
  for i, x in xs {
    if !f(i, x) {
      return false
    }
  }
  true
}

///|
/// Directed multigraph with a source vertex. `src` is in `[0, n)` when
/// `n > 0`.
priv struct WG {
  n : Int
  src : Int
  edges : Array[(Int, Int, Int64)]
} derive(Debug)

///|
fn gen_weight(rs : @quickcheck.RandomState) -> Int64 {
  match rint(rs, 0, 19) {
    0 => 0L
    1 => 100000000000000000L - rint(rs, 0, 3).to_int64()
    _ => rint(rs, 0, 9).to_int64()
  }
}

///|
impl @quickcheck.Arbitrary for WG with fn arbitrary(size, rs) {
  let n = rint(rs, 0, 8)
  let max_m = if size < 3 * n { size } else { 3 * n }
  let m = if n == 0 { 0 } else { rint(rs, 0, max_m) }
  let edges = Array::makei(m, _ => {
    let u = rint(rs, 0, n - 1)
    let v = rint(rs, 0, n - 1)
    (u, v, gen_weight(rs))
  })
  { n, src: if n == 0 { 0 } else { rint(rs, 0, n - 1) }, edges, }
}

///|
/// Shrinks by dropping the highest non-source vertex, dropping one edge, or
/// halving one weight toward zero.
impl @quickcheck.Shrink for WG with fn shrink(g) {
  let out : Array[WG] = []
  let k = g.n - 1
  if g.n > 1 && g.src != k {
    out.push({
      n: k,
      src: g.src,
      edges: g.edges.filter(e => e.0 != k && e.1 != k),
    })
  }
  for i in 0..<g.edges.length() {
    let edges = g.edges.copy()
    edges.remove(i) |> ignore
    out.push({ ..g, edges, })
  }
  for i, e in g.edges {
    if e.2 != 0L {
      let edges = g.edges.copy()
      edges[i] = (e.0, e.1, e.2 / 2L)
      out.push({ ..g, edges, })
    }
  }
  out.iter()
}

///|
/// Bellman-Ford reference: `Some(d)` for vertices reachable from `s`.
fn ref_dist(
  n : Int,
  edges : Array[(Int, Int, Int64)],
  s : Int,
) -> Array[Int64?] {
  let d : Array[Int64?] = Array::make(n, None)
  if s < 0 || s >= n {
    return d
  }
  d[s] = Some(0L)
  for _ in 0..<n {
    for e in edges {
      let (u, v, w) = e
      if d[u] is Some(du) {
        match d[v] {
          Some(dv) if dv <= du + w => ()
          _ => d[v] = Some(du + w)
        }
      }
    }
  }
  d
}

///|
fn build(g : WG) -> @dijkstra.Graph {
  let gr = @dijkstra.Graph(g.n)
  for e in g.edges {
    gr.add_edge(e.0, e.1, e.2)
  }
  gr
}

///|
fn build_reverse(g : WG) -> @dijkstra.Graph {
  let gr = @dijkstra.Graph(g.n)
  for e in g.edges {
    gr.add_edge(e.1, e.0, e.2)
  }
  gr
}

///|
/// Minimum weight among the parallel edges `u -> v`, if any.
fn min_edge(edges : Array[(Int, Int, Int64)], u : Int, v : Int) -> Int64? {
  edges.fold(init=None, (acc, e) => {
    if e.0 != u || e.1 != v {
      acc
    } else {
      match acc {
        Some(w) if w <= e.2 => acc
        _ => Some(e.2)
      }
    }
  })
}

///|
/// The sentinel `dijkstra` uses for unreachable vertices (documented: an
/// invalid source yields "all INF").
fn dijkstra_inf() -> Int64 {
  @dijkstra.dijkstra(Graph(1), -1).dist[0]
}

///|
test "qc: dijkstra distances match a Bellman-Ford reference" {
  let inf = dijkstra_inf()
  @quickcheck.check(
    (g : WG) => {
      let expected = ref_dist(g.n, g.edges, g.src)
      let res = @dijkstra.dijkstra(build(g), g.src)
      res.dist.length() == g.n &&
      all_i(expected, (v, e) => {
        match e {
          Some(d) => res.dist[v] == d
          None => res.dist[v] == inf
        }
      })
    },
    observe=g => {
      let reach = ref_dist(g.n, g.edges, g.src)
      [
        @quickcheck.classify(reach.any(d => d is None), "has unreachable"),
        @quickcheck.classify(
          g.edges.any(e => e.2 >= 1000000000L),
          "has large weight",
        ),
        @quickcheck.classify(g.edges.any(e => e.0 == e.1), "has self-loop"),
        @quickcheck.classify(
          !all_i(g.edges, (i, e) => {
            !g.edges[:i].iter().any(f => f.0 == e.0 && f.1 == e.1)
          }),
          "has parallel edges",
        ),
      ]
    },
    count=300,
    seed=0x1D1A,
  )
}

///|
test "qc: shortest_distance is Some(reference) or None" {
  @quickcheck.check(
    (g : WG) => {
      let gr = build(g)
      let expected = ref_dist(g.n, g.edges, g.src)
      all_i(expected, (t, e) => @dijkstra.shortest_distance(gr, g.src, t) == e) &&
      @dijkstra.shortest_distance(gr, g.src, g.n) is None &&
      @dijkstra.shortest_distance(gr, g.src, -1) is None
    },
    count=300,
    seed=0x5D15,
  )
}

///|
test "qc: reconstruct_path yields a real path of the reported length" {
  @quickcheck.check(
    (g : WG) => {
      let res = @dijkstra.dijkstra(build(g), g.src)
      let expected = ref_dist(g.n, g.edges, g.src)
      all_i(expected, (t, e) => {
        let path = @dijkstra.reconstruct_path(res, t)
        match e {
          None => path.is_empty()
          Some(d) => {
            let total = for i in 1..<path.length(); total = Some(0L) {
              match (total, min_edge(g.edges, path[i - 1], path[i])) {
                (Some(a), Some(w)) => continue Some(a + w)
                _ => break None
              }
            } nobreak {
              total
            }
            path.length() >= 1 &&
            path[0] == g.src &&
            path[path.length() - 1] == t &&
            total == Some(d)
          }
        }
      })
    },
    count=300,
    seed=0x9A7B,
  )
}

///|
test "qc: bidirectional_dijkstra agrees with the reference" {
  @quickcheck.check(
    (g : WG) => {
      let gr = build(g)
      let rev = build_reverse(g)
      let expected = ref_dist(g.n, g.edges, g.src)
      all_i(expected, (t, e) => {
        @dijkstra.bidirectional_dijkstra(gr, rev, g.src, t) == e
      })
    },
    count=300,
    seed=0xB1D1,
  )
}

///|
test "qc: dijkstra_dense agrees with the reference on Int weights" {
  let inf = @dijkstra.dijkstra_dense([[]], -1)[0]
  @quickcheck.check(
    (g : WG) => {
      let small = g.edges.map(e => (e.0, e.1, e.2 % 1000L))
      let adj : Array[Array[(Int, Int)]] = Array::makei(g.n, _ => [])
      for e in small {
        adj[e.0].push((e.1, e.2.to_int()))
      }
      let dist = @dijkstra.dijkstra_dense(adj, g.src)
      let expected = ref_dist(g.n, small, g.src)
      dist.length() == g.n &&
      all_i(expected, (v, e) => {
        match e {
          Some(d) => dist[v].to_int64() == d
          None => dist[v] == inf
        }
      })
    },
    count=300,
    seed=0xDE45,
  )
}
