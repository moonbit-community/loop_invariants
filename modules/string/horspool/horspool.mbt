// ============================================================================
// BOYER-MOORE-HORSPOOL STRING SEARCH  -  Horspool 1980
// ============================================================================
//
// PROBLEM
//
// Find all occurrences of a pattern `p` (length `m`) inside a text `t`
// (length `n`).
//
// Horspool's algorithm is a simplification of Boyer-Moore that keeps only
// the **bad-character shift table** (no good-suffix rule). It is
// remarkably simple, has O(n/m) **best-case** time and O(nm) worst-case
// (same as naive), but performs extremely well in practice on natural
// data thanks to large average shifts.
//
// THE BAD-CHARACTER SHIFT
//
// Pre-compute, for each character `c`, the rightmost position of `c` in
// `p[0 .. m-2]` (we exclude the last character on purpose: a mismatch
// on the **last** character means we must shift past it). Define
//
//   shift[c] =  m - 1 - rightmost index of c in p[0..m-2]
//
// or `m` if `c` does not occur in that range. After aligning `p` with
// `t[i..i+m-1]`, if a mismatch is found we slide `p` forward by
// `shift[ t[i + m - 1] ]` -- the character at the **last** alignment
// position of the window.
//
// COMPLEXITY
//
//   Pre-processing : O(m + sigma) where sigma = alphabet size
//   Search worst    : O(n * m)
//   Search average  : O(n / m) -- close to optimal on random text
//   Search best     : O(n / m) -- pattern's last char absent from text
//
// THE INVARIANT
//
//   "After processing window position i, every match start in
//    [0, i) has been reported (or otherwise emitted), and the table
//    `shift` is exactly that of pattern p."

///|
/// The alphabet used by this implementation: characters are mapped to
/// their Int value mod `ALPHABET_SIZE`. We use a generous size so that
/// 16-bit Unicode code units don't collide.
const ALPHABET_SIZE : Int = 65536

///|
fn build_shift_table(p : Array[Int]) -> Array[Int] {
  let m = p.length()
  let table = Array::make(ALPHABET_SIZE, m)
  // Look only at p[0 .. m-2]; the last position is intentionally excluded.
  for i in 0..<(m - 1) {
    let c = p[i] & (ALPHABET_SIZE - 1)
    table[c] = m - 1 - i
  }
  table
}

///|
/// Find every (overlapping) occurrence of `pattern` in `text`, in order
/// of starting index. Returns an empty array if `pattern` is empty or
/// longer than `text`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let t = "ababcababc".to_array().map(c => c.to_int())
///   let p = "abc".to_array().map(c => c.to_int())
///   @debug.assert_eq(@horspool.find_all(t, p), [2, 7])
/// }
/// ```
pub fn find_all(text : Array[Int], pattern : Array[Int]) -> Array[Int] {
  let n = text.length()
  let m = pattern.length()
  let res : Array[Int] = []
  if m == 0 || m > n {
    return res
  }
  let shift = build_shift_table(pattern)
  let mut i = 0
  while i <= n - m {
    // Compare from the rightmost position of the window leftwards.
    let mut k = m - 1
    while k >= 0 && pattern[k] == text[i + k] {
      k = k - 1
    }
    if k < 0 {
      res.push(i)
      // Advance by one to allow overlapping matches; for non-overlapping
      // semantics use `i = i + m` instead.
      i = i + 1
    } else {
      let c = text[i + m - 1] & (ALPHABET_SIZE - 1)
      i = i + shift[c]
    }
  }
  res
}

///|
/// Like `find_all`, but stops at the first match. Returns `None` if the
/// pattern does not occur.
pub fn find_first(text : Array[Int], pattern : Array[Int]) -> Int? {
  let n = text.length()
  let m = pattern.length()
  if m == 0 || m > n {
    return None
  }
  let shift = build_shift_table(pattern)
  let mut i = 0
  while i <= n - m {
    let mut k = m - 1
    while k >= 0 && pattern[k] == text[i + k] {
      k = k - 1
    }
    if k < 0 {
      return Some(i)
    } else {
      let c = text[i + m - 1] & (ALPHABET_SIZE - 1)
      i = i + shift[c]
    }
  }
  None
}

///|
fn s(str : String) -> Array[Int] {
  let r : Array[Int] = []
  for c in str {
    r.push(c.to_int())
  }
  r
}

///|
test "horspool basic" {
  // "abcabcd" inside "xxabcabcdxx" once at index 2.
  @debug.assert_eq(find_all(s("xxabcabcdxx"), s("abcabcd")), [2])
}

///|
test "horspool no match" {
  @debug.assert_eq(find_all(s("hello world"), s("xyz")), [])
  @debug.assert_eq(find_first(s("hello world"), s("xyz")), None)
}

///|
test "horspool empty pattern" {
  // Empty pattern returns empty list -- caller-convention choice.
  @debug.assert_eq(find_all(s("abc"), s("")), [])
  @debug.assert_eq(find_first(s("abc"), s("")), None)
}

///|
test "horspool pattern longer than text" {
  @debug.assert_eq(find_all(s("ab"), s("abc")), [])
  @debug.assert_eq(find_first(s("ab"), s("abc")), None)
}

///|
test "horspool overlapping matches" {
  // "aaa" in "aaaaa" overlaps three times: indexes 0, 1, 2.
  @debug.assert_eq(find_all(s("aaaaa"), s("aaa")), [0, 1, 2])
}

///|
test "horspool match at end" {
  @debug.assert_eq(find_all(s("xxxabc"), s("abc")), [3])
  @debug.assert_eq(find_first(s("xxxabc"), s("abc")), Some(3))
}

///|
test "horspool first match" {
  // "the" appears at positions 0 and 32 (counting from 0).
  let text = "the quick brown fox jumps over the lazy dog"
  let arr = s(text)
  let pat = s("the")
  @debug.assert_eq(find_first(arr, pat), Some(0))
  @debug.assert_eq(find_all(arr, pat), [0, 31])
}

///|
test "horspool single character pattern" {
  // Edge case: m = 1.
  @debug.assert_eq(find_all(s("banana"), s("a")), [1, 3, 5])
  @debug.assert_eq(find_first(s("banana"), s("a")), Some(1))
}

///|
test "horspool single character text" {
  @debug.assert_eq(find_all(s("a"), s("a")), [0])
  @debug.assert_eq(find_all(s("a"), s("b")), [])
}

///|
test "horspool agrees with naive" {
  fn naive(t : Array[Int], p : Array[Int]) -> Array[Int] {
    let n = t.length()
    let m = p.length()
    let r : Array[Int] = []
    if m == 0 || m > n {
      return r
    }
    for i in 0..<=(n - m) {
      let mut ok = true
      for j in 0..<m {
        if t[i + j] != p[j] {
          ok = false
          break
        }
      }
      if ok {
        r.push(i)
      }
    }
    r
  }

  let texts = [
    "abcabcabc", "aaaaaaaaaa", "the cat sat on the mat", "mississippi", "abracadabra abracadabra",
  ]
  let pats = ["abc", "aaa", "the", "ssi", "abra"]
  for t in texts {
    for p in pats {
      @debug.assert_eq(find_all(s(t), s(p)), naive(s(t), s(p)))
    }
  }
}

///|
test "horspool unicode-safe" {
  // Different Int values map to different alphabet slots (mod 2^16).
  // Pattern with code points outside ASCII.
  let t = "héllo wörld héllo"
  let p = "héllo"
  let matches = find_all(s(t), s(p))
  @debug.assert_eq(matches.length(), 2)
  @debug.assert_eq(matches[0], 0)
}
