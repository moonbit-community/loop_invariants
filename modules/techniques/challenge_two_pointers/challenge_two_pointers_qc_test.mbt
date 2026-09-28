// Property-based tests for `count_subarrays_leq` on non-negative input (the
// documented precondition) against an O(n^2) count, including values near
// `Int::MAX_VALUE`.

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
/// Non-negative array (negatives mapped by `lnot`) and a bound `k` that is
/// small, an element, an extremum, or arbitrary.
priv struct Case {
  xs : Array[Int]
  k : Int
} derive(Debug)

///|
fn nonneg(xs : Array[Int]) -> Array[Int] {
  xs.map(x => if x < 0 { x.lnot() } else { x })
}

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(size, rs) {
  let a : Ints = @quickcheck.Arbitrary::arbitrary(size, rs)
  let xs = nonneg(a.xs)
  let n = xs.length()
  let k = match rint(rs, 0, 4) {
    0 => rint(rs, -1, 10)
    1 if n > 0 => xs[rint(rs, 0, n - 1)]
    2 => [IMAX, IMAX - 1, IMIN][rint(rs, 0, 2)]
    _ => @quickcheck.Arbitrary::arbitrary(size, rs)
  }
  { xs, k, }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.xs, self.k)).map(p => {
    xs: nonneg(p.0),
    k: p.1,
  })
}

///|
/// O(n^2) count; extensions are tested as `x > k - s` with `0 <= s <= k`, so
/// the reference cannot overflow.
fn ref_count(xs : Array[Int], k : Int) -> Int {
  if k < 0 {
    return 0
  }
  let mut c = 0
  for i in 0..<xs.length() {
    let mut s = 0
    for j in i..<xs.length() {
      if xs[j] > k - s {
        break
      }
      s = s + xs[j]
      c = c + 1
    }
  }
  c
}

///|
test "qc: count_subarrays_leq matches an O(n^2) count" {
  @quickcheck.check(
    (c : Case) => {
      @challenge_two_pointers.count_subarrays_leq(c.xs[:], c.k) ==
      ref_count(c.xs, c.k)
    },
    count=400,
    max_size=40,
    max_shrinks=1000,
    seed=111,
    observe=c => {
      let n = c.xs.length()
      let r = ref_count(c.xs, c.k)
      [
        @quickcheck.classify(r == 0, "count 0"),
        @quickcheck.classify(n > 0 && r == n * (n + 1) / 2, "all subarrays"),
        @quickcheck.classify(c.xs.contains(IMAX), "contains Int::MAX_VALUE"),
      ]
    },
  )
}

///|
test "qc: count_subarrays_leq is monotone in k" {
  @quickcheck.check(
    (c : Case) => {
      @challenge_two_pointers.count_subarrays_leq(c.xs[:], c.k) <=
      @challenge_two_pointers.count_subarrays_leq(c.xs[:], c.k + 1)
    },
    filter=c => c.k < IMAX,
    count=300,
    max_size=40,
    max_shrinks=1000,
    seed=112,
  )
}

///|
test "regression: count_subarrays_leq window sum overflow" {
  // 1 + Int::MAX_VALUE used to wrap negative, so [1, MAX] and [MAX] were
  // counted as having sum <= 16.
  inspect(
    @challenge_two_pointers.count_subarrays_leq([1, 2147483647], 16),
    content="1",
  )
  inspect(
    @challenge_two_pointers.count_subarrays_leq(
      [2147483647, 2147483647],
      2147483647,
    ),
    content="2",
  )
}
