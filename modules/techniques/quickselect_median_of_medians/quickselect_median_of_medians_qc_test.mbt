// Property-based tests for `select_kth` / `median`: agreement with sorting,
// the documented `None` cases for out-of-range ranks, and non-mutation.

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
fn sorted_copy(xs : Array[Int]) -> Array[Int] {
  let s = xs.copy()
  s.sort()
  s
}

///|
test "qc: select_kth(a, k) == sorted(a)[k] for every rank" {
  @quickcheck.check(
    (a : Ints) => {
      let s = sorted_copy(a.xs)
      for k in 0..<a.xs.length() {
        if @quickselect_median_of_medians.select_kth(a.xs[:], k) != Some(s[k]) {
          return false
        }
      }
      true
    },
    count=300,
    max_size=80,
    max_shrinks=1000,
    seed=11,
    observe=a => {
      let n = a.xs.length()
      [
        @quickcheck.classify(n == 0, "empty"),
        @quickcheck.classify(n > 0 && n <= 5, "base case n <= 5"),
        @quickcheck.classify(n > 25, "recursion depth >= 2 (n > 25)"),
      ]
    },
  )
}

///|
test "qc: select_kth returns None exactly for k outside [0, n)" {
  @quickcheck.check(
    (input : (Ints, Int)) => {
      let (a, k) = input
      let n = a.xs.length()
      let r = @quickselect_median_of_medians.select_kth(a.xs[:], k)
      if k < 0 || k >= n {
        r is None
      } else {
        r is Some(_)
      }
    },
    seed=12,
  )
}

///|
test "qc: select_kth on a sub-view ignores elements outside the view" {
  @quickcheck.check(
    (input : (Ints, Int, Int)) => {
      let (a, i, j) = input
      let n = a.xs.length()
      if n == 0 {
        return true
      }
      let lo = (i % n).abs()
      let hi = lo + (j % (n - lo + 1)).abs()
      let view = a.xs[lo:hi]
      let s = sorted_copy(view.to_owned())
      for k in 0..<view.length() {
        if @quickselect_median_of_medians.select_kth(view, k) != Some(s[k]) {
          return false
        }
      }
      true
    },
    count=150,
    max_size=60,
    seed=13,
  )
}

///|
test "qc: median is the lower median sorted[(n - 1) / 2]" {
  @quickcheck.check(
    (a : Ints) => {
      let n = a.xs.length()
      let m = @quickselect_median_of_medians.median(a.xs[:])
      if n == 0 {
        m is None
      } else {
        m == Some(sorted_copy(a.xs)[(n - 1) / 2])
      }
    },
    max_size=80,
    seed=14,
  )
}

///|
test "qc: select_kth does not mutate its input" {
  @quickcheck.check(
    (input : (Ints, Int)) => {
      let (a, k) = input
      let before = a.xs.copy()
      let _ = @quickselect_median_of_medians.select_kth(a.xs[:], k)
      let _ = @quickselect_median_of_medians.median(a.xs[:])
      a.xs == before
    },
    seed=15,
  )
}
