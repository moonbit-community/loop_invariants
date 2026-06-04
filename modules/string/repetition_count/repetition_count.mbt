// ============================================================================
// REPETITION / SMALLEST PERIOD  -  via KMP failure function
// ============================================================================
//
// PROBLEM
//
// Given a string `s` of length `n`, determine:
//
//   - **smallest_period(s)** : the smallest `p` such that `s[i] = s[i + p]`
//     for all valid `i`. (`s` is then a prefix of `s[0:p]` repeated.)
//   - **is_periodic(s)**     : `true` iff the smallest period divides `n`
//     (so the entire string is a perfect concatenation of copies).
//   - **repetition_count(s)** : `n / smallest_period(s)` when periodic,
//     else `1`.
//   - **count_occurrences(text, pattern)** : count overlapping matches
//     of `pattern` in `text` in `O(n + m)`.
//
// THE KEY IDENTITY
//
// Let `fail[i] = ` length of the longest proper prefix of `s[0..i+1]`
// that is also a suffix. Then
//
//   smallest_period(s) = n - fail[n - 1]
//
// because the longest non-trivial overlap of `s` with itself slid
// right is `fail[n-1]`, leaving a period of `n - fail[n-1]`.
//
// COMPLEXITY
//
//   build failure table : O(n)
//   smallest_period      : O(n)
//   count_occurrences    : O(n + m)
//
// THE INVARIANT (KMP failure)
//
//   "After processing index i, fail[i] is the length of the longest
//    proper prefix of s[0..i+1] equal to its suffix."

///|
/// KMP failure table.
fn failure(p : Array[Int]) -> Array[Int] {
  let m = p.length()
  let f = Array::make(m, 0)
  let mut k = 0
  for i in 1..<m {
    while k > 0 && p[k] != p[i] {
      k = f[k - 1]
    }
    if p[k] == p[i] {
      k = k + 1
    }
    f[i] = k
  }
  f
}

///|
/// Smallest period of `s`. Returns `s.length()` when no nontrivial
/// period exists (every prefix-suffix overlap is empty). `0` for the
/// empty string.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let s = "abcabc".to_array().map(c => c.to_int())
///   @debug.assert_eq(@repetition_count.smallest_period(s), 3)
/// }
/// ```
pub fn smallest_period(s : Array[Int]) -> Int {
  let n = s.length()
  if n == 0 {
    return 0
  }
  let f = failure(s)
  n - f[n - 1]
}

///|
/// `true` iff `s` is a perfect concatenation of `>= 2` copies of a
/// shorter string.
pub fn is_periodic(s : Array[Int]) -> Bool {
  let n = s.length()
  if n < 2 {
    return false
  }
  let p = smallest_period(s)
  p < n && n % p == 0
}

///|
/// Number of times `s` is the concatenation of a smaller block. Returns
/// `1` when `s` is aperiodic (or empty / single-char), `n / period`
/// otherwise.
pub fn repetition_count(s : Array[Int]) -> Int {
  let n = s.length()
  if n == 0 {
    return 0
  }
  let p = smallest_period(s)
  if p < n && n % p == 0 {
    n / p
  } else {
    1
  }
}

///|
/// Number of (overlapping) occurrences of `pattern` in `text` via KMP.
pub fn count_occurrences(text : Array[Int], pattern : Array[Int]) -> Int {
  let n = text.length()
  let m = pattern.length()
  if m == 0 || m > n {
    return 0
  }
  let f = failure(pattern)
  let mut q = 0
  let mut count = 0
  for i in 0..<n {
    while q > 0 && pattern[q] != text[i] {
      q = f[q - 1]
    }
    if pattern[q] == text[i] {
      q = q + 1
    }
    if q == m {
      count = count + 1
      q = f[q - 1]
    }
  }
  count
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
test "period of abcabc is 3" {
  @debug.assert_eq(smallest_period(s("abcabc")), 3)
}

///|
test "period of abcd is 4 (aperiodic)" {
  @debug.assert_eq(smallest_period(s("abcd")), 4)
  @debug.assert_eq(is_periodic(s("abcd")), false)
}

///|
test "period of empty / single" {
  @debug.assert_eq(smallest_period([]), 0)
  @debug.assert_eq(smallest_period(s("a")), 1)
  @debug.assert_eq(is_periodic([]), false)
  @debug.assert_eq(is_periodic(s("a")), false)
}

///|
test "repetition_count examples" {
  @debug.assert_eq(repetition_count(s("abab")), 2)
  @debug.assert_eq(repetition_count(s("abcabcabc")), 3)
  @debug.assert_eq(repetition_count(s("aaaa")), 4)
  @debug.assert_eq(repetition_count(s("abcd")), 1)
}

///|
test "is_periodic for ababab" {
  @debug.assert_eq(is_periodic(s("ababab")), true)
  @debug.assert_eq(is_periodic(s("abcabc")), true)
  @debug.assert_eq(is_periodic(s("abcab")), false) // period 3 but n=5 not divisible
}

///|
test "count_occurrences basic" {
  @debug.assert_eq(count_occurrences(s("abababab"), s("ab")), 4)
  @debug.assert_eq(count_occurrences(s("abababab"), s("aba")), 3)
  @debug.assert_eq(count_occurrences(s("aaaa"), s("aa")), 3)
  @debug.assert_eq(count_occurrences(s("hello"), s("ll")), 1)
}

///|
test "count_occurrences none" {
  @debug.assert_eq(count_occurrences(s("hello"), s("xyz")), 0)
  @debug.assert_eq(count_occurrences(s(""), s("a")), 0)
  @debug.assert_eq(count_occurrences(s("abc"), s("")), 0)
}

///|
test "period agrees with brute force" {
  fn brute_period(arr : Array[Int]) -> Int {
    let n = arr.length()
    if n == 0 {
      return 0
    }
    for p in 1..<=n {
      let mut ok = true
      for i in 0..<n {
        if arr[i] != arr[i % p] {
          ok = false
          break
        }
      }
      if ok {
        return p
      }
    }
    n
  }

  let cases : ReadOnlyArray[String] = [
    "abcabc", "abab", "aaaa", "abcd", "abcabcab", "abacab", "xyzxyzxyz",
  ]
  for c in cases {
    @debug.assert_eq(smallest_period(s(c)), brute_period(s(c)))
  }
}
