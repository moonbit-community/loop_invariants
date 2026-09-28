// Property-based tests for Prufer codes: decode(encode(tree)) recovers the
// tree, encode(decode(code)) recovers the code, and encode rejects exactly
// the edge lists that are not labelled trees (checked independently).

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// An edge list on `[0, n)` that is a labelled tree (shuffled labels, edge
/// order and orientation) or, when `mutated`, a tree with one random edit
/// (drop, duplicate, or replace an edge with arbitrary endpoints, possibly
/// out of range or a self-loop).
priv struct MaybeTree {
  n : Int
  edges : Array[(Int, Int)]
} derive(Debug)

///|
fn random_tree(rs : @quickcheck.RandomState, n : Int) -> Array[(Int, Int)] {
  let label = Array::makei(n, i => i)
  for i = n - 1; i > 0; i = i - 1 {
    let j = rint(rs, 0, i)
    let t = label[i]
    label[i] = label[j]
    label[j] = t
  }
  let edges = Array::makei(n - 1, k => {
    let (a, b) = (label[k + 1], label[rint(rs, 0, k)])
    if rint(rs, 0, 1) == 0 {
      (a, b)
    } else {
      (b, a)
    }
  })
  for i = edges.length() - 1; i > 0; i = i - 1 {
    let j = rint(rs, 0, i)
    let t = edges[i]
    edges[i] = edges[j]
    edges[j] = t
  }
  edges
}

///|
impl @quickcheck.Arbitrary for MaybeTree with fn arbitrary(size, rs) {
  let n = rint(rs, 1, if size < 2 { 2 } else if size > 10 { 10 } else { size })
  let edges = random_tree(rs, n)
  match rint(rs, 0, 5) {
    0 if edges.length() > 0 =>
      edges.remove(rint(rs, 0, edges.length() - 1)) |> ignore
    1 if edges.length() > 0 =>
      edges.push(edges[rint(rs, 0, edges.length() - 1)])
    2 if edges.length() > 0 =>
      edges[rint(rs, 0, edges.length() - 1)] = (
        rint(rs, -1, n),
        rint(rs, -1, n),
      )
    3 => edges.push((rint(rs, -1, n), rint(rs, -1, n)))
    _ => ()
  }
  { n, edges, }
}

///|
impl @quickcheck.Shrink for MaybeTree

///|
/// Independent tree check: `n - 1` in-range edges without self-loops that
/// connect all `n` vertices (which also rules out duplicates).
fn is_tree(n : Int, edges : Array[(Int, Int)]) -> Bool {
  if n <= 0 || edges.length() != n - 1 {
    return false
  }
  if edges
    .iter()
    .any(e => e.0 < 0 || e.1 < 0 || e.0 >= n || e.1 >= n || e.0 == e.1) {
    return false
  }
  let seen = Array::make(n, false)
  seen[0] = true
  let stack = [0]
  while stack.pop() is Some(u) {
    for e in edges {
      let v = if e.0 == u { e.1 } else if e.1 == u { e.0 } else { -1 }
      if v >= 0 && !seen[v] {
        seen[v] = true
        stack.push(v)
      }
    }
  }
  seen.iter().all(x => x)
}

///|
fn normalize(edges : Array[(Int, Int)]) -> Array[(Int, Int)] {
  let out = edges.map(e => if e.0 <= e.1 { e } else { (e.1, e.0) })
  out.sort()
  out
}

///|
test "qc: prufer_encode accepts exactly the labelled trees" {
  @quickcheck.check(
    (t : MaybeTree) => {
      let code = @prufer_code.prufer_encode(t.n, t.edges)
      (code is Some(_)) == is_tree(t.n, t.edges)
    },
    observe=t => {
      [
        @quickcheck.classify(is_tree(t.n, t.edges), "valid tree"),
        @quickcheck.classify(t.n <= 2, "n <= 2"),
      ]
    },
    count=500,
    seed=0x9F01,
  )
}

///|
test "qc: prufer_decode inverts prufer_encode on trees with n >= 2" {
  @quickcheck.check(
    (t : MaybeTree) => {
      match @prufer_code.prufer_encode(t.n, t.edges) {
        None => true
        Some(code) =>
          code.length() == (if t.n >= 2 { t.n - 2 } else { 0 }) &&
          (
            t.n < 2 ||
            (match @prufer_code.prufer_decode(code) {
              Some(back) => normalize(back) == normalize(t.edges)
              None => false
            })
          )
      }
    },
    count=500,
    seed=0x9F02,
  )
}

///|
test "qc: prufer_encode inverts prufer_decode on in-range codes" {
  @quickcheck.check(
    (raw : Array[Int]) => {
      let n = raw.length() + 2
      let code = raw.map(x => (x % n + n) % n)
      match @prufer_code.prufer_decode(code) {
        Some(tree) =>
          tree.length() == n - 1 &&
          is_tree(n, tree) &&
          @prufer_code.prufer_encode(n, tree) == Some(code)
        None => false
      }
    },
    count=500,
    seed=0x9F03,
  )
}

///|
test "qc: prufer_decode rejects out-of-range codes" {
  @quickcheck.check(
    (input : (Array[Int], Int)) => {
      let (raw, bad) = input
      let n = raw.length() + 2
      let code = raw.map(x => (x % n + n) % n)
      // Overwrite one position with a value outside [0, n).
      let v = if bad % 2 == 0 { -1 - (bad & 7) } else { n + (bad & 7) }
      let pos = (bad % (code.length() + 1) + code.length() + 1) %
        (code.length() + 1)
      if pos < code.length() {
        code[pos] = v
      } else {
        code.push(v)
      }
      @prufer_code.prufer_decode(code) is None
    },
    count=300,
    seed=0x9F04,
  )
}

///|
/// For `n == 2` the only tree is `0 - 1`; a self-loop or an out-of-range
/// edge used to be accepted (encoded as `Some([])`) because the `n <= 2`
/// shortcut only checked the edge count.
test "regression: prufer_encode rejects invalid 2-vertex edge lists" {
  debug_inspect(@prufer_code.prufer_encode(2, [(0, 0)]), content="None")
  debug_inspect(@prufer_code.prufer_encode(2, [(0, 2)]), content="None")
  debug_inspect(@prufer_code.prufer_encode(2, [(1, 0)]), content="Some([])")
  debug_inspect(@prufer_code.prufer_encode(1, []), content="Some([])")
  debug_inspect(@prufer_code.prufer_encode(1, [(0, 0)]), content="None")
}
