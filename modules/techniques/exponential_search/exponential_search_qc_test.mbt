// Property-based tests for exponential search: `lower_bound`, `find` and
// `gallop` are compared with a linear scan on sorted arrays with duplicates
// and `Int` extrema.

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
}

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
/// A sorted array plus a target that is often an element of the array, a
/// neighbour of one, or an arbitrary `Int` (including the extrema).
priv struct Case {
  xs : Array[Int]
  target : Int
  start : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(size, rs) {
  let a : Ints = @quickcheck.Arbitrary::arbitrary(size, rs)
  let xs = a.xs
  xs.sort()
  let n = xs.length()
  let target = match rint(rs, 0, 4) {
    0 | 1 if n > 0 => xs[rint(rs, 0, n - 1)]
    2 if n > 0 => xs[rint(rs, 0, n - 1)] + rint(rs, -1, 1) // may wrap
    3 => [IMAX, IMIN, 0][rint(rs, 0, 2)]
    _ => @quickcheck.Arbitrary::arbitrary(size, rs)
  }
  let start = rint(rs, 0, n + 2)
  { xs, target, start, }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  // Shrink the array but keep it sorted; clamp `start` loosely.
  @quickcheck.Shrink::shrink((self.xs, self.target, self.start)).map(t => {
    let (xs, target, start) = t
    let xs = xs.copy()
    xs.sort()
    { xs, target, start: if start < 0 { 0 } else { start }, }
  })
}

///|
fn naive_lower_bound(xs : Array[Int], from : Int, t : Int) -> Int {
  let mut i = from
  while i < xs.length() && xs[i] < t {
    i = i + 1
  }
  if i > xs.length() {
    xs.length()
  } else {
    i
  }
}

///|
test "qc: lower_bound agrees with a linear scan" {
  @quickcheck.check(
    (c : Case) => {
      @exponential_search.lower_bound(c.xs, c.target) ==
      naive_lower_bound(c.xs, 0, c.target)
    },
    count=400,
    max_size=70,
    max_shrinks=1000,
    seed=21,
    observe=c => {
      let n = c.xs.length()
      let lb = naive_lower_bound(c.xs, 0, c.target)
      [
        @quickcheck.classify(n == 0, "empty"),
        @quickcheck.classify(n > 0 && lb == 0, "answer 0"),
        @quickcheck.classify(n > 0 && lb == n, "answer n (all < target)"),
        @quickcheck.classify(c.xs.contains(c.target), "target present"),
        @quickcheck.classify(
          c.target == IMAX || c.target == IMIN,
          "target is Int extremum",
        ),
      ]
    },
  )
}

///|
test "qc: find returns the first occurrence or None" {
  @quickcheck.check(
    (c : Case) => {
      let lb = naive_lower_bound(c.xs, 0, c.target)
      let expected = if lb < c.xs.length() && c.xs[lb] == c.target {
        Some(lb)
      } else {
        None
      }
      @exponential_search.find(c.xs, c.target) == expected
    },
    count=300,
    max_size=70,
    seed=22,
  )
}

///|
test "qc: gallop(xs, start, t) is the first index >= start with xs[i] >= t" {
  @quickcheck.check(
    (c : Case) => {
      @exponential_search.gallop(c.xs, c.start, c.target) ==
      naive_lower_bound(c.xs, c.start, c.target)
    },
    count=400,
    max_size=70,
    max_shrinks=1000,
    seed=23,
  )
}

///|
test "qc: gallop from 0 coincides with lower_bound" {
  @quickcheck.check(
    (c : Case) => {
      @exponential_search.gallop(c.xs, 0, c.target) ==
      @exponential_search.lower_bound(c.xs, c.target)
    },
    seed=24,
  )
}
