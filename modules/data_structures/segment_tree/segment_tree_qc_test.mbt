// Property-based tests for `SegmentTree` (point assign, range sum): operation
// sequences are replayed against a plain `Array[Int64]` model with wrapping
// Int64 arithmetic.

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
  Update(Int, Int64)
  Query(Int, Int)
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
    if rint(rs, 0, 1) == 0 {
      Update(gen_index(rs, n), gen_val(rs))
    } else {
      Query(gen_index(rs, n), gen_index(rs, n))
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
  let st = @segment_tree.SegmentTree(c.init.copy())
  let check_query = (l : Int, r : Int) => {
    let expected = if l < 0 || r >= n || l > r {
      0L
    } else {
      let mut s = 0L
      for i in l..<=r {
        s = s + model[i]
      }
      s
    }
    st.query(l, r) == expected
  }
  for op in c.ops {
    match op {
      Update(i, v) => {
        st.update(i, v)
        if i >= 0 && i < n {
          model[i] = v
        }
      }
      Query(l, r) => if !check_query(l, r) { return false }
    }
  }
  // Exhaustively compare every range at the end.
  for l in 0..<n {
    for r in l..<n {
      if !check_query(l, r) {
        return false
      }
    }
  }
  true
}

///|
test "qc: segment tree agrees with array model" {
  @quickcheck.check(run_case, seed=0x5E6_7EE, count=300, observe=c => {
    [
      @quickcheck.classify(c.init.length() == 0, "empty"),
      @quickcheck.classify(c.init.length() == 1, "size 1"),
      @quickcheck.classify(c.init.length() >= 16, "size >= 16"),
      @quickcheck.classify(
        c.ops
        .iter()
        .any(op => op is Update(i, _) && (i < 0 || i >= c.init.length())),
        "out-of-range update",
      ),
    ]
  })
}
