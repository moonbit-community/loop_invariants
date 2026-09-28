// Property-based tests for `SparseTableMin`: every query is compared with a
// naive linear scan; invalid ranges return Int64::MAX as documented.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Mostly small values (so sums are readable), sometimes full-range values and
/// the Int64 extrema.
fn gen_val(rs : @quickcheck.RandomState) -> Int64 {
  match rint(rs, 0, 9) {
    0 => @quickcheck.Arbitrary::arbitrary(0, rs)
    1 => [9223372036854775807L, -9223372036854775808L, 0L][rint(rs, 0, 2)]
    _ => rint(rs, -20, 20).to_int64()
  }
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
priv struct Case {
  arr : Array[Int64]
  queries : Array[(Int, Int)]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(size, rs) {
  let n = rint(rs, 0, if size < 70 { size } else { 70 })
  // Small value domain sometimes, to force many duplicates.
  let narrow = rint(rs, 0, 2) == 0
  let arr = Array::makei(n, _ => {
    if narrow {
      rint(rs, 0, 3).to_int64()
    } else {
      gen_val(rs)
    }
  })
  let queries = Array::makei(rint(rs, 0, size), _ => {
    (gen_index(rs, n), gen_index(rs, n))
  })
  { arr, queries, }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.queries).map(queries => { ..self, queries, })
}

///|
fn naive_min(arr : Array[Int64], l : Int, r : Int) -> Int64 {
  if l < 0 || r >= arr.length() || l > r {
    return 9223372036854775807L
  }
  let mut m = arr[l]
  for i in l..<=r {
    if arr[i] < m {
      m = arr[i]
    }
  }
  m
}

///|
test "qc: sparse table min agrees with naive scan" {
  @quickcheck.check(
    (c : Case) => {
      let st = @sparse_table.SparseTableMin(c.arr)
      let n = c.arr.length()
      for q in c.queries {
        if st.query(q.0, q.1) != naive_min(c.arr, q.0, q.1) {
          return false
        }
      }
      // Every valid range, so all power-of-two levels are exercised.
      for l in 0..<n {
        for r in l..<n {
          if st.query(l, r) != naive_min(c.arr, l, r) {
            return false
          }
        }
      }
      true
    },
    seed=0x5BA_7AB,
    count=200,
    observe=c => {
      [
        @quickcheck.classify(c.arr.length() == 0, "empty"),
        @quickcheck.classify(c.arr.length() > 32, "length > 32"),
        @quickcheck.classify(
          c.arr
          .iter()
          .any(x => x == -9223372036854775808L || x == 9223372036854775807L),
          "contains Int64 extremum",
        ),
      ]
    },
  )
}
