// Property-based tests for the Kahn toposort challenge on random directed
// multigraphs (half DAGs, half arbitrary with self-loops and parallel
// edges): `topo_sort` against a transitive-closure cycle reference, and the
// `is_topo` checker against an independent one.

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
test "qc: topo_sort is None iff cyclic, else a valid order" {
  @quickcheck.check(
    (g : DG) => {
      match @challenge_toposort_kahn.topo_sort(g.n, g.edges) {
        None => has_cycle(g)
        Some(order) =>
          !has_cycle(g) &&
          is_order(g, order) &&
          @challenge_toposort_kahn.is_topo(order, g.n, g.edges)
      }
    },
    observe=g => [@quickcheck.classify(has_cycle(g), "cyclic")],
    count=400,
    seed=0x7C4A,
  )
}

///|
/// A permutation of `[0, n)` obtained by swaps driven by `noise`.
fn shuffled(n : Int, noise : Array[Int]) -> Array[Int] {
  let p = Array::makei(n, i => i)
  if n > 0 {
    for i, x in noise {
      let a = i % n
      let b = (x % n + n) % n
      let t = p[a]
      p[a] = p[b]
      p[b] = t
    }
  }
  p
}

///|
test "qc: is_topo agrees with an independent checker on random sequences" {
  @quickcheck.check(
    (input : (DG, Array[Int])) => {
      let (g, noise) = input
      // A candidate that is often a permutation (a shuffle of 0..n-1) and
      // sometimes arbitrary noise (duplicates, out-of-range, wrong length).
      let cand = if noise.length() % 3 == 0 {
        noise
      } else {
        shuffled(g.n, noise)
      }
      @challenge_toposort_kahn.is_topo(cand, g.n, g.edges) == is_order(g, cand)
    },
    observe=input => {
      let (g, noise) = input
      [
        @quickcheck.classify(noise.length() % 3 == 0, "raw noise candidate"),
        @quickcheck.classify(
          noise.length() % 3 != 0 &&
          g.edges.length() > 0 &&
          is_order(g, shuffled(g.n, noise)),
          "valid order with >= 1 edge",
        ),
      ]
    },
    count=400,
    seed=0x7C4B,
  )
}
