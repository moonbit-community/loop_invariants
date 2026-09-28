// Property-based tests for LCS length: agreement with the recursive
// definition (memoised) and basic algebraic facts.

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
/// Recursive definition of LCS length on suffixes, memoised.
fn ref_lcs(a : Array[Char], b : Array[Char]) -> Int {
  let memo : Map[(Int, Int), Int] = Map([])
  fn go(i : Int, j : Int) -> Int {
    if i == a.length() || j == b.length() {
      return 0
    }
    match memo.get((i, j)) {
      Some(v) => return v
      None => ()
    }
    let v = if a[i] == b[j] {
      1 + go(i + 1, j + 1)
    } else {
      max2(go(i + 1, j), go(i, j + 1))
    }
    memo[(i, j)] = v
    v
  }

  go(0, 0)
}

///|
fn lcs(a : Str, b : Str) -> Int {
  @challenge_lcs.lcs_length(a.cs[:], b.cs[:])
}

///|
test "qc: lcs_length matches the recursive definition" {
  @quickcheck.check(
    (p : (Str, Str)) => lcs(p.0, p.1) == ref_lcs(p.0.cs, p.1.cs),
    count=400,
    max_size=10,
    max_shrinks=1000,
    seed=241,
    observe=p => {
      let r = ref_lcs(p.0.cs, p.1.cs)
      let m = min2(p.0.cs.length(), p.1.cs.length())
      [
        @quickcheck.classify(m == 0, "an empty side"),
        @quickcheck.classify(m > 0 && r == 0, "no common char"),
        @quickcheck.classify(
          m > 0 && r == m,
          "one is a subsequence of the other",
        ),
        @quickcheck.classify(r > 0 && r < m, "partial overlap"),
      ]
    },
  )
}

///|
test "qc: lcs_length is symmetric, bounded, and |a| on (a, a)" {
  @quickcheck.check(
    (p : (Str, Str)) => {
      let (a, b) = p
      lcs(a, b) == lcs(b, a) &&
      lcs(a, b) <= min2(a.cs.length(), b.cs.length()) &&
      lcs(a, a) == a.cs.length()
    },
    seed=242,
  )
}

///|
test "qc: lcs_length of a with a concatenation is at least lcs with a part" {
  @quickcheck.check(
    (t : (Str, Str, Str)) => {
      let (a, b, c) = t
      let bc : Str = { cs: b.cs + c.cs, }
      let l = lcs(a, bc)
      l >= lcs(a, b) && l >= lcs(a, c) && l <= lcs(a, b) + lcs(a, c)
    },
    seed=243,
  )
}
