// Property-based tests for meet-in-the-middle `best_subset_sum_leq` against
// brute-force enumeration of all subsets. Inputs keep every subset sum
// representable as an `Int` (positive part <= Int::MAX_VALUE, negative part
// >= Int::MIN_VALUE) and use `target >= 0`, the documented assumption.

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
fn pos_neg_sums(xs : Array[Int]) -> (Int64, Int64) {
  let mut pos = 0L
  let mut neg = 0L
  for x in xs {
    if x > 0 {
      pos = pos + x.to_int64()
    } else {
      neg = neg + x.to_int64()
    }
  }
  (pos, neg)
}

///|
/// All subset sums fit in `Int`.
fn sums_fit(xs : Array[Int]) -> Bool {
  let (pos, neg) = pos_neg_sums(xs)
  pos <= IMAX.to_int64() && neg >= IMIN.to_int64()
}

///|
/// Brute force over all 2^n subsets, with 64-bit sums.
fn brute(xs : Array[Int], target : Int) -> Int64 {
  let n = xs.length()
  let mut best = 0L
  for mask in 0..<(1 << n) {
    let mut s = 0L
    for i in 0..<n {
      if ((mask >> i) & 1) == 1 {
        s = s + xs[i].to_int64()
      }
    }
    if s <= target.to_int64() && s > best {
      best = s
    }
  }
  best
}

///|
priv struct Case {
  xs : Array[Int]
  target : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(size, rs) {
  // Lengths up to 14 regardless of the driver size (2^14 brute-force
  // subsets stays cheap); the filter below otherwise biases towards tiny
  // arrays.
  let a : Ints = @quickcheck.Arbitrary::arbitrary(14, rs)
  let xs = a.xs
  if xs.length() > 0 && rint(rs, 0, 4) == 0 {
    // One huge positive element (so the positive part still fits in `Int`)
    // next to small values, with a target just below `Int::MAX_VALUE`:
    // the optimum may pair a negative sum with the huge element.
    let small = xs.map(x => x % 4)
    let pos = small.fold(init=0, (acc, x) => if x > 0 { acc + x } else { acc })
    small[rint(rs, 0, small.length() - 1)] = IMAX - pos - rint(rs, 0, 6)
    return { xs: small, target: IMAX - rint(rs, 0, 8), }
  }
  let target = match rint(rs, 0, 4) {
    0 => rint(rs, 0, 12)
    1 => if rint(rs, 0, 3) == 0 { 0 } else { IMAX - rint(rs, 0, 8) }
    2 | 3 => {
      // Near the sum of a random subset, so the optimum is non-trivial.
      let mut s = 0L
      for x in xs {
        if x > 0 && rint(rs, 0, 2) != 0 {
          s = s + x.to_int64()
        }
      }
      let s = s + rint(rs, -3, 1).to_int64()
      if s < 0L {
        0
      } else if s > IMAX.to_int64() {
        IMAX
      } else {
        s.to_int()
      }
    }
    _ => {
      let t : Int = @quickcheck.Arbitrary::arbitrary(size, rs)
      if t < 0 {
        t.lnot()
      } else {
        t
      }
    }
  }
  { xs, target, }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.xs, self.target)).map(p => {
    xs: p.0,
    target: if p.1 < 0 {
      p.1.lnot()
    } else {
      p.1
    },
  })
}

///|
test "qc: best_subset_sum_leq matches brute force over all subsets" {
  @quickcheck.check(
    (c : Case) => {
      @challenge_meet_in_middle.best_subset_sum_leq(c.xs[:], c.target).to_int64() ==
      brute(c.xs, c.target)
    },
    filter=c => sums_fit(c.xs),
    count=300,
    max_size=14,
    max_shrinks=1000,
    seed=131,
    observe=c => {
      let b = brute(c.xs, c.target)
      [
        @quickcheck.classify(b == 0L, "best is empty subset"),
        @quickcheck.classify(b == c.target.to_int64() && b > 0L, "exact hit"),
        @quickcheck.classify(c.xs.iter().any(x => x < 0), "has negatives"),
        @quickcheck.classify(
          c.xs.iter().any(x => x > 1000000 || x < -1000000),
          "has large magnitudes",
        ),
      ]
    },
  )
}

///|
test "regression: best_subset_sum_leq target - val overflow" {
  // Subset sums are 0, -6, 2147483643 and 2147483637; the best one <=
  // 2147483642 is 2147483637. For the left sum -6, `target - (-6)` used to
  // wrap negative, so that pairing was skipped and 0 was returned.
  inspect(
    @challenge_meet_in_middle.best_subset_sum_leq([-6, 2147483643], 2147483642),
    content="2147483637",
  )
}
