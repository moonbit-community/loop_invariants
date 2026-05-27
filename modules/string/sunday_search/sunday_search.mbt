// ============================================================================
// SUNDAY'S STRING SEARCH  -  Sunday 1990
// ============================================================================
//
// PROBLEM
//
// Locate every occurrence of pattern `p` (length `m`) inside text `t`
// (length `n`).
//
// Sunday's variant is a tweak of Boyer-Moore-Horspool. After comparing a
// window, it looks at the character **one past** the window end --
// `t[i + m]` -- and shifts so that this character lines up with its
// rightmost occurrence in `p`. If the character isn't in `p` at all, we
// can slide past it entirely: shift by `m + 1`.
//
// Because the shift uses the character that *must* be matched on the
// next alignment, Sunday's algorithm often takes larger average shifts
// than Horspool, especially on small alphabets.
//
// THE SHIFT TABLE
//
//   shift[c] = m - rightmost_index_of_c_in_p   for c in p
//   shift[c] = m + 1                            otherwise
//
// COMPLEXITY
//
//   Preprocessing : O(m + sigma)
//   Search avg    : O(n / m)
//   Search worst  : O(n * m) -- like Horspool, no quadratic-worst-case
//                   guarantee
//
// THE INVARIANT
//
//   "After processing window position i, every match starting in
//    [0, i) has been emitted, and the shift table is exactly that of
//    pattern p."

///|
const ALPHABET_SIZE : Int = 65536

///|
fn build_shift(p : Array[Int]) -> Array[Int] {
  let m = p.length()
  let t = Array::make(ALPHABET_SIZE, m + 1)
  for i in 0..<m {
    let c = p[i].land(ALPHABET_SIZE - 1)
    t[c] = m - i
  }
  t
}

///|
/// Find every overlapping match of `pattern` in `text`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let arr = fn(s : String) {
///     let r : Array[Int] = []
///     for c in s {
///       r.push(c.to_int())
///     }
///     r
///   }
///   @debug.assert_eq(@sunday_search.find_all(arr("ababab"), arr("ab")), [0, 2, 4])
/// }
/// ```
pub fn find_all(text : Array[Int], pattern : Array[Int]) -> Array[Int] {
  let n = text.length()
  let m = pattern.length()
  let res : Array[Int] = []
  if m == 0 || m > n {
    return res
  }
  let shift = build_shift(pattern)
  let mut i = 0
  while i + m <= n {
    let mut k = 0
    while k < m && pattern[k] == text[i + k] {
      k = k + 1
    }
    if k == m {
      res.push(i)
      // Advance by 1 for overlap; the bound check stays correct.
      i = i + 1
    } else {
      // Use the character at the next window's leading position.
      if i + m >= n {
        break
      }
      let c = text[i + m].land(ALPHABET_SIZE - 1)
      i = i + shift[c]
    }
  }
  res
}

///|
/// Return the first match index, or `None`.
pub fn find_first(text : Array[Int], pattern : Array[Int]) -> Int? {
  let n = text.length()
  let m = pattern.length()
  if m == 0 || m > n {
    return None
  }
  let shift = build_shift(pattern)
  let mut i = 0
  while i + m <= n {
    let mut k = 0
    while k < m && pattern[k] == text[i + k] {
      k = k + 1
    }
    if k == m {
      return Some(i)
    }
    if i + m >= n {
      break
    }
    let c = text[i + m].land(ALPHABET_SIZE - 1)
    i = i + shift[c]
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
test "sunday basic" {
  @debug.assert_eq(find_all(s("ababab"), s("ab")), [0, 2, 4])
  @debug.assert_eq(find_all(s("hello world"), s("world")), [6])
  @debug.assert_eq(find_all(s("xxx"), s("x")), [0, 1, 2])
}

///|
test "sunday no match" {
  @debug.assert_eq(find_all(s("abcdef"), s("xyz")), [])
  @debug.assert_eq(find_first(s("hello"), s("world")), None)
}

///|
test "sunday empty pattern" {
  @debug.assert_eq(find_all(s("abc"), s("")), [])
  @debug.assert_eq(find_first(s("abc"), s("")), None)
}

///|
test "sunday pattern equals text" {
  @debug.assert_eq(find_all(s("abc"), s("abc")), [0])
  @debug.assert_eq(find_first(s("abc"), s("abc")), Some(0))
}

///|
test "sunday pattern longer than text" {
  @debug.assert_eq(find_all(s("ab"), s("abc")), [])
}

///|
test "sunday overlapping" {
  @debug.assert_eq(find_all(s("aaaa"), s("aa")), [0, 1, 2])
}

///|
test "sunday agrees with naive" {
  fn naive(t : Array[Int], p : Array[Int]) -> Array[Int] {
    let res : Array[Int] = []
    let n = t.length()
    let m = p.length()
    if m == 0 || m > n {
      return res
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
        res.push(i)
      }
    }
    res
  }

  let cases = [
    ("the quick brown fox", "qu"),
    ("aaaaaaaa", "aaa"),
    ("mississippi", "issi"),
    ("abcabcabcabc", "cabc"),
    ("xyz", "x"),
  ]
  for c in cases {
    let t = s(c.0)
    let p = s(c.1)
    @debug.assert_eq(find_all(t, p), naive(t, p))
  }
}
