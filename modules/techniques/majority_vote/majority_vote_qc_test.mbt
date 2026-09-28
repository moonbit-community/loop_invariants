// Property-based tests for Boyer-Moore majority vote, compared with an
// explicit occurrence count.

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
fn occurrences(xs : Array[Int], x : Int) -> Int {
  xs.iter().filter(y => y == x).count()
}

///|
/// Reference: the element occurring more than n / 2 times, if any.
fn ref_majority(xs : Array[Int]) -> Int? {
  for x in xs {
    if occurrences(xs, x) * 2 > xs.length() {
      return Some(x)
    }
  }
  None
}

///|
/// Arrays that frequently have a strict majority (or an exact half).
priv struct Voting {
  xs : Array[Int]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Voting with fn arbitrary(size, rs) {
  let a : Ints = @quickcheck.Arbitrary::arbitrary(size, rs)
  let xs = a.xs
  let n = xs.length()
  if n > 0 && rint(rs, 0, 1) == 0 {
    // Overwrite about half (sometimes exactly half) of the positions with
    // one value at random positions.
    let v = xs[rint(rs, 0, n - 1)]
    let m = n / 2 + rint(rs, 0, 1)
    for _ in 0..<m {
      xs[rint(rs, 0, n - 1)] = v
    }
  }
  { xs, }
}

///|
impl @quickcheck.Shrink for Voting with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.xs).map(xs => { xs, })
}

///|
test "qc: majority agrees with explicit counting" {
  @quickcheck.check(
    (v : Voting) => @majority_vote.majority(v.xs) == ref_majority(v.xs),
    count=400,
    max_size=40,
    max_shrinks=1000,
    seed=51,
    observe=v => {
      let r = ref_majority(v.xs)
      let n = v.xs.length()
      [
        @quickcheck.classify(r is Some(_), "has majority"),
        @quickcheck.classify(n == 0, "empty"),
        @quickcheck.classify(
          n > 0 &&
          n % 2 == 0 &&
          v.xs.iter().any(x => occurrences(v.xs, x) * 2 == n),
          "some value at exactly n/2",
        ),
      ]
    },
  )
}

///|
test "qc: find_candidate returns the majority when one exists" {
  @quickcheck.check(
    (v : Voting) => {
      match ref_majority(v.xs) {
        Some(m) => @majority_vote.find_candidate(v.xs) == m
        None => true
      }
    },
    count=300,
    max_size=40,
    seed=52,
  )
}

///|
test "qc: find_candidate always returns an element of the input" {
  @quickcheck.check(
    (v : Voting) => v.xs.contains(@majority_vote.find_candidate(v.xs)),
    filter=v => v.xs.length() > 0,
    seed=53,
  )
}

///|
test "qc: majority is invariant under reversal" {
  @quickcheck.check(
    (v : Voting) => {
      @majority_vote.majority(v.xs) == @majority_vote.majority(v.xs.rev())
    },
    seed=54,
  )
}
