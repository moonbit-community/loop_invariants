// Property-based tests for Rabin-Karp: single- and multi-pattern search are
// compared with a naive O(n*m) scan over UTF-16 code units (the unit `String`
// indexing uses). Hashing must never cause a missed match, whatever the
// characters (upper case, digits, NUL, astral chars ...).

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Tiny alphabet so that matches and long borders are frequent.
let small_alpha : Array[Char] = ['a', 'b', 'c']

///|
/// Characters that tend to break implementations: sentinel-like symbols,
/// upper case, NUL, non-ASCII BMP and astral (surrogate pair) characters.
let spicy_alpha : Array[Char] = [
  'a', 'b', '$', '#', 'A', '0', 'é', '\u{0}', '\u{FFFF}', '😀',
]

///|
fn gen_str(
  rs : @quickcheck.RandomState,
  alpha : Array[Char],
  max_len : Int,
) -> String {
  let len = rint(rs, 0, max_len)
  let sb = StringBuilder()
  for _ in 0..<len {
    sb.write_char(alpha[rint(rs, 0, alpha.length() - 1)])
  }
  sb.to_string()
}

///|
fn gen_text(rs : @quickcheck.RandomState, size : Int) -> String {
  let k = rint(rs, 0, 9)
  if k < 5 {
    gen_str(rs, small_alpha, size)
  } else if k < 8 {
    gen_str(rs, spicy_alpha, size)
  } else {
    @quickcheck.Arbitrary::arbitrary(size, rs)
  }
}

///|
/// Either a random short string or a slice (by characters) of `text`.
fn gen_pattern(rs : @quickcheck.RandomState, text : String) -> String {
  let chars : Array[Char] = []
  for c in text {
    chars.push(c)
  }
  let k = rint(rs, 0, 9)
  if k < 5 && chars.length() > 0 {
    let i = rint(rs, 0, chars.length() - 1)
    let rest = chars.length() - i
    // mostly short and non-empty; sometimes long (up to the rest of the
    // text) so hashes over long windows are exercised; now and then empty
    let lo = if rint(rs, 0, 9) == 0 { 0 } else { 1 }
    let hi = if rint(rs, 0, 3) == 0 || rest < 5 { rest } else { 5 }
    let len = rint(rs, lo, hi)
    let sb = StringBuilder()
    for j in i..<(i + len) {
      sb.write_char(chars[j])
    }
    sb.to_string()
  } else if k < 8 {
    gen_str(rs, small_alpha, 4)
  } else {
    gen_str(rs, spicy_alpha, 3)
  }
}

///|
priv struct Search {
  text : String
  pattern : String
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Search with fn arbitrary(size, rs) {
  let text = gen_text(rs, size)
  { text, pattern: gen_pattern(rs, text), }
}

///|
impl @quickcheck.Shrink for Search with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.text, self.pattern)).map(p => {
    text: p.0,
    pattern: p.1,
  })
}

///|
/// Reference: all (overlapping) start indices; none for an empty pattern.
fn naive_search(text : String, pattern : String) -> Array[Int] {
  let n = text.length()
  let m = pattern.length()
  let res : Array[Int] = []
  if m == 0 || m > n {
    return res
  }
  for i in 0..<=(n - m) {
    let mut ok = true
    for j in 0..<m {
      if text[i + j] != pattern[j] {
        ok = false
        break
      }
    }
    if ok {
      res.push(i)
    }
  }
  res
}

///|
fn has_astral(s : String) -> Bool {
  for c in s {
    if c.to_int() > 0xFFFF {
      return true
    }
  }
  false
}

///|
priv struct Multi {
  text : String
  patterns : Array[String]
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Multi with fn arbitrary(size, rs) {
  let text = gen_text(rs, size)
  let k = rint(rs, 0, 4)
  { text, patterns: Array::makei(k, _ => gen_pattern(rs, text)), }
}

///|
impl @quickcheck.Shrink for Multi with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.text, self.patterns)).map(p => {
    text: p.0,
    patterns: p.1,
  })
}

///|
fn below_a(s : String) -> Bool {
  for c in s {
    if c < 'a' {
      return true
    }
  }
  false
}

///|
/// Hashes of characters below 'a' used to be left negative (`%` keeps the
/// sign), so the rolling window hash and the pattern hash disagreed and real
/// matches were dropped.
test "regression: rabin_karp chars below 'a' are found" {
  debug_inspect(@rabin_karp.rabin_karp_search("a/", "/"), content="[1]")
  debug_inspect(@rabin_karp.rabin_karp_search("AB", "B"), content="[1]")
  debug_inspect(@rabin_karp.rabin_karp_count("x1x1", "x1"), content="2")
  debug_inspect(@rabin_karp.rabin_karp_multi("a$", ["$"]), content="[(0, 1)]")
}

///|
fn sorted_pairs(xs : Array[(Int, Int)]) -> Array[(Int, Int)] {
  let ys = xs.copy()
  ys.sort()
  ys
}

///|
test "qc: rabin_karp_search and rabin_karp_count agree with naive search" {
  @quickcheck.check(
    (c : Search) => {
      let expected = naive_search(c.text, c.pattern)
      @rabin_karp.rabin_karp_search(c.text, c.pattern) == expected &&
      @rabin_karp.rabin_karp_count(c.text, c.pattern) == expected.length()
    },
    observe=c => {
      let hits = naive_search(c.text, c.pattern).length()
      [
        @quickcheck.classify(hits > 0, "pattern occurs"),
        @quickcheck.classify(below_a(c.pattern), "pattern has chars below 'a'"),
        @quickcheck.classify(has_astral(c.text), "astral chars in text"),
      ]
    },
    count=500,
    max_size=40,
    seed=0x726b0001,
  )
}

///|
test "qc: rabin_karp_multi reports exactly the naive (pattern, position) pairs" {
  @quickcheck.check(
    (c : Multi) => {
      let expected : Array[(Int, Int)] = []
      for idx, p in c.patterns {
        for pos in naive_search(c.text, p) {
          expected.push((idx, pos))
        }
      }
      sorted_pairs(@rabin_karp.rabin_karp_multi(c.text, c.patterns)) ==
      sorted_pairs(expected)
    },
    count=300,
    max_size=40,
    seed=0x726b0002,
  )
}

///|
/// Mixed lower case / below-'a' text with a long pattern cut out of it: the
/// shape that drives prefix hashes negative (characters below 'a' have
/// negative values) and long windows make `prefix[l] * base^len` large.
priv struct MixedCase(Search) derive(Debug)

///|
impl @quickcheck.Arbitrary for MixedCase with fn arbitrary(size, rs) {
  let text = gen_str(
    rs,
    ['a', 'b', 'A', '!'],
    if size < 16 {
      size
    } else {
      16
    },
  )
  let n = text.length()
  if n == 0 {
    return MixedCase({ text, pattern: "a", })
  }
  let i = rint(rs, 0, n - 1)
  let j = rint(rs, i + 1, n)
  MixedCase({
    text,
    pattern: text.view(start_offset=i, end_offset=j).to_owned(),
  })
}

///|
impl @quickcheck.Shrink for MixedCase with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(s => MixedCase(s))
}

///|
test "qc: rabin_karp_search finds long windows over mixed-case text" {
  @quickcheck.check(
    (c : MixedCase) => {
      @rabin_karp.rabin_karp_search(c.0.text, c.0.pattern) ==
      naive_search(c.0.text, c.0.pattern)
    },
    count=1000,
    max_size=16,
    seed=0x726b0003,
  )
}
