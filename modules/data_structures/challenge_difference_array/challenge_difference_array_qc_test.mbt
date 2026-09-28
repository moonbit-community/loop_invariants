// Property-based tests for `apply_range_add` against applying each update
// cell by cell (invalid updates are skipped, as documented).

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Mostly small Ints, sometimes full-range values (including the extrema);
/// arithmetic wraps identically in the implementation and the model.
fn gen_int(rs : @quickcheck.RandomState) -> Int {
  match rint(rs, 0, 7) {
    0 => @quickcheck.Arbitrary::arbitrary(0, rs)
    1 => [2147483647, -2147483648][rint(rs, 0, 1)]
    _ => rint(rs, -20, 20)
  }
}

///|
priv struct Case {
  base : Array[Int]
  updates : Array[(Int, Int, Int)]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(size, rs) {
  let n = rint(rs, 0, size)
  let base = Array::makei(n, _ => gen_int(rs))
  let idx = () => {
    if n == 0 || rint(rs, 0, 7) == 0 {
      rint(rs, -2, n + 2)
    } else {
      rint(rs, 0, n - 1)
    }
  }
  let updates = Array::makei(rint(rs, 0, size), _ => (idx(), idx(), gen_int(rs)))
  { base, updates, }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.updates).map(updates => { ..self, updates, })
}

///|
test "qc: apply_range_add agrees with naive per-cell updates" {
  @quickcheck.check(
    (c : Case) => {
      let n = c.base.length()
      let expected = c.base.copy()
      for u in c.updates {
        let (l, r, d) = u
        if l >= 0 && l <= r && r < n {
          for i in l..<=r {
            expected[i] = expected[i] + d
          }
        }
      }
      @challenge_difference_array.apply_range_add(c.base[:], c.updates[:]) ==
      expected
    },
    seed=0xD1F_0001,
    count=300,
    observe=c => {
      [
        @quickcheck.classify(
          c.updates
          .iter()
          .any(u => u.0 < 0 || u.0 > u.1 || u.1 >= c.base.length()),
          "has invalid update",
        ),
        @quickcheck.classify(
          c.updates
          .iter()
          .any(u => u.0 >= 0 && u.0 <= u.1 && u.1 == c.base.length() - 1),
          "valid update touching last cell",
        ),
      ]
    },
  )
}
