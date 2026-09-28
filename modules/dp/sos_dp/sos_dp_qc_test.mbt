// Property-based tests for the SOS (zeta / Mobius) transforms: agreement with
// the O(4^n) definition, inverse pairs, and rejection of lengths that are not
// powers of two. All arithmetic wraps in `Int64`, so extreme values are fine.

///|
const LMAX : Int64 = 9223372036854775807L

///|
const LMIN : Int64 = -9223372036854775808L

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// `Int64` arrays whose elements come from one of three regimes: a tiny range
/// (many duplicates), full-range `Int64` (hits the extrema), or a per-element
/// mix of small values and `Int64` extrema.
priv struct I64s {
  xs : Array[Int64]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for I64s with fn arbitrary(size, rs) {
  let len = rint(rs, 0, size)
  let mode = rint(rs, 0, 3)
  let xs = Array::makei(len, _ => {
    match mode {
      0 | 1 => rint(rs, -3, 3).to_int64()
      2 => @quickcheck.Arbitrary::arbitrary(size, rs)
      _ =>
        if rint(rs, 0, 3) == 0 {
          [LMAX, LMIN, 0L, LMAX - 1L][rint(rs, 0, 3)]
        } else {
          rint(rs, -3, 3).to_int64()
        }
    }
  })
  { xs, }
}

///|
impl @quickcheck.Shrink for I64s with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.xs).map(xs => { xs, })
}

///|
/// An array of length exactly `2^n` for `n` in `[0, 6]`.
priv struct Cube {
  f : Array[Int64]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Cube with fn arbitrary(size, rs) {
  let n = rint(rs, 0, 6)
  let a : I64s = @quickcheck.Arbitrary::arbitrary(size + (1 << n), rs)
  let f = Array::makei(1 << n, i => if i < a.xs.length() { a.xs[i] } else { 0L })
  { f, }
}

///|
/// Shrinks values only, so the length stays a power of two.
impl @quickcheck.Shrink for Cube with fn shrink(self) {
  let f = self.f
  let n = f.length()
  (0)
  .until(n)
  .flat_map(i => {
    @quickcheck.Shrink::shrink(f[i]).map(v => {
      let g = f.copy()
      g[i] = v
      { f: g, }
    })
  })
}

///|
fn naive(f : Array[Int64], subsets : Bool) -> Array[Int64] {
  let size = f.length()
  Array::makei(size, s => {
    let mut acc = 0L
    for t in 0..<size {
      let ok = if subsets { (t & s) == t } else { (t & s) == s }
      if ok {
        acc = acc + f[t]
      }
    }
    acc
  })
}

///|
test "qc: sum_over_subsets matches the O(4^n) definition" {
  @quickcheck.check(
    (c : Cube) => {
      let g = c.f.copy()
      @sos_dp.sum_over_subsets(g) && g == naive(c.f, true)
    },
    count=200,
    max_shrinks=1000,
    seed=291,
    observe=c => {
      [
        @quickcheck.collect(c.f.length()),
        @quickcheck.classify(
          c.f.contains(LMAX) || c.f.contains(LMIN),
          "Int64 extremum",
        ),
      ]
    },
  )
}

///|
test "qc: sum_over_supersets matches the O(4^n) definition" {
  @quickcheck.check(
    (c : Cube) => {
      let g = c.f.copy()
      @sos_dp.sum_over_supersets(g) && g == naive(c.f, false)
    },
    count=200,
    max_shrinks=1000,
    seed=292,
  )
}

///|
test "qc: mobius transforms invert the zeta transforms (both orders)" {
  @quickcheck.check(
    (c : Cube) => {
      let a = c.f.copy()
      let b = c.f.copy()
      let d = c.f.copy()
      let e = c.f.copy()
      @sos_dp.sum_over_subsets(a) &&
      @sos_dp.mobius_subsets(a) &&
      a == c.f &&
      @sos_dp.mobius_subsets(b) &&
      @sos_dp.sum_over_subsets(b) &&
      b == c.f &&
      @sos_dp.sum_over_supersets(d) &&
      @sos_dp.mobius_supersets(d) &&
      d == c.f &&
      @sos_dp.mobius_supersets(e) &&
      @sos_dp.sum_over_supersets(e) &&
      e == c.f
    },
    count=200,
    seed=293,
  )
}

///|
test "qc: non-power-of-two lengths are rejected and left untouched" {
  @quickcheck.check(
    (a : I64s) => {
      let n = a.xs.length()
      let pow2 = n > 0 && (n & (n - 1)) == 0
      let results = [
        @sos_dp.sum_over_subsets(a.xs.copy()),
        @sos_dp.sum_over_supersets(a.xs.copy()),
        @sos_dp.mobius_subsets(a.xs.copy()),
        @sos_dp.mobius_supersets(a.xs.copy()),
      ]
      let g = a.xs.copy()
      let ok = @sos_dp.sum_over_subsets(g)
      results.iter().all(r => r == pow2) && (ok || g == a.xs)
    },
    max_size=40,
    seed=294,
  )
}
