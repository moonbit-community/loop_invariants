// ============================================================================
// MINIMUM CYCLIC ROTATION - Booth's Algorithm
// ============================================================================
//
// Booth's algorithm finds the lexicographically smallest rotation of a string
// in linear time. It compares rotations starting at indices i and j, and skips
// dominated candidates using the length of their common prefix k.
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
/// Return the starting index of the lexicographically smallest rotation.
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
    invariant: i >= 0 && j >= 0 && k >= 0 && i <= n && j <= n,
    reasoning: (
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
/// Return the lexicographically smallest rotation of the string.
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
  inspect(min_cyclic_rotation("baca"), content="abac")
  inspect(min_cyclic_rotation_index("baca"), content="3")
}

///|
test "min rotation repeated" {
  inspect(min_cyclic_rotation("ababab"), content="ababab")
}
