// Property-based tests for articulation points on random undirected
// multigraphs (self-loops and parallel edges included), compared with
// removal-and-connectivity brute force.

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
test "qc: find returns exactly the articulation points, sorted" {
  @quickcheck.check(
    (g : UG) => {
      @articulation_points.find(g.n, adjacency(g)) ==
      brute_articulation_points(g)
    },
    observe=g => {
      [
        @quickcheck.classify(
          brute_articulation_points(g).length() > 0,
          "has AP",
        ),
        @quickcheck.classify(
          brute_articulation_points(g).length() >= 2,
          "two or more APs",
        ),
      ]
    },
    count=400,
    seed=0xA27C,
  )
}
