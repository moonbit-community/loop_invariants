// Property-based tests for Tarjan / Kosaraju SCCs and the 2-SAT solver.
// SCCs are compared with mutual-reachability classes computed from a
// transitive closure on random directed multigraphs (half DAGs, half
// arbitrary with self-loops and parallel edges); 2-SAT is compared with
// brute-force enumeration of all assignments.

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
fn adjacency(g : DG) -> Array[Array[Int]] {
  let adj = Array::makei(g.n, _ => [])
  for e in g.edges {
    adj[e.0].push(e.1)
  }
  adj
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
/// Checks every documented field of an `SCCResult` against the reference.
fn check_result(g : DG, r : @scc.SCCResult) -> Bool {
  let k = check_partition(g, r.component)
  let sizes_ok = r.scc_sizes.length() == k &&
    r.scc_sizes
    .iter()
    .mapi((c, s) => r.component.iter().filter(x => x == c).count() == s)
    .all(x => x)
  // Condensation: c -> d listed once iff some edge crosses from c to d.
  let cond_ok = r.scc_adj.length() == k &&
    r.scc_adj
    .iter()
    .mapi((c, outs) => {
      let expected : Array[Int] = []
      for e in g.edges {
        let (a, b) = (r.component[e.0], r.component[e.1])
        if a == c && b != c && !expected.contains(b) {
          expected.push(b)
        }
      }
      outs.length() == expected.length() &&
      expected.iter().all(d => outs.contains(d))
    })
    .all(x => x)
  k >= 0 && r.num_sccs == k && sizes_ok && cond_ok
}

///|
test "qc: find_sccs (Tarjan) components are mutual-reachability classes" {
  @quickcheck.check(
    (g : DG) => check_result(g, @scc.find_sccs(g.n, adjacency(g))),
    observe=g => {
      let r = reach(g)
      let classes = Array::makei(g.n, u => {
        Array::makei(g.n, v => v).filter(v => same_scc(r, u, v)).length()
      })
      [
        @quickcheck.classify(classes.any(s => s >= 3), "an SCC of size >= 3"),
        @quickcheck.classify(
          g.n >= 2 && classes.all(s => s == 1),
          "all singleton SCCs (n >= 2)",
        ),
        @quickcheck.classify(
          g.n >= 2 && classes.all(s => s == g.n),
          "strongly connected (n >= 2)",
        ),
      ]
    },
    count=400,
    seed=0x5CC1,
  )
}

///|
test "qc: find_sccs numbers components in reverse topological order" {
  @quickcheck.check(
    (g : DG) => {
      let r = @scc.find_sccs(g.n, adjacency(g))
      g.edges.iter().all(e => r.component[e.0] >= r.component[e.1])
    },
    count=400,
    seed=0x5CC2,
  )
}

///|
test "qc: find_sccs_kosaraju agrees with the reference" {
  @quickcheck.check(
    (g : DG) => check_result(g, @scc.find_sccs_kosaraju(g.n, adjacency(g))),
    count=400,
    seed=0x5CC3,
  )
}

///|
/// A 2-SAT instance: `(a, neg_a, b, neg_b)` is the clause
/// `(x_a XOR neg_a) OR (x_b XOR neg_b)`.
priv struct Sat {
  n : Int
  clauses : Array[(Int, Bool, Int, Bool)]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Sat with fn arbitrary(size, rs) {
  let n = rint(rs, 1, 5)
  let m = rint(rs, 0, if size < 3 * n { size } else { 3 * n })
  let clauses = Array::makei(m, _ => {
    (
      rint(rs, 0, n - 1),
      rint(rs, 0, 1) == 1,
      rint(rs, 0, n - 1),
      rint(rs, 0, 1) == 1,
    )
  })
  { n, clauses, }
}

///|
impl @quickcheck.Shrink for Sat with fn shrink(s) {
  Array::makei(s.clauses.length(), i => {
    let clauses = s.clauses.copy()
    clauses.remove(i) |> ignore
    { ..s, clauses, }
  }).iter()
}

///|
fn satisfies(s : Sat, assign : Array[Bool]) -> Bool {
  assign.length() == s.n &&
  s.clauses.iter().all(c => assign[c.0] != c.1 || assign[c.2] != c.3)
}

///|
fn brute_sat(s : Sat) -> Bool {
  for mask in 0..<(1 << s.n) {
    if satisfies(s, Array::makei(s.n, i => ((mask >> i) & 1) == 1)) {
      return true
    }
  }
  false
}

///|
fn solve_sat(s : Sat) -> Array[Bool]? {
  let ts = @scc.TwoSAT(s.n)
  for c in s.clauses {
    ts.add_clause(c.0, c.1, c.2, c.3)
  }
  ts.solve()
}

///|
test "qc: TwoSAT is sound and complete against brute force" {
  @quickcheck.check(
    (s : Sat) => {
      match solve_sat(s) {
        None => !brute_sat(s)
        Some(assign) => satisfies(s, assign)
      }
    },
    observe=s => [@quickcheck.classify(brute_sat(s), "satisfiable")],
    count=500,
    seed=0x25A7,
  )
}

///|
/// The unit clause `x0 OR x0` forces `x0 = true`. `solve` used to pick the
/// literal whose SCC has the *higher* Tarjan index (earlier in topological
/// order), returning `[false]`.
test "regression: TwoSAT picks the literal later in topological order" {
  let ts = @scc.TwoSAT(1)
  ts.add_clause(0, false, 0, false)
  debug_inspect(ts.solve(), content="Some([true])")
  let ts = @scc.TwoSAT(5)
  ts.add_clause(4, false, 3, false)
  let assign = ts.solve().unwrap()
  assert_true(assign[4] || assign[3])
}
