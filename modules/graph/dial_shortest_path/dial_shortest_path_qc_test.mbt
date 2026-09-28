// Property-based tests for Dial's bucket-based shortest paths: distances on
// random directed multigraphs with small non-negative weights (self-loops
// and parallel edges included) are compared against a Bellman-Ford
// reference.

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
/// Directed multigraph with a source (`n >= 1`, `src` in `[0, n)`) and
/// weights in `[0, max_w]`.
priv struct IG {
  n : Int
  src : Int
  max_w : Int
  edges : Array[(Int, Int, Int)]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for IG with fn arbitrary(size, rs) {
  let n = rint(rs, 1, 8)
  let max_w = rint(rs, 0, 5)
  let max_m = if size < 3 * n { size } else { 3 * n }
  let m = rint(rs, 0, max_m)
  let edges = Array::makei(m, _ => {
    let u = rint(rs, 0, n - 1)
    let v = rint(rs, 0, n - 1)
    (u, v, rint(rs, 0, max_w))
  })
  { n, src: rint(rs, 0, n - 1), max_w, edges, }
}

///|
/// Shrinks by dropping the highest non-source vertex, dropping one edge, or
/// setting one weight to zero.
impl @quickcheck.Shrink for IG with fn shrink(g) {
  let out : Array[IG] = []
  let k = g.n - 1
  if g.n > 1 && g.src != k {
    out.push({ ..g, n: k, edges: g.edges.filter(e => e.0 != k && e.1 != k), })
  }
  for i in 0..<g.edges.length() {
    let edges = g.edges.copy()
    edges.remove(i) |> ignore
    out.push({ ..g, edges, })
  }
  for i, e in g.edges {
    if e.2 != 0 {
      let edges = g.edges.copy()
      edges[i] = (e.0, e.1, 0)
      out.push({ ..g, edges, })
    }
  }
  out.iter()
}

///|
/// Bellman-Ford reference: `Some(d)` for vertices reachable from `g.src`.
fn ref_dist(g : IG) -> Array[Int?] {
  let d : Array[Int?] = Array::make(g.n, None)
  d[g.src] = Some(0)
  for _ in 0..<g.n {
    for e in g.edges {
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
/// Documented sentinel for unreachable vertices (`DIAL_INF`).
const UNREACHABLE : Int = 1000000000

///|
test "qc: dial_shortest_paths matches the reference" {
  @quickcheck.check(
    (g : IG) => {
      // `max_weight` is an upper bound on the edge weights; sometimes loose.
      let gr = @dial_shortest_path.Graph(g.n, g.max_w + g.n % 2)
      for e in g.edges {
        gr.add_edge(e.0, e.1, e.2)
      }
      let dist = @dial_shortest_path.dial_shortest_paths(gr, g.src)
      dist.length() == g.n &&
      all_i(ref_dist(g), (v, e) => dist[v] == e.unwrap_or(UNREACHABLE))
    },
    observe=g => {
      [
        @quickcheck.classify(g.max_w == 0, "all weights zero"),
        @quickcheck.classify(ref_dist(g).any(d => d is None), "has unreachable"),
      ]
    },
    count=400,
    seed=0xD1A1,
  )
}
