// ============================================================================
// Challenge: Edit Distance (Levenshtein)
// ============================================================================

///|
fn min3(a : Int, b : Int, c : Int) -> Int {
  if a <= b && a <= c {
    a
  } else if b <= c {
    b
  } else {
    c
  }
}

///|
/// Compute edit distance using full DP table.
pub fn edit_distance(s1 : ArrayView[Char], s2 : ArrayView[Char]) -> Int {
  let m = s1.length()
  let n = s2.length()
  let dp : Array[Int] = Array::make((m + 1) * (n + 1), 0)
  for i in 0 ..<= m {
    dp[i * (n + 1)] = i
  }
  for j in 0 ..<= n {
    dp[j] = j
  }
  for i in 1 ..<= m {
    for j in 1 ..<= n {
      let idx = i * (n + 1) + j
      if s1[i - 1] == s2[j - 1] {
        dp[idx] = dp[(i - 1) * (n + 1) + (j - 1)]
      } else {
        dp[idx] = 1 +
          min3(
            dp[(i - 1) * (n + 1) + j],
            dp[i * (n + 1) + (j - 1)],
            dp[(i - 1) * (n + 1) + (j - 1)],
          )
      }
    }
  }
  dp[m * (n + 1) + n]
}

///|
test "edit_distance" {
  let s1 : Array[Char] = ['k', 'i', 't', 't', 'e', 'n']
  let s2 : Array[Char] = ['s', 'i', 't', 't', 'i', 'n', 'g']
  assert_eq(edit_distance(s1[:], s2[:]), 3)
  assert_eq(edit_distance(['a', 'b'][:], ['a', 'c'][:]), 1)
}
