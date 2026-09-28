// Property-based tests for Kahn's algorithm on random directed multigraphs
// (half DAGs, half arbitrary with self-loops and parallel edges). Cycle
// detection is checked against a transitive-closure reference and the
// lexicographic variant against brute-force permutation enumeration.

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
fn has_cycle(g : DG) -> Bool {
  let r = reach(g)
  r.iter().mapi((i, row) => row[i]).any(x => x)
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
/// `order` lists distinct vertices of `g`, every edge between two listed
/// vertices goes forward, and no listed vertex has a predecessor that is
/// not listed before it (a valid topological prefix).
fn is_prefix(g : DG, order : Array[Int]) -> Bool {
  let pos = Array::make(g.n, -1)
  for i, v in order {
    if v < 0 || v >= g.n || pos[v] != -1 {
      return false
    }
    pos[v] = i
  }
  g.edges
  .iter()
  .all(e => pos[e.1] == -1 || (pos[e.0] != -1 && pos[e.0] < pos[e.1]))
}

///|
/// A complete topological order.
fn is_order(g : DG, order : Array[Int]) -> Bool {
  order.length() == g.n && is_prefix(g, order)
}

///|
/// Lexicographically smallest topological order by enumerating permutations
/// in lexicographic order (small `n` only).
fn brute_lex_order(g : DG) -> Array[Int]? {
  let perm : Array[Int] = []
  let used = Array::make(g.n, false)
  fn go() -> Array[Int]? {
    if perm.length() == g.n {
      return if is_order(g, perm) { Some(perm.copy()) } else { None }
    }
    for v in 0..<g.n {
      if !used[v] {
        used[v] = true
        perm.push(v)
        let r = go()
        perm.pop() |> ignore
        used[v] = false
        if r is Some(_) {
          return r
        }
      }
    }
    None
  }
  go()
}

///|
test "qc: kahn toposort reports a cycle iff one exists, else a valid order" {
  @quickcheck.check(
    (g : DG) => {
      let r = @kahn_toposort.toposort(g.n, adjacency(g))
      r.has_cycle == has_cycle(g) &&
      (if r.has_cycle {
        r.order.length() < g.n && is_prefix(g, r.order)
      } else {
        is_order(g, r.order)
      })
    },
    observe=g => {
      [
        @quickcheck.classify(has_cycle(g), "cyclic"),
        @quickcheck.classify(g.edges.any(e => e.0 == e.1), "self-loop"),
        @quickcheck.classify(g.edges.length() >= 2 * g.n, "dense (m >= 2n)"),
      ]
    },
    count=400,
    seed=0x7090,
  )
}

///|
test "qc: lex_toposort is the lexicographically smallest topological order" {
  @quickcheck.check(
    (g : DG) => {
      let r = @kahn_toposort.lex_toposort(g.n, adjacency(g))
      r.has_cycle == has_cycle(g) &&
      (if r.has_cycle {
        r.order.length() < g.n && is_prefix(g, r.order)
      } else {
        g.n > 7 || Some(r.order) == brute_lex_order(g)
      })
    },
    count=300,
    seed=0x7091,
  )
}
