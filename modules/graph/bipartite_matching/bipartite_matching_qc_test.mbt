// Property-based tests for bipartite matching (Hopcroft-Karp and the
// augmenting-path "Hungarian" solver) on small random bipartite graphs with
// parallel edges: matching size against brute force, validity of the
// returned pairs, and Koenig's theorem for the minimum vertex cover.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Bipartite graph: edges `(u, v)` with `u` in `[0, left)` and `v` in
/// `[0, right)`; parallel edges allowed.
priv struct BG {
  left : Int
  right : Int
  edges : Array[(Int, Int)]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for BG with fn arbitrary(size, rs) {
  let left = rint(rs, 0, 6)
  let right = rint(rs, 0, 6)
  let cap = 2 * (left + right)
  let m = if left == 0 || right == 0 {
    0
  } else {
    rint(rs, 0, if size < cap { size } else { cap })
  }
  let edges = Array::makei(m, _ => {
    (rint(rs, 0, left - 1), rint(rs, 0, right - 1))
  })
  { left, right, edges, }
}

///|
impl @quickcheck.Shrink for BG with fn shrink(g) {
  Array::makei(g.edges.length(), i => {
    let edges = g.edges.copy()
    edges.remove(i) |> ignore
    { ..g, edges, }
  }).iter()
}

///|
fn build(g : BG) -> @bipartite_matching.BipartiteGraph {
  let bg = @bipartite_matching.BipartiteGraph(g.left, g.right)
  for e in g.edges {
    bg.add_edge(e.0, e.1)
  }
  bg
}

///|
/// Brute force: try every choice (skip, or any free right neighbour) for
/// each left vertex in turn.
fn brute_matching(g : BG) -> Int {
  let used = Array::make(g.right, false)
  fn go(u : Int) -> Int {
    if u == g.left {
      return 0
    }
    let mut best = go(u + 1)
    for e in g.edges {
      if e.0 == u && !used[e.1] {
        used[e.1] = true
        let r = 1 + go(u + 1)
        used[e.1] = false
        if r > best {
          best = r
        }
      }
    }
    best
  }
  go(0)
}

///|
/// Pairs are edges of `g` with no repeated left or right vertex.
fn valid_matching(g : BG, pairs : Array[(Int, Int)]) -> Bool {
  let ls = Array::make(g.left, false)
  let rs = Array::make(g.right, false)
  pairs
  .iter()
  .all(p => {
    let ok = g.edges.contains(p) && !ls[p.0] && !rs[p.1]
    ls[p.0] = true
    rs[p.1] = true
    ok
  })
}

///|
test "qc: hopcroft_karp finds a maximum matching" {
  @quickcheck.check(
    (g : BG) => {
      let hk = build(g).hopcroft_karp()
      let size = hk.max_matching()
      let pairs = hk.get_matching()
      size == brute_matching(g) &&
      pairs.length() == size &&
      valid_matching(g, pairs)
    },
    observe=g => {
      let m = brute_matching(g)
      [
        @quickcheck.classify(m >= 3, "matching size >= 3"),
        @quickcheck.classify(
          m > 0 && m < (if g.left < g.right { g.left } else { g.right }),
          "not perfect on the smaller side",
        ),
      ]
    },
    count=400,
    seed=0x4B01,
  )
}

///|
test "qc: hungarian finds a maximum matching" {
  @quickcheck.check(
    (g : BG) => {
      let h = build(g).hungarian()
      let size = h.max_matching()
      let pairs = h.get_matching()
      size == brute_matching(g) &&
      pairs.length() == size &&
      valid_matching(g, pairs)
    },
    count=400,
    seed=0x4B02,
  )
}

///|
test "qc: min_vertex_cover covers every edge and has matching size" {
  @quickcheck.check(
    (g : BG) => {
      let (lc, rc) = build(g).hopcroft_karp().min_vertex_cover()
      lc.length() + rc.length() == brute_matching(g) &&
      g.edges.iter().all(e => lc.contains(e.0) || rc.contains(e.1))
    },
    count=400,
    seed=0x4B03,
  )
}
