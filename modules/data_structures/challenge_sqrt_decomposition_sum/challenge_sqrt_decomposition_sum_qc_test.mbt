// Property-based tests for the challenge sqrt decomposition: point updates and
// half-open range sums `[l, r)` (with `0 <= l <= r <= n`) are replayed against
// a plain `Array[Int]` model (wrapping sums).

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
/// Indices are stored raw and resolved at run time: updates use
/// `raw % n`, range bounds `raw % (n + 1)`.
priv enum Op {
  Update(Int, Int)
  Sum(Int, Int)
} derive(Debug)

///|
impl @quickcheck.Shrink for Op

///|
priv struct Case {
  init : Array[Int]
  ops : Array[Op]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(size, rs) {
  let init = Array::makei(rint(rs, 0, if size < 50 { size } else { 50 }), _ => {
    gen_int(rs)
  })
  let ops = Array::makei(rint(rs, 0, size), _ => {
    if rint(rs, 0, 1) == 0 {
      Update(rint(rs, 0, 1000), gen_int(rs))
    } else {
      Sum(rint(rs, 0, 1000), rint(rs, 0, 1000))
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
  let sd = @challenge_sqrt_decomposition_sum.build_sqrt_decomp(c.init[:])
  let expected = (l : Int, r : Int) => {
    let mut s = 0
    for i in l..<r {
      s = s + model[i]
    }
    s
  }
  for op in c.ops {
    match op {
      Update(raw, v) =>
        if n > 0 {
          @challenge_sqrt_decomposition_sum.update(sd, raw % n, v)
          model[raw % n] = v
        }
      Sum(a, b) => {
        let (x, y) = (a % (n + 1), b % (n + 1))
        let (l, r) = if x <= y { (x, y) } else { (y, x) }
        if @challenge_sqrt_decomposition_sum.range_sum(sd, l, r) !=
          expected(l, r) {
          return false
        }
      }
    }
  }
  (0)
  .until(n + 1)
  .all(l => {
    l
    .until(n + 1)
    .all(r => {
      @challenge_sqrt_decomposition_sum.range_sum(sd, l, r) == expected(l, r)
    })
  })
}

///|
test "qc: challenge sqrt decomposition agrees with array model" {
  @quickcheck.check(run_case, seed=0x5D5_0001, count=200, observe=c => {
    [
      @quickcheck.classify(c.init.length() == 0, "empty"),
      @quickcheck.classify(c.init.length() >= 17, "length >= 17 (>= 5 blocks)"),
    ]
  })
}
