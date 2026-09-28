// Property-based tests for the challenge sparse table: `range_min(st, l, r)`
// over every non-empty half-open range `[l, r)` equals a naive scan.

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
priv struct Values(Array[Int]) derive(Debug)

///|
impl @quickcheck.Arbitrary for Values with fn arbitrary(size, rs) {
  let narrow = rint(rs, 0, 1) == 0
  Values(
    Array::makei(rint(rs, 0, if size < 80 { size } else { 80 }), _ => {
      if narrow {
        rint(rs, 0, 3)
      } else {
        gen_int(rs)
      }
    }),
  )
}

///|
impl @quickcheck.Shrink for Values with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(xs => Values(xs))
}

///|
test "qc: challenge sparse table range_min agrees with naive scan" {
  @quickcheck.check(
    (v : Values) => {
      let arr = v.0
      let n = arr.length()
      let st = @challenge_sparse_table_rmq.build_sparse_table(arr[:])
      for l in 0..<n {
        let mut m = arr[l]
        for r in (l + 1)..<=n {
          if arr[r - 1] < m {
            m = arr[r - 1]
          }
          if @challenge_sparse_table_rmq.range_min(st, l, r) != m {
            return false
          }
        }
      }
      true
    },
    seed=0x5BA_7AC,
    count=200,
    observe=v => {
      [
        @quickcheck.classify(v.0.length() == 0, "empty"),
        @quickcheck.classify(v.0.length() == 1, "length 1"),
        @quickcheck.classify(v.0.length() >= 64, "length >= 64"),
      ]
    },
  )
}
