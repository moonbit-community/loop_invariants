// Property-based tests for the BFS bipartiteness check on random undirected
// multigraphs (self-loops and parallel edges included), compared with
// brute-force enumeration of all 2-colourings.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Undirected multigraph on `[0, n)` (self-loops and parallel edges
/// allowed). Half of the graphs start from a random spanning tree.
priv struct UG {
  n : Int
  edges : Array[(Int, Int)]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for UG with fn arbitrary(size, rs) {
  let n = rint(rs, 0, 8)
  let max_m = if size < 2 * n { size } else { 2 * n }
  let m = if n == 0 { 0 } else { rint(rs, 0, max_m) }
  let edges : Array[(Int, Int)] = []
  if rint(rs, 0, 1) == 0 {
    for i in 1..<n {
      edges.push((rint(rs, 0, i - 1), i))
    }
  }
  for _ in 0..<m {
    edges.push((rint(rs, 0, n - 1), rint(rs, 0, n - 1)))
  }
  { n, edges, }
}

///|
/// Shrinks by dropping the highest vertex (with its edges) or one edge.
impl @quickcheck.Shrink for UG with fn shrink(g) {
  let out : Array[UG] = []
  let k = g.n - 1
  if g.n > 0 {
    out.push({ n: k, edges: g.edges.filter(e => e.0 != k && e.1 != k), })
  }
  for i in 0..<g.edges.length() {
    let edges = g.edges.copy()
    edges.remove(i) |> ignore
    out.push({ ..g, edges, })
  }
  out.iter()
}

///|
/// Symmetric adjacency lists (a self-loop appears twice in its own list).
fn adjacency(g : UG) -> Array[Array[Int]] {
  let adj = Array::makei(g.n, _ => [])
  for e in g.edges {
    adj[e.0].push(e.1)
    adj[e.1].push(e.0)
  }
  adj
}

///|
fn brute_bipartite(g : UG) -> Bool {
  for mask in 0..<(1 << g.n) {
    if g.edges.iter().all(e => ((mask >> e.0) & 1) != ((mask >> e.1) & 1)) {
      return true
    }
  }
  false
}

///|
test "qc: is_bipartite agrees with brute force and returns valid witnesses" {
  @quickcheck.check(
    (g : UG) => {
      let r = @bipartite_check.is_bipartite(g.n, adjacency(g))
      let edge = (u : Int, v : Int) => {
        g.edges
        .iter()
        .any(e => (e.0 == u && e.1 == v) || (e.0 == v && e.1 == u))
      }
      r.is_bipartite == brute_bipartite(g) &&
      (if r.is_bipartite {
        r.odd_cycle_edge is None &&
        r.color.length() == g.n &&
        g.edges
        .iter()
        .all(e => {
          let (a, b) = (r.color[e.0], r.color[e.1])
          (a == 0 || a == 1) && (b == 0 || b == 1) && a != b
        })
      } else {
        match r.odd_cycle_edge {
          Some((u, v)) => edge(u, v) && r.color[u] == r.color[v]
          None => false
        }
      })
    },
    observe=g => {
      [
        @quickcheck.classify(brute_bipartite(g), "bipartite"),
        @quickcheck.classify(
          !brute_bipartite(g) && !g.edges.any(e => e.0 == e.1),
          "odd cycle without self-loop",
        ),
      ]
    },
    count=400,
    seed=0xB1FA,
  )
}
