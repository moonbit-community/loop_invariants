// Property-based tests for `count`: agreement with the O(n^2) definition
// of an inversion, plus algebraic facts that follow from it.

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
/// duplicates), full-range `Int` (hits the extrema), or a per-element mix.
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
fn brute(arr : Array[Int]) -> Int64 {
  let mut c = 0L
  for i in 0..<arr.length() {
    for j in (i + 1)..<arr.length() {
      if arr[i] > arr[j] {
        c = c + 1L
      }
    }
  }
  c
}

///|
test "qc: count agrees with the O(n^2) definition" {
  @quickcheck.check(
    (a : Ints) => @inversion_count.count(a.xs) == brute(a.xs),
    count=300,
    max_size=60,
    max_shrinks=1000,
    seed=1,
    observe=a => {
      let n = a.xs.length()
      let inv = @inversion_count.count(a.xs)
      [
        @quickcheck.classify(n <= 1, "n <= 1"),
        @quickcheck.classify(inv == 0L && n > 1, "sorted, n > 1"),
        @quickcheck.classify(
          n > 1 && inv == (n * (n - 1) / 2).to_int64(),
          "strictly decreasing, n > 1",
        ),
        @quickcheck.classify(
          a.xs.contains(IMIN) || a.xs.contains(IMAX),
          "contains Int extremum",
        ),
      ]
    },
  )
}

///|
test "qc: count does not mutate its input" {
  @quickcheck.check(
    (a : Ints) => {
      let before = a.xs.copy()
      let _ = @inversion_count.count(a.xs)
      a.xs == before
    },
    seed=2,
  )
}

///|
test "qc: count(a) + count(reverse a) + equal pairs == n(n-1)/2" {
  // Every unordered pair {i, j} with a[i] != a[j] is an inversion in exactly
  // one of `a` and `reverse(a)`; equal pairs are inversions in neither.
  @quickcheck.check(
    (a : Ints) => {
      let n = a.xs.length()
      let rev = a.xs.rev()
      let mut equal = 0L
      for i in 0..<n {
        for j in (i + 1)..<n {
          if a.xs[i] == a.xs[j] {
            equal = equal + 1L
          }
        }
      }
      @inversion_count.count(a.xs) + @inversion_count.count(rev) + equal ==
      n.to_int64() * (n - 1).to_int64() / 2L
    },
    count=200,
    max_size=60,
    seed=3,
  )
}

///|
test "qc: count is zero exactly on sorted input" {
  @quickcheck.check(
    (a : Ints) => {
      let sorted = a.xs.copy()
      sorted.sort()
      @inversion_count.count(sorted) == 0L &&
      (@inversion_count.count(a.xs) == 0L) == (a.xs == sorted)
    },
    seed=4,
  )
}
