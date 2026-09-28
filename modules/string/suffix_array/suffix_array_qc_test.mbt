// Property-based tests for the suffix array: construction, LCP, search and
// the derived queries are compared with naive definitions over UTF-16 code
// units (the unit `String` indexing uses).

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
/// A single string drawn from the same distribution as search texts.
priv struct Str(String) derive(Debug)

///|
impl @quickcheck.Arbitrary for Str with fn arbitrary(size, rs) {
  Str(gen_text(rs, size))
}

///|
impl @quickcheck.Shrink for Str with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(s => Str(s))
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
/// Lexicographic comparison of the suffixes starting at `a` and `b`, code
/// unit by code unit (a proper prefix sorts first).
fn cmp_suffix(s : String, a : Int, b : Int) -> Int {
  let n = s.length()
  let mut k = 0
  while a + k < n && b + k < n {
    let x = s[a + k]
    let y = s[b + k]
    if x != y {
      return if x < y { -1 } else { 1 }
    }
    k = k + 1
  }
  // the shorter suffix (larger start) is a prefix of the other
  if a + k == n && b + k == n {
    0
  } else if a + k == n {
    -1
  } else {
    1
  }
}

///|
fn naive_sa(s : String) -> Array[Int] {
  let sa = Array::makei(s.length(), i => i)
  sa.sort_by((a, b) => cmp_suffix(s, a, b))
  sa
}

///|
fn lcp_at(s : String, a : Int, b : Int) -> Int {
  let n = s.length()
  let mut k = 0
  while a + k < n && b + k < n && s[a + k] == s[b + k] {
    k = k + 1
  }
  k
}

///|
fn naive_lcp(s : String, sa : Array[Int]) -> Array[Int] {
  Array::makei(sa.length(), i => {
    if i == 0 {
      0
    } else {
      lcp_at(s, sa[i - 1], sa[i])
    }
  })
}

///|
/// Key identifying the code-unit substring `s[i..j)`.
fn key(s : String, i : Int, j : Int) -> String {
  let sb = StringBuilder()
  for k in i..<j {
    sb.write_string(s[k].to_string())
    sb.write_char(',')
  }
  sb.to_string()
}

///|
test "qc: suffix_array is the naive sorted order of suffixes" {
  @quickcheck.check(
    (s : Str) => @suffix_array.suffix_array(s.0) == naive_sa(s.0),
    observe=s => {
      [
        @quickcheck.classify(s.0.length() == 0, "empty"),
        @quickcheck.classify(
          naive_lcp(s.0, naive_sa(s.0)).iter().any(x => x > 1),
          "some adjacent suffixes share >1 unit",
        ),
        @quickcheck.classify(has_astral(s.0), "astral chars"),
      ]
    },
    count=300,
    max_size=40,
    seed=0x5a0001,
  )
}

///|
test "qc: lcp_array and SuffixArray::lcp equal naive adjacent LCPs" {
  @quickcheck.check(
    (s : Str) => {
      let sa = naive_sa(s.0)
      let expected = if s.0.length() == 0 { [] } else { naive_lcp(s.0, sa) }
      let built = @suffix_array.SuffixArray(s.0)
      @suffix_array.lcp_array(s.0, sa[:]) == expected &&
      built.lcp == expected &&
      built.text == s.0
    },
    count=300,
    max_size=40,
    seed=0x5a0002,
  )
}

///|
test "qc: find_all, count and search agree with naive search" {
  @quickcheck.check(
    (c : Search) => {
      let sa = @suffix_array.SuffixArray(c.text)
      let expected = naive_search(c.text, c.pattern)
      let range_ok = match sa.search(c.pattern) {
        None => expected.length() == 0
        Some((first, last)) => {
          // every rank in [first, last] is an occurrence, and only those
          let starts = sa.sa[first:last + 1].to_owned()
          starts.sort()
          starts == expected
        }
      }
      range_ok &&
      sa.find_all(c.pattern) == expected &&
      sa.count(c.pattern) == expected.length()
    },
    observe=c => {
      [
        @quickcheck.classify(
          naive_search(c.text, c.pattern).length() > 0,
          "pattern occurs",
        ),
      ]
    },
    count=500,
    max_size=40,
    seed=0x5a0003,
  )
}

///|
test "qc: count_distinct_substrings equals the size of the naive substring set" {
  @quickcheck.check(
    (s : Str) => {
      let str = s.0
      let seen : Set[String] = Set([])
      for i in 0..<str.length() {
        for j in (i + 1)..<=str.length() {
          seen.add(key(str, i, j))
        }
      }
      @suffix_array.SuffixArray(str).count_distinct_substrings() ==
      seen.length().to_int64()
    },
    count=200,
    max_size=25,
    seed=0x5a0004,
  )
}

///|
test "qc: longest_repeated_substring is a longest substring occurring twice" {
  @quickcheck.check(
    (s : Str) => {
      let str = s.0
      let n = str.length()
      // naive: longest L such that two distinct starts share L units
      let mut best = 0
      for a in 0..<n {
        for b in (a + 1)..<n {
          let l = lcp_at(str, a, b)
          if l > best {
            best = l
          }
        }
      }
      let got = @suffix_array.SuffixArray(str).longest_repeated_substring()
      got.length() == best &&
      (best == 0 || naive_search(str, got).length() >= 2)
    },
    count=300,
    max_size=30,
    seed=0x5a0005,
  )
}

///|
test "qc: get_suffix(i) is the suffix of rank i, empty when out of range" {
  @quickcheck.check(
    (s : Str) => {
      let str = s.0
      let sa = @suffix_array.SuffixArray(str)
      let n = str.length()
      for i in 0..<n {
        let suf = sa.get_suffix(i)
        let start = sa.sa[i]
        guard suf.length() == n - start else { return false }
        for k in 0..<suf.length() {
          if suf[k] != str[start + k] {
            return false
          }
        }
      }
      sa.get_suffix(-1) == "" && sa.get_suffix(n) == ""
    },
    count=200,
    max_size=30,
    seed=0x5a0006,
  )
}
