// Property-based tests for `find_min_unimodal` on arrays that strictly
// decrease to a single valley and then strictly increase (optionally with a
// two-element flat bottom), built from arbitrary `Int` values.

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
/// Unimodal array: strictly decreasing distinct values of `left`, then the
/// valley (once, or twice when `flat_bottom`), then strictly increasing
/// distinct values of `right`. Values equal to the valley are dropped from
/// the slopes so the valley is the strict minimum of each side.
fn build(
  left : Array[Int],
  right : Array[Int],
  flat_bottom : Bool,
) -> Array[Int] {
  let mut valley = IMAX
  for x in left {
    if x < valley {
      valley = x
    }
  }
  for x in right {
    if x < valley {
      valley = x
    }
  }
  let l = left.filter(x => x != valley)
  l.sort()
  l.dedup()
  let r = right.filter(x => x != valley)
  r.sort()
  r.dedup()
  let arr = l.rev()
  arr.push(valley)
  if flat_bottom {
    arr.push(valley)
  }
  arr.append(r)
  arr
}

///|
test "qc: find_min_unimodal returns an index of the minimum" {
  @quickcheck.check(
    (input : (Ints, Ints, Bool)) => {
      let (a, b, flat) = input
      let arr = build(a.xs, b.xs, flat)
      let i = @challenge_ternary_search.find_min_unimodal(arr[:])
      let mut m = arr[0]
      for x in arr {
        if x < m {
          m = x
        }
      }
      i >= 0 && i < arr.length() && arr[i] == m
    },
    count=500,
    max_size=60,
    max_shrinks=1000,
    seed=121,
    observe=input => {
      let (a, b, flat) = input
      let arr = build(a.xs, b.xs, flat)
      let n = arr.length()
      let mut v = 0
      for i, x in arr {
        if x < arr[v] {
          v = i
        }
      }
      [
        @quickcheck.classify(n <= 4, "n <= 4 (no ternary step)"),
        @quickcheck.classify(n > 4 && v == 0, "valley at start"),
        @quickcheck.classify(n > 4 && v >= n - 2, "valley at end"),
        @quickcheck.classify(n > 12, "n > 12"),
        @quickcheck.classify(flat, "flat bottom"),
      ]
    },
  )
}

///|
test "find_min_unimodal on the empty view is -1" {
  inspect(@challenge_ternary_search.find_min_unimodal([][:]), content="-1")
}
