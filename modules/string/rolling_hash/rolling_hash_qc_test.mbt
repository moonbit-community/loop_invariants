// Property-based tests for the rolling-hash Rabin-Karp helpers: results are
// compared with a naive O(n*m) scan over UTF-16 code units (the unit `String`
// indexing uses), for any characters, not just 'a'..'z'.

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
test "qc: find_pattern_rabin_karp and count_pattern_rabin_karp agree with naive search" {
  @quickcheck.check(
    (c : Search) => {
      let expected = naive_search(c.text, c.pattern)
      @rolling_hash.find_pattern_rabin_karp(c.text, c.pattern) == expected &&
      @rolling_hash.count_pattern_rabin_karp(c.text, c.pattern) ==
      expected.length()
    },
    observe=c => {
      [
        @quickcheck.classify(
          naive_search(c.text, c.pattern).length() > 0,
          "pattern occurs",
        ),
        @quickcheck.classify(has_astral(c.text), "astral chars in text"),
      ]
    },
    count=500,
    max_size=40,
    seed=0x72680001,
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
test "qc: find_pattern_rabin_karp finds long windows over mixed-case text" {
  @quickcheck.check(
    (c : MixedCase) => {
      @rolling_hash.find_pattern_rabin_karp(c.0.text, c.0.pattern) ==
      naive_search(c.0.text, c.0.pattern)
    },
    count=1000,
    max_size=16,
    seed=0x72680002,
  )
}

///|
/// Prefix hashes of text containing characters below 'a' were left negative,
/// so `get_hash` could return `h - HASH_MOD` for a window whose pattern hash
/// was `h`, and the match was skipped.
test "regression: find_pattern_rabin_karp long window after char below 'a'" {
  debug_inspect(
    @rolling_hash.find_pattern_rabin_karp("a!aaaaa", "!aaaaa"),
    content="[1]",
  )
  debug_inspect(
    @rolling_hash.count_pattern_rabin_karp("aA!b!b!ab", "A!b!b!ab"),
    content="1",
  )
}
