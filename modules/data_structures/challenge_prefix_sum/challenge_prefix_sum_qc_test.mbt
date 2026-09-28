// Property-based tests for `build_prefix_sum` / `range_sum` against naive
// summation (wrapping Int arithmetic on both sides).

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
  arr : Array[Int]
  queries : Array[(Int, Int)]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(size, rs) {
  let n = rint(rs, 0, size)
  let arr = Array::makei(n, _ => gen_int(rs))
  let queries = Array::makei(rint(rs, 0, size), _ => {
    (rint(rs, -2, n + 2), rint(rs, -2, n + 2))
  })
  { arr, queries, }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.arr, self.queries)).map(p => {
    arr: p.0,
    queries: p.1,
  })
}

///|
test "qc: prefix array has length n+1, starts at 0, steps by arr[i]" {
  @quickcheck.check(
    (c : Case) => {
      let p = @challenge_prefix_sum.build_prefix_sum(c.arr[:])
      let n = c.arr.length()
      p.length() == n + 1 &&
      p[0] == 0 &&
      (0).until(n).all(i => p[i + 1] - p[i] == c.arr[i])
    },
    seed=0xC4A_0001,
    count=300,
  )
}

///|
test "qc: range_sum agrees with naive inclusive sum; invalid ranges give 0" {
  @quickcheck.check(
    (c : Case) => {
      let p = @challenge_prefix_sum.build_prefix_sum(c.arr[:])
      let n = c.arr.length()
      c.queries
      .iter()
      .all(q => {
        let (l, r) = q
        let expected = if l < 0 || r < l || r >= n {
          0
        } else {
          let mut s = 0
          for i in l..<=r {
            s = s + c.arr[i]
          }
          s
        }
        @challenge_prefix_sum.range_sum(p[:], l, r) == expected
      })
    },
    seed=0xC4A_0002,
    count=300,
    observe=c => {
      [
        @quickcheck.classify(
          c.queries
          .iter()
          .any(q => q.0 >= 0 && q.0 <= q.1 && q.1 < c.arr.length()),
          "has valid query",
        ),
        @quickcheck.classify(
          c.arr.iter().any(x => x == 2147483647 || x == -2147483648),
          "contains Int extremum",
        ),
      ]
    },
  )
}
