// Property-based tests for `UnionFind`: operation sequences are replayed
// against a naive component-labelling model (`label[i]` = component id,
// relabelled on every union).

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Mostly valid indices, sometimes just outside `[0, n)`.
fn gen_index(rs : @quickcheck.RandomState, n : Int) -> Int {
  if n == 0 || rint(rs, 0, 7) == 0 {
    rint(rs, -2, n + 2)
  } else {
    rint(rs, 0, n - 1)
  }
}

///|
priv enum Op {
  Union(Int, Int)
  Connected(Int, Int)
  Find(Int)
  SetSize(Int)
  CountSets
} derive(Debug)

///|
impl @quickcheck.Shrink for Op

///|
priv struct Case {
  n : Int
  ops : Array[Op]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(size, rs) {
  let n = rint(rs, 0, if size < 30 { size } else { 30 })
  let ops = Array::makei(rint(rs, 0, size * 2), _ => {
    match rint(rs, 0, 5) {
      0 | 1 => Union(gen_index(rs, n), gen_index(rs, n))
      2 => Connected(gen_index(rs, n), gen_index(rs, n))
      3 => Find(gen_index(rs, n))
      4 => SetSize(gen_index(rs, n))
      _ => CountSets
    }
  })
  { n, ops, }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.ops).map(ops => { ..self, ops, })
}

///|
fn run_case(c : Case) -> Bool {
  let n = c.n
  let uf = @union_find.UnionFind(n)
  let label = Array::makei(n, i => i)
  let valid = (i : Int) => i >= 0 && i < n
  let components = () => {
    let seen : Map[Int, Bool] = Map([])
    for l in label {
      seen[l] = true
    }
    seen.length()
  }
  let check_find = (x : Int) => {
    let root = uf.find(x)
    if !valid(x) {
      root == -1
    } else {
      // The representative is a member of x's component.
      valid(root) && label[root] == label[x]
    }
  }
  for op in c.ops {
    match op {
      Union(x, y) => {
        let expected = valid(x) && valid(y) && label[x] != label[y]
        if uf.union(x, y) != expected {
          return false
        }
        if expected {
          let (from, to) = (label[y], label[x])
          for i in 0..<n {
            if label[i] == from {
              label[i] = to
            }
          }
        }
      }
      Connected(x, y) => {
        let expected = valid(x) && valid(y) && label[x] == label[y]
        if uf.connected(x, y) != expected {
          return false
        }
      }
      Find(x) => if !check_find(x) { return false }
      SetSize(x) => {
        let expected = if valid(x) {
          label.iter().filter(l => l == label[x]).count()
        } else {
          0
        }
        if uf.set_size(x) != expected {
          return false
        }
      }
      CountSets => if uf.count_sets() != components() { return false }
    }
  }
  // Final exhaustive comparison of the partition.
  if uf.count_sets() != components() {
    return false
  }
  for x in 0..<n {
    if !check_find(x) {
      return false
    }
    for y in 0..<n {
      if uf.connected(x, y) != (label[x] == label[y]) {
        return false
      }
      if (uf.find(x) == uf.find(y)) != (label[x] == label[y]) {
        return false
      }
    }
  }
  true
}

///|
test "qc: union find agrees with component labelling" {
  @quickcheck.check(run_case, seed=0x0F1_7D5, count=300, observe=c => {
    // How many sets remain at the end: shows runs are not all trivial.
    let uf = @union_find.UnionFind(c.n)
    for op in c.ops {
      if op is Union(x, y) {
        uf.union(x, y) |> ignore
      }
    }
    let k = uf.count_sets()
    [
      @quickcheck.classify(c.n == 0, "n = 0"),
      @quickcheck.classify(c.n > 0 && k == 1, "fully merged"),
      @quickcheck.classify(k > 1 && k < c.n, "partially merged"),
    ]
  })
}
