// Property-based tests for Levenshtein distance: agreement with the
// recursive definition (memoised) and the metric laws.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
fn min2(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn max2(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
/// Short char arrays over a tiny alphabet (so matches are common), sometimes
/// mixed with arbitrary scalar values (astral and control characters too).
priv struct Str {
  cs : Array[Char]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Str with fn arbitrary(size, rs) {
  let len = rint(rs, 0, 10)
  let wild = rint(rs, 0, 3) == 0
  let cs = Array::makei(len, _ => {
    if wild && rint(rs, 0, 2) == 0 {
      @quickcheck.Arbitrary::arbitrary(size, rs)
    } else {
      ['a', 'b', 'c', '😀'][rint(rs, 0, 3)]
    }
  })
  { cs, }
}

///|
impl @quickcheck.Shrink for Str with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.cs).map(cs => { cs, })
}

///|
/// Recursive definition of Levenshtein distance on suffixes, memoised.
fn ref_dist(a : Array[Char], b : Array[Char]) -> Int {
  let memo : Map[(Int, Int), Int] = Map([])
  fn go(i : Int, j : Int) -> Int {
    if i == a.length() {
      return b.length() - j
    }
    if j == b.length() {
      return a.length() - i
    }
    match memo.get((i, j)) {
      Some(v) => return v
      None => ()
    }
    let v = if a[i] == b[j] {
      go(i + 1, j + 1)
    } else {
      let del = go(i + 1, j)
      let ins = go(i, j + 1)
      let sub = go(i + 1, j + 1)
      1 + min2(del, min2(ins, sub))
    }
    memo[(i, j)] = v
    v
  }

  go(0, 0)
}

///|
fn d(a : Str, b : Str) -> Int {
  @challenge_edit_distance.edit_distance(a.cs[:], b.cs[:])
}

///|
test "qc: edit_distance matches the recursive definition" {
  @quickcheck.check(
    (p : (Str, Str)) => d(p.0, p.1) == ref_dist(p.0.cs, p.1.cs),
    count=400,
    max_size=10,
    max_shrinks=1000,
    seed=231,
    observe=p => {
      let r = ref_dist(p.0.cs, p.1.cs)
      [
        @quickcheck.classify(
          p.0.cs.length() == 0 || p.1.cs.length() == 0,
          "an empty side",
        ),
        @quickcheck.classify(r == 0, "distance 0"),
        @quickcheck.classify(
          r < max2(p.0.cs.length(), p.1.cs.length()) && r > 0,
          "0 < d < max length",
        ),
      ]
    },
  )
}

///|
test "qc: edit_distance is symmetric and zero exactly on equal inputs" {
  @quickcheck.check(
    (p : (Str, Str)) => {
      let (a, b) = p
      d(a, b) == d(b, a) && d(a, a) == 0 && (d(a, b) == 0) == (a.cs == b.cs)
    },
    seed=232,
  )
}

///|
test "qc: edit_distance satisfies the triangle inequality" {
  @quickcheck.check(
    (t : (Str, Str, Str)) => {
      let (a, b, c) = t
      d(a, c) <= d(a, b) + d(b, c)
    },
    seed=233,
  )
}

///|
test "qc: edit_distance lies between the length difference and the max length" {
  @quickcheck.check(
    (p : (Str, Str)) => {
      let (a, b) = p
      let m = a.cs.length()
      let n = b.cs.length()
      let r = d(a, b)
      (m - n).abs() <= r && r <= max2(m, n)
    },
    seed=234,
  )
}
