// Property-based tests for `SqrtSum`: point assignments and inclusive range
// sums are replayed against a plain `Array[Int64]` model (wrapping sums);
// invalid ranges give 0 and out-of-range updates are ignored.

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
  let n = rint(rs, 0, if size < 40 { size } else { 40 })
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
  let st = @sqrt_decomposition.SqrtSum(c.init)
  let expected = (l : Int, r : Int) => {
    let mut s = 0L
    if l >= 0 && l <= r && r < n {
      for i in l..<=r {
        s = s + model[i]
      }
    }
    s
  }
  for op in c.ops {
    match op {
      Update(i, v) => {
        st.update(i, v)
        if i >= 0 && i < n {
          model[i] = v
        }
      }
      Query(l, r) => if st.query(l, r) != expected(l, r) { return false }
    }
  }
  (0).until(n).all(l => l.until(n).all(r => st.query(l, r) == expected(l, r)))
}

///|
test "qc: sqrt decomposition agrees with array model" {
  @quickcheck.check(run_case, seed=0x5B7_0001, count=300, observe=c => {
    [
      @quickcheck.classify(c.init.length() == 0, "empty"),
      @quickcheck.classify(c.init.length() >= 16, "length >= 16 (>= 4 blocks)"),
    ]
  })
}

///|
test "qc: SqrtSum does not alias its input array" {
  @quickcheck.check(
    (xs : Array[Int64]) => {
      let input = xs.copy()
      let st = @sqrt_decomposition.SqrtSum(input)
      if xs.length() > 0 {
        st.update(0, 12345L)
      }
      input == xs
    },
    seed=0x5B7_0002,
    count=100,
  )
}
