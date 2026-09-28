// Property-based tests for Aho-Corasick: the multiset of reported matches is
// compared with a naive per-pattern scan. The automaton's alphabet is
// documented as byte values 0-255 (see README "Pitfalls"), so generated text
// and patterns stay within U+0000..U+00FF.

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

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
/// Mostly 'a'..'c' (frequent, overlapping matches); sometimes the whole
/// supported byte range, including NUL, 0x7F-0xFF.
fn gen_byte_text(rs : @quickcheck.RandomState, max_len : Int) -> String {
  if rint(rs, 0, 3) == 0 {
    let len = rint(rs, 0, max_len)
    let sb = StringBuilder()
    for _ in 0..<len {
      sb.write_char(rint(rs, 0, 255).unsafe_to_char())
    }
    sb.to_string()
  } else {
    gen_str(rs, ['a', 'b', 'c'], max_len)
  }
}

///|
/// A non-empty pattern: a slice of `text`, or a short random string.
fn gen_nonempty_pattern(rs : @quickcheck.RandomState, text : String) -> String {
  let n = text.length()
  if n > 0 && rint(rs, 0, 1) == 0 {
    let i = rint(rs, 0, n - 1)
    let j = rint(rs, i + 1, if n - i > 5 { i + 5 } else { n })
    text.view(start_offset=i, end_offset=j).to_owned()
  } else {
    let s = gen_str(rs, ['a', 'b', 'c'], 3)
    if s.length() == 0 {
      "a"
    } else {
      s
    }
  }
}

///|
priv struct Dict {
  patterns : Array[String]
  text : String
} derive(Debug)

///|
impl @quickcheck.Arbitrary for Dict with fn arbitrary(size, rs) {
  let text = gen_byte_text(rs, size)
  let k = rint(rs, 0, 5)
  { patterns: Array::makei(k, _ => gen_nonempty_pattern(rs, text)), text, }
}

///|
impl @quickcheck.Shrink for Dict with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.patterns, self.text))
  .filter(p => p.0.iter().all(s => s.length() > 0))
  .map(p => { patterns: p.0, text: p.1, })
}

///|
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
fn naive_matches(
  patterns : Array[String],
  text : String,
) -> Array[(Int, Int, String)] {
  let res : Array[(Int, Int, String)] = []
  for p in patterns {
    for i in naive_search(text, p) {
      res.push((i, i + p.length(), p))
    }
  }
  res.sort()
  res
}

///|
test "qc: find_all_matches reports exactly the naive matches" {
  @quickcheck.check(
    (d : Dict) => {
      let got = @aho_corasick.find_all_matches(d.patterns[:], d.text)
      got.sort()
      got == naive_matches(d.patterns, d.text)
    },
    observe=d => {
      let m = naive_matches(d.patterns, d.text)
      [
        @quickcheck.classify(m.length() > 0, "some match"),
        @quickcheck.classify(m.length() > 3, "more than 3 matches"),
        @quickcheck.classify(
          d.patterns
          .iter()
          .any(p => d.patterns.iter().any(q => q != p && q.contains(p))),
          "a pattern is inside another",
        ),
      ]
    },
    count=500,
    max_size=30,
    seed=0xac0001,
  )
}

///|
test "qc: count_all_matches is the number of naive matches" {
  @quickcheck.check(
    (d : Dict) => {
      @aho_corasick.count_all_matches(d.patterns[:], d.text) ==
      naive_matches(d.patterns, d.text).length()
    },
    count=500,
    max_size=30,
    seed=0xac0002,
  )
}

///|
test "qc: matches are reported in order of their end position" {
  @quickcheck.check(
    (d : Dict) => {
      let got = @aho_corasick.find_all_matches(d.patterns[:], d.text)
      for i in 1..<got.length() {
        if got[i - 1].1 > got[i].1 {
          return false
        }
      }
      true
    },
    count=300,
    max_size=30,
    seed=0xac0003,
  )
}

///|
/// A dictionary that may also contain empty patterns.
priv struct DictWithEmpty(Dict) derive(Debug)

///|
impl @quickcheck.Arbitrary for DictWithEmpty with fn arbitrary(size, rs) {
  let d : Dict = @quickcheck.Arbitrary::arbitrary(size, rs)
  let patterns = d.patterns.copy()
  for _ in 0..<rint(rs, 1, 2) {
    patterns.insert(rint(rs, 0, patterns.length()), "")
  }
  DictWithEmpty({ patterns, text: d.text, })
}

///|
impl @quickcheck.Shrink for DictWithEmpty with fn shrink(self) {
  @quickcheck.Shrink::shrink((self.0.patterns, self.0.text)).map(p => {
    DictWithEmpty({ patterns: p.0, text: p.1, })
  })
}

///|
test "qc: empty patterns never match and do not disturb the others" {
  @quickcheck.check(
    (d : DictWithEmpty) => {
      let got = @aho_corasick.find_all_matches(d.0.patterns[:], d.0.text)
      got.sort()
      got == naive_matches(d.0.patterns, d.0.text) &&
      @aho_corasick.count_all_matches(d.0.patterns[:], d.0.text) == got.length()
    },
    count=300,
    max_size=30,
    seed=0xac0004,
  )
}

///|
/// An empty pattern made the root accepting; its "matches" were reported only
/// where the search fell back to the root (never at 0) and vanished as soon
/// as another pattern covered the next character.
test "regression: aho_corasick empty pattern" {
  debug_inspect(@aho_corasick.find_all_matches([""][:], "ab"), content="[]")
  debug_inspect(
    @aho_corasick.find_all_matches(["", "ab"][:], "abb"),
    content=(
      #|[(0, 2, "ab")]
    ),
  )
  debug_inspect(
    @aho_corasick.count_all_matches(["", "b"][:], "ab"),
    content="1",
  )
}
