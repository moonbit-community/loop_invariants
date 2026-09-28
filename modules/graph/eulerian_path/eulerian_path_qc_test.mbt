// Property-based tests for Eulerian paths (directed and undirected) on small
// random multigraphs with self-loops and parallel edges. Half of the inputs
// are shuffled random walks (so an Eulerian path exists); existence is
// compared with an exhaustive backtracking search and returned paths are
// checked to use every edge exactly once.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
priv struct EG {
  n : Int
  edges : Array[(Int, Int)]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for EG with fn arbitrary(size, rs) {
  let n = rint(rs, 1, 6)
  let m = rint(rs, 0, if size < 8 { size } else { 8 })
  let edges : Array[(Int, Int)] = []
  if rint(rs, 0, 1) == 0 {
    // A random walk: its edges always admit an Eulerian trail.
    let _ = for k = 0, u = rint(rs, 0, n - 1); k < m; {
      let v = rint(rs, 0, n - 1)
      edges.push((u, v))
      continue k + 1, v
    }
    for i = edges.length() - 1; i > 0; i = i - 1 {
      let j = rint(rs, 0, i)
      let t = edges[i]
      edges[i] = edges[j]
      edges[j] = t
    }
  } else {
    for _ in 0..<m {
      edges.push((rint(rs, 0, n - 1), rint(rs, 0, n - 1)))
    }
  }
  { n, edges, }
}

///|
impl @quickcheck.Shrink for EG with fn shrink(g) {
  Array::makei(g.edges.length(), i => {
    let edges = g.edges.copy()
    edges.remove(i) |> ignore
    { ..g, edges, }
  }).iter()
}

///|
/// Exhaustive search for a trail using every edge exactly once.
fn brute_exists(g : EG, directed : Bool) -> Bool {
  let used = Array::make(g.edges.length(), false)
  fn go(u : Int, left : Int) -> Bool {
    if left == 0 {
      return true
    }
    for i, e in g.edges {
      if used[i] {
        continue
      }
      let next = if e.0 == u {
        e.1
      } else if !directed && e.1 == u {
        e.0
      } else {
        continue
      }
      used[i] = true
      let ok = go(next, left - 1)
      used[i] = false
      if ok {
        return true
      }
    }
    false
  }
  g.edges.is_empty() ||
  Array::makei(g.n, v => v).any(v => go(v, g.edges.length()))
}

///|
/// `path` walks every edge of `g` exactly once.
fn is_euler_path(g : EG, path : Array[Int], directed : Bool) -> Bool {
  if g.edges.is_empty() {
    return path.is_empty()
  }
  if path.length() != g.edges.length() + 1 {
    return false
  }
  let used = Array::make(g.edges.length(), false)
  for k in 1..<path.length() {
    let (a, b) = (path[k - 1], path[k])
    let found = for i, e in g.edges {
      if !used[i] &&
        ((e.0 == a && e.1 == b) || (!directed && e.0 == b && e.1 == a)) {
        used[i] = true
        break true
      }
    } nobreak {
      false
    }
    if !found {
      return false
    }
  }
  true
}

///|
test "qc: eulerian_path_directed exists iff brute force finds a trail" {
  @quickcheck.check(
    (g : EG) => {
      match @eulerian_path.eulerian_path_directed(g.n, g.edges) {
        None => !brute_exists(g, true)
        Some(path) => is_euler_path(g, path, true)
      }
    },
    observe=g => {
      [
        @quickcheck.classify(brute_exists(g, true), "directed trail exists"),
        @quickcheck.classify(g.edges.length() >= 5, "m >= 5"),
      ]
    },
    count=400,
    seed=0xE01E,
  )
}

///|
test "qc: eulerian_path_undirected exists iff brute force finds a trail" {
  @quickcheck.check(
    (g : EG) => {
      match @eulerian_path.eulerian_path_undirected(g.n, g.edges) {
        None => !brute_exists(g, false)
        Some(path) => is_euler_path(g, path, false)
      }
    },
    observe=g => {
      [@quickcheck.classify(brute_exists(g, false), "undirected trail exists")]
    },
    count=400,
    seed=0xE01F,
  )
}
