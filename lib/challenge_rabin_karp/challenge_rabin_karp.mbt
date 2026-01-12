// ============================================================================
// Challenge: Rabin-Karp String Matching
// ============================================================================

///|
const RK_BASE : Int64 = 911382323L

///|
const RK_MOD : Int64 = 1000000007L

///|
fn equal_at(text : StringView, pattern : StringView, start : Int) -> Bool {
  let m = pattern.length()
  for j in 0..<m {
    if text[start + j] != pattern[j] {
      return false
    }
  }
  true
}

///|
/// Find all occurrences of pattern in text using Rabin-Karp.
#warnings("+missing_invariant+missing_reasoning")
pub fn rabin_karp_search(text : StringView, pattern : StringView) -> Array[Int] {
  let n = text.length()
  let m = pattern.length()
  let matches : Array[Int] = []
  if m == 0 || m > n {
    return matches
  }
  let mut pattern_hash = 0L
  let mut text_hash = 0L
  for i = 0; i < m; i = i + 1 {
    let p = pattern[i].to_int().to_int64()
    let t = text[i].to_int().to_int64()
    pattern_hash = (pattern_hash * RK_BASE + p) % RK_MOD
    text_hash = (text_hash * RK_BASE + t) % RK_MOD
  } where {
    invariant: i >= 0 && i <= m,
    reasoning: (
      #|INVARIANT (initial hashes):
      #|pattern_hash hashes pattern[0..i) and text_hash hashes text[0..i).
      #|MAINTENANCE:
      #|Append the next character to both rolling hashes.
      #|TERMINATION:
      #|At i = m, both hashes cover the full pattern and first window.
    ),
  }
  let mut base_pow = 1L
  for i = 0; i < m - 1; i = i + 1 {
    base_pow = base_pow * RK_BASE % RK_MOD
  } where {
    invariant: i >= 0 && i <= m - 1,
    reasoning: (
      #|INVARIANT (base power):
      #|base_pow equals RK_BASE^i modulo RK_MOD.
      #|MAINTENANCE:
      #|Multiply by RK_BASE to extend the power.
      #|TERMINATION:
      #|At i = m - 1, base_pow is RK_BASE^(m-1).
    ),
  }
  for i = 0; i <= n - m; i = i + 1 {
    if text_hash == pattern_hash && equal_at(text, pattern, i) {
      matches.push(i)
    }
    if i < n - m {
      let left = text[i].to_int().to_int64()
      let right = text[i + m].to_int().to_int64()
      text_hash = (text_hash - left * base_pow % RK_MOD + RK_MOD) % RK_MOD
      text_hash = (text_hash * RK_BASE + right) % RK_MOD
    }
  } where {
    invariant: i >= 0 && i <= n - m + 1,
    reasoning: (
      #|INVARIANT (window scan):
      #|text_hash is the hash of text[i..i+m). All matches in earlier windows
      #|have been recorded.
      #|MAINTENANCE:
      #|When hashes match, verify the window to avoid collisions, then roll the
      #|hash by removing the left character and adding the new right one.
      #|TERMINATION:
      #|At i = n - m + 1, every window of length m has been checked.
    ),
  }
  matches
}

///|
test "rabin_karp_basic" {
  let text = "abracadabra"
  let pattern = "abra"
  assert_eq(rabin_karp_search(text[:], pattern[:]), [0, 7])
  assert_eq(rabin_karp_search(text[:], "cad"[:]), [4])
  assert_eq(rabin_karp_search(text[:], "xyz"[:]), [])
}
