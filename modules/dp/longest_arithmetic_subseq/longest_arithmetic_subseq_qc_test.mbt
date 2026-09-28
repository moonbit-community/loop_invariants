// Property-based tests for the longest arithmetic subsequence against brute
// force over all subsequences. Differences are compared exactly (not modulo
// 2^64), so values near the `Int64` extrema are included.

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
/// Exact difference `b - a` as (wrapped difference, `b >= a`); two pairs
/// have the same mathematical difference iff their keys are equal.
fn diff_key(a : Int64, b : Int64) -> (Int64, Bool) {
  (b - a, b >= a)
}

///|
fn subseq(xs : Array[Int64], mask : Int) -> Array[Int64] {
  let out : Array[Int64] = []
  for i in 0..<xs.length() {
    if ((mask >> i) & 1) == 1 {
      out.push(xs[i])
    }
  }
  out
}

///|
fn is_arith(seq : Array[Int64]) -> Bool {
  for i in 2..<seq.length() {
    if diff_key(seq[i - 1], seq[i]) != diff_key(seq[i - 2], seq[i - 1]) {
      return false
    }
  }
  true
}

///|
fn brute(xs : Array[Int64], fixed : Int64?) -> Int {
  let mut best = 0
  for mask in 0..<(1 << xs.length()) {
    let seq = subseq(xs, mask)
    let ok = match fixed {
      None => is_arith(seq)
      Some(d) =>
        (1)
        .until(seq.length())
        .all(i => diff_key(seq[i - 1], seq[i]) == (d, d >= 0L))
    }
    if ok && seq.length() > best {
      best = seq.length()
    }
  }
  best
}

///|
/// Concatenates two generated arrays, keeping at most 12 elements for the
/// 2^n brute force.
fn join(p : (I64s, I64s)) -> Array[Int64] {
  let xs = p.0.xs + p.1.xs
  if xs.length() > 12 {
    xs[:12].to_owned()
  } else {
    xs
  }
}

///|
test "qc: length matches brute force over all subsequences" {
  @quickcheck.check(
    (p : (I64s, I64s)) => {
      let xs = join(p)
      @longest_arithmetic_subseq.length(xs) == brute(xs, None)
    },
    count=300,
    max_size=12,
    max_shrinks=1000,
    seed=311,
    observe=p => {
      let xs = join(p)
      let b = brute(xs, None)
      [
        @quickcheck.classify(xs.length() == 0, "empty"),
        @quickcheck.classify(b >= 4, "length >= 4"),
        @quickcheck.classify(
          xs.contains(LMIN) || xs.contains(LMAX),
          "Int64 extremum",
        ),
      ]
    },
  )
}

///|
test "qc: length_fixed_diff matches brute force over all subsequences" {
  @quickcheck.check(
    (input : ((I64s, I64s), Int64)) => {
      let xs = join(input.0)
      let d = match (input.1 % 4L).abs() {
        0L => input.1 % 3L
        1L if xs.length() >= 2 => xs[1] - xs[0]
        2L => [LMAX, LMIN, 1L, -1L][(input.1 / 4L % 4L).abs().to_int()]
        _ => input.1
      }
      @longest_arithmetic_subseq.length_fixed_diff(xs, d) == brute(xs, Some(d))
    },
    count=300,
    max_size=12,
    max_shrinks=1000,
    seed=312,
  )
}

///|
test "regression: longest_arithmetic_subseq wrapped differences" {
  // MAX - (-3) and 1 - MAX both wrap to Int64::MIN_VALUE + 2, so
  // [-3, MAX, 1] used to be reported as a 3-term progression.
  inspect(@longest_arithmetic_subseq.length([-3L, LMAX, 1L]), content="2")
  inspect(@longest_arithmetic_subseq.length([0L, LMIN, 0L]), content="2")
}

///|
test "regression: length_fixed_diff wrapped predecessor" {
  // (MAX - 1) - (MIN + 1) wraps to -3, so -3 used to be taken as the
  // predecessor of MAX - 1 for difference MIN + 1.
  inspect(
    @longest_arithmetic_subseq.length_fixed_diff([-3L, LMAX - 1L], LMIN + 1L),
    content="1",
  )
}
