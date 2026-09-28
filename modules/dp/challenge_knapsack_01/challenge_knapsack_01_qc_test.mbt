// Property-based tests for the 1-D 0/1 knapsack DP against brute-force
// enumeration of every item subset (non-negative weights, capacity >= 0).

///|
const IMAX : Int = 2147483647

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Items with small non-negative weights (zero included, sometimes
/// `Int::MAX_VALUE` so an item never fits) and small or large values
/// (negative values included), plus possibly mismatched array lengths.
priv struct Sack {
  weights : Array[Int]
  values : Array[Int]
  capacity : Int
} derive(Debug)

///|
fn fix_weight(w : Int) -> Int {
  if w < 0 {
    w.lnot()
  } else {
    w
  }
}

///|
impl @quickcheck.Arbitrary for Sack with fn arbitrary(_, rs) {
  // Up to 12 items regardless of the driver size (2^12 subsets stays cheap).
  let n = rint(rs, 0, 12)
  let big_values = rint(rs, 0, 3) == 0
  let weights = Array::makei(n + rint(rs, -1, 1), _ => {
    if rint(rs, 0, 9) == 0 {
      IMAX
    } else {
      rint(rs, 0, 6)
    }
  })
  let values = Array::makei(n + rint(rs, -1, 1), _ => {
    if big_values {
      rint(rs, -1000, 200000000)
    } else {
      rint(rs, -3, 10)
    }
  })
  { weights, values, capacity: rint(rs, 0, 15), }
}

///|
impl @quickcheck.Shrink for Sack with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.weights, self.values, self.capacity)).map(t => {
    weights: t.0.map(fix_weight),
    values: t.1,
    capacity: if t.2 < 0 {
      0
    } else {
      t.2
    },
  })
}

///|
fn brute(s : Sack) -> Int64 {
  let n = if s.weights.length() < s.values.length() {
    s.weights.length()
  } else {
    s.values.length()
  }
  let mut best = 0L
  for mask in 0..<(1 << n) {
    let mut w = 0L
    let mut v = 0L
    for i in 0..<n {
      if ((mask >> i) & 1) == 1 {
        w = w + s.weights[i].to_int64()
        v = v + s.values[i].to_int64()
      }
    }
    if w <= s.capacity.to_int64() && v > best {
      best = v
    }
  }
  best
}

///|
test "qc: knapsack_01 matches brute force over all subsets" {
  @quickcheck.check(
    (s : Sack) => {
      @challenge_knapsack_01.knapsack_01(s.weights[:], s.values[:], s.capacity).to_int64() ==
      brute(s)
    },
    count=400,
    max_size=12,
    max_shrinks=1000,
    seed=221,
    observe=s => {
      let b = brute(s)
      [
        @quickcheck.classify(b == 0L, "best is empty set"),
        @quickcheck.classify(
          s.weights.length() != s.values.length(),
          "mismatched lengths",
        ),
        @quickcheck.classify(s.weights.contains(0), "zero-weight item"),
        @quickcheck.classify(s.capacity == 0, "capacity 0"),
      ]
    },
  )
}

///|
test "qc: knapsack_01 is monotone in capacity" {
  @quickcheck.check(
    (s : Sack) => {
      @challenge_knapsack_01.knapsack_01(s.weights[:], s.values[:], s.capacity) <=
      @challenge_knapsack_01.knapsack_01(
        s.weights[:],
        s.values[:],
        s.capacity + 1,
      )
    },
    seed=222,
  )
}
