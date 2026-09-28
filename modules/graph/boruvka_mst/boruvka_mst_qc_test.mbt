// Property-based tests for Boruvka's minimum spanning forest: the chosen
// edges must form a spanning forest of minimum total weight, compared with
// brute-force enumeration on small random undirected multigraphs
// (self-loops, parallel edges, negative weights, many ties).

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Undirected weighted multigraph on `[0, n)`; self-loops, parallel edges
/// and negative weights allowed, weights often tied.
priv struct UG {
  n : Int
  edges : Array[(Int, Int, Int)]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for UG with fn arbitrary(size, rs) {
  let n = rint(rs, 0, 7)
  let max_m = if size < 2 * n { size } else { 2 * n }
  let m = if n == 0 { 0 } else { rint(rs, 0, max_m) }
  // A quarter of the graphs use weights in {0, 1} to force many ties.
  let (lo, hi) = if rint(rs, 0, 3) == 0 { (0, 1) } else { (-3, 9) }
  let edges : Array[(Int, Int, Int)] = []
  // Half of the graphs start from a random spanning tree (connected).
  if rint(rs, 0, 1) == 0 {
    for i in 1..<n {
      edges.push((rint(rs, 0, i - 1), i, rint(rs, lo, hi)))
    }
  }
  for _ in 0..<m {
    edges.push((rint(rs, 0, n - 1), rint(rs, 0, n - 1), rint(rs, lo, hi)))
  }
  { n, edges, }
}

///|
/// Shrinks by dropping the highest vertex (with its edges), dropping one
/// edge, or setting one weight to zero.
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
fn find_root(parent : Array[Int], x : Int) -> Int {
  if parent[x] == x {
    x
  } else {
    find_root(parent, parent[x])
  }
}

///|
/// Number of connected components.
fn components(g : UG) -> Int {
  let parent = Array::makei(g.n, i => i)
  for e in g.edges {
    let (a, b) = (find_root(parent, e.0), find_root(parent, e.1))
    if a != b {
      parent[a] = b
    }
  }
  Array::makei(g.n, i => i).filter(i => parent[i] == i).length()
}

///|
/// Brute force: minimum weight over all spanning forests (maximal acyclic
/// edge subsets), by exhaustive include/exclude enumeration.
fn brute_forest_weight(g : UG) -> Int {
  let target = g.n - components(g)
  fn go(i : Int, parent : Array[Int], used : Int, w : Int) -> Int? {
    if used == target {
      return Some(w)
    }
    if i == g.edges.length() {
      return None
    }
    let skip = go(i + 1, parent, used, w)
    let (u, v, wt) = g.edges[i]
    let (a, b) = (find_root(parent, u), find_root(parent, v))
    let take = if a == b {
      None
    } else {
      let p = parent.copy()
      p[a] = b
      go(i + 1, p, used + 1, w + wt)
    }
    match (skip, take) {
      (Some(x), Some(y)) => Some(if x < y { x } else { y })
      (Some(_), None) => skip
      _ => take
    }
  }
  go(0, Array::makei(g.n, i => i), 0, 0).unwrap()
}

///|
test "qc: boruvka mst returns a minimum spanning forest" {
  @quickcheck.check(
    (g : UG) => {
      let chosen = @boruvka_mst.mst(g.n, g.edges)
      // Distinct in-range edge indices that never close a cycle.
      let parent = Array::makei(g.n, i => i)
      let seen = Array::make(g.edges.length(), false)
      let acyclic = chosen
        .iter()
        .all(ei => {
          if ei < 0 || ei >= g.edges.length() || seen[ei] {
            return false
          }
          seen[ei] = true
          let (u, v, _) = g.edges[ei]
          let (a, b) = (find_root(parent, u), find_root(parent, v))
          parent[a] = b
          a != b
        })
      let total = chosen.fold(init=0, (acc, ei) => acc + g.edges[ei].2)
      acyclic &&
      chosen.length() == g.n - components(g) &&
      total == brute_forest_weight(g) &&
      @boruvka_mst.mst_weight(g.n, g.edges) == total
    },
    observe=g => {
      [
        @quickcheck.classify(components(g) > 1, "disconnected (forest)"),
        @quickcheck.classify(
          g.edges.iter().all(e => e.2 == 0 || e.2 == 1),
          "weights in {0, 1} (many ties)",
        ),
      ]
    },
    count=300,
    seed=0xB0B1,
  )
}
