// ============================================================================
// Challenge: Z-Algorithm
// ============================================================================

///|
fn min(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
#warnings("+missing_invariant+missing_reasoning")
pub fn z_function(s : StringView) -> Array[Int] {
  let n = s.length()
  if n == 0 {
    return []
  }
  let z = Array::make(n, 0)
  z[0] = n
  for i = 1, l = 0, r = 0 {
    if i >= n {
      break
    }
    let seed = if i < r { min(z[i - l], r - i) } else { 0 }
    let len = for t = seed {
      if i + t < n && s[t] == s[i + t] {
        continue t + 1
      } else {
        break t
      }
    } where {
      invariant: t >= seed && t <= n - i,
      reasoning: (
        #|INVARIANT (Z extend):
        #|t is the current match length between s[0..t) and s[i..i+t).
        #|MAINTENANCE:
        #|If the next characters match, increment t; otherwise stop.
        #|TERMINATION:
        #|When mismatch or end is reached, t is the maximal extension.
      ),
    }
    z[i] = len
    if i + len > r {
      continue i + 1, i, i + len
    } else {
      continue i + 1, l, r
    }
  } where {
    invariant: i >= 1 && i <= n && l >= 0 && l <= r && r <= n,
    reasoning: (
      #|INVARIANT (Z-box):
      #|For all positions < i, z is correct. [l, r) is the current segment
      #|matching the prefix, i.e., s[l..r) == s[0..r-l).
      #|MAINTENANCE:
      #|Seed z[i] from the Z-box if i < r, then extend by comparisons. If the
      #|new match crosses r, update the Z-box to [i, i+z[i]).
      #|TERMINATION:
      #|At i = n, all Z values are computed in linear time.
    ),
  }
  z
}

///|
#warnings("+missing_invariant+missing_reasoning")
pub fn z_search(text : StringView, pattern : StringView) -> Array[Int] {
  let n = text.length()
  let m = pattern.length()
  let matches : Array[Int] = []
  if m == 0 || m > n {
    return matches
  }
  let concat = pattern.to_string() + "#" + text.to_string()
  let z = z_function(concat[:])
  let offset = m + 1
  for i = offset; i < concat.length(); i = i + 1 {
    if z[i] == m {
      matches.push(i - offset)
    }
  } where {
    invariant: i >= offset && i <= concat.length(),
    reasoning: (
      #|INVARIANT (Z scan):
      #|All positions in [offset, i) have been checked for z[i] == m and any
      #|matches have been recorded.
      #|MAINTENANCE:
      #|If z[i] equals m, the pattern matches starting at i - offset.
      #|TERMINATION:
      #|At i = concat.length(), all matches in the text are found.
    ),
  }
  matches
}

///|
test "z_function_basic" {
  assert_eq(z_function("aaaaa"[:]), [5, 4, 3, 2, 1])
  assert_eq(z_function("abacaba"[:]), [7, 0, 1, 0, 3, 0, 1])
}

///|
test "z_search_basic" {
  let text = "ababa"
  let pattern = "aba"
  assert_eq(z_search(text[:], pattern[:]), [0, 2])
}
