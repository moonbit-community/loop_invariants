// Property-based tests for `FenwickRangeAddRangeSum`: operation sequences are
// replayed against a plain `Array[Int64]` model with wrapping Int64
// arithmetic. Out-of-bounds `range_add` is ignored; `range_sum` returns 0 for
// empty ranges and ranges entirely outside `[0, n-1]`, and (as the
// prefix-difference formula implies) clamps a partially overlapping range.

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
  RangeSum(Int, Int)
} derive(Debug)

///|
impl @quickcheck.Shrink for Op

///|
priv struct Case {
  from_array : Bool
  init : Array[Int64]
  ops : Array[Op]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(size, rs) {
  let n = rint(rs, 0, if size < 24 { size } else { 24 })
  let from_array = rint(rs, 0, 3) != 0
  let init = if from_array {
    Array::makei(n, _ => gen_val(rs))
  } else {
    Array::make(n, 0L)
  }
  let ops = Array::makei(rint(rs, 0, size), _ => {
    if rint(rs, 0, 1) == 0 {
      RangeAdd(gen_index(rs, n), gen_index(rs, n), gen_val(rs))
    } else {
      RangeSum(gen_index(rs, n), gen_index(rs, n))
    }
  })
  { from_array, init, ops, }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.ops).map(ops => { ..self, ops, })
}

///|
fn model_sum(model : Array[Int64], l : Int, r : Int) -> Int64 {
  let n = model.length()
  let lo = if l < 0 { 0 } else { l }
  let hi = if r >= n { n - 1 } else { r }
  let mut s = 0L
  for i in lo..<=hi {
    s = s + model[i]
  }
  s
}

///|
fn run_case(c : Case) -> Bool {
  let n = c.init.length()
  let model = c.init.copy()
  let st = if c.from_array {
    @fenwick_range_add_range_sum.FenwickRangeAddRangeSum::from_array(c.init[:])
  } else {
    FenwickRangeAddRangeSum(n)
  }
  for op in c.ops {
    match op {
      RangeAdd(l, r, d) => {
        st.range_add(l, r, d)
        if l >= 0 && l <= r && r < n {
          for i in l..<=r {
            model[i] = model[i] + d
          }
        }
      }
      RangeSum(l, r) =>
        if st.range_sum(l, r) != model_sum(model, l, r) {
          return false
        }
    }
  }
  for l in 0..<n {
    for r in l..<n {
      if st.range_sum(l, r) != model_sum(model, l, r) {
        return false
      }
    }
  }
  true
}

///|
test "qc: fenwick range-add range-sum agrees with array model" {
  @quickcheck.check(run_case, seed=0xF3A_2A55, count=300, observe=c => {
    let n = c.init.length()
    [
      @quickcheck.classify(n == 0, "empty"),
      @quickcheck.classify(n >= 16, "size >= 16"),
      @quickcheck.classify(
        c.ops
        .iter()
        .any(op => op is RangeSum(l, r) && l <= r && (l < 0 || r >= n)),
        "partially/fully out-of-range sum",
      ),
    ]
  })
}

///|
/// `range_sum` with `r >= n + 1` used to index past the internal BIT arrays
/// and abort, although ranges entirely outside `[0, n-1]` are documented to
/// return 0.
test "regression: fenwick range-add range-sum out-of-range query" {
  let st = @fenwick_range_add_range_sum.FenwickRangeAddRangeSum::from_array([7L])
  debug_inspect(st.range_sum(2, 3), content="0")
  debug_inspect(st.range_sum(1, 1), content="0")
  debug_inspect(st.range_sum(0, 2), content="7")
  debug_inspect(st.range_sum(-1, 5), content="7")
}
