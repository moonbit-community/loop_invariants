// Property-based tests for `RollbackDSU`: operation sequences (with snapshots
// and rollbacks) are replayed against a stack of component labellings, one per
// history entry. `snapshot` is the history length; every `union` call,
// successful or not, adds one entry.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
priv enum Op {
  Union(Int, Int)
  Same(Int, Int)
  Find(Int)
  Snapshot
  /// Roll back to `raw % (history + 2)`; targets above the current history
  /// length must be no-ops.
  Rollback(Int)
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
  let n = rint(rs, 1, if size < 20 { size + 1 } else { 20 })
  let i = () => rint(rs, 0, n - 1)
  let ops = Array::makei(rint(rs, 0, size * 2), _ => {
    match rint(rs, 0, 7) {
      0 | 1 | 2 => Union(i(), i())
      3 => Same(i(), i())
      4 => Find(i())
      5 => Snapshot
      _ => Rollback(rint(rs, 0, 1000))
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
  let dsu = @challenge_union_find_rollback.RollbackDSU(n)
  // states[k] = component labels after k history entries.
  let states : Array[Array[Int]] = [Array::makei(n, i => i)]
  for op in c.ops {
    let label = states[states.length() - 1]
    match op {
      Union(a, b) => {
        let expected = label[a] != label[b]
        if dsu.union(a, b) != expected {
          return false
        }
        let next = label.copy()
        if expected {
          let (from, to) = (label[b], label[a])
          for i in 0..<n {
            if next[i] == from {
              next[i] = to
            }
          }
        }
        states.push(next)
      }
      Same(a, b) => if dsu.same(a, b) != (label[a] == label[b]) { return false }
      Find(a) => {
        let r = dsu.find(a)
        if r < 0 || r >= n || label[r] != label[a] {
          return false
        }
      }
      Snapshot => if dsu.snapshot() != states.length() - 1 { return false }
      Rollback(raw) => {
        let target = raw % (states.length() + 1)
        dsu.rollback(target)
        if target < states.length() - 1 {
          states.truncate(target + 1)
        }
      }
    }
  }
  let label = states[states.length() - 1]
  for a in 0..<n {
    for b in 0..<n {
      if dsu.same(a, b) != (label[a] == label[b]) {
        return false
      }
    }
  }
  dsu.snapshot() == states.length() - 1
}

///|
test "qc: rollback DSU agrees with labelling stack" {
  @quickcheck.check(run_case, seed=0x0D5_0001, count=300, observe=c => {
    let unions = c.ops.iter().filter(op => op is Union(_, _)).count()
    let rollbacks = c.ops.iter().filter(op => op is Rollback(_)).count()
    [
      @quickcheck.classify(rollbacks > 0 && unions > 0, "unions and rollbacks"),
      @quickcheck.classify(unions >= 2 * c.n, "unions >= 2n"),
    ]
  })
}
