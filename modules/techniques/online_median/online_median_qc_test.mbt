// Property-based tests for the two-heap online median: after every `add`,
// the lower / upper / Double medians must match a sorted copy of the prefix.

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
/// Replays `xs` and checks all queries after each insertion.
fn medians_match(xs : Array[Int]) -> Bool {
  let m = @online_median.new()
  if m.size() != 0 ||
    m.lower_median() is Some(_) ||
    m.upper_median() is Some(_) ||
    m.median() is Some(_) {
    return false
  }
  let seen : Array[Int] = []
  for x in xs {
    m.add(x)
    seen.push(x)
    let s = seen.copy()
    s.sort()
    let n = s.length()
    let lo = s[(n - 1) / 2]
    let hi = s[n / 2]
    let mid = (lo.to_double() + hi.to_double()) / 2.0
    if m.size() != n ||
      m.lower_median() != Some(lo) ||
      m.upper_median() != Some(hi) ||
      m.median() != Some(mid) {
      return false
    }
  }
  true
}

///|
test "qc: online medians match a sorted prefix after every add" {
  @quickcheck.check(
    (a : Ints) => medians_match(a.xs),
    count=300,
    max_size=60,
    max_shrinks=1000,
    seed=71,
    observe=a => {
      [
        @quickcheck.classify(a.xs.length() % 2 == 0, "even length"),
        @quickcheck.classify(a.xs.contains(IMIN), "contains Int::MIN_VALUE"),
        @quickcheck.classify(a.xs.contains(IMAX), "contains Int::MAX_VALUE"),
      ]
    },
  )
}

///|
test "regression: online_median Int::MIN_VALUE negation overflow" {
  // `hi` used to store `-x`; `-Int::MIN_VALUE` wraps to itself, so the
  // second MIN_VALUE sat at the bottom of `hi` and 0 was reported as the
  // median of [MIN, MIN, 0].
  let m = @online_median.new()
  m.add(IMIN)
  m.add(IMIN)
  m.add(0)
  debug_inspect(m.lower_median(), content="Some(-2147483648)")
  debug_inspect(m.upper_median(), content="Some(-2147483648)")
  m.add(IMIN)
  debug_inspect(m.upper_median(), content="Some(-2147483648)")
  debug_inspect(m.median(), content="Some(-2147483648)")
}
