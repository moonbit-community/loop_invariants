// Property-based tests for word-break counting: `count` is compared with an
// explicit (unmemoised) enumeration of segmentations and `can_break` with
// `count > 0`. Strings and words use a two-letter alphabet so many
// segmentations exist.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
priv struct Case {
  s : Array[Int]
  dict : Array[Array[Int]]
} derive(Debug)

///|
/// Removes duplicate words (the count is over sequences of dictionary
/// entries, so duplicates would be counted twice).
fn dedup_words(dict : Array[Array[Int]]) -> Array[Array[Int]] {
  let out : Array[Array[Int]] = []
  for w in dict {
    if !out.contains(w) {
      out.push(w)
    }
  }
  out
}

///|
impl @quickcheck.Arbitrary for Case with fn arbitrary(_, rs) {
  let letter = () => {
    if rint(rs, 0, 15) == 0 {
      [0x1F600, -1, 2147483647][rint(rs, 0, 2)]
    } else {
      rint(rs, 97, 98)
    }
  }
  let dict = Array::makei(rint(rs, 0, 6), _ => {
    let len = if rint(rs, 0, 9) == 0 { 0 } else { rint(rs, 1, 3) }
    Array::makei(len, _ => letter())
  })
  let s = if rint(rs, 0, 2) == 0 || dict.length() == 0 {
    Array::makei(rint(rs, 0, 12), _ => letter())
  } else {
    // Concatenate random dictionary words so a segmentation usually exists.
    let s : Array[Int] = []
    for _ in 0..<rint(rs, 0, 8) {
      s.append(dict[rint(rs, 0, dict.length() - 1)])
    }
    s
  }
  { s, dict: dedup_words(dict), }
}

///|
impl @quickcheck.Shrink for Case with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.s, self.dict)).map(p => {
    s: p.0,
    dict: dedup_words(p.1),
  })
}

///|
/// Counts segmentations by trying every non-empty word at every position,
/// without memoisation.
fn ref_count(s : Array[Int], dict : Array[Array[Int]]) -> Int64 {
  fn go(i : Int) -> Int64 {
    if i == s.length() {
      return 1L
    }
    let mut total = 0L
    for w in dict {
      if w.length() > 0 &&
        i + w.length() <= s.length() &&
        s[i:i + w.length()] == w[:] {
        total = total + go(i + w.length())
      }
    }
    total
  }

  go(0)
}

///|
test "qc: count matches explicit enumeration of segmentations" {
  @quickcheck.check(
    (c : Case) => @word_break_count.count(c.s, c.dict) == ref_count(c.s, c.dict),
    count=400,
    max_shrinks=1000,
    seed=271,
    observe=c => {
      let r = ref_count(c.s, c.dict)
      [
        @quickcheck.classify(r == 0L, "no segmentation"),
        @quickcheck.classify(r >= 2L, "ambiguous (>= 2 segmentations)"),
        @quickcheck.classify(c.s.length() == 0, "empty string"),
        @quickcheck.classify(
          c.dict.iter().any(w => w.length() == 0),
          "empty word in dict",
        ),
      ]
    },
  )
}

///|
test "qc: can_break is equivalent to count > 0" {
  @quickcheck.check(
    (c : Case) => {
      @word_break_count.can_break(c.s, c.dict) == (ref_count(c.s, c.dict) > 0L)
    },
    count=400,
    max_shrinks=1000,
    seed=272,
  )
}
