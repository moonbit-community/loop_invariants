// Property-based tests for Bellman-Ford on small random directed multigraphs
// with possibly negative weights (self-loops and parallel edges included).
// The reference is the "shortest walk with at most k edges" dynamic program:
// a negative cycle is reachable from the source iff D_n != D_(n-1).

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
/// Directed multigraph with a source; `src` is in `[0, n)` (n >= 1).
priv struct NG {
  n : Int
  src : Int
  edges : Array[(Int, Int, Int64)]
} derive(Debug)

///|
fn gen_weight(rs : @quickcheck.RandomState) -> Int64 {
  match rint(rs, 0, 29) {
    0 => 1000000000000000L
    1 => -1000000000000000L
    2..=9 => rint(rs, -5, -1).to_int64()
    _ => rint(rs, 0, 9).to_int64()
  }
}

///|
impl @quickcheck.Arbitrary for NG with fn arbitrary(size, rs) {
  let n = rint(rs, 1, 8)
  let max_m = if size < 3 * n { size } else { 3 * n }
  let m = rint(rs, 0, max_m)
  let edges = Array::makei(m, _ => {
    let u = rint(rs, 0, n - 1)
    let v = rint(rs, 0, n - 1)
    (u, v, gen_weight(rs))
  })
  { n, src: rint(rs, 0, n - 1), edges, }
}

///|
/// Shrinks by dropping the highest non-source vertex, dropping one edge, or
/// halving one weight toward zero.
impl @quickcheck.Shrink for NG with fn shrink(g) {
  let out : Array[NG] = []
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
/// One step of the walk DP: best walk with one more edge allowed.
fn walk_step(
  d : Array[Int64?],
  edges : Array[(Int, Int, Int64)],
) -> Array[Int64?] {
  let next = d.copy()
  for e in edges {
    let (u, v, w) = e
    if d[u] is Some(du) {
      match next[v] {
        Some(dv) if dv <= du + w => ()
        _ => next[v] = Some(du + w)
      }
    }
  }
  next
}

///|
/// Reference: shortest-walk distances with at most `n - 1` edges (exact when
/// there is no reachable negative cycle) and whether such a cycle exists.
fn reference(g : NG) -> (Array[Int64?], Bool) {
  let d : Array[Int64?] = Array::make(g.n, None)
  d[g.src] = Some(0L)
  let d = for _ in 1..<g.n; d = d {
    continue walk_step(d, g.edges)
  } nobreak {
    d
  }
  (d, walk_step(d, g.edges) != d)
}

///|
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
fn solve(g : NG) -> @bellman_ford.BellmanFord {
  let bf = @bellman_ford.BellmanFord(g.n)
  for e in g.edges {
    bf.add_edge(e.0, e.1, e.2)
  }
  bf.compute(g.src)
}

///|
test "qc: negative cycle flag matches the walk DP" {
  @quickcheck.check(
    (g : NG) => solve(g).has_negative_cycle() == reference(g).1,
    observe=g => {
      let (d, neg) = reference(g)
      [
        @quickcheck.classify(neg, "reachable negative cycle"),
        @quickcheck.classify(
          !neg && g.edges.any(e => e.2 < 0L),
          "negative edges, no negative cycle",
        ),
        @quickcheck.classify(d.any(x => x is None), "has unreachable"),
      ]
    },
    count=400,
    seed=0xBE11,
  )
}

///|
test "qc: get_distance matches the reference when no negative cycle" {
  @quickcheck.check(
    (g : NG) => {
      let (expected, neg) = reference(g)
      let res = solve(g)
      neg ||
      (
        all_i(expected, (v, e) => res.get_distance(v) == e) &&
        res.get_distance(-1) is None &&
        res.get_distance(g.n) is None
      )
    },
    count=400,
    seed=0xBE12,
  )
}

///|
test "qc: get_path is a real path whose weight is the distance" {
  @quickcheck.check(
    (g : NG) => {
      let (expected, neg) = reference(g)
      let res = solve(g)
      neg ||
      all_i(expected, (t, e) => {
        match (e, res.get_path(t)) {
          (None, None) => true
          (Some(d), Some(path)) => {
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
          _ => false
        }
      })
    },
    count=400,
    seed=0xBE13,
  )
}

///|
test "qc: Int wrapper bellman_ford agrees with the reference" {
  let no_path = @bellman_ford.bellman_ford(1, [], -1).0[0]
  @quickcheck.check(
    (g : NG) => {
      let small = g.edges.map(e => (e.0, e.1, (e.2 % 1000L).to_int()))
      let (dist, neg) = @bellman_ford.bellman_ford(g.n, small, g.src)
      let (expected, ref_neg) = reference({
        ..g,
        edges: small.map(e => (e.0, e.1, e.2.to_int64())),
      })
      neg == ref_neg &&
      dist.length() == g.n &&
      (
        neg ||
        all_i(expected, (v, e) => {
          match e {
            Some(d) => dist[v].to_int64() == d
            None => dist[v] == no_path
          }
        })
      )
    },
    count=400,
    seed=0xBE14,
  )
}
