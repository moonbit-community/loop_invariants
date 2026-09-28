// Property-based tests for longest common substring: the reported length is
// the brute-force maximum and the reported substring really occurs in both
// inputs (compared by UTF-16 code units, the unit `String` indexing uses).

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
fn lcp_at(a : String, i : Int, b : String, j : Int) -> Int {
  let mut k = 0
  while i + k < a.length() && j + k < b.length() && a[i + k] == b[j + k] {
    k = k + 1
  }
  k
}

///|
test "qc: longest_common_substring is a longest substring common to both" {
  @quickcheck.check(
    (c : Search) => {
      // reuse the text/pattern generator: the pattern is often a slice of
      // the text, so long common substrings are frequent
      let a = c.text
      let b = c.pattern + c.text.rev() + c.pattern
      let mut best = 0
      for i in 0..<a.length() {
        for j in 0..<b.length() {
          let l = lcp_at(a, i, b, j)
          if l > best {
            best = l
          }
        }
      }
      let r = @longest_common_substring.longest_common_substring(a, b)
      r.length == best &&
      r.substring.length() == best &&
      (
        best == 0 ||
        (
          naive_search(a, r.substring).length() > 0 &&
          naive_search(b, r.substring).length() > 0
        )
      )
    },
    observe=c => {
      [
        @quickcheck.classify(has_astral(c.text), "astral chars"),
        @quickcheck.classify(c.pattern.length() >= 3, "pattern length >= 3"),
      ]
    },
    count=300,
    max_size=25,
    seed=0x1c5001,
  )
}

///|
test "qc: longest_common_substring laws" {
  @quickcheck.check(
    (s : Str) => {
      let str = s.0
      let lcs = @longest_common_substring.longest_common_substring
      let r = lcs(str, str)
      let e = lcs(str, "")
      r.length == str.length() &&
      r.substring == str &&
      e.length == 0 &&
      e.substring == "" &&
      lcs(str, str + "x").length == str.length()
    },
    count=200,
    max_size=25,
    seed=0x1c5002,
  )
}
