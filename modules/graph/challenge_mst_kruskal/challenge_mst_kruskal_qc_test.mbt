// Property-based tests for the Kruskal MST challenge: the total weight is
// compared with brute-force enumeration of spanning forests on small random
// undirected multigraphs (self-loops, parallel edges, negative weights).

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
/// Documented contract: `Some(MST weight)` when connected, else `None`.
fn expected_mst(g : UG) -> Int? {
  if g.n <= 1 {
    Some(0)
  } else if components(g) == 1 {
    Some(brute_forest_weight(g))
  } else {
    None
  }
}

///|
test "qc: kruskal mst_weight equals the brute-force minimum" {
  @quickcheck.check(
    (g : UG) => {
      @challenge_mst_kruskal.mst_weight(g.n, g.edges) == expected_mst(g)
    },
    observe=g => {
      [
        @quickcheck.classify(g.n > 1 && components(g) == 1, "connected, n > 1"),
        @quickcheck.classify(g.edges.any(e => e.2 < 0), "negative weight"),
      ]
    },
    count=300,
    seed=0x3A57,
  )
}

///|
test "qc: kruskal mst_weight ignores out-of-range edges" {
  @quickcheck.check(
    (g : UG) => {
      let noisy = g.edges.copy()
      noisy.push((-1, 0, -100))
      noisy.push((0, g.n, -100))
      @challenge_mst_kruskal.mst_weight(g.n, noisy) ==
      @challenge_mst_kruskal.mst_weight(g.n, g.edges)
    },
    count=100,
    seed=0x3A58,
  )
}
