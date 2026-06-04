// ============================================================================
// WORD BREAK COUNT  -  number of ways to split a string into dictionary words
// ============================================================================
//
// PROBLEM
//
// Given a string `s` (an `Array[Int]` of code points) and a dictionary
// of words (also `Array[Array[Int]]`), how many distinct concatenations
// of dictionary words equal `s`?
//
// Equivalently:
//
//   ways[i] = sum over w in dict, w is a prefix of s[i..] of ways[i + |w|]
//   ways[n] = 1
//
// The total is `ways[0]`.
//
// COMPLEXITY
//
//   Time : O(n^2 * |dict|) -- prefix check is O(n) in the worst case,
//          but with a trie we can do O(n + matches).
//   Space: O(n + total dict size)
//
// THE INVARIANT
//
//   "After ways[i] has been computed, it equals the number of distinct
//    dictionary-word sequences that concatenate to s[i..]."

///|
/// Number of ways to split `s` into concatenated dictionary words.
/// Result is mod `1_000_000_007` to keep within `Int64`.
///
/// ## Example
///
/// ```moonbit nocheck
/// test {
///   let to_arr = fn(str : String) {
///     let r : Array[Int] = []
///     for c in str {
///       r.push(c.to_int())
///     }
///     r
///   }
///   let s = to_arr("catsanddog")
///   let dict = [
///     to_arr("cat"),
///     to_arr("cats"),
///     to_arr("and"),
///     to_arr("sand"),
///     to_arr("dog"),
///   ]
///   @debug.assert_eq(@word_break_count.count(s, dict), 2L)
/// }
/// ```
pub fn count(s : Array[Int], dict : Array[Array[Int]]) -> Int64 {
  let n = s.length()
  let m = 1000000007L
  let ways = Array::make(n + 1, 0L)
  ways[n] = 1L
  let mut i = n - 1
  while i >= 0 {
    let mut total = 0L
    for w in dict {
      let wl = w.length()
      if wl == 0 || i + wl > n {
        continue
      }
      let mut k = 0
      let mut ok = true
      while k < wl {
        if s[i + k] != w[k] {
          ok = false
          break
        }
        k = k + 1
      }
      if ok {
        total = (total + ways[i + wl]) % m
      }
    }
    ways[i] = total
    i = i - 1
  }
  ways[0]
}

///|
/// `true` iff at least one segmentation of `s` into dictionary words
/// exists.
pub fn can_break(s : Array[Int], dict : Array[Array[Int]]) -> Bool {
  let n = s.length()
  let ok = Array::make(n + 1, false)
  ok[n] = true
  let mut i = n - 1
  while i >= 0 {
    let mut any = false
    for w in dict {
      let wl = w.length()
      if wl == 0 || i + wl > n {
        continue
      }
      let mut k = 0
      let mut match_ok = true
      while k < wl {
        if s[i + k] != w[k] {
          match_ok = false
          break
        }
        k = k + 1
      }
      if match_ok && ok[i + wl] {
        any = true
        break
      }
    }
    ok[i] = any
    i = i - 1
  }
  ok[0]
}

///|
fn arr(str : String) -> Array[Int] {
  let r : Array[Int] = []
  for c in str {
    r.push(c.to_int())
  }
  r
}

///|
test "word break classic catsanddog" {
  let s = arr("catsanddog")
  let dict = [arr("cat"), arr("cats"), arr("and"), arr("sand"), arr("dog")]
  @debug.assert_eq(count(s, dict), 2L)
}

///|
test "word break no segmentation" {
  let s = arr("apple")
  let dict = [arr("app"), arr("ly")]
  @debug.assert_eq(count(s, dict), 0L)
}

///|
test "word break empty string" {
  let dict = [arr("a"), arr("b")]
  // Empty s -> one (vacuous) way.
  @debug.assert_eq(count(arr(""), dict), 1L)
}

///|
test "word break single word" {
  let s = arr("hello")
  let dict = [arr("hello")]
  @debug.assert_eq(count(s, dict), 1L)
}

///|
test "word break many splits" {
  // "aaaaaaa" with dict {"a", "aa", "aaa"} -> count is a Tribonacci-like number.
  let s = arr("aaaaaaa")
  let dict = [arr("a"), arr("aa"), arr("aaa")]
  // Tribonacci(0)=1, T(1)=1, T(2)=2, T(3)=4, T(4)=7, T(5)=13, T(6)=24, T(7)=44.
  @debug.assert_eq(count(s, dict), 44L)
}

///|
test "can_break basic" {
  let s = arr("leetcode")
  let dict = [arr("leet"), arr("code")]
  @debug.assert_eq(can_break(s, dict), true)
  let dict2 = [arr("leet"), arr("cod")]
  @debug.assert_eq(can_break(s, dict2), false)
}

///|
test "can_break overlapping prefixes" {
  let s = arr("aaaa")
  let dict = [arr("a"), arr("aaa")]
  @debug.assert_eq(can_break(s, dict), true)
}

///|
test "word break empty dict" {
  let s = arr("abc")
  let dict : Array[Array[Int]] = []
  @debug.assert_eq(count(s, dict), 0L)
  @debug.assert_eq(can_break(s, dict), false)
}
