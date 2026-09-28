// Property-based tests for the Z-algorithm package: the Z-array is compared
// with its definition and every search helper with a naive O(n*m) scan over
// UTF-16 code units (the unit `String` indexing uses).

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
test "qc: find_pattern, z_search and count_pattern agree with naive search" {
  @quickcheck.check(
    (c : Search) => {
      let expected = naive_search(c.text, c.pattern)
      @z_algorithm.find_pattern(c.text, c.pattern) == expected &&
      @z_algorithm.z_search(c.text, c.pattern) == expected &&
      @z_algorithm.count_pattern(c.text, c.pattern) == expected.length()
    },
    observe=c => {
      let hits = naive_search(c.text, c.pattern).length()
      [
        @quickcheck.classify(hits > 0, "pattern occurs"),
        @quickcheck.classify(c.text.contains("$"), "text contains '$'"),
        @quickcheck.classify(has_astral(c.text), "astral chars in text"),
      ]
    },
    count=500,
    max_size=40,
    seed=0x7a616c01,
  )
}

///|
test "qc: compute_z and z_function match the definition" {
  @quickcheck.check(
    (s : Str) => {
      let str = s.0
      let n = str.length()
      let z = @z_algorithm.compute_z(str)
      guard z.length() == n && @z_algorithm.z_function(str) == z else {
        return false
      }
      for i in 0..<n {
        let mut k = 0
        while i + k < n && str[k] == str[i + k] {
          k = k + 1
        }
        if z[i] != k {
          return false
        }
      }
      true
    },
    count=300,
    max_size=30,
    seed=0x7a616c02,
  )
}

///|
/// `find_pattern` used to compare `z[i] == m`; when `pattern + "$"` also
/// occurs in the text the Z-value runs past the sentinel and the match was
/// silently dropped.
test "regression: find_pattern pattern followed by '$' in text" {
  debug_inspect(@z_algorithm.find_pattern("a$", "a"), content="[0]")
  debug_inspect(@z_algorithm.find_pattern("$$", "$"), content="[0, 1]")
  debug_inspect(@z_algorithm.count_pattern("ab$ab", "ab"), content="2")
}
