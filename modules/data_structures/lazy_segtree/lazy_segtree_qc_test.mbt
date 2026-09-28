// Property-based tests for `LazySegTreeSum` (range add, point set, range sum):
// operation sequences are replayed against a plain `Array[Int64]` model with
// wrapping Int64 arithmetic. Invalid ranges must yield `None` / be ignored.

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
priv enum Op {
  RangeAdd(Int, Int, Int64)
  PointSet(Int, Int64)
  RangeSum(Int, Int)
  PointQuery(Int)
} derive(Debug)

///|
impl @quickcheck.Shrink for Op

///|
priv struct Case {
  init : Array[Int64]
  ops : Array[Op]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(size, rs) {
  let n = rint(rs, 0, if size < 24 { size } else { 24 })
  let init = Array::makei(n, _ => gen_val(rs))
  let ops = Array::makei(rint(rs, 0, size), _ => {
    match rint(rs, 0, 3) {
      0 => RangeAdd(gen_index(rs, n), gen_index(rs, n), gen_val(rs))
      1 => PointSet(gen_index(rs, n), gen_val(rs))
      2 => RangeSum(gen_index(rs, n), gen_index(rs, n))
      _ => PointQuery(gen_index(rs, n))
    }
  })
  { init, ops, }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.ops).map(ops => { ..self, ops, })
}

///|
fn run_case(c : Case) -> Bool {
  let n = c.init.length()
  let model = c.init.copy()
  let st = @lazy_segtree.LazySegTreeSum(c.init.copy())
  if st.length() != n {
    return false
  }
  let valid = (l : Int, r : Int) => l >= 0 && r < n && l <= r
  let model_sum = (l : Int, r : Int) => {
    let mut s = 0L
    for i in l..<=r {
      s = s + model[i]
    }
    s
  }
  for op in c.ops {
    match op {
      RangeAdd(l, r, v) => {
        st.range_add(l, r, v)
        if valid(l, r) {
          for i in l..<=r {
            model[i] = model[i] + v
          }
        }
      }
      PointSet(i, v) => {
        st.point_set(i, v)
        if valid(i, i) {
          model[i] = v
        }
      }
      RangeSum(l, r) => {
        let expected = if valid(l, r) { Some(model_sum(l, r)) } else { None }
        if st.range_sum(l, r) != expected {
          return false
        }
      }
      PointQuery(i) => {
        let expected = if valid(i, i) { Some(model[i]) } else { None }
        if st.point_query(i) != expected {
          return false
        }
      }
    }
  }
  for l in 0..<n {
    for r in l..<n {
      if st.range_sum(l, r) != Some(model_sum(l, r)) {
        return false
      }
    }
  }
  true
}

///|
test "qc: lazy segment tree agrees with array model" {
  @quickcheck.check(run_case, seed=0x1A2_5E6, count=300, observe=c => {
    [
      @quickcheck.classify(c.init.length() == 0, "empty"),
      @quickcheck.classify(c.init.length() >= 16, "size >= 16"),
      @quickcheck.classify(
        c.ops
        .iter()
        .any(op => {
          op is RangeAdd(l, r, _) && l >= 0 && r < c.init.length() && r - l >= 2
        }),
        "range add over >= 3 cells",
      ),
    ]
  })
}
