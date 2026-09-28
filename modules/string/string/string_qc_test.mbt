// Property-based tests for the public `string` helpers on `ArrayView[Char]`:
// `lcs_length` against a memoised recursion and `longest_palindrome_range`
// against brute force (both are per character, not per code unit).

///|
/// Uniform integer in the inclusive range `[lo, hi]`.
fn rint(rs : @quickcheck.RandomState, lo : Int, hi : Int) -> Int {
  lo +
  rs.next_uint(limit=(hi - lo + 1).reinterpret_as_uint()).reinterpret_as_int()
}

///|
/// Mostly a 3-letter alphabet; sometimes arbitrary chars including '#', the
/// separator Manacher's transform uses internally, and astral chars.
fn gen_chars(rs : @quickcheck.RandomState, max_len : Int) -> Array[Char] {
  let len = rint(rs, 0, max_len)
  let alpha = if rint(rs, 0, 2) == 0 {
    ['a', '#', 'Z', '😀', '\u{0}']
  } else {
    ['a', 'b', 'c']
  }
  Array::makei(len, _ => {
    if rint(rs, 0, 9) == 0 {
      @quickcheck.Arbitrary::arbitrary(max_len, rs)
    } else {
      alpha[rint(rs, 0, alpha.length() - 1)]
    }
  })
}

///|
priv struct Chars(Array[Char]) derive(Debug)

///|
impl @quickcheck.Arbitrary for Chars with fn arbitrary(size, rs) {
  Chars(gen_chars(rs, if size < 25 { size } else { 25 }))
}

///|
impl @quickcheck.Shrink for Chars with fn shrink(self) {
  @quickcheck.Shrink::shrink(self.0).map(a => Chars(a))
}

///|
fn naive_lcs(a : ArrayView[Char], b : ArrayView[Char]) -> Int {
  let memo : Map[(Int, Int), Int] = Map([])
  fn go(i : Int, j : Int) -> Int {
    if i == a.length() || j == b.length() {
      return 0
    }
    match memo.get((i, j)) {
      Some(v) => return v
      None => ()
    }
    let r = if a[i] == b[j] {
      go(i + 1, j + 1) + 1
    } else {
      let x = go(i + 1, j)
      let y = go(i, j + 1)
      if x > y {
        x
      } else {
        y
      }
    }
    memo[(i, j)] = r
    r
  }

  go(0, 0)
}

///|
fn is_pal(s : ArrayView[Char], i : Int, j : Int) -> Bool {
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
test "qc: lcs_length agrees with the recursive definition, including on sub-views" {
  @quickcheck.check(
    (c : (Chars, Chars, Int)) => {
      let a = c.0.0
      let b = c.1.0
      // also exercise views that do not start at offset 0
      let off = if a.length() == 0 { 0 } else { (c.2 % a.length()).abs() }
      @string.lcs_length(a[:], b[:]) == naive_lcs(a[:], b[:]) &&
      @string.lcs_length(a[off:], b[:]) == naive_lcs(a[off:], b[:]) &&
      @string.lcs_length(b[:], a[:]) == naive_lcs(a[:], b[:])
    },
    observe=c => {
      [@quickcheck.classify(naive_lcs(c.0.0[:], c.1.0[:]) > 2, "lcs > 2")]
    },
    count=300,
    seed=0x57001,
  )
}

///|
test "qc: longest_palindrome_range is a longest palindrome" {
  @quickcheck.check(
    (c : (Chars, Int)) => {
      let full = c.0.0
      let off = if full.length() == 0 { 0 } else { (c.1 % full.length()).abs() }
      let s = full[off:]
      let n = s.length()
      let mut best = 0
      for i in 0..<n {
        for j in (i + best + 1)..<=n {
          if is_pal(s, i, j) {
            best = j - i
          }
        }
      }
      let (start, len) = @string.longest_palindrome_range(s)
      len == best &&
      start >= 0 &&
      start + len <= n &&
      is_pal(s, start, start + len)
    },
    observe=c => [@quickcheck.classify(c.0.0.contains('#'), "contains '#'")],
    count=300,
    seed=0x57002,
  )
}
