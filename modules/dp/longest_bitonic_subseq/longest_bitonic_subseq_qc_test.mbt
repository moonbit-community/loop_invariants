// Property-based tests for the longest bitonic subsequence against brute
// force over all subsequences (strictly increasing, then strictly
// decreasing; either half may be empty).

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
fn is_bitonic(seq : Array[Int64]) -> Bool {
  let n = seq.length()
  let mut i = 1
  while i < n && seq[i - 1] < seq[i] {
    i = i + 1
  }
  while i < n && seq[i - 1] > seq[i] {
    i = i + 1
  }
  i >= n
}

///|
fn brute(xs : Array[Int64]) -> Int {
  let n = xs.length()
  let mut best = 0
  for mask in 0..<(1 << n) {
    let seq : Array[Int64] = []
    for i in 0..<n {
      if ((mask >> i) & 1) == 1 {
        seq.push(xs[i])
      }
    }
    if seq.length() > best && is_bitonic(seq) {
      best = seq.length()
    }
  }
  best
}

///|
/// Concatenates two generated arrays (fewer empty inputs than one array),
/// keeping at most 12 elements for the 2^n brute force.
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
      @longest_bitonic_subseq.length(xs) == brute(xs)
    },
    count=300,
    max_size=12,
    max_shrinks=1000,
    seed=281,
    observe=p => {
      let xs = join(p)
      let n = xs.length()
      let b = brute(xs)
      [
        @quickcheck.classify(n == 0, "empty"),
        @quickcheck.classify(n > 0 && b == n, "whole array bitonic"),
        @quickcheck.classify(b >= 5, "length >= 5"),
      ]
    },
  )
}

///|
test "qc: length_with_split agrees with length and splits consistently" {
  @quickcheck.check(
    (a : I64s) => {
      let (best, inc, dec) = @longest_bitonic_subseq.length_with_split(a.xs)
      if a.xs.length() == 0 {
        best == 0 && inc == 0 && dec == 0
      } else {
        best == @longest_bitonic_subseq.length(a.xs) &&
        inc >= 1 &&
        dec >= 1 &&
        inc + dec - 1 == best
      }
    },
    max_size=40,
    seed=282,
  )
}
