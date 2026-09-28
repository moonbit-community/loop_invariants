// Property-based tests for LIS with reconstruction: the length matches the
// O(n^2) DP and the returned path is a strictly increasing subsequence of the
// input with exactly that length.

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
/// `sub` occurs in `xs` as a (not necessarily contiguous) subsequence.
fn is_subsequence(sub : Array[Int], xs : Array[Int]) -> Bool {
  let mut k = 0
  for x in xs {
    if k < sub.length() && sub[k] == x {
      k = k + 1
    }
  }
  k == sub.length()
}

///|
fn strictly_increasing(xs : Array[Int]) -> Bool {
  for i in 1..<xs.length() {
    if xs[i - 1] >= xs[i] {
      return false
    }
  }
  true
}

///|
test "qc: length matches the O(n^2) DP" {
  @quickcheck.check(
    (a : Ints) => @lis_reconstruction.length(a.xs) == ref_lis(a.xs),
    count=400,
    max_size=60,
    max_shrinks=1000,
    seed=211,
    observe=a => {
      [
        @quickcheck.classify(a.xs.length() == 0, "empty"),
        @quickcheck.classify(ref_lis(a.xs) >= 5, "LIS >= 5"),
      ]
    },
  )
}

///|
test "qc: length_and_path returns a strictly increasing subsequence of LIS length" {
  @quickcheck.check(
    (a : Ints) => {
      let (len, path) = @lis_reconstruction.length_and_path(a.xs)
      len == ref_lis(a.xs) &&
      path.length() == len &&
      strictly_increasing(path) &&
      is_subsequence(path, a.xs)
    },
    count=400,
    max_size=60,
    max_shrinks=1000,
    seed=212,
  )
}
