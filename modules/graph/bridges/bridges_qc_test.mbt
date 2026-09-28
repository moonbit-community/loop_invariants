// Property-based tests for bridges and articulation points on random
// undirected multigraphs (self-loops and parallel edges included), compared
// with removal-and-connectivity brute force.

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
/// Connected-component label per vertex, ignoring vertex `skip` and the
/// edge with index `skip_edge` (pass `-1` to ignore nothing).
fn labels(g : UG, skip : Int, skip_edge : Int) -> Array[Int] {
  let label = Array::make(g.n, -1)
  for s in 0..<g.n {
    if s == skip || label[s] != -1 {
      continue
    }
    label[s] = s
    let stack = [s]
    while stack.pop() is Some(u) {
      for i, e in g.edges {
        if i == skip_edge || e.0 == skip || e.1 == skip {
          continue
        }
        let v = if e.0 == u { e.1 } else if e.1 == u { e.0 } else { -1 }
        if v >= 0 && label[v] == -1 {
          label[v] = s
          stack.push(v)
        }
      }
    }
  }
  label
}

///|
/// Brute force: `v` is an articulation point iff its neighbours (other than
/// itself) fall into at least two components of `G - v`.
fn brute_articulation_points(g : UG) -> Array[Int] {
  Array::makei(g.n, v => v).filter(v => {
    let label = labels(g, v, -1)
    let seen : Array[Int] = []
    for e in g.edges {
      let w = if e.0 == v { e.1 } else if e.1 == v { e.0 } else { v }
      if w != v && !seen.contains(label[w]) {
        seen.push(label[w])
      }
    }
    seen.length() >= 2
  })
}

///|
fn normalize(pairs : Array[(Int, Int)]) -> Array[(Int, Int)] {
  let out = pairs.map(p => if p.0 <= p.1 { p } else { (p.1, p.0) })
  out.sort()
  out
}

///|
test "qc: find_bridges equals the edges whose removal disconnects" {
  @quickcheck.check(
    (g : UG) => {
      let base = labels(g, -1, -1)
      let expected = g.edges
        .iter()
        .mapi((i, e) => (i, e))
        .filter(p => {
          let (i, e) = p
          e.0 != e.1 &&
          ({
            let l = labels(g, -1, i)
            l[e.0] != l[e.1] && base[e.0] == base[e.1]
          })
        })
        .map(p => p.1)
        .collect()
      normalize(@bridges.find_bridges(g.n, g.edges)) == normalize(expected)
    },
    observe=g => {
      [
        @quickcheck.classify(
          g.edges.length() > 0 &&
          @bridges.find_bridges(g.n, g.edges).length() == 0,
          "has edges, no bridge",
        ),
        @quickcheck.classify(
          @bridges.find_bridges(g.n, g.edges).length() > 0 &&
          @bridges.find_bridges(g.n, g.edges).length() <
          g.edges.filter(e => e.0 != e.1).length(),
          "some but not all edges are bridges",
        ),
        @quickcheck.classify(
          g.edges
          .iter()
          .mapi((i, e) => {
            e.0 != e.1 &&
            g.edges[:i]
            .iter()
            .any(f => (f.0 == e.0 && f.1 == e.1) || (f.0 == e.1 && f.1 == e.0))
          })
          .any(x => x),
          "has parallel edges",
        ),
      ]
    },
    count=400,
    seed=0xB21D,
  )
}

///|
test "qc: bridges.articulation_points equals removal brute force" {
  @quickcheck.check(
    (g : UG) => {
      @bridges.articulation_points(g.n, g.edges) == brute_articulation_points(g)
    },
    observe=g => {
      [
        @quickcheck.classify(
          brute_articulation_points(g).length() > 0,
          "has AP",
        ),
      ]
    },
    count=400,
    seed=0xB21E,
  )
}

///|
/// Two parallel copies of `0 - 1`: removing either leaves the graph
/// connected, so neither is a bridge. The DFS used to skip every edge back
/// to the parent vertex, so the second copy was not seen as a back edge.
test "regression: find_bridges with parallel edges" {
  debug_inspect(@bridges.find_bridges(2, [(0, 1), (0, 1)]), content="[]")
  debug_inspect(
    @bridges.find_bridges(3, [(0, 1), (1, 2), (2, 1)]),
    content="[(0, 1)]",
  )
}
