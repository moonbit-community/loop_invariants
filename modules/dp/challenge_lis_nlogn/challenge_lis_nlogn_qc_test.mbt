// Property-based tests for the O(n log n) LIS length against the O(n^2) DP.

///|
const IMAX : Int = 2147483647

///|
const IMIN : Int = -2147483648

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Arrays whose elements come from one of three regimes: a tiny range (many
/// duplicates), full-range `Int` (hits the extrema), or a per-element mix of
/// small values and `Int` extrema.
priv struct Ints {
  xs : Array[Int]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Ints with fn arbitrary(size, rs) {
  let len = rint(rs, 0, size)
  let mode = rint(rs, 0, 3)
  let xs = Array::makei(len, _ => {
    match mode {
      0 | 1 => rint(rs, -3, 3)
      2 => @quickcheck.Arbitrary::arbitrary(size, rs)
      _ =>
        if rint(rs, 0, 3) == 0 {
          [IMAX, IMIN, 0][rint(rs, 0, 2)]
        } else {
          rint(rs, -3, 3)
        }
    }
  })
  { xs, }
}

///|
impl @quickcheck.Shrink for Ints with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.xs).map(xs => { xs, })
}

///|
/// O(n^2) strictly-increasing LIS length.
fn ref_lis(xs : Array[Int]) -> Int {
  let n = xs.length()
  let best = Array::make(n, 1)
  let mut ans = 0
  for i in 0..<n {
    for j in 0..<i {
      if xs[j] < xs[i] && best[j] + 1 > best[i] {
        best[i] = best[j] + 1
      }
    }
    if best[i] > ans {
      ans = best[i]
    }
  }
  ans
}

///|
test "qc: lis_length matches the O(n^2) DP" {
  @quickcheck.check(
    (a : Ints) => @challenge_lis_nlogn.lis_length(a.xs[:]) == ref_lis(a.xs),
    count=400,
    max_size=60,
    max_shrinks=1000,
    seed=201,
    observe=a => {
      let n = a.xs.length()
      let l = ref_lis(a.xs)
      [
        @quickcheck.classify(n == 0, "empty"),
        @quickcheck.classify(n > 1 && l == 1, "LIS 1 (non-increasing)"),
        @quickcheck.classify(n > 1 && l == n, "strictly increasing"),
        @quickcheck.classify(
          a.xs.contains(IMIN) || a.xs.contains(IMAX),
          "Int extremum",
        ),
      ]
    },
  )
}

///|
test "qc: lis_length on a sub-view equals lis of the copied slice" {
  @quickcheck.check(
    (input : (Ints, Int, Int)) => {
      let (a, i, j) = input
      let n = a.xs.length()
      let lo = if n == 0 { 0 } else { (i % (n + 1)).abs() }
      let hi = lo + (j % (n - lo + 1)).abs()
      let v = a.xs[lo:hi]
      @challenge_lis_nlogn.lis_length(v) == ref_lis(v.to_owned())
    },
    seed=202,
  )
}

///|
test "qc: lis_length is invariant under strictly increasing relabelling" {
  // Replacing each value by its rank among the distinct values preserves
  // every comparison, so the LIS length must not change.
  @quickcheck.check(
    (a : Ints) => {
      let d = a.xs.copy()
      d.sort()
      d.dedup()
      let ranked = a.xs.map(x => d.binary_search(x).unwrap())
      @challenge_lis_nlogn.lis_length(a.xs[:]) ==
      @challenge_lis_nlogn.lis_length(ranked[:])
    },
    seed=203,
  )
}
