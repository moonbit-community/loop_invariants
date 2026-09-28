// Property-based tests for Floyd-Warshall on small random directed
// multigraphs with possibly negative weights, compared per source against
// the "shortest walk with at most k edges" dynamic program.

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
/// Adjacency matrix: cheapest parallel edge, `INF` for none, and the
/// diagonal is `min(0, cheapest self-loop)`.
fn matrix(g : NG) -> Array[Array[Int64]] {
  let w = Array::makei(g.n, i => {
    Array::makei(g.n, j => if i == j { 0L } else { @floyd_warshall.INF })
  })
  for e in g.edges {
    if e.2 < w[e.0][e.1] {
      w[e.0][e.1] = e.2
    }
  }
  w
}

///|
fn all_refs(g : NG) -> Array[(Array[Int64?], Bool)] {
  Array::makei(g.n, s => reference({ ..g, src: s, }))
}

///|
test "qc: floyd_warshall detects a negative cycle iff one exists" {
  @quickcheck.check(
    (g : NG) => {
      let expected = all_refs(g).iter().any(r => r.1)
      @floyd_warshall.has_negative_cycle(@floyd_warshall.apsp(matrix(g))) ==
      expected
    },
    observe=g => {
      [
        @quickcheck.classify(
          all_refs(g).iter().any(r => r.1),
          "has negative cycle",
        ),
      ]
    },
    count=300,
    seed=0xF1A1,
  )
}

///|
test "qc: floyd_warshall apsp matches per-source reference" {
  @quickcheck.check(
    (g : NG) => {
      let refs = all_refs(g)
      let dist = @floyd_warshall.apsp(matrix(g))
      refs.iter().any(r => r.1) ||
      all_i(refs, (i, r) => {
        all_i(r.0, (j, e) => {
          match e {
            Some(d) => dist[i][j] == d
            None => dist[i][j] == @floyd_warshall.INF
          }
        })
      })
    },
    count=300,
    seed=0xF1A2,
  )
}

///|
test "qc: floyd_warshall reconstruct yields real shortest paths" {
  @quickcheck.check(
    (g : NG) => {
      let refs = all_refs(g)
      let (dist, next) = @floyd_warshall.apsp_with_path(matrix(g))
      dist == @floyd_warshall.apsp(matrix(g)) &&
      (
        refs.iter().any(r => r.1) ||
        all_i(refs, (i, r) => {
          all_i(r.0, (j, e) => {
            let path = @floyd_warshall.reconstruct(next, i, j)
            match e {
              None => path.is_empty()
              Some(d) => {
                let total = for k in 1..<path.length(); total = Some(0L) {
                  match (total, min_edge(g.edges, path[k - 1], path[k])) {
                    (Some(a), Some(w)) => continue Some(a + w)
                    _ => break None
                  }
                } nobreak {
                  total
                }
                path.length() >= 1 &&
                path[0] == i &&
                path[path.length() - 1] == j &&
                total == Some(d)
              }
            }
          })
        })
      )
    },
    count=300,
    seed=0xF1A3,
  )
}
