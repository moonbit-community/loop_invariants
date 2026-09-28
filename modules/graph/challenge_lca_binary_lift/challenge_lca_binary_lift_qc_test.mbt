// Property-based tests for the binary-lifting LCA challenge on random trees
// (random recursive trees, deep paths, stars; shuffled labels and edge
// orientations) with a random root, compared with naive parent walking.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// A tree on `[0, n)` given as a shuffled, randomly oriented edge list,
/// plus a root. Shapes: random recursive tree, path (deep), or star.
priv struct Tree {
  n : Int
  root : Int
  edges : Array[(Int, Int)]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Tree with fn arbitrary(size, rs) {
  let n = rint(rs, 1, if size < 3 { 3 } else if size > 20 { 20 } else { size })
  let shape = rint(rs, 0, 3)
  let label = Array::makei(n, i => i)
  for i = n - 1; i > 0; i = i - 1 {
    let j = rint(rs, 0, i)
    let t = label[i]
    label[i] = label[j]
    label[j] = t
  }
  let edges = Array::makei(n - 1, k => {
    let i = k + 1
    let p = match shape {
      0 => i - 1
      1 => 0
      _ => rint(rs, 0, i - 1)
    }
    if rint(rs, 0, 1) == 0 {
      (label[p], label[i])
    } else {
      (label[i], label[p])
    }
  })
  for i = edges.length() - 1; i > 0; i = i - 1 {
    let j = rint(rs, 0, i)
    let t = edges[i]
    edges[i] = edges[j]
    edges[j] = t
  }
  { n, root: rint(rs, 0, n - 1), edges, }
}

///|
/// Shrinks by deleting vertex `n - 1` when it is a non-root leaf, or by
/// moving the root to 0.
impl @quickcheck.Shrink for Tree with fn shrink(t) {
  let out : Array[Tree] = []
  let k = t.n - 1
  let incident = t.edges.filter(e => e.0 == k || e.1 == k)
  if t.n > 1 && t.root != k && incident.length() == 1 {
    out.push({
      n: k,
      root: t.root,
      edges: t.edges.filter(e => e.0 != k && e.1 != k),
    })
  }
  if t.root != 0 {
    out.push({ ..t, root: 0, })
  }
  out.iter()
}

///|
/// Naive reference: BFS parents/depths from `root`, then walk the deeper
/// vertex up until both meet.
fn naive_lca(t : Tree, root : Int, u : Int, v : Int) -> Int {
  let parent = Array::make(t.n, -1)
  let depth = Array::make(t.n, -1)
  depth[root] = 0
  let queue = [root]
  for i = 0; i < queue.length(); i = i + 1 {
    let x = queue[i]
    for e in t.edges {
      let y = if e.0 == x { e.1 } else if e.1 == x { e.0 } else { -1 }
      if y >= 0 && depth[y] == -1 {
        depth[y] = depth[x] + 1
        parent[y] = x
        queue.push(y)
      }
    }
  }
  let mut a = u
  let mut b = v
  while a != b {
    if depth[a] >= depth[b] {
      a = parent[a]
    } else {
      b = parent[b]
    }
  }
  a
}

///|
/// Depth of the deepest vertex when rooted at `root`.
fn height(t : Tree, root : Int) -> Int {
  let depth = Array::make(t.n, -1)
  depth[root] = 0
  let queue = [root]
  for i = 0; i < queue.length(); i = i + 1 {
    let x = queue[i]
    for e in t.edges {
      let y = if e.0 == x { e.1 } else if e.1 == x { e.0 } else { -1 }
      if y >= 0 && depth[y] == -1 {
        depth[y] = depth[x] + 1
        queue.push(y)
      }
    }
  }
  depth.fold(init=0, (a, b) => if a > b { a } else { b })
}

///|
test "qc: challenge lca equals naive parent walking for every pair and root" {
  @quickcheck.check(
    (t : Tree) => {
      let l = @challenge_lca_binary_lift.build_lca(t.n, t.edges, t.root)
      Array::makei(t.n * t.n, i => (i / t.n, i % t.n)).all(p => {
        @challenge_lca_binary_lift.lca(l, p.0, p.1) ==
        naive_lca(t, t.root, p.0, p.1)
      })
    },
    observe=t => {
      [
        @quickcheck.classify(height(t, t.root) >= 8, "height >= 8"),
        @quickcheck.classify(t.root != 0, "root != 0"),
      ]
    },
    count=300,
    seed=0x1CB1,
  )
}
