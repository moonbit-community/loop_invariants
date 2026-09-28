// Property-based tests for the Tarjan SCC challenge: component ids are
// compared with mutual-reachability classes computed from a transitive
// closure on random directed multigraphs (half DAGs, half arbitrary with
// self-loops and parallel edges).

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Directed multigraph on `[0, n)`. Half of the generated graphs are DAGs
/// (edges follow a random vertex ranking); the rest are arbitrary and may
/// contain self-loops and parallel edges.
priv struct DG {
  n : Int
  edges : Array[(Int, Int)]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for DG with fn arbitrary(size, rs) {
  let n = rint(rs, 0, 8)
  let max_m = if size < 3 * n { size } else { 3 * n }
  let m = if n == 0 { 0 } else { rint(rs, 0, max_m) }
  let rank = Array::makei(n, i => i)
  for i = n - 1; i > 0; i = i - 1 {
    let j = rint(rs, 0, i)
    let t = rank[i]
    rank[i] = rank[j]
    rank[j] = t
  }
  let dag = rint(rs, 0, 1) == 0
  let edges : Array[(Int, Int)] = []
  for _ in 0..<m {
    let u = rint(rs, 0, n - 1)
    let v = rint(rs, 0, n - 1)
    if !dag {
      edges.push((u, v))
    } else if rank[u] < rank[v] {
      edges.push((u, v))
    } else if rank[v] < rank[u] {
      edges.push((v, u))
    }
  }
  { n, edges, }
}

///|
/// Shrinks by dropping the highest vertex (with its edges) or one edge.
impl @quickcheck.Shrink for DG with fn shrink(g) {
  let out : Array[DG] = []
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
/// `reach[u][v]`: there is a directed walk with at least one edge u -> v.
fn reach(g : DG) -> Array[Array[Bool]] {
  let r = Array::makei(g.n, _ => Array::make(g.n, false))
  for e in g.edges {
    r[e.0][e.1] = true
  }
  for k in 0..<g.n {
    for i in 0..<g.n {
      for j in 0..<g.n {
        if r[i][k] && r[k][j] {
          r[i][j] = true
        }
      }
    }
  }
  r
}

///|
/// Reference SCC relation: `u` and `v` are mutually reachable.
fn same_scc(r : Array[Array[Bool]], u : Int, v : Int) -> Bool {
  u == v || (r[u][v] && r[v][u])
}

///|
/// `comp` labels exactly the mutual-reachability classes of `g` using ids
/// `0..k-1` (all used); returns `k`, or `-1` if the labelling is wrong.
fn check_partition(g : DG, comp : Array[Int]) -> Int {
  if comp.length() != g.n {
    return -1
  }
  let r = reach(g)
  let k = comp.fold(init=0, (acc, c) => if c + 1 > acc { c + 1 } else { acc })
  let used = Array::make(k, false)
  for u in 0..<g.n {
    if comp[u] < 0 {
      return -1
    }
    used[comp[u]] = true
    for v in 0..<g.n {
      if (comp[u] == comp[v]) != same_scc(r, u, v) {
        return -1
      }
    }
  }
  if used.iter().all(x => x) {
    k
  } else {
    -1
  }
}

///|
test "qc: scc_tarjan labels exactly the mutual-reachability classes" {
  @quickcheck.check(
    (g : DG) => {
      check_partition(g, @challenge_scc_tarjan.scc_tarjan(g.n, g.edges)) >= 0
    },
    observe=g => {
      let r = reach(g)
      [
        @quickcheck.classify(
          Array::makei(g.n, u => u).any(u => {
            Array::makei(g.n, v => v).any(v => u != v && same_scc(r, u, v))
          }),
          "non-trivial SCC",
        ),
      ]
    },
    count=400,
    seed=0x7A21,
  )
}

///|
test "qc: scc_tarjan ids follow completion order (reverse topological)" {
  @quickcheck.check(
    (g : DG) => {
      let comp = @challenge_scc_tarjan.scc_tarjan(g.n, g.edges)
      g.edges.iter().all(e => comp[e.0] >= comp[e.1])
    },
    count=400,
    seed=0x7A22,
  )
}

///|
test "qc: scc_tarjan ignores out-of-range edges" {
  @quickcheck.check(
    (g : DG) => {
      let noisy = g.edges.copy()
      noisy.push((-1, 0))
      noisy.push((0, g.n))
      @challenge_scc_tarjan.scc_tarjan(g.n, noisy) ==
      @challenge_scc_tarjan.scc_tarjan(g.n, g.edges)
    },
    count=100,
    seed=0x7A23,
  )
}
