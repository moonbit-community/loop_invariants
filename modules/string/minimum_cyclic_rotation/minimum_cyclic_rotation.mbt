// ============================================================================
// MINIMUM CYCLIC ROTATION - Booth's Algorithm
// ============================================================================
//
// Booth's algorithm finds the lexicographically smallest rotation of a string
// in linear time. It compares rotations starting at indices i and j, and skips
// dominated candidates using the length of their common prefix k.
//
// CORE IDEA:
// Work on the doubled string "s + s" so that rotation i corresponds to the
// slice doubled[i .. i+n), avoiding modulo arithmetic inside the hot loop.
// Two candidate starts i and j are compared character by character; when a
// mismatch is found at offset k, all starts from the losing candidate up to
// offset k are dominated in one jump, giving the O(n) bound.
//
// TIME COMPLEXITY: O(n)
// SPACE COMPLEXITY: O(n)

///|
fn slice_rotation(s : String, start : Int, len : Int) -> String {
  let sb = StringBuilder::new()
  for offset in 0..<len {
    let ch = s[start + offset].to_int()
    sb.write_char(ch.unsafe_to_char())
  }
  sb.to_string()
}

///|
/// Return the starting index of the lexicographically smallest rotation of `s`.
///
/// Among all `n` rotations of `s`, this function identifies the one that comes
/// first in dictionary order.  When two or more rotations are equal (possible
/// only for strings with repeated structure such as `"abab"`), the smallest
/// starting index is returned.
///
/// The search uses **Booth's algorithm**: it maintains two candidate rotation
/// starts `i` and `j` together with a common-prefix length `k`, and eliminates
/// losing candidates in bulk on each mismatch.  Because every index from `0` to
/// `n-1` is eliminated at most once, the total number of character comparisons
/// is O(n).
///
/// Parameters:
/// - `s` - the input string (any length, including empty)
///
/// Returns the 0-based index into `s` at which the minimum rotation begins.
/// Returns `0` for the empty string and for single-character strings.
///
/// Time complexity: O(n), where n = `s.length()`
/// Space complexity: O(n) for the doubled string
///
/// Example:
/// ```
/// // "baca": rotations are "baca", "acab", "caba", "abac"
/// //         minimum is "abac", which starts at index 3
/// let idx = min_cyclic_rotation_index("baca")
/// // idx == 3
///
/// // "abab": rotations "abab" (idx 0) and "abab" (idx 2) tie; smallest index wins
/// let idx2 = min_cyclic_rotation_index("abab")
/// // idx2 == 0
/// ```
pub fn min_cyclic_rotation_index(s : String) -> Int {
  let n = s.length()
  if n == 0 {
    return 0
  }
  let doubled = s + s
  let (i, j) = for i = 0, j = 1, k = 0 {
    if i >= n || j >= n || k >= n {
      break (i, j)
    } else {
      let a = doubled[i + k]
      let b = doubled[j + k]
      if a == b {
        continue i, j, k + 1
      } else if a > b {
        let next_i = i + k + 1
        let next_i = if next_i <= j { j + 1 } else { next_i }
        continue next_i, j, 0
      } else {
        let next_j = j + k + 1
        let next_j = if next_j <= i { i + 1 } else { next_j }
        continue i, next_j, 0
      }
    }
  } where {
    proof_invariant: i >= 0 && j >= 0 && k >= 0 && i <= n && j <= n,
    proof_reasoning: (
      #|INVARIANT (Booth scan):
      #|i and j are candidate rotation starts; all indices less than min(i, j)
      #|have been ruled out as strictly worse. k is the common prefix length of
      #|the rotations starting at i and j in the doubled string.
      #|MAINTENANCE:
      #|On mismatch, skip the dominated candidate by k+1 positions and reset k.
      #|On equality, extend the common prefix.
      #|TERMINATION:
      #|When i or j reaches n, the remaining candidate is minimal.
    ),
  }
  if i < j {
    i
  } else {
    j
  }
}

///|
/// Return the lexicographically smallest rotation of `s`.
///
/// This is a convenience wrapper around `min_cyclic_rotation_index`: it finds
/// the optimal starting index and then extracts the corresponding length-`n`
/// slice from the doubled string `s + s`.
///
/// Parameters:
/// - `s` - the input string (any length, including empty)
///
/// Returns the rotation of `s` that is smallest in lexicographic (dictionary)
/// order.  Returns `""` for the empty string.
///
/// Time complexity: O(n), where n = `s.length()`
/// Space complexity: O(n)
///
/// Example:
/// ```
/// // Rotations of "baca": "baca", "acab", "caba", "abac"
/// let r = min_cyclic_rotation("baca")
/// // r == "abac"
///
/// // Already the minimum rotation
/// let r2 = min_cyclic_rotation("abac")
/// // r2 == "abac"
///
/// // All characters equal: any rotation is the same
/// let r3 = min_cyclic_rotation("aaaa")
/// // r3 == "aaaa"
/// ```
pub fn min_cyclic_rotation(s : String) -> String {
  let n = s.length()
  if n == 0 {
    return ""
  }
  let idx = min_cyclic_rotation_index(s)
  let doubled = s + s
  slice_rotation(doubled, idx, n)
}

// ============================================================================
// TESTS
// ============================================================================

///|
test "min rotation basic" {
  debug_inspect(min_cyclic_rotation("baca"), content=(
    #|"abac"
  ))
  debug_inspect(min_cyclic_rotation_index("baca"), content="3")
}

///|
test "min rotation repeated" {
  debug_inspect(min_cyclic_rotation("ababab"), content=(
    #|"ababab"
  ))
}
