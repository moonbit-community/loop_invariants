// Property-based tests for `SegmentTreeBeats`: range chmin / range sum /
// range max over half-open ranges `[l, r)` are replayed against a plain
// `Array[Int64]` model (wrapping sums). Ranges may stick out of `[0, n)`; the
// tree then acts on the intersection. Empty ranges give sum 0 and the
// documented "no element" max sentinel.

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
  Chmin(Int, Int, Int64)
  Sum(Int, Int)
  Max(Int, Int)
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
  let small = rint(rs, 0, 1) == 0
  let v = () => if small { rint(rs, -6, 6).to_int64() } else { gen_val(rs) }
  let init = Array::makei(n, _ => v())
  // Half-open bounds: an index in [-2, n + 2] works as either end.
  let b = () => gen_index(rs, n + 1)
  let ops = Array::makei(rint(rs, 0, size), _ => {
    match rint(rs, 0, 3) {
      0 | 1 => Chmin(b(), b(), v())
      2 => Sum(b(), b())
      _ => Max(b(), b())
    }
  })
  { init, ops, }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.init, self.ops)).map(p => {
    init: p.0,
    ops: p.1,
  })
}

///|
fn run_case(c : Case) -> Bool {
  let n = c.init.length()
  let model = c.init.copy()
  let st = @segment_tree_beats.SegmentTreeBeats(c.init[:])
  let empty_max = st.range_max(0, 0)
  let clamp = (l : Int, r : Int) => {
    (if l < 0 { 0 } else { l }, if r > n { n } else { r })
  }
  for op in c.ops {
    match op {
      Chmin(l, r, x) => {
        st.range_chmin(l, r, x)
        let (lo, hi) = clamp(l, r)
        for i in lo..<hi {
          if model[i] > x {
            model[i] = x
          }
        }
      }
      Sum(l, r) => {
        let (lo, hi) = clamp(l, r)
        let mut s = 0L
        for i in lo..<hi {
          s = s + model[i]
        }
        if st.range_sum(l, r) != s {
          return false
        }
      }
      Max(l, r) => {
        let (lo, hi) = clamp(l, r)
        let expected = if lo >= hi {
          empty_max
        } else {
          let mut m = model[lo]
          for i in lo..<hi {
            if model[i] > m {
              m = model[i]
            }
          }
          m
        }
        if st.range_max(l, r) != expected {
          return false
        }
      }
    }
  }
  for i in 0..<n {
    if st.range_sum(i, i + 1) != model[i] || st.range_max(i, i + 1) != model[i] {
      return false
    }
  }
  true
}

///|
test "qc: segment tree beats agrees with array model" {
  @quickcheck.check(run_case, seed=0xBEA7_5001, count=300, observe=c => {
    [
      @quickcheck.classify(c.init.length() == 0, "empty"),
      @quickcheck.classify(c.init.length() >= 16, "size >= 16"),
      @quickcheck.classify(
        c.ops.iter().any(op => op is Chmin(l, r, _) && r - l >= 3),
        "chmin over >= 3 cells",
      ),
    ]
  })
}

///|
/// `NEG_INF` (the identity for `max`) was `Int64::MIN + 1`, so a range whose
/// maximum is `Int64::MIN` combined with an empty half reported `MIN + 1`.
test "regression: segment tree beats range_max of Int64::MIN" {
  let st = @segment_tree_beats.SegmentTreeBeats([-9223372036854775808L, -6L][:])
  debug_inspect(st.range_max(0, 1), content="-9223372036854775808")
}

///|
/// `range_chmin` with `x` not above the leaf `second_max` sentinel used to
/// descend below a leaf: it zeroed the leaf's sum (n = 1) or indexed past the
/// node arrays and aborted (n = 3).
test "regression: segment tree beats chmin to a sentinel-sized cap" {
  let st = @segment_tree_beats.SegmentTreeBeats([5L][:])
  st.range_chmin(0, 1, -9223372036854775807L)
  debug_inspect(st.range_sum(0, 1), content="-9223372036854775807")
  let st3 = @segment_tree_beats.SegmentTreeBeats([5L, 3L, 8L][:])
  st3.range_chmin(0, 3, -9223372036854775808L)
  debug_inspect(st3.range_max(0, 3), content="-9223372036854775808")
  debug_inspect(st3.range_sum(1, 2), content="-9223372036854775808")
}
