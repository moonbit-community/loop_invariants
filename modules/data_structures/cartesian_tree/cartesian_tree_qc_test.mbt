// Property-based tests for `cartesian_tree`: every inclusive range query `[l, r]`
// agrees with a naive min; invalid ranges (`l < 0`, `r >= n`, `l > r`) give `None`.

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
  let n = rint(rs, 0, if size < 40 { size } else { 40 })
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
  @quickcheck.Shrink::shrink((self.arr, self.queries)).map(p => {
    arr: p.0,
    queries: p.1,
  })
}

///|
fn naive(arr : Array[Int64], l : Int, r : Int) -> Int64? {
  if l < 0 || r >= arr.length() || l > r {
    return None
  }
  let mut acc = arr[l]
  for i in (l + 1)..<=r {
    if arr[i] < acc {
      acc = arr[i]
    }
  }
  Some(acc)
}

///|
test "qc: cartesian_tree range query agrees with naive min" {
  @quickcheck.check(
    (c : Case) => {
      let query = (l, r) => @cartesian_tree.range_min(c.arr[:], l, r)
      let n = c.arr.length()
      c.queries.iter().all(q => query(q.0, q.1) == naive(c.arr, q.0, q.1)) &&
      (0)
      .until(n)
      .all(l => l.until(n).all(r => query(l, r) == naive(c.arr, l, r)))
    },
    seed=0xCA7_0001,
    count=200,
    observe=c => {
      [
        @quickcheck.classify(c.arr.length() == 0, "empty"),
        @quickcheck.classify(c.arr.length() > 16, "length > 16"),
        @quickcheck.classify(
          c.queries
          .iter()
          .any(q => q.0 < 0 || q.1 >= c.arr.length() || q.0 > q.1),
          "has invalid query",
        ),
      ]
    },
  )
}
