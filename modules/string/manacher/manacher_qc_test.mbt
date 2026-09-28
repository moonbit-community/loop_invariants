// Property-based tests for Manacher's algorithm: palindrome lengths, counts
// and radii are compared with brute force over UTF-16 code units (the unit
// `String` indexing uses). The spicy alphabet contains '#', the separator the
// implementation inserts, to make sure it never matches real text.

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
fn is_pal(s : String, i : Int, j : Int) -> Bool {
  let mut a = i
  let mut b = j - 1
  while a < b {
    if s[a] != s[b] {
      return false
    }
    a = a + 1
    b = b - 1
  }
  true
}

///|
fn naive_longest(s : String) -> Int {
  let n = s.length()
  let mut best = 0
  for i in 0..<n {
    for j in (i + 1)..<=n {
      if j - i > best && is_pal(s, i, j) {
        best = j - i
      }
    }
  }
  best
}

///|
test "qc: longest_palindrome_len and longest_palindrome match brute force" {
  @quickcheck.check(
    (s : Str) => {
      let str = s.0
      let best = naive_longest(str)
      let p = @manacher.longest_palindrome(str)
      @manacher.longest_palindrome_len(str) == best &&
      p.length() == best &&
      is_pal(p, 0, p.length()) &&
      (best == 0 || naive_search(str, p).length() > 0)
    },
    observe=s => {
      let best = naive_longest(s.0)
      [
        @quickcheck.classify(best >= 3, "palindrome of length >= 3"),
        @quickcheck.classify(best % 2 == 0 && best > 0, "longest is even"),
        @quickcheck.classify(s.0.contains("#"), "contains '#'"),
        @quickcheck.classify(has_astral(s.0), "astral chars"),
      ]
    },
    count=300,
    max_size=30,
    seed=0x6d610001,
  )
}

///|
test "qc: count_palindromes counts palindromic (start, end) pairs" {
  @quickcheck.check(
    (s : Str) => {
      let str = s.0
      let mut count = 0
      for i in 0..<str.length() {
        for j in (i + 1)..<=str.length() {
          if is_pal(str, i, j) {
            count = count + 1
          }
        }
      }
      @manacher.count_palindromes(str) == count
    },
    count=300,
    max_size=30,
    seed=0x6d610002,
  )
}

///|
test "qc: manacher_radii match the odd / even radius definitions" {
  @quickcheck.check(
    (s : Str) => {
      let str = s.0
      let n = str.length()
      let (d1, d2) = @manacher.manacher_radii(str)
      guard d1.length() == n && d2.length() == n else { return false }
      for i in 0..<n {
        // d1[i]: number of odd palindromes centred at i
        let mut k = 1
        while i - k >= 0 && i + k < n && str[i - k] == str[i + k] {
          k = k + 1
        }
        // d2[i]: number of even palindromes centred between i-1 and i
        let mut e = 0
        while i - e - 1 >= 0 && i + e < n && str[i - e - 1] == str[i + e] {
          e = e + 1
        }
        if d1[i] != k || d2[i] != e {
          return false
        }
      }
      true
    },
    count=300,
    max_size=30,
    seed=0x6d610003,
  )
}
