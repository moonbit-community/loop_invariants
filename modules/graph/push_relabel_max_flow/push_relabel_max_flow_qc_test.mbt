// Property-based tests for push-relabel max flow on small random networks
// (self-loops, parallel/anti-parallel edges, zero and large capacities):
// the flow value equals the brute-force minimum cut, for directed and
// undirected edges, and repeated calls agree.

///|
const BIG_CAP : Int = 1000000000

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// A flow network on `[0, n)` (`n >= 2`) with distinct source `s` and sink
/// `t`; self-loops, parallel and anti-parallel edges and zero capacities
/// allowed.
priv struct Net {
  n : Int
  s : Int
  t : Int
  edges : Array[(Int, Int, Int)]
} derive(Debug)

///|
fn gen_cap(rs : @quickcheck.RandomState) -> Int {
  match rint(rs, 0, 19) {
    0 => 0
    1 => BIG_CAP - rint(rs, 0, 5)
    _ => rint(rs, 1, 9)
  }
}

///|
impl @quickcheck.Arbitrary for Net with fn arbitrary(size, rs) {
  let n = rint(rs, 2, 7)
  let max_m = if size < 3 * n { size } else { 3 * n }
  let m = rint(rs, 0, max_m)
  let s = rint(rs, 0, n - 1)
  let t = (s + rint(rs, 1, n - 1)) % n
  let edges : Array[(Int, Int, Int)] = []
  // Half of the networks get a random s -> ... -> t path first.
  if rint(rs, 0, 1) == 0 {
    let last = for k = rint(rs, 0, 2), u = s; k > 0; {
      let v = rint(rs, 0, n - 1)
      edges.push((u, v, gen_cap(rs)))
      continue k - 1, v
    } nobreak {
      u
    }
    edges.push((last, t, gen_cap(rs)))
  }
  for _ in 0..<m {
    // Bias endpoints towards the terminals so that flows are non-trivial.
    let pick = () => {
      match rint(rs, 0, 4) {
        0 => s
        1 => t
        _ => rint(rs, 0, n - 1)
      }
    }
    edges.push((pick(), pick(), gen_cap(rs)))
  }
  { n, s, t, edges, }
}

///|
/// Shrinks by dropping one edge or lowering one capacity.
impl @quickcheck.Shrink for Net with fn shrink(g) {
  let out : Array[Net] = []
  for i in 0..<g.edges.length() {
    let edges = g.edges.copy()
    edges.remove(i) |> ignore
    out.push({ ..g, edges, })
  }
  for i, e in g.edges {
    if e.2 > 0 {
      let edges = g.edges.copy()
      edges[i] = (e.0, e.1, e.2 / 2)
      out.push({ ..g, edges, })
    }
  }
  out.iter()
}

///|
/// Capacity of the cut `(S, V \ S)`; `in_s` is a bitmask of `S`.
fn cut_capacity(g : Net, in_s : Int) -> Int64 {
  g.edges.fold(init=0L, (acc, e) => {
    if ((in_s >> e.0) & 1) == 1 && ((in_s >> e.1) & 1) == 0 {
      acc + e.2.to_int64()
    } else {
      acc
    }
  })
}

///|
/// Brute force: minimum capacity over all `s`-`t` cuts (max-flow min-cut).
fn brute_min_cut(g : Net) -> Int64 {
  let mut best : Int64? = None
  for mask in 0..<(1 << g.n) {
    if ((mask >> g.s) & 1) == 1 && ((mask >> g.t) & 1) == 0 {
      let c = cut_capacity(g, mask)
      if best is Some(b) && b <= c {
        continue
      }
      best = Some(c)
    }
  }
  best.unwrap()
}

///|
test "qc: push-relabel max_flow equals the brute-force min cut" {
  @quickcheck.check(
    (g : Net) => {
      let pr = @push_relabel_max_flow.PushRelabel(g.n)
      for e in g.edges {
        pr.add_edge(e.0, e.1, e.2.to_int64())
      }
      pr.max_flow(g.s, g.t) == brute_min_cut(g)
    },
    observe=g => {
      [
        @quickcheck.classify(brute_min_cut(g) == 0L, "zero flow"),
        @quickcheck.classify(
          g.edges.any(e => e.0 == g.s && e.2 > 0),
          "source has out-capacity",
        ),
      ]
    },
    count=400,
    seed=0x9E11,
  )
}

///|
test "qc: push-relabel undirected edges equal two directed edges" {
  @quickcheck.check(
    (g : Net) => {
      let pr = @push_relabel_max_flow.PushRelabel(g.n)
      let both : Array[(Int, Int, Int)] = []
      for e in g.edges {
        pr.add_undirected_edge(e.0, e.1, e.2.to_int64())
        both.push(e)
        both.push((e.1, e.0, e.2))
      }
      pr.max_flow(g.s, g.t) == brute_min_cut({ ..g, edges: both, })
    },
    count=400,
    seed=0x9E12,
  )
}

///|
test "qc: push-relabel max_flow can be called repeatedly" {
  @quickcheck.check(
    (g : Net) => {
      let pr = @push_relabel_max_flow.PushRelabel(g.n)
      for e in g.edges {
        pr.add_edge(e.0, e.1, e.2.to_int64())
      }
      let reversed = pr.max_flow(g.t, g.s)
      let forward = pr.max_flow(g.s, g.t)
      forward == brute_min_cut(g) &&
      reversed == brute_min_cut({ ..g, s: g.t, t: g.s, })
    },
    count=200,
    seed=0x9E13,
  )
}
